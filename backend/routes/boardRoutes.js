const express = require('express');
const router = express.Router();
const Board = require('../models/boardModel');
const Project = require('../models/projectModel');
const Task = require('../models/taskModel');
const authMiddleware = require('../middleware/auth');
const Notification = require('../models/notificationModel');
const boardController = require('../controllers/boardController');
const projectTeamMiddleware = require('../middleware/projectTeamMiddleware');
const checkProjectPermission = require('../middleware/checkProjectPermission');
const mongoose = require('mongoose');
const { protect, authorize } = require('../middleware/auth');

// Helper function to update project task counts
async function updateProjectTaskCounts(projectId) {
  try {
    const project = await Project.findById(projectId);
    if (!project) return;

    // Get all boards for this project
    const boards = await Board.find({ project: projectId });
    
    // Get all tasks for these boards
    const tasks = await Task.find({ board: { $in: boards.map(b => b._id) } });
    
    // Update project task counts
    project.totalTasks = tasks.length;
    project.completedTasks = tasks.filter(task => task.status === 'Done').length;
    project.progress = project.totalTasks > 0 
      ? Math.round((project.completedTasks / project.totalTasks) * 100) 
      : 0;
    
    await project.save();
  } catch (error) {
    console.error('Error updating project task counts:', error);
  }
}

// Create a new board
router.post('/projects/:projectId/boards', authMiddleware, projectTeamMiddleware, checkProjectPermission('manage_boards'), async (req, res) => {
  try {
    console.log('=== Board Creation Debug ===');
    console.log('Project ID:', req.params.projectId);
    console.log('Request Body:', req.body);
    console.log('User ID:', req.user.id);

    const { title, deadline, assignedTo, status, type } = req.body;
    console.log('Extracted Data:', { title, deadline, assignedTo, status, type });

    const project = await Project.findById(req.params.projectId);
    console.log('Project Found:', project ? 'Yes' : 'No');
    
    if (!project) {
      console.log('Project not found with ID:', req.params.projectId);
      return res.status(404).json({ message: 'Project not found' });
    }

    console.log('Creating new board...');
    const newBoard = new Board({ 
      title, 
      project: project._id,
      deadline: deadline ? new Date(deadline) : undefined,
      members: assignedTo || [],
      status: status || 'To Do',
      type: type || status || 'To Do'
    });

    console.log('Saving board...');
    await newBoard.save();
    console.log('Board saved successfully:', newBoard);

    console.log('Updating project...');
    project.boards.push(newBoard._id);
    await project.save();
    console.log('Project updated successfully');

    // Update project task counts
    await updateProjectTaskCounts(project._id);

    // Send notifications to assigned users
    if (assignedTo && assignedTo.length > 0) {
      console.log('Creating notifications for assigned users...');
      assignedTo.forEach(async (userId) => {
        const notification = new Notification({
          user: userId,
          type: 'board',
          message: `You have been assigned to a new board: ${title}`
        });
        await notification.save();
      });
    }

    console.log('Sending success response...');
    res.status(201).json(newBoard);
  } catch (error) {
    console.error('Error creating board:');
    console.error('Error message:', error.message);
    console.error('Error stack:', error.stack);
    res.status(500).json({ 
      message: 'Error creating board', 
      error: error.message,
      stack: error.stack 
    });
  }
});

// Get board details
router.get('/:id', authMiddleware, async (req, res) => {
  try {
    const board = await Board.findById(req.params.id)
      .populate('tasks')
      .populate('members', 'name email');
    
    if (!board) return res.status(404).json({ message: 'Board not found' });
    
    res.status(200).json(board);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get all boards for a project
router.get('/project/:projectId', authMiddleware, async (req, res) => {
  try {
    const boards = await Board.find({ project: req.params.projectId })
      .populate('tasks')
      .populate('members', 'name email');
    res.status(200).json(boards);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update a board
router.put('/:id', authMiddleware, projectTeamMiddleware, checkProjectPermission('manage_boards'), async (req, res) => {
  try {
    const { title, deadline, assignedTo } = req.body;
    const board = await Board.findById(req.params.id);
    
    if (!board) return res.status(404).json({ message: 'Board not found' });

    // Check for new assignees to notify
    const newAssignees = assignedTo ? assignedTo.filter(userId => 
      !board.members.includes(userId)
    ) : [];

    const updatedBoard = await Board.findByIdAndUpdate(
      req.params.id,
      { 
        title,
        deadline: deadline ? new Date(deadline) : undefined,
        members: assignedTo || board.members
      },
      { new: true }
    ).populate('tasks').populate('members', 'name email');

    // Update project task counts
    await updateProjectTaskCounts(updatedBoard.project);

    // Send notifications to new assignees
    newAssignees.forEach(async (userId) => {
      const notification = new Notification({
        user: userId,
        type: 'board',
        message: `You have been assigned to the board: ${title}`
      });
      await notification.save();
    });

    res.status(200).json(updatedBoard);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Delete a board
router.delete('/:id', authMiddleware, async (req, res) => {
  try {
    const boardId = req.params.id;
    const userId = req.user.id;

    console.log('Delete Request - Board ID:', boardId, '| User ID:', userId);

    if (!mongoose.Types.ObjectId.isValid(boardId)) {
      return res.status(400).json({ message: 'Invalid board ID format' });
    }

    const board = await Board.findById(boardId);
    if (!board) {
      return res.status(404).json({ message: 'Board not found' });
    }

    const project = await Project.findById(board.project);
    if (!project) {
      return res.status(404).json({ message: 'Associated project not found' });
    }

    if (project.manager.toString() !== userId) {
      return res.status(403).json({ message: 'Only the project owner can delete this board' });
    }

    // Delete all tasks linked to this board
    await Task.deleteMany({ board: board._id });

    // Remove the board from the project
    project.boards.pull(board._id);
    await project.save();

    // Delete the board
    await Board.findByIdAndDelete(boardId);

    return res.status(200).json({ message: 'Board deleted successfully' });
  } catch (error) {
    console.error('Board deletion error:', error);
    return res.status(500).json({ message: 'Failed to delete board', error: error.message });
  }
});

// Update board status
router.put('/:id/status', authMiddleware, async (req, res) => {
  try {
    const { status } = req.body;
    const board = await Board.findById(req.params.id);
    
    if (!board) return res.status(404).json({ message: 'Board not found' });

    board.status = status;
    await board.save();

    // Update project task counts after status change
    await updateProjectTaskCounts(board.project);

    res.status(200).json(board);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Update board positions
router.put('/projects/:projectId/boards/positions', authMiddleware, boardController.updateBoardPositions);

module.exports = router;

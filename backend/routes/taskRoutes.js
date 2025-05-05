const express = require('express');
const router = express.Router();
const Task = require('../models/taskModel');
const Board = require('../models/boardModel');
const Project = require('../models/projectModel');
const authMiddleware = require('../middleware/auth');
const Notification = require('../models/notificationModel');
const upload = require('../middleware/fileUploadMiddleware');

// Helper function to update project task counts
async function updateProjectTaskCounts(boardId) {
  try {
    console.log('=== Updating Project Task Counts ===');
    console.log('Board ID:', boardId);

    // Find the board and populate its project
    const board = await Board.findById(boardId);
    if (!board) {
      console.log('Board not found');
      return;
    }

    // Find the project
    const project = await Project.findById(board.project);
    if (!project) {
      console.log('Project not found');
      return;
    }

    console.log('Project found:', project.title);

    // Get all boards for this project
    const boards = await Board.find({ project: project._id });
    console.log('Found', boards.length, 'boards for project');
    
    // Get all tasks for all boards in this project
    const boardIds = boards.map(b => b._id);
    const tasks = await Task.find({ board: { $in: boardIds } });
    const totalTasks = tasks.length;
    console.log('Found', totalTasks, 'total tasks');
    
    // Count completed tasks (status is 'Done')
    const completedTasks = tasks.filter(task => task.status === 'Done').length;
    console.log('Completed tasks:', completedTasks);
    
    // Calculate progress percentage
    const progress = totalTasks > 0 ? Math.round((completedTasks / totalTasks) * 100) : 0;
    console.log('Calculated progress:', progress + '%');
    
    // Update project with new counts
    project.totalTasks = totalTasks;
    project.completedTasks = completedTasks;
    project.progress = progress;
    
    await project.save();
    console.log('Project updated successfully');
    
    return {
      totalTasks,
      completedTasks,
      progress
    };
  } catch (error) {
    console.error('Error updating project task counts:', error);
    throw error;
  }
}

// Create a new task
router.post('/:boardId', authMiddleware, async (req, res) => {
  try {
    const { title, description, deadline, assignedTo, color } = req.body;
    const board = await Board.findById(req.params.boardId);
    
    if (!board) return res.status(404).json({ message: 'Board not found' });

    const newTask = new Task({ 
      title, 
      description, 
      deadline, 
      board: board._id, 
      assignedTo,
      color: color || '#6B4EFF' // Include color with default fallback
    });
    await newTask.save();

    board.tasks.push(newTask._id);
    await board.save();

    // Update project task counts
    await updateProjectTaskCounts(board._id);

    // Send notifications to assigned users
    assignedTo.forEach(async (userId) => {
      const notification = new Notification({
        user: userId,
        type: 'task',
        message: `You have been assigned a new task: ${title}`
      });
      await notification.save();
    });

    res.status(201).json(newTask);
  } catch (error) {
    res.status(500).json({ message: 'Error creating task', error });
  }
});

// Get all tasks for a board
router.get('/board/:boardId', authMiddleware, async (req, res) => {
  try {
    const tasks = await Task.find({ board: req.params.boardId });
    res.status(200).json(tasks);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get all tasks for a project (Manager and Members allowed)
router.get('/project/:projectId', authMiddleware, async (req, res) => {
  try {
    const projectId = req.params.projectId;
    const userId = req.user.id;

    const project = await Project.findById(projectId);
    if (!project) {
      return res.status(404).json({ message: 'Project not found' });
    }

    // Authorization: only manager or member can access
    const isManager = project.manager.toString() === userId;
    const isMember = project.members.map(m => m.toString()).includes(userId);

    if (!isManager && !isMember) {
      return res.status(403).json({ message: 'Access denied: Not a member or manager of this project.' });
    }

    // Find all boards for this project
    const boards = await Board.find({ project: projectId });

    // Find all tasks in those boards
    const boardIds = boards.map(board => board._id);
    const tasks = await Task.find({ board: { $in: boardIds } })
      .populate('board')
      .populate('assignedTo', 'name email');

    res.status(200).json(tasks);
  } catch (error) {
    console.error('Error fetching project tasks:', error);
    res.status(500).json({ message: 'Error fetching tasks', error: error.message });
  }
});

// Update a task
router.put('/:id', authMiddleware, async (req, res) => {
  try {
    console.log('=== Task Update Debug ===');
    const taskId = req.params.id;
    const userId = req.user.id;
    const updates = req.body;

    console.log('Task ID:', taskId);
    console.log('User ID:', userId);
    console.log('Updates:', updates);

    // Find and validate task
    const task = await Task.findById(taskId);
    if (!task) {
      console.log('Task not found');
      return res.status(404).json({ message: 'Task not found' });
    }
    console.log('Found task:', task);

    // Store the old board ID before updating
    const oldBoardId = task.board;
    console.log('Old Board ID:', oldBoardId);

    // Find and validate old board
    const oldBoard = await Board.findById(oldBoardId);
    if (!oldBoard) {
      console.log('Original board not found');
      return res.status(404).json({ message: 'Original board not found' });
    }
    console.log('Found old board:', oldBoard);

    // Find and validate old project
    const oldProject = await Project.findById(oldBoard.project);
    if (!oldProject) {
      console.log('Original project not found');
      return res.status(404).json({ message: 'Original project not found' });
    }
    console.log('Found old project:', oldProject);

    // Authorization check
    const isManager = oldProject.manager.toString() === userId;
    const isAssigned = task.assignedTo.map(id => id.toString()).includes(userId);

    if (!isManager && !isAssigned) {
      console.log('Authorization failed - User is neither manager nor assigned');
      return res.status(403).json({ message: 'Access denied: Not authorized to update this task.' });
    }

    // If board is being updated, validate new board exists
    if (updates.board && updates.board !== oldBoardId.toString()) {
      console.log('Board change detected. Validating new board...');
      const newBoard = await Board.findById(updates.board);
      if (!newBoard) {
        console.log('New board not found');
        return res.status(404).json({ message: 'New board not found' });
      }
      console.log('New board validated:', newBoard);
    }

    // Update task
    console.log('Updating task...');
    const updatedTask = await Task.findByIdAndUpdate(
      taskId,
      { $set: updates },
      { new: true }
    ).populate('assignedTo', 'name email');

    if (!updatedTask) {
      console.log('Failed to update task');
      return res.status(500).json({ message: 'Failed to update task' });
    }
    console.log('Task updated successfully:', updatedTask);

    // Update project task counts
    console.log('Updating project task counts...');
    try {
      if (updates.board && updates.board !== oldBoardId.toString()) {
        // Update old project's task counts
        await updateProjectTaskCounts(oldBoardId);
        // Update new project's task counts
        await updateProjectTaskCounts(updates.board);
      } else {
        // If the board hasn't changed, just update the current project's task counts
        await updateProjectTaskCounts(oldBoardId);
      }
      console.log('Project task counts updated successfully');
    } catch (countError) {
      console.error('Error updating project task counts:', countError);
      // Don't fail the request if count update fails
    }

    console.log('Sending success response');
    res.status(200).json(updatedTask);
  } catch (error) {
    console.error('Error updating task:', error);
    res.status(500).json({ 
      message: 'Error updating task', 
      error: error.message,
      stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
});

// Delete a task
router.delete('/:id', authMiddleware, async (req, res) => {
  try {
    const task = await Task.findById(req.params.id);
    if (!task) return res.status(404).json({ message: 'Task not found' });

    const boardId = task.board;
    await Task.findByIdAndDelete(req.params.id);

    // Update project task counts
    await updateProjectTaskCounts(boardId);

    res.status(200).json({ message: 'Task deleted' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Attach file to a task
router.post('/:id/attachments', authMiddleware, upload.single('file'), async (req, res) => {
    try {
      const task = await Task.findById(req.params.id);
      if (!task) return res.status(404).json({ message: 'Task not found' });
  
      task.attachments.push(req.file.path); // Save file path
      await task.save();
  
      res.status(200).json({ message: 'File attached successfully', task });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  // Assign a user to a task and notify them
router.post('/:id/assign', async (req, res) => {
  const { userId } = req.body;

  try {
    const task = await Task.findById(req.params.id);
    if (!task) return res.status(404).json({ message: 'Task not found' });

    if (!task.members.includes(userId)) {
      task.members.push(userId);
      await task.save();
      sendNotification(userId, `You have been assigned a new task: ${task.title}`);
    }

    res.status(200).json(task);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Upload a file to a task
router.post('/:id/upload', upload.single('file'), async (req, res) => {
  try {
    const task = await Task.findById(req.params.id);
    if (!task) return res.status(404).json({ message: 'Task not found' });

    task.attachments.push(req.file.path);
    await task.save();

    res.status(200).json({ message: 'File uploaded successfully', file: req.file.path });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get task details by ID
router.get('/:id', authMiddleware, async (req, res) => {
  try {
    console.log('=== Fetching Task Details Debug ===');
    console.log('Task ID:', req.params.id);

    const task = await Task.findById(req.params.id)
      .populate('board')
      .populate('assignedTo', 'name email');

    if (!task) {
      console.log('Task not found with ID:', req.params.id);
      return res.status(404).json({ message: 'Task not found' });
    }

    console.log('Task found:', task);
    res.status(200).json(task);
  } catch (error) {
    console.error('Error fetching task details:', error);
    res.status(500).json({ message: 'Error fetching task details', error: error.message });
  }
});

// Get upcoming tasks (tasks with deadlines in specified date range)
router.get('/filter/upcoming', authMiddleware, async (req, res) => {
  try {
    console.log('=== Fetching Upcoming Tasks Debug ===');
    const startDate = new Date(req.headers['start-date']);
    const endDate = new Date(req.headers['end-date']);
    
    console.log('Searching for tasks with deadlines between:');
    console.log('UTC Start:', startDate.toISOString());
    console.log('UTC End:', endDate.toISOString());
    console.log('Local Start:', startDate.toString());
    console.log('Local End:', endDate.toString());

    // Find tasks that:
    // 1. Have a non-null deadline within the date range
    // 2. Are not completed (status is not 'Done')
    const tasks = await Task.find({
      $and: [
        {
          deadline: {
            $ne: null,  // Only include tasks with non-null deadlines
            $exists: true,
            $gte: startDate,
            $lte: endDate
          }
        },
        {
          status: { $ne: 'Done' }
        }
      ]
    })
    .populate({
      path: 'board',
      populate: {
        path: 'project',
        select: 'title'
      }
    })
    .sort({ deadline: 1 }); // Sort by deadline ascending

    console.log(`Found ${tasks.length} tasks within the date range`);
    
    // Log found tasks for debugging
    if (tasks.length > 0) {
      console.log('Found tasks:');
      tasks.forEach(task => {
        console.log({
          title: task.title,
          deadline: task.deadline,
          deadlineUTC: task.deadline?.toISOString(),
          status: task.status,
          board: task.board?.title,
          project: task.board?.project?.title
        });
      });
    }

    if (tasks.length === 0) {
      return res.status(404).json({ 
        message: 'No upcoming tasks found',
        debug: {
          dateRange: {
            startUtc: startDate.toISOString(),
            endUtc: endDate.toISOString(),
            startLocal: startDate.toString(),
            endLocal: endDate.toString()
          }
        }
      });
    }

    res.status(200).json(tasks);
  } catch (error) {
    console.error('Error fetching upcoming tasks:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get all tasks for the authenticated user
router.get('/', authMiddleware, async (req, res) => {
  try {
    console.log('=== Fetching All Tasks Debug ===');
    const userId = req.user.id;
    console.log('User ID:', userId);

    // Find all projects where user is manager or member
    const projects = await Project.find({
      $or: [
        { manager: userId },
        { members: userId }
      ]
    });
    console.log('Found', projects.length, 'projects for user');

    // Get all boards from these projects
    const projectIds = projects.map(p => p._id);
    const boards = await Board.find({ project: { $in: projectIds } });
    console.log('Found', boards.length, 'boards');

    // Get all tasks from these boards
    const boardIds = boards.map(b => b._id);
    const tasks = await Task.find({ board: { $in: boardIds } })
      .populate('board')
      .populate('assignedTo', 'name email')
      .sort({ deadline: 1 });

    console.log('Found', tasks.length, 'tasks');
    res.status(200).json(tasks);
  } catch (error) {
    console.error('Error fetching all tasks:', error);
    res.status(500).json({ message: 'Error fetching tasks', error: error.message });
  }
});

module.exports = router;

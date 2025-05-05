const express = require('express');
const router = express.Router();
const Project = require('../models/projectModel');
const authMiddleware = require('../middleware/auth');
const roleMiddleware = require('../middleware/roleMiddleware');
const Notification = require('../models/notificationModel');
const { validateRequest, createProjectSchema } = require('../validators/validationSchemas');
const Task = require('../models/taskModel'); 
const Board = require('../models/boardModel');


// List of predefined colors for projects
const projectColors = [
  '#6B4EFF', // Purple
  '#211B4E', // Dark blue
  '#96292B', // Red
  '#808C44', // Olive green
  '#35383F', // Dark gray
];

// Get all tasks for a project (Manager and Members allowed)
router.get('/:id/tasks', authMiddleware, async (req, res) => {
  try {
    const projectId = req.params.id;
    const userId = req.user.id;

    const project = await Project.findById(projectId);

    if (!project) {
      return res.status(404).json({ message: 'Project not found' });
    }

    // Authorization check: manager or member
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


// Get all projects or recent projects
router.get('/', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;
    const isRecent = req.query.recent === 'true';
    const status = req.query.status;

    let query = {
      $or: [
        { manager: userId },
        { members: userId }
      ]
    };

    // Add status filter if provided and not 'all'
    if (status && status !== 'all') {
      query.status = status;
    }

    let projects;
    if (isRecent) {
      // For recent projects, limit to 5 and sort by creation date
      projects = await Project.find(query)
        .sort({ createdAt: -1 })
        .limit(5)
        .populate('manager', 'name email')
        .populate('members', 'name email');
    } else {
      // For all projects
      projects = await Project.find(query)
        .populate('manager', 'name email')
        .populate('members', 'name email');
    }

    console.log(`Found ${projects.length} projects (recent: ${isRecent}, status: ${status})`);
    res.status(200).json(projects);
  } catch (error) {
    console.error('Error fetching projects:', error);
    res.status(500).json({ 
      message: 'Error fetching projects', 
      error: error.message,
      stack: error.stack 
    });
  }
});

// Get project by ID
router.get('/:id', async (req, res) => {
  try {
    const project = await Project.findById(req.params.id).populate('manager members');
    if (!project) return res.status(404).json({ error: 'Project not found' });
    res.status(200).json(project);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update project (only manager can update)
router.put('/:id', authMiddleware, async (req, res) => {
  try {
    const project = await Project.findById(req.params.id);
    if (!project) return res.status(404).json({ message: 'Project not found' });
    if (project.manager.toString() !== req.user.id) {
      return res.status(403).json({ message: 'Only the project manager can edit the project.' });
    }
    const updatedProject = await Project.findByIdAndUpdate(req.params.id, req.body, { new: true });
    res.status(200).json(updatedProject);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Delete project (only manager can delete)
router.delete('/:id', authMiddleware, async (req, res) => {
  try {
    const project = await Project.findById(req.params.id);
    if (!project) return res.status(404).json({ message: 'Project not found' });
    if (project.manager.toString() !== req.user.id) {
      return res.status(403).json({ message: 'Only the project manager can delete the project.' });
    }
    await Project.findByIdAndDelete(req.params.id);
    res.status(200).json({ message: 'Project deleted' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Assign members to a project
router.post('/:id/members', authMiddleware, async (req, res) => {
    const { members } = req.body; // Array of User IDs
  
    try {
      const project = await Project.findById(req.params.id);
      if (!project) return res.status(404).json({ message: 'Project not found' });
  
      // Ensure no duplicate members
      project.members = [...new Set([...project.members, ...members])];
      await project.save();
  
      res.status(200).json({ message: 'Members added successfully', project });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  // Update a project (Manager only)
router.put('/:id', authMiddleware, roleMiddleware(['manager']), async (req, res) => {
    try {
      const updatedProject = await Project.findByIdAndUpdate(req.params.id, req.body, { new: true });
      if (!updatedProject) return res.status(404).json({ message: 'Project not found' });
      res.status(200).json(updatedProject);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  });

// Create a project
router.post('/', authMiddleware, async (req, res) => {
  try {
    const { title, description, deadline, members, color } = req.body;
    
    const newProject = new Project({
      title,
      description,
      deadline,
      manager: req.user.id, // Assigning the creator as manager
      members: [...new Set([...members, req.user.id])], // Ensure manager is also a member
      color: color || projectColors[Math.floor(Math.random() * projectColors.length)], // Use provided color or random if not provided
    });

    await newProject.save();

    // Send notifications to assigned users
    members.forEach(async (userId) => {
      const notification = new Notification({
        user: userId,
        type: 'project',
        message: `You have been assigned a new project: ${title}`
      });
      await notification.save();
    });

    res.status(201).json(newProject);
  } catch (error) {
    res.status(500).json({ message: 'Error creating project', error: error.message });
  }
});

// Update project status based on tasks
router.put('/:id/status', authMiddleware, async (req, res) => {
  try {
    const projectId = req.params.id;
    console.log(`Updating status for project: ${projectId}`);

    // Find the project
    const project = await Project.findById(projectId);
    if (!project) {
      return res.status(404).json({ message: 'Project not found' });
    }

    // Find all boards for this project
    const boards = await Board.find({ project: projectId });
    const boardIds = boards.map(board => board._id);

    // Get all tasks for these boards
    const tasks = await Task.find({ board: { $in: boardIds } });
    
    // Calculate progress
    const totalTasks = tasks.length;
    const completedTasks = tasks.filter(task => task.status === 'Done').length;
    const progress = totalTasks > 0 ? Math.round((completedTasks / totalTasks) * 100) : 0;

    // Update project status based on progress
    let status = 'To Do';
    if (progress >= 100) {
      status = 'Completed';
    } else if (progress > 0) {
      status = 'In Progress';
    }

    // Update the project
    project.status = status;
    project.progress = progress;
    project.totalTasks = totalTasks;
    project.completedTasks = completedTasks;
    await project.save();

    console.log(`Project status updated - Progress: ${progress}%, Status: ${status}`);
    res.status(200).json(project);
  } catch (error) {
    console.error('Error updating project status:', error);
    res.status(500).json({ message: 'Error updating project status', error: error.message });
  }
});

module.exports = router;
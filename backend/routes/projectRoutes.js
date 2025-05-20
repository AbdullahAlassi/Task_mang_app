const express = require('express');
const router = express.Router();
const Project = require('../models/projectModel');
const authMiddleware = require('../middleware/auth');
const roleMiddleware = require('../middleware/roleMiddleware');
const Notification = require('../models/notificationModel');
const { validateRequest, createProjectSchema } = require('../validators/validationSchemas');
const Task = require('../models/taskModel'); 
const Board = require('../models/boardModel');
const { getPersonalProjects } = require('../controllers/projectController');
const mongoose = require('mongoose');


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
    const type = req.query.type; // 'personal' or 'team'

    // Base query for user's projects
    let query = {
      $or: [
        { manager: userId },
        { 'members.userId': userId }
      ]
    };

    // Filter by project type
    if (type === 'personal') {
      query.type = 'personal';
    } else if (type === 'team') {
      query.type = 'team';
      // For team projects, also include projects from user's teams
      query.$or.push({ team: { $in: req.user.teams?.map(t => t.team) || [] } });
    }

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
        .populate('manager', 'name email profilePicture')
        .populate('members.userId', 'name email profilePicture')
        .populate('team', 'name title');
    } else {
      // For all projects
      projects = await Project.find(query)
        .sort({ createdAt: -1 })
        .populate('manager', 'name email profilePicture')
        .populate('members.userId', 'name email profilePicture')
        .populate('team', 'name title');
    }

    console.log(`Found ${projects.length} projects (recent: ${isRecent}, status: ${status}, type: ${type})`);
    res.status(200).json(projects);
  } catch (error) {
    console.error('Error fetching projects:', error);
    res.status(500).json({ 
      message: 'Error fetching projects', 
      error: error.message,
      stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
});

// Get project by ID
router.get('/:id', async (req, res) => {
  try {
    const project = await Project.findById(req.params.id)
    .populate('manager members')
    .populate('members.userId', 'name email profilePicture');
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

    // Handle members update separately
    if (req.body.members && Array.isArray(req.body.members)) {
      const currentMembers = project.members;
      const incomingMemberIds = req.body.members;

      // Keep the manager as owner
      const newMembers = [
        {
          userId: project.manager,
          role: 'owner',
          joinedAt: new Date()
        }
      ];

      // Add other members with their existing roles or default to 'viewer'
      incomingMemberIds.forEach(userId => {
        if (userId !== project.manager.toString()) {
          const existingMember = currentMembers.find(m => m.userId.toString() === userId);
          newMembers.push({
            userId: new mongoose.Types.ObjectId(userId),
            role: existingMember ? existingMember.role : 'viewer',
            joinedAt: existingMember ? existingMember.joinedAt : new Date()
          });
        }
      });

      req.body.members = newMembers;
    }

    const updatedProject = await Project.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true }
    ).populate('manager', 'name email profilePicture')
     .populate('members.userId', 'name email profilePicture');

    res.status(200).json(updatedProject);
  } catch (error) {
    console.error('Error updating project:', error);
    res.status(400).json({ error: error.message });
  }
});


// Delete project (only manager can delete)
router.delete('/:id', authMiddleware, async (req, res) => {
  try {
    const project = await Project.findById(req.params.id);
    if (!project) return res.status(404).json({ message: 'Project not found' });
    // Check if the current user is the project owner (createdBy or role is owner)
    const isOwner = project.createdBy.toString() === req.user.id;
    const isMemberOwner = project.members.some(
      m => m.userId.toString() === req.user.id && m.role === 'owner'
    );
    if (!isOwner && !isMemberOwner) {
      return res.status(403).json({ message: 'Only the project owner can delete the project.' });
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
    const projectId = req.params.id;
    const updates = { ...req.body }; // Copy of the request body

    const project = await Project.findById(projectId);
    if (!project) return res.status(404).json({ message: 'Project not found' });

    // Handle members update separately
    if (updates.members && Array.isArray(updates.members)) {
      const currentMembers = project.members;
      const incomingMemberIds = updates.members.map(String); // Ensure incoming are strings

      const newMembers = incomingMemberIds.map(userId => {
        const existingMember = currentMembers.find(m => m.userId.toString() === userId);
        if (existingMember) {
          // Keep existing member details (userId, role, joinedAt)
          // Ensure userId is stored as ObjectId if needed by your schema
          return { ...existingMember.toObject(), userId: existingMember.userId };
        } else {
          // Add new member with default role
          // Explicitly create a new ObjectId for new members
          return {
            userId: new mongoose.Types.ObjectId(userId), // Convert string to ObjectId
            role: 'member', // Default role for new members
            joinedAt: new Date(),
          };
        }
      });
      project.members = newMembers;
      delete updates.members; // Remove members from the general updates
    }

    // Apply other updates
    Object.assign(project, updates); // Update other fields from req.body

    await project.save(); // Save the updated project

    // Re-populate members if needed for the response
    const updatedProject = await Project.findById(projectId)
      .populate('manager', 'name email profilePicture')
      .populate({
        path: 'members.userId',
        select: 'name email profilePicture',
        strictPopulate: false,
      });


    res.status(200).json(updatedProject);
  } catch (error) {
    console.error('Error updating project:', error);
    res.status(400).json({ 
      message: 'Error updating project', 
      error: error.message,
      stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
});

// Create a project
router.post('/', authMiddleware, async (req, res) => {
  try {
    console.log('=== Project Creation Debug ===');
    console.log('Request Body:', req.body);
    console.log('User ID:', req.user.id);

    const { title, description, deadline, members = [], color, type, team } = req.body;
    const managerId = req.user.id;

    console.log('Extracted Data:', { title, description, deadline, members, color, type, team });

    // Build members array
    const filtered = Array.isArray(members) ? [...new Set(members.filter(m => m !== managerId))] : [];
    console.log('Filtered Members:', filtered);

    const newMembers = [
      {
        userId: managerId,
        role: 'owner',
        joinedAt: new Date()
      },
      ...filtered.map(userId => ({
        userId,
        role: 'viewer',
        joinedAt: new Date()
      }))
    ];
    console.log('New Members Array:', newMembers);

    const newProject = new Project({
      title,
      description,
      deadline,
      manager: managerId,
      members: newMembers,
      color: color || projectColors[Math.floor(Math.random() * projectColors.length)],
      type: type || 'personal',
      team: type === 'team' ? team : undefined,
      createdBy: managerId
    });
    console.log('New Project Object:', newProject);

    const savedProject = await newProject.save();
    console.log('Project Saved Successfully:', savedProject._id);

    if (type === 'team' && team) {
      console.log('Updating team with new project...');
      await require('../models/teamModel').findByIdAndUpdate(team, {
        $push: { projects: savedProject._id }
      });
      console.log('Team updated successfully');
    }

    const populated = await Project.findById(savedProject._id)
      .populate('manager', 'name email profilePicture')
      .populate({
        path: 'members.userId',
        select: 'name email profilePicture',
        strictPopulate: false, // allow skip if userId is invalid
      });
    console.log('Project populated successfully');

    res.status(201).json(populated);
  } catch (error) {
    console.error('=== Project Creation Error ===');
    console.error('Error Type:', error.name);
    console.error('Error Message:', error.message);
    console.error('Error Stack:', error.stack);
    console.error('Request Body:', req.body);
    console.error('User ID:', req.user.id);
    
    // Check for specific error types
    if (error.name === 'ValidationError') {
      console.error('Validation Errors:', Object.keys(error.errors).map(key => ({
        field: key,
        message: error.errors[key].message
      })));
      return res.status(400).json({ 
        message: 'Validation Error', 
        errors: Object.keys(error.errors).map(key => ({
          field: key,
          message: error.errors[key].message
        }))
      });
    }

    if (error.name === 'CastError') {
      console.error('Cast Error Details:', {
        path: error.path,
        value: error.value,
        kind: error.kind
      });
      return res.status(400).json({ 
        message: 'Invalid Data Type', 
        details: {
          path: error.path,
          value: error.value,
          kind: error.kind
        }
      });
    }

    res.status(500).json({ 
      message: 'Error creating project', 
      error: error.message,
      stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
});

router.put('/:projectId/members/:userId', authMiddleware, async (req, res) => {
  try {
    const { projectId, userId } = req.params;
    const { role } = req.body;

    const project = await Project.findById(projectId);
    if (!project) return res.status(404).json({ message: 'Project not found' });

    const memberIndex = project.members.findIndex(m => m.userId.toString() === userId);
    if (memberIndex === -1) {
      return res.status(404).json({ message: 'Member not found in project' });
    }

    project.members[memberIndex].role = role;
    await project.save();

    res.status(200).json({ message: 'Member role updated', project });
  } catch (error) {
    console.error('Error updating project member role:', error);
    res.status(500).json({ message: 'Error updating project member role', error: error.message });
  }
});

router.get('/:projectId/members', authMiddleware, async (req, res) => {
  try {
    const { projectId } = req.params;

    const project = await Project.findById(projectId).populate('members.userId', 'name email profilePicture');
    if (!project) return res.status(404).json({ message: 'Project not found' });

    const members = project.members.map(m => ({
      userId: m.userId._id,
      role: m.role,
      joinedAt: m.joinedAt,
      user: m.userId, // populated user info
    }));

    res.status(200).json(members);
  } catch (error) {
    console.error('Error fetching project members:', error);
    res.status(500).json({ message: 'Failed to fetch project members', error: error.message });
  }
});

router.delete('/:projectId/members/:userId', authMiddleware, async (req, res) => {
  try {
    const { projectId, userId } = req.params;

    const project = await Project.findById(projectId);
    if (!project) return res.status(404).json({ message: 'Project not found' });

    const memberIndex = project.members.findIndex(m => m.userId.toString() === userId);
    if (memberIndex === -1) {
      return res.status(404).json({ message: 'Member not found in project' });
    }

    project.members.splice(memberIndex, 1);
    await project.save();

    res.status(200).json({ message: 'Member removed from project' });
  } catch (error) {
    console.error('Error removing project member:', error);
    res.status(500).json({ message: 'Error removing project member', error: error.message });
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
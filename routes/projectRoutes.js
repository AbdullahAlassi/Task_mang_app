const express = require('express');
const router = express.Router();
const Project = require('../models/projectModel');
const authMiddleware = require('../middleware/auth');
const roleMiddleware = require('../middleware/roleMiddleware');
const { validateRequest, createProjectSchema } = require('../validators/validationSchemas');


// Create a project
router.post(
  '/',
  authMiddleware,
  roleMiddleware(['admin', 'manager']),
  validateRequest(createProjectSchema), // Apply validation
  async (req, res) => {
    const { title, description, deadline } = req.body;

    try {
      const newProject = new Project({
        title,
        description,
        deadline,
        manager: req.user.id,
      });

      await newProject.save();
      res.status(201).json(newProject);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }
);
  

// Get all projects
router.get('/', async (req, res) => {
  try {
    const projects = await Project.find().populate('manager members');
    res.status(200).json(projects);
  } catch (error) {
    res.status(500).json({ error: error.message });
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

// Update project
router.put('/:id', async (req, res) => {
  try {
    const updatedProject = await Project.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
    });
    res.status(200).json(updatedProject);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Delete project
router.delete('/:id', async (req, res) => {
  try {
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

// Create a project (only admin and manager can access)
router.post('/', authMiddleware, roleMiddleware(['admin', 'manager']), async (req, res) => {
  const { title, description, deadline } = req.body;

  try {
    const newProject = new Project({
      title,
      description,
      deadline,
      manager: req.user.id,
    });

    await newProject.save();
    res.status(201).json(newProject);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});


module.exports = router;
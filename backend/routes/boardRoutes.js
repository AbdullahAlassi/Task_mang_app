const express = require('express');
const router = express.Router();
const Board = require('../models/boardModel');
const Project = require('../models/projectModel');
const authMiddleware = require('../middleware/auth');
const Notification = require('../models/notificationModel');


// Create a new board
router.post('/:projectId', authMiddleware, async (req, res) => {
  try {
    const { title, members } = req.body;
    const project = await Project.findById(req.params.projectId);
    
    if (!project) return res.status(404).json({ message: 'Project not found' });

    const newBoard = new Board({ title, project: project._id, members });
    await newBoard.save();
  

    project.boards.push(newBoard._id);
    await project.save();
    // 📌 Send notifications to assigned users
    members.forEach(async (userId) => {
      const notification = new Notification({
        user: userId,
        type: 'board',
        message: `You have been assigned a new board: ${title}`
      });
      await notification.save();
    });

    

    res.status(201).json(newBoard);
  } catch (error) {
    res.status(500).json({ message: 'Error creating board', error });
  }
});
  

// Get all boards for a project
router.get('/project/:projectId', authMiddleware, async (req, res) => {
  try {
    const boards = await Board.find({ project: req.params.projectId });
    res.status(200).json(boards);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update a board
router.put('/:id', authMiddleware, async (req, res) => {
  try {
    const updatedBoard = await Board.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!updatedBoard) return res.status(404).json({ message: 'Board not found' });
    res.status(200).json(updatedBoard);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Delete a board
router.delete('/:id', authMiddleware, async (req, res) => {
  try {
    await Board.findByIdAndDelete(req.params.id);
    res.status(200).json({ message: 'Board deleted' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;

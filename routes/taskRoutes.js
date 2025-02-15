const express = require('express');
const router = express.Router();
const Task = require('../models/taskModel');
const Board = require('../models/boardModel');
const authMiddleware = require('../middleware/auth');
const multer = require('multer');
const upload = multer({ dest: 'uploads/' }); // Save files in 'uploads/' directory
const { sendNotification } = require('../app'); // Import notification function
const upload = require('../middleware/fileUploadMiddleware');

// Create a new task
router.post('/', authMiddleware, async (req, res) => {
  const { title, description, deadline, boardId, members, attachments } = req.body;

  try {
    const board = await Board.findById(boardId);
    if (!board) return res.status(404).json({ message: 'Board not found' });

    const newTask = new Task({
      title,
      description,
      deadline,
      board: boardId,
      project: board.project, // Get project from board
      members: members || [],
      attachments: attachments || [],
    });

    await newTask.save();
    board.tasks.push(newTask._id);
    await board.save();

    res.status(201).json(newTask);
  } catch (error) {
    res.status(400).json({ error: error.message });
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

// Update a task
router.put('/:id', authMiddleware, async (req, res) => {
  try {
    const updatedTask = await Task.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!updatedTask) return res.status(404).json({ message: 'Task not found' });
    res.status(200).json(updatedTask);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Delete a task
router.delete('/:id', authMiddleware, async (req, res) => {
  try {
    await Task.findByIdAndDelete(req.params.id);
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

module.exports = router;

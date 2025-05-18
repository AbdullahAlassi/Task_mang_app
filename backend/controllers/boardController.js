const mongoose = require('mongoose');
const Board = require('../models/boardModel');

// Update board positions
exports.updateBoardPositions = async (req, res) => {
  try {
    console.log('=== Updating Board Positions Debug ===');
    const { projectId } = req.params;
    const { boardIds } = req.body;

    console.log('Project ID:', projectId);
    console.log('Board IDs:', boardIds);

    // Validate input
    if (!Array.isArray(boardIds)) {
      console.log('Invalid input: boardIds is not an array');
      return res.status(400).json({ message: 'Invalid input: boardIds must be an array' });
    }

    // First, verify all boards belong to the specified project
    console.log('Verifying boards belong to project...');
    const boards = await Board.find({
      _id: { $in: boardIds },
      project: projectId
    });

    console.log('Found boards:', boards.map(b => ({ id: b._id, title: b.title })));

    if (boards.length !== boardIds.length) {
      console.log('Board count mismatch. Found:', boards.length, 'Expected:', boardIds.length);
      return res.status(400).json({ 
        message: 'Some boards do not belong to the specified project or do not exist' 
      });
    }

    // Update each board's position
    console.log('Updating board positions...');
    const updatePromises = boardIds.map((boardId, index) => {
      console.log(`Setting position ${index} for board ${boardId}`);
      return Board.findByIdAndUpdate(
        boardId,
        { position: index },
        { new: true, runValidators: true }
      ).exec();
    });

    const updatedBoards = await Promise.all(updatePromises);
    console.log('Updated boards:', updatedBoards.map(b => ({ id: b._id, title: b.title, position: b.position })));

    res.json({ 
      message: 'Board positions updated successfully',
      boards: updatedBoards.map(b => ({ id: b._id, title: b.title, position: b.position }))
    });
  } catch (error) {
    console.error('Error updating board positions:', error);
    res.status(500).json({ 
      message: 'Error updating board positions', 
      error: error.message,
      details: error.stack 
    });
  }
}; 
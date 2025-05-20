const mongoose = require('mongoose');
const Board = require('../models/boardModel');
const Task = require('../models/taskModel');
const Project = require('../models/projectModel');

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

// Delete a board
exports.deleteBoard = async (req, res) => {
  console.log('\n=== Board Deletion Debug ===');
  console.log('Raw board ID:', req.params.id);

  // Validate ObjectId format
  if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
    console.log('Invalid board ID format');
    return res.status(400).json({ message: 'Invalid board ID format' });
  }

  const boardId = new mongoose.Types.ObjectId(req.params.id);
  console.log('Validated board ID:', boardId);

  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    console.log('Finding board...');
    const board = await Board.findById(boardId).session(session);
    
    if (!board) {
      console.log('Board not found');
      await session.abortTransaction();
      session.endSession();
      return res.status(404).json({ message: 'Board not found' });
    }
    console.log('Board found:', { id: board._id, title: board.title });

    // Store project ID before deletion
    const projectId = board.project;
    console.log('Associated project ID:', projectId);

    // Remove all tasks under this board
    console.log('Deleting associated tasks...');
    const deleteTasksResult = await Task.deleteMany({ board: boardId }).session(session);
    console.log(`Deleted ${deleteTasksResult.deletedCount} tasks`);

    // Remove board from project's board list
    console.log('Removing board from project...');
    const updateProjectResult = await Project.updateOne(
      { _id: projectId },
      { $pull: { boards: boardId } }
    ).session(session);
    console.log('Project update result:', updateProjectResult);

    // Delete the board itself
    console.log('Deleting board...');
    const deleteBoardResult = await Board.findByIdAndDelete(boardId).session(session);
    console.log('Board deletion result:', deleteBoardResult);

    // Update project task counts
    console.log('Updating project task counts...');
    await updateProjectTaskCounts(projectId);

    await session.commitTransaction();
    session.endSession();
    console.log('Transaction committed successfully');

    res.status(200).json({ 
      message: 'Board deleted successfully',
      deletedBoard: {
        id: boardId,
        title: board.title
      }
    });
  } catch (err) {
    console.error('\n=== Board Deletion Error ===');
    console.error('Error:', err);
    console.error('Stack:', err.stack);
    
    await session.abortTransaction();
    session.endSession();
    
    res.status(500).json({ 
      message: 'Failed to delete board', 
      error: err.message,
      stack: process.env.NODE_ENV === 'development' ? err.stack : undefined
    });
  }
}; 
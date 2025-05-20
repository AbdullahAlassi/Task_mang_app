const mongoose = require('mongoose');
const Project = require('../models/projectModel');

// GET /api/projects/personal
exports.getPersonalProjects = async (req, res) => {
  console.log('[getPersonalProjects] START');
  console.log('[getPersonalProjects] req.user:', req.user);
  try {
    const userId = req.user && req.user.id;
    console.log('[getPersonalProjects] userId:', userId);
    if (!userId || typeof userId !== 'string' || !mongoose.Types.ObjectId.isValid(userId)) {
      console.error('[getPersonalProjects] Invalid user ID:', userId);
      return res.status(400).json({ message: 'Invalid user ID' });
    }
    let projects = [];
    try {
      projects = await Project.find({
        type: 'personal',
        members: { $in: [userId] }
      }).select('_id title description deadline status progress color members');
      console.log('[getPersonalProjects] Projects found:', projects.length);
      return res.status(200).json(projects);
    } catch (error) {
      console.error('[getPersonalProjects] Mongoose error:', error);
      // Optional fallback: return empty array instead of crashing
      return res.status(200).json([]);
      // Or, if you want to see the error in the client, use:
      // return res.status(500).json({ message: 'Failed to load personal projects', error: error.message });
    }
  } catch (err) {
    console.error('[getPersonalProjects] Fatal error:', err);
    return res.status(500).json({ message: 'Failed to load personal projects', error: err.message });
  }
}; 
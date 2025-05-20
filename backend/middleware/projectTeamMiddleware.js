const ProjectTeam = require('../models/projectTeamModel');
const Project = require('../models/projectModel');
const { standardizeRole } = require('../utils/projectPermissions');
const Task = require('../models/taskModel');

const projectTeamMiddleware = async (req, res, next) => {
  try {
    const userId = req.user.id;

    // Infer projectId from board if not directly provided
    if (req.params.boardId) {
      const Board = require('../models/boardModel');
      const board = await Board.findById(req.params.boardId);
      if (!board) return res.status(404).json({ message: 'Board not found in middleware' });
      req.projectId = board.project.toString();
    } else if (req.params.taskId || req.params.id) {
      const taskId = req.params.taskId || req.params.id;
      const task = await Task.findById(taskId).populate('board');
      if (!task || !task.board) {
        return res.status(404).json({ message: 'Task or its board not found' });
      }
      req.projectId = task.board.project.toString();
    } else if (req.params.projectId) {
      req.projectId = req.params.projectId;
    } else {
      return res.status(400).json({ message: 'Missing project, board, or task identifier in request' });
    }

    // Check if project exists
    const project = await Project.findById(req.projectId);
    if (!project) {
      return res.status(404).json({ message: 'Project not found' });
    }

    // If the user is the creator, they are the owner
    if (project.createdBy.toString() === userId) {
      req.userRole = 'owner';
      req.projectTeam = { role: 'owner' };
      return next();
    }

    // First, check ProjectTeam model
    const teamRecord = await ProjectTeam.findOne({ projectId: req.projectId, userId });
    if (teamRecord) {
      req.userRole = standardizeRole(teamRecord.role);
      req.projectTeam = teamRecord;
      return next();
    }

    // If not found in ProjectTeam, fallback to embedded project.members
    const memberEntry = project.members.find(m => m.userId.toString() === userId);
    if (memberEntry) {
      req.userRole = standardizeRole(memberEntry.role);
      req.projectTeam = memberEntry;
      return next();
    }

    // If no membership is found at all
    req.userRole = 'viewer';
    req.projectTeam = { role: 'viewer' };
    return res.status(403).json({ message: 'Access denied: not a project member' });
  } catch (error) {
    console.error('Project Team Middleware Error:', error);
    return res.status(500).json({ message: 'Error checking project team membership' });
  }
};

module.exports = projectTeamMiddleware; 
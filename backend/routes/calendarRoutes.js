const express = require('express');
const router = express.Router();
const Task = require('../models/taskModel');
const Project = require('../models/projectModel');
const Board = require('../models/boardModel');
const authMiddleware = require('../middleware/auth');

// Get calendar events for a date range
router.get('/events', authMiddleware, async (req, res) => {
  try {
    console.log('=== Fetching Calendar Events Debug ===');
    const userId = req.user.id;
    const startDate = new Date(req.query.start);
    const endDate = new Date(req.query.end);
    
    console.log('Date Range:', {
      start: startDate.toISOString(),
      end: endDate.toISOString(),
      user: userId
    });

    // Find all projects where user is manager or member
    const projects = await Project.find({
      $or: [
        { manager: userId },
        { members: userId }
      ],
      $or: [
        { deadline: { $gte: startDate, $lte: endDate } },
        { status: { $ne: 'Completed' } }
      ]
    }).select('_id title deadline color status');

    // Find all teams the user is a member of
    const userTeams = await require('../models/teamModel').find({
      'members.user': userId
    }).select('_id');
    const userTeamIds = userTeams.map(t => t._id);

    // Find all boards for the user's projects
    const boards = await Board.find({ project: { $in: projects.map(p => p._id) } }).select('_id');
    const boardIds = boards.map(b => b._id);

    // Find all tasks with deadlines in the date range, assigned to the user (directly or via team), and in user's projects
    const tasks = await Task.find({
      deadline: { $gte: startDate, $lte: endDate },
      board: { $in: boardIds },
      $or: [
        { assignedTo: userId },
        { assignedTeam: { $in: userTeamIds } }
      ]
    })
    .populate({
      path: 'board',
      select: 'title project',
      populate: {
        path: 'project',
        select: 'title color'
      }
    })
    .select('title deadline status color board');

    // Format events for calendar
    const events = [
      // Format project events
      ...projects.map(project => ({
        id: `project_${project._id}`,
        title: `${project.title} (Project)`,
        start: project.deadline,
        end: project.deadline ? new Date(project.deadline.getTime() + 60 * 60 * 1000) : null, // 1 hour duration
        color: project.color,
        type: 'project',
        status: project.status,
        allDay: false
      })),
      // Format task events
      ...tasks.map(task => ({
        id: `task_${task._id}`,
        title: task.title,
        start: task.deadline,
        end: task.deadline ? new Date(task.deadline.getTime() + 60 * 60 * 1000) : null, // 1 hour duration
        color: task.color || task.board?.project?.color || '#6B4EFF',
        type: 'task',
        status: task.status,
        projectTitle: task.board?.project?.title,
        allDay: false
      }))
    ].filter(event => event.start != null); // Filter out events without start dates

    console.log(`Found ${events.length} events (${projects.length} projects, ${tasks.length} tasks)`);
    res.status(200).json(events);
  } catch (error) {
    console.error('Error fetching calendar events:', error);
    res.status(500).json({ 
      message: 'Error fetching calendar events', 
      error: error.message 
    });
  }
});

module.exports = router; 
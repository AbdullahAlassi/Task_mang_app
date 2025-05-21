const express = require('express');
const router = express.Router();
const Team = require('../models/teamModel');
const User = require('../models/userModel');
const authMiddleware = require('../middleware/auth');
const { validateRequest, createTeamSchema } = require('../validators/validationSchemas');

// Helper to check if user is team_leader
async function isTeamLeader(team, userId) {
  return team.members.some(m => m.user.toString() === userId && m.role === 'team_leader');
}

// Create a new team
router.post('/', authMiddleware, async (req, res) => {
  const { name, description, type, parent } = req.body;

  try {
    if (parent) {
      const parentTeam = await Team.findById(parent);
      if (!parentTeam) {
        return res.status(400).json({ error: 'Parent team not found' });
      }
      if (!(await isTeamLeader(parentTeam, req.user.id))) {
        return res.status(403).json({ message: 'Only the team leader can create a subteam.' });
      }
    }

    // Create new team with creator as team_leader and member
    const newTeam = new Team({
      name,
      description,
      type,
      manager: req.user.id,
      members: [{ user: req.user.id, role: 'team_leader' }],
      parent: parent || null,
      children: []
    });

    await newTeam.save();

    // If parent team exists, add this team to its children
    if (parent) {
      await Team.findByIdAndUpdate(parent, {
        $push: { children: newTeam._id }
      });
    }

    // Update user's team memberships
    await User.findByIdAndUpdate(req.user.id, {
      $push: { teams: { team: newTeam._id, role: 'team_leader' } }
    });

    // Populate parent and children info in response
    const populatedTeam = await Team.findById(newTeam._id)
      .populate('parent', 'name')
      .populate('children', 'name')
      .populate('manager', 'name email')
      .populate('members.user', 'name email');

    res.status(201).json(populatedTeam);
  } catch (error) {
    console.error('Error creating team:', error);
    res.status(400).json({ error: error.message });
  }
});

// Get all teams (hierarchical structure)
router.get('/', authMiddleware, async (req, res) => {
  try {
    const teams = await Team.find()
      .populate('parent', 'name')
      .populate('children', 'name')
      .populate('members.user', 'name email profilePicture')
      .sort({ createdAt: -1 });

    res.status(200).json(teams);
  } catch (error) {
    console.error('Error fetching teams:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get team by ID with full details
router.get('/:id', authMiddleware, async (req, res) => {
  try {
    const team = await Team.findById(req.params.id)
      .populate('parent', 'name')
      .populate('children', 'name')
      .populate('members.user', 'name email profilePicture')
      .populate('members.responsibilities')
      .populate('members.skills');

    if (!team) {
      return res.status(404).json({ message: 'Team not found' });
    }

    res.status(200).json(team);
  } catch (error) {
    console.error('Error fetching team:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get team hierarchy
router.get('/:id/hierarchy', authMiddleware, async (req, res) => {
  try {
    const team = await Team.findById(req.params.id);
    if (!team) {
      return res.status(404).json({ message: 'Team not found' });
    }

    const hierarchy = await team.getHierarchyPath();
    res.status(200).json(hierarchy);
  } catch (error) {
    console.error('Error fetching team hierarchy:', error);
    res.status(500).json({ error: error.message });
  }
});

// Update a team
router.put('/:id', authMiddleware, async (req, res) => {
  const { name, description, parent, members, department, type, metadata, settings } = req.body;

  try {
    const team = await Team.findById(req.params.id);
    if (!team) {
      return res.status(404).json({ message: 'Team not found' });
    }
    if (!(await isTeamLeader(team, req.user.id))) {
      return res.status(403).json({ message: 'Only the team leader can edit the team.' });
    }

    // Handle parent team change
    if (parent && parent !== team.parent?.toString()) {
      // Remove from old parent's children
      if (team.parent) {
        await Team.findByIdAndUpdate(team.parent, {
          $pull: { children: team._id }
        });
      }
      // Add to new parent's children
      await Team.findByIdAndUpdate(parent, {
        $push: { children: team._id }
      });
    }

    const updatedTeam = await Team.findByIdAndUpdate(
      req.params.id,
      {
        name,
        description,
        parent: parent || null,
        members,
        department,
        type,
        metadata,
        settings
      },
      { new: true }
    )
      .populate('parent', 'name')
      .populate('children', 'name')
      .populate('members.user', 'name email profilePicture');

    res.status(200).json(updatedTeam);
  } catch (error) {
    console.error('Error updating team:', error);
    res.status(400).json({ error: error.message });
  }
});

// Delete a team
router.delete('/:id', authMiddleware, async (req, res) => {
  try {
    const team = await Team.findById(req.params.id);
    if (!team) {
      return res.status(404).json({ message: 'Team not found' });
    }
    if (!(await isTeamLeader(team, req.user.id))) {
      return res.status(403).json({ message: 'Only the team leader can delete the team.' });
    }

    // Remove from parent's children
    if (team.parent) {
      await Team.findByIdAndUpdate(team.parent, {
        $pull: { children: team._id }
      });
    }

    // Remove team from users' team memberships
    const memberIds = team.members.map(m => m.user);
    await User.updateMany(
      { _id: { $in: memberIds } },
      { $pull: { teams: { team: team._id } } }
    );

    // Delete all child teams
    await Team.deleteMany({ parent: team._id });

    // Delete the team
    await Team.findByIdAndDelete(team._id);

    res.status(200).json({ message: 'Team and sub-teams deleted successfully' });
  } catch (error) {
    console.error('Error deleting team:', error);
    res.status(500).json({ error: error.message });
  }
});

// Add member to team
router.post('/:id/members', authMiddleware, async (req, res) => {
  const { userId, role, responsibilities, skills } = req.body;

  try {
    const team = await Team.findById(req.params.id);
    if (!team) {
      return res.status(404).json({ message: 'Team not found' });
    }
    if (!(await isTeamLeader(team, req.user.id))) {
      return res.status(403).json({ message: 'Only the team leader can add members.' });
    }

    // Check if user is already a member
    const existingMember = team.members.find(m => m.user.toString() === userId);
    if (existingMember) {
      return res.status(400).json({ message: 'User is already a member of this team' });
    }

    // Add member to team
    team.members.push({
      user: userId,
      role,
      responsibilities: responsibilities || [],
      skills: skills || []
    });

    await team.save();

    // Update user's team membership
    await User.findByIdAndUpdate(userId, {
      $push: { teams: { team: team._id, role } }
    });

    const updatedTeam = await Team.findById(req.params.id)
      .populate('parent', 'name')
      .populate('children', 'name')
      .populate('members.user', 'name email profilePicture');

    res.status(200).json(updatedTeam);
  } catch (error) {
    console.error('Error adding team member:', error);
    res.status(400).json({ error: error.message });
  }
});

// Remove member from team
router.delete('/:id/members/:userId', authMiddleware, async (req, res) => {
  try {
    const team = await Team.findById(req.params.id);
    if (!team) {
      return res.status(404).json({ message: 'Team not found' });
    }
    if (!(await isTeamLeader(team, req.user.id))) {
      return res.status(403).json({ message: 'Only the team leader can remove members.' });
    }

    // Remove member from team
    team.members = team.members.filter(m => m.user.toString() !== req.params.userId);
    await team.save();

    // Update user's team membership
    await User.findByIdAndUpdate(req.params.userId, {
      $pull: { teams: { team: team._id } }
    });

    const updatedTeam = await Team.findById(req.params.id)
      .populate('parent', 'name')
      .populate('children', 'name')
      .populate('members.user', 'name email profilePicture');

    res.status(200).json(updatedTeam);
  } catch (error) {
    console.error('Error removing team member:', error);
    res.status(400).json({ error: error.message });
  }
});

// Update member role
router.put('/:id/members/:userId/role', authMiddleware, async (req, res) => {
  const { role } = req.body;

  try {
    const team = await Team.findById(req.params.id);
    if (!team) {
      return res.status(404).json({ message: 'Team not found' });
    }
    if (!(await isTeamLeader(team, req.user.id))) {
      return res.status(403).json({ message: 'Only the team leader can update member roles.' });
    }

    // Update member role in team
    const member = team.members.find(m => m.user.toString() === req.params.userId);
    if (!member) {
      return res.status(404).json({ message: 'Member not found in team' });
    }

    // If setting to team_leader, demote any existing team_leader to member
    if (role === 'team_leader') {
      team.members.forEach(m => {
        if (m.role === 'team_leader') {
          m.role = 'member';
        }
      });
    }

    member.role = role;
    await team.save();

    // Update user's team role
    await User.updateOne(
      { _id: req.params.userId, 'teams.team': team._id },
      { $set: { 'teams.$.role': role } }
    );

    // If demoted someone, update their user doc as well
    if (role === 'team_leader') {
      for (const m of team.members) {
        if (m.user.toString() !== req.params.userId && m.role === 'member') {
          await User.updateOne(
            { _id: m.user, 'teams.team': team._id },
            { $set: { 'teams.$.role': 'member' } }
          );
        }
      }
    }

    const updatedTeam = await Team.findById(req.params.id)
      .populate('parent', 'name')
      .populate('children', 'name')
      .populate('members.user', 'name email profilePicture');

    res.status(200).json(updatedTeam);
  } catch (error) {
    console.error('Error updating member role:', error);
    res.status(400).json({ error: error.message });
  }
});

// Get total task count for a team (across all its projects)
router.get('/:id/taskCount', authMiddleware, async (req, res) => {
  try {
    const teamId = req.params.id;
    const Project = require('../models/projectModel');
    const Board = require('../models/boardModel');
    const Task = require('../models/taskModel');

    // 1. Find all projects for this team
    const projects = await Project.find({ team: teamId });
    const projectIds = projects.map(p => p._id);

    // 2. Find all boards for these projects
    const boards = await Board.find({ project: { $in: projectIds } });
    const boardIds = boards.map(b => b._id);

    // 3. Count all tasks in these boards
    const count = await Task.countDocuments({ board: { $in: boardIds } });

    res.status(200).json({ count });
  } catch (error) {
    console.error('Error getting team task count:', error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;

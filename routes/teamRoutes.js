const express = require('express');
const router = express.Router();
const Team = require('../models/teamModel');
const authMiddleware = require('../middleware/auth');

// Create a new team
router.post('/', authMiddleware, async (req, res) => {
  const { name, parent, members } = req.body;

  try {
    const newTeam = new Team({ name, parent: parent || null, members: members || [] });
    await newTeam.save();

    res.status(201).json(newTeam);
  } catch (error) {
    console.error('Error creating team:', error);
    res.status(400).json({ error: error.message });
  }
});

module.exports = router;

// Get all teams (hierarchical structure)
router.get('/', authMiddleware, async (req, res) => {
    try {
      const teams = await Team.find()
        .populate('parent', 'name') // Include parent team name
        .populate('members.user', 'name email'); // Include user details for members
  
      res.status(200).json(teams);
    } catch (error) {
      console.error('Error fetching teams:', error);
      res.status(500).json({ error: error.message });
    }
  });
  
  // Update a team
router.put('/:id', authMiddleware, async (req, res) => {
    const { name, parent, members } = req.body;
  
    try {
      const updatedTeam = await Team.findByIdAndUpdate(
        req.params.id,
        { name, parent: parent || null, members },
        { new: true }
      )
        .populate('parent', 'name') // Include parent team name
        .populate('members.user', 'name email'); // Include user details for members
  
      if (!updatedTeam) {
        return res.status(404).json({ message: 'Team not found' });
      }
  
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
  
      // Optionally handle deletion of sub-teams
      await Team.deleteMany({ parent: team._id });
  
      await team.remove();
      res.status(200).json({ message: 'Team and sub-teams deleted' });
    } catch (error) {
      console.error('Error deleting team:', error);
      res.status(500).json({ error: error.message });
    }
  });
  
  // Assign roles to users in a team
router.post('/:id/assign-roles', authMiddleware, async (req, res) => {
    const { userId, role } = req.body;
  
    try {
      const team = await Team.findById(req.params.id);
      if (!team) {
        return res.status(404).json({ message: 'Team not found' });
      }
  
      // Check if user already exists in team
      const member = team.members.find((member) => member.user.toString() === userId);
      if (member) {
        member.role = role; // Update role
      } else {
        team.members.push({ user: userId, role }); // Add new member with role
      }
  
      await team.save();
      res.status(200).json({ message: 'Role assigned successfully', team });
    } catch (error) {
      console.error('Error assigning roles:', error);
      res.status(400).json({ error: error.message });
    }
  });
  
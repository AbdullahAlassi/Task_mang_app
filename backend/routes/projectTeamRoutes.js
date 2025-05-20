const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth');
const projectTeamMiddleware = require('../middleware/projectTeamMiddleware');
const checkProjectPermission = require('../middleware/checkProjectPermission');
const projectTeamController = require('../controllers/projectTeamController');

// Apply auth middleware to all routes
router.use(authMiddleware);

// Apply project team middleware to all routes
router.use('/:projectId/*', projectTeamMiddleware);

// Add member to project team
router.post(
  '/:projectId/members',
  checkProjectPermission('invite_members'),
  projectTeamController.addMember
);

// Remove member from project team
router.delete(
  '/:projectId/members/:userId',
  checkProjectPermission('assign_roles'),
  projectTeamController.removeMember
);

// Update member role
router.put(
  '/:projectId/members/:userId/role',
  checkProjectPermission('assign_roles'),
  projectTeamController.updateMemberRole
);

// Get all project members
router.get(
  '/:projectId/members',
  checkProjectPermission('view'),
  projectTeamController.getProjectMembers
);

module.exports = router; 
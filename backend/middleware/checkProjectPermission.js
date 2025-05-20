const { canPerformAction } = require('../utils/projectPermissions');

const checkProjectPermission = (requiredPermission) => {
  return async (req, res, next) => {
    try {
      const userRole = req.userRole;
      
      if (!userRole) {
        return res.status(403).json({ 
          message: 'User role not found. Please ensure projectTeamMiddleware is used before this middleware.' 
        });
      }

      // Optionally, fetch the project for more advanced permission checks
      // const Project = require('../models/projectModel');
      // const project = await Project.findById(req.projectId);
      // if (!project) return res.status(404).json({ message: 'Project not found in permissions check' });

      if (!req.userRole) {
        return res.status(403).json({ message: 'Permission denied: role not found' });
      }

      if (!canPerformAction(req.userRole, requiredPermission)) {
        return res.status(403).json({ 
          message: `Permission denied. Required permission: ${requiredPermission}` 
        });
      }

      next();
    } catch (error) {
      console.error('Permission Check Error:', error);
      res.status(500).json({ message: 'Error checking permissions' });
    }
  };
};

module.exports = checkProjectPermission; 
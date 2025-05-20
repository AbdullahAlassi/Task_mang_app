const mongoose = require('mongoose');

const projectTeamSchema = new mongoose.Schema({
  projectId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Project', 
    required: true 
  },
  userId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User', 
    required: true 
  },
  role: {
    type: String,
    enum: ['owner', 'admin', 'member', 'viewer'],
    default: 'member'
  },
  joinedAt: {
    type: Date,
    default: Date.now
  },
  addedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  }
}, { 
  timestamps: true 
});

// Create compound index for projectId and userId
projectTeamSchema.index({ projectId: 1, userId: 1 }, { unique: true });

// Virtual for getting user details
projectTeamSchema.virtual('user', {
  ref: 'User',
  localField: 'userId',
  foreignField: '_id',
  justOne: true
});

// Method to check if user can perform an action
projectTeamSchema.methods.canPerformAction = function(action) {
  const rolePermissions = {
    owner: ['create', 'edit', 'delete', 'assign_roles', 'invite_members', 'view', 'manage_tasks'],
    admin: ['create', 'edit', 'invite_members', 'view', 'manage_tasks'],
    member: ['create', 'edit_own', 'view'],
    viewer: ['view']
  };
  return rolePermissions[this.role]?.includes(action) || false;
};

module.exports = mongoose.model('ProjectTeam', projectTeamSchema); 
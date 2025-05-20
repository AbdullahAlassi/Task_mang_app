const mongoose = require('mongoose');

const projectSchema = new mongoose.Schema({
  title: { type: String, required: true },
  description: { type: String },
  deadline: { type: Date },
  manager: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  members: [
    {
      userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
      },
      role: {
        type: String,
        enum: ['owner', 'admin', 'member', 'viewer'],
        default: 'viewer'
      },
      joinedAt: {
        type: Date,
        default: Date.now
      }
    }
  ],
  
  boards: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Board' }],
  status: { type: String, enum: ['To Do', 'In Progress', 'Completed', 'Archived'], default: 'To Do' },
  progress: { type: Number, default: 0 },
  totalTasks: { type: Number, default: 0 },
  completedTasks: { type: Number, default: 0 },
  color: { type: String, default: '#6B4EFF' },
  // New fields for team support
  type: { 
    type: String, 
    enum: ['personal', 'team'], 
    default: 'personal',
    required: true 
  },
  team: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Team',
    required: function() {
      return this.type === 'team';
    }
  },
  createdBy: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User', 
    required: true 
  },
  visibility: {
    type: String,
    enum: ['public', 'private'],
    default: 'private'
  }
}, { 
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Virtual for getting all team members if it's a team project
projectSchema.virtual('allTeamMembers').get(async function() {
  if (this.type === 'team' && this.team) {
    const Team = mongoose.model('Team');
    const team = await Team.findById(this.team).populate('members.user');
    return team ? team.members.map(m => m.user) : [];
  }
  return [];
});

// Method to update status based on progress
projectSchema.methods.updateStatusBasedOnProgress = function() {
  if (this.progress >= 100) {
    this.status = 'Completed';
  } else if (this.progress > 0) {
    this.status = 'In Progress';
  } else {
    this.status = 'To Do';
  }
};

// Pre-save middleware to update status based on progress
projectSchema.pre('save', function(next) {
  this.updateStatusBasedOnProgress();
  next();
});

// Indexes for better query performance
projectSchema.index({ type: 1 });
projectSchema.index({ team: 1 });
projectSchema.index({ createdBy: 1 });
projectSchema.index({ 'members': 1 });

module.exports = mongoose.model('Project', projectSchema);

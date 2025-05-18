const mongoose = require('mongoose');

const taskSchema = new mongoose.Schema({
  title: { type: String, required: true },
  description: { type: String },
  status: { type: String, enum: ['To Do', 'In Progress', 'Done'], default: 'To Do' },
  deadline: { type: Date },
  board: { type: mongoose.Schema.Types.ObjectId, ref: 'Board', required: true },
  assignedTo: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }], // Individual users
  assignedTeam: { type: mongoose.Schema.Types.ObjectId, ref: 'Team' }, // Optional team assignment
  color: { type: String, default: '#6B4EFF' }, // Default purple color
  priority: { type: String, enum: ['Low', 'Medium', 'High', 'Urgent'], default: 'Medium' },
  // New fields for better task tracking
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  lastModifiedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  estimatedHours: { type: Number },
  actualHours: { type: Number },
  dependencies: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Task' }],
  tags: [{ type: String }],
  attachments: [{ 
    filename: String,
    path: String,
    uploadedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    uploadedAt: { type: Date, default: Date.now }
  }],
  comments: [{
    text: String,
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    createdAt: { type: Date, default: Date.now }
  }]
}, { 
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Virtual for getting all assignees (both individual and team members)
taskSchema.virtual('allAssignees').get(async function() {
  const assignees = [...this.assignedTo];
  
  if (this.assignedTeam) {
    const Team = mongoose.model('Team');
    const team = await Team.findById(this.assignedTeam).populate('members.user');
    if (team) {
      const teamMembers = team.members.map(m => m.user);
      assignees.push(...teamMembers);
    }
  }
  
  return [...new Set(assignees)]; // Remove duplicates
});

// Indexes for better query performance
taskSchema.index({ board: 1 });
taskSchema.index({ assignedTo: 1 });
taskSchema.index({ assignedTeam: 1 });
taskSchema.index({ status: 1 });
taskSchema.index({ priority: 1 });
taskSchema.index({ deadline: 1 });
taskSchema.index({ createdBy: 1 });

// Method to check if a user is assigned to the task
taskSchema.methods.isUserAssigned = async function(userId) {
  if (this.assignedTo.includes(userId)) {
    return true;
  }
  
  if (this.assignedTeam) {
    const Team = mongoose.model('Team');
    const team = await Team.findById(this.assignedTeam);
    return team && team.members.some(m => m.user.toString() === userId.toString());
  }
  
  return false;
};

module.exports = mongoose.model('Task', taskSchema);

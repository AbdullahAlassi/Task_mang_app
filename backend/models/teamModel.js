const mongoose = require('mongoose');

const TeamSchema = new mongoose.Schema({
  name: { type: String, required: true },
  description: { type: String },
  parent: { type: mongoose.Schema.Types.ObjectId, ref: 'Team', default: null },
  children: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Team' }],
  members: [{
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    role: { type: String, enum: ['team_lead', 'member'], default: 'member' },
    joinedAt: { type: Date, default: Date.now },
    responsibilities: [{ type: String }],
    skills: [{ type: String }]
  }],
  department: { type: String },
  type: { 
    type: String, 
    enum: ['department', 'project', 'functional', 'cross-functional'],
    default: 'functional'
  },
  status: {
    type: String,
    enum: ['active', 'inactive', 'archived'],
    default: 'active'
  },
  metadata: {
    location: { type: String },
    timezone: { type: String },
    workingHours: { type: String },
    meetingSchedule: { type: String }
  },
  settings: {
    allowMemberInvites: { type: Boolean, default: false },
    requireApprovalForJoining: { type: Boolean, default: true },
    visibility: { type: String, enum: ['public', 'private'], default: 'private' }
  }
}, { 
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Virtual for getting all team members including those from child teams
TeamSchema.virtual('allMembers').get(function() {
  return this.members;
});

// Method to get the full hierarchy path
TeamSchema.methods.getHierarchyPath = async function() {
  const path = [this];
  let currentTeam = this;
  
  while (currentTeam.parent) {
    currentTeam = await this.constructor.findById(currentTeam.parent);
    if (currentTeam) {
      path.unshift(currentTeam);
    } else {
      break;
    }
  }
  
  return path;
};

// Indexes for better query performance
TeamSchema.index({ name: 1 });
TeamSchema.index({ parent: 1 });
TeamSchema.index({ 'members.user': 1 });
TeamSchema.index({ department: 1 });
TeamSchema.index({ type: 1 });
TeamSchema.index({ status: 1 });

module.exports = mongoose.model('Team', TeamSchema);

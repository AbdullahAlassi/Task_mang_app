const mongoose = require('mongoose');

const TeamSchema = new mongoose.Schema({
  name: { type: String, required: true },
  description: { type: String },
  type: { 
    type: String, 
    enum: ['Department', 'Cross-functional', 'Project-based'],
    default: 'Department'
  },
  manager: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  members: [{ 
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
  }],
  parent: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Team',
    default: null 
  },
  children: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Team',
    default: []
  }]
}, { 
  timestamps: true
});

// Indexes for better query performance
TeamSchema.index({ name: 1 });
TeamSchema.index({ manager: 1 });
TeamSchema.index({ 'members.user': 1 });
TeamSchema.index({ type: 1 });
TeamSchema.index({ parent: 1 });
TeamSchema.index({ children: 1 });

module.exports = mongoose.model('Team', TeamSchema);

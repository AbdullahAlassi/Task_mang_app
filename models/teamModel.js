const mongoose = require('mongoose');

const TeamSchema = new mongoose.Schema({
  name: { type: String, required: true }, // Team name
  parent: { type: mongoose.Schema.Types.ObjectId, ref: 'Team', default: null }, // Parent team (null for top-level teams)
  members: [
    {
      user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
      role: { type: String, default: 'member' }, // Role in the team (e.g., 'team_lead', 'member')
    },
  ],
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('Team', TeamSchema);

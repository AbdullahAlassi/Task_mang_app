const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  dateOfBirth: { type: Date },
  country: { type: String },
  phoneNumber: { type: String },
  profilePicture: { type: String },
  role: { type: String, enum: ['admin', 'manager', 'member'], default: 'member' },
  teams: [{
    team: { type: mongoose.Schema.Types.ObjectId, ref: 'Team' },
    role: { type: String, enum: ['team_lead', 'member'], default: 'member' },
    joinedAt: { type: Date, default: Date.now }
  }],
  department: { type: String },
  position: { type: String },
  employeeId: { type: String, unique: true, sparse: true },
  reportingTo: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  subordinates: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
}, { timestamps: true });

// Index for faster queries
userSchema.index({ email: 1 });
userSchema.index({ employeeId: 1 });
userSchema.index({ 'teams.team': 1 });

module.exports = mongoose.model('User', userSchema);

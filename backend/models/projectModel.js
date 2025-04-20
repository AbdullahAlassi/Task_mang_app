const mongoose = require('mongoose');

const projectSchema = new mongoose.Schema({
  title: { type: String, required: true },
  description: { type: String },
  deadline: { type: Date },
  manager: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true }, // Assigned automatically
  members: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  boards: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Board' }],
  status: { type: String, enum: ['Not Started', 'In Progress', 'Completed', 'Archived'], default: 'Not Started' },
  progress: { type: Number, default: 0 },
  totalTasks: { type: Number, default: 0 },
  completedTasks: { type: Number, default: 0 },
  color: { type: String, default: '#6B4EFF' } // Default purple color
}, { timestamps: true });

module.exports = mongoose.model('Project', projectSchema);

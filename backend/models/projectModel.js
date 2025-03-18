const mongoose = require('mongoose');

const projectSchema = new mongoose.Schema({
  title: { type: String, required: true },
  description: { type: String },
  deadline: { type: Date },
  manager: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true }, // Assigned automatically
  members: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  boards: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Board' }],
}, { timestamps: true });

module.exports = mongoose.model('Project', projectSchema);

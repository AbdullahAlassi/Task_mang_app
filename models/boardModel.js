const mongoose = require('mongoose');

const boardSchema = new mongoose.Schema({
  title: { type: String, required: true },
  project: { type: mongoose.Schema.Types.ObjectId, ref: 'Project', required: true },
  members: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }], // Users assigned to the board
  tasks: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Task' }],
}, { timestamps: true });

module.exports = mongoose.model('Board', boardSchema);

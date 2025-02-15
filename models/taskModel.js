const mongoose = require('mongoose');

const TaskSchema = new mongoose.Schema({
  boardId: { type: mongoose.Schema.Types.ObjectId, ref: 'Board', required: true },
  title: { type: String, required: true },
  description: { type: String },
  deadline: { type: Date },
  project: { type: mongoose.Schema.Types.ObjectId, ref: 'Project', required: true },
  members: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  attachments: [String],
  subtasks: [
    {
      title: { type: String, required: true },
      deadline: { type: Date },
    },
  ],
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('Task', TaskSchema);

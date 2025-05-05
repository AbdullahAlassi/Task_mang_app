const mongoose = require('mongoose');

const projectSchema = new mongoose.Schema({
  title: { type: String, required: true },
  description: { type: String },
  deadline: { type: Date },
  manager: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true }, // Assigned automatically
  members: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  boards: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Board' }],
  status: { type: String, enum: ['To Do', 'In Progress', 'Completed', 'Archived'], default: 'To Do' },
  progress: { type: Number, default: 0 },
  totalTasks: { type: Number, default: 0 },
  completedTasks: { type: Number, default: 0 },
  color: { type: String, default: '#6B4EFF' } // Default purple color
}, { timestamps: true });

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

module.exports = mongoose.model('Project', projectSchema);

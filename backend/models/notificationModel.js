const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true }, // Who receives the notification
  type: { type: String, enum: ['task', 'board', 'project', 'deadline', 'project-team'], required: true }, // Type of notification
  message: { type: String, required: true }, // Message content
  isRead: { type: Boolean, default: false }, // Read status
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Notification', notificationSchema);

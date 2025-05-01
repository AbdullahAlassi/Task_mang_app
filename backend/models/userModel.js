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
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);

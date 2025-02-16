const express = require('express');
const User = require('../models/userModel');
const authMiddleware = require('../middleware/auth');
const bcrypt = require('bcrypt');
const {check, validationResult }= require('express-validator');
const { validateRegistration }= require('../validators/validationSchemas');
const { handleValidationErrors, createProjectSchema, createTeamSchema, validateLogin }= require('../validators/validationSchemas');
const jwt = require('jsonwebtoken');

const router = express.Router();

router.post(
  '/register',
  validateRegistration, // Apply validation rules
  handleValidationErrors, // Handle validation errors
  async (req, res) => {
    const { name, email, password } = req.body;

    try {
      // Hash password
      const hashedPassword = await bcrypt.hash(password, 10);

      // Create a new user
      const newUser = new User({ name, email, password: hashedPassword });
      await newUser.save();

      res.status(201).json({ message: 'User registered successfully' });
    } catch (error) {
      res.status(500).json({ error: 'Error registering user', details: error.message });
    }
  }
);

// Create a new user
router.post('/', async (req, res) => {
  try {
    const newUser = new User(req.body);
    await newUser.save();
    res.status(201).json(newUser);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Get all users
router.get('/', authMiddleware, async (req, res) => {
  try {
    const users = await User.find();
    res.status(200).json(users);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get user by ID
router.get('/id', authMiddleware,async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password');// Exclude password from response
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.status(200).json(user);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update user
router.put('/:id', async (req, res) => {
  try {
    const updatedUser = await User.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
    });
    res.status(200).json(updatedUser);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Delete user
router.delete('/:id', async (req, res) => {
  try {
    await User.findByIdAndDelete(req.params.id);
    res.status(200).json({ message: 'User deleted' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get logged-in user's profile
router.get('/me', authMiddleware, async (req, res) => {
    try {
      const user = await User.findById(req.user.id).select('-password'); // Exclude password from response
      if (!user) {
        return res.status(404).json({ message: 'User not found' });
      }
      res.status(200).json(user);
    } catch (error) {
      res.status(500).json({ message: error.message });
    }
  });

 // Update logged-in user's profile
 router.put('/me', authMiddleware, async (req, res) => {
    const { name, email, password } = req.body;
  
    try {
      console.log('User ID from authMiddleware:', req.user?.id); // Debug log
      const user = await User.findById(req.user.id); // Use req.user.id from token
      console.log('User found:', user); // Log user data if found
  
      if (!user) {
        return res.status(404).json({ message: 'User not found' });
      }
  
      // Update fields if provided
      if (name) user.name = name;
      if (email) user.email = email;
      if (password) {
        const hashedPassword = await bcrypt.hash(password, 10);
        user.password = hashedPassword;
      }
  
      await user.save();
      console.log('Updated user:', user); // Log updated user data
      res.status(200).json({ message: 'Profile updated successfully' });
    } catch (error) {
      console.error('Error during PUT /me:', error); // Log any error
      res.status(500).json({ error: error.message });
    }
  });
  
  // Get all users (admin only)
router.get('/admin', authMiddleware, async (req, res) => {
    try {
      // Check if the logged-in user is an admin
      if (req.user.role !== 'admin') {
        return res.status(403).json({ message: 'Access denied. Admins only.' });
      }
  
      const users = await User.find().select('-password'); // Exclude passwords
      res.status(200).json(users);
    } catch (error) {
      res.status(500).json({ message: error.message });
    }
  });

router.post(
  '/login',
  validateLogin, // Apply validation rules
  handleValidationErrors, // Handle validation errors
  async (req, res) => {
    const { email, password } = req.body;

    try {
      const user = await User.findOne({ email });
      if (!user) {
        return res.status(401).json({ error: 'Invalid email or password' });
      }

      const isMatch = await bcrypt.compare(password, user.password);
      if (!isMatch) {
        return res.status(401).json({ error: 'Invalid email or password' });
      }

      const token = jwt.sign({ id: user._id, role: user.role }, process.env.JWT_SECRET, {
        expiresIn: '1h',
      });

      res.json({ token });
    } catch (error) {
      res.status(500).json({ error: 'Error logging in', details: error.message });
    }
  }
);

module.exports = router;


const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const User = require('../models/userModel');

const router = express.Router();

//Register
router.post('/register', async (req, res) => {
    try{
        const {name, email, password} = req.body;
        console.log("Register request received with data:", {name, email});

        const hashedPassword = await bcrypt.hash(password, 10);
        const newUser = new User({name, email, password: hashedPassword});
        await newUser.save();
        res.status(201).json({ message: "User registerd successfully"});
    } catch(error){
        console.error("Error during registration:", error);
        res.status(500).json({ error: 'Error registering user', details: error.message});
    }
});

//Login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    console.log('Login request received for:', email);

    // Find user
    const user = await User.findOne({ email });
    console.log('User found:', user);

    if (!user) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    // Compare password
    const isMatch = await bcrypt.compare(password, user.password);
    console.log('Password match:', isMatch);

    if (!isMatch) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    // Generate JWT token
    const token = jwt.sign({ id: user._id, role: user.role }, process.env.JWT_SECRET, { expiresIn: '1h' });
    console.log('Token generated:', token);

    res.json({ token });
  } catch (error) {
    console.error('Error during login:', error);
    res.status(500).json({ error: 'Error logging in', details: error.message });
  }
});

  
module.exports = router;
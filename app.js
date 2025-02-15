require('dotenv').config();
const express = require('express');
const connectDB = require('./db');
const authRoutes = require('./routes/auth');
const http = require('http'); // Required for socket.io
const socketIo = require('socket.io');
const cors = require('cors');

const app = express();
const server = http.createServer(app); // Wrap Express app in HTTP server
const io = socketIo(server, {
    cors: {
      origin: '*', // Allow all origins (adjust for production)
    },
  });
  
  // Store connected clients
  const clients = new Map();
  
  io.on('connection', (socket) => {
    console.log('New client connected:', socket.id);
  
    socket.on('registerUser', (userId) => {
      clients.set(userId, socket.id);
      console.log(`User ${userId} registered for notifications.`);
    });
  
    socket.on('disconnect', () => {
      clients.forEach((value, key) => {
        if (value === socket.id) {
          clients.delete(key);
        }
      });
      console.log('Client disconnected:', socket.id);
    });
  });
  
  app.use(cors());
  app.use(express.json());
  
  // Function to send notifications
  const sendNotification = (userId, message) => {
    const socketId = clients.get(userId);
    if (socketId) {
      io.to(socketId).emit('notification', { message });
    }
  };

// Connect Database
connectDB();

// Middleware
app.use(express.json());

// Routes
const errorMiddleware = require('./middleware/errorMiddleware');
app.use(errorMiddleware);
app.use('/api/users', require('./routes/userRoutes'));
app.use('/api/projects', require('./routes/projectRoutes'));
app.use('/api/auth', authRoutes);
app.use('/api/boards', require('./routes/userRoutes'));
app.use('/api/tasks', require('./routes/taskRoutes'));
app.use('/api/teams', require('./routes/teamRoutes'));


// Server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));

module.exports = { app, server, sendNotification };



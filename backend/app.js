require('dotenv').config();
const express = require('express');
const connectDB = require('./db');
const http = require('http'); 
const cors = require('cors');

const app = express();
const server = http.createServer(app); // Wrap Express app in HTTP server

// 🔹 Connect Database BEFORE initializing routes
connectDB();

// 🔹 Middleware
app.use(cors({
  origin: '*', // ❗ Change this to your frontend URL in production
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
}));
app.use(express.json());

// 🔹 Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/users', require('./routes/userRoutes'));
app.use('/api/projects', require('./routes/projectRoutes'));
app.use('/api/boards', require('./routes/boardRoutes'));
app.use('/api/tasks', require('./routes/taskRoutes'));
app.use('/api/teams', require('./routes/teamRoutes'));

// 🔹 Error Handling Middleware
const errorMiddleware = require('./middleware/errorMiddleware');
app.use(errorMiddleware);

// 🔹 Start Server (✅ FIXED: Use `server.listen`, not `app.listen`)
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => console.log(`🚀 Server running on port ${PORT}`));

module.exports = { app, server };

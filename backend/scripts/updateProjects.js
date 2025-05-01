const mongoose = require('mongoose');
const Project = require('../models/projectModel');

// MongoDB connection URL - replace with your actual connection string
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/task_management';

async function updateAllProjects() {
  try {
    // Connect to MongoDB
    await mongoose.connect(MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log('Connected to MongoDB');

    // Find all projects
    const projects = await Project.find({});
    console.log(`Found ${projects.length} projects to update`);

    // Update each project
    for (const project of projects) {
      // Ensure all required fields have default values
      const updates = {
        status: project.status || 'To Do',
        progress: typeof project.progress === 'number' ? project.progress : 0,
        totalTasks: typeof project.totalTasks === 'number' ? project.totalTasks : 0,
        completedTasks: typeof project.completedTasks === 'number' ? project.completedTasks : 0,
        color: project.color || '#6B4EFF',
        boards: project.boards || [],
        members: project.members || [],
      };

      // Calculate progress if not set
      if (updates.totalTasks > 0) {
        updates.progress = Math.round((updates.completedTasks / updates.totalTasks) * 100);
      }

      // Update status based on progress
      if (updates.progress >= 100) {
        updates.status = 'Completed';
      } else if (updates.progress > 0) {
        updates.status = 'In Progress';
      } else {
        updates.status = 'To Do';
      }

      // Update the project
      await Project.findByIdAndUpdate(project._id, { $set: updates });
      console.log(`Updated project: ${project.title}`);
    }

    console.log('All projects updated successfully');
  } catch (error) {
    console.error('Error updating projects:', error);
  } finally {
    // Close MongoDB connection
    await mongoose.connection.close();
    console.log('MongoDB connection closed');
  }
}

// Run the update function
updateAllProjects(); 
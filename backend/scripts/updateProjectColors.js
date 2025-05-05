const mongoose = require('mongoose');
const Project = require('../models/projectModel');

const projectColors = [
  '#6B4EFF', // Purple
  '#211B4E', // Dark blue
  '#96292B', // Red
  '#808C44', // Olive green
  '#35383F', // Dark gray
];

async function updateProjectColors() {
  try {
    // Connect to MongoDB - update this URL to match your actual database URL
    await mongoose.connect('mongodb://127.0.0.1:27017/amertaskmanagement');

    // Get all projects
    const projects = await Project.find({});
    console.log(`Found ${projects.length} projects to update`);

    // Update each project with a random color
    for (const project of projects) {
      const randomColor = projectColors[Math.floor(Math.random() * projectColors.length)];
      await Project.findByIdAndUpdate(project._id, { $set: { color: randomColor } });
      console.log(`Updated project ${project.title} with color ${randomColor}`);
    }

    console.log('All projects have been updated with colors');
    process.exit(0);
  } catch (error) {
    console.error('Error updating projects:', error);
    process.exit(1);
  }
}

updateProjectColors(); 
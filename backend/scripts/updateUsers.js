const mongoose = require('mongoose');
const User = require('../models/userModel');

async function updateUsers() {
    try {
        // Connect to MongoDB
        await mongoose.connect('mongodb://localhost:27017/task_management');
        console.log('Connected to MongoDB');

        // Update all users
        const result = await User.updateMany(
            {}, // Match all documents
            {
                $set: {
                    dateOfBirth: null,
                    country: 'Not specified',
                    phoneNumber: 'Not specified',
                    profilePicture: null,
                    role: 'member' // Set default role if not already set
                }
            }
        );

        console.log(`Updated ${result.modifiedCount} users`);
        console.log('Update completed successfully');

    } catch (error) {
        console.error('Error updating users:', error);
    } finally {
        // Close the connection
        await mongoose.disconnect();
        console.log('Disconnected from MongoDB');
    }
}

// Run the update
updateUsers(); 
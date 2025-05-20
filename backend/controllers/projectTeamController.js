const ProjectTeam = require('../models/projectTeamModel');
const Project = require('../models/projectModel');
const User = require('../models/userModel');
const Notification = require('../models/notificationModel');
const { standardizeRole, canModifyRole } = require('../utils/projectPermissions');

// Add member to project team
const addMember = async (req, res) => {
  try {
    const { projectId } = req.params;
    const { email, role } = req.body;
    const addedBy = req.user.id;

   // Validate user exists
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    } 
    
    // Validate project exists
    const project = await Project.findById(projectId);
    if (!project) {
      return res.status(404).json({ message: 'Project not found' });
    }

      // Check if user already in project.members
    const alreadyExists = project.members.some(m =>
      m.userId.toString() === user._id.toString()
    );
    if (alreadyExists) {
      return res.status(400).json({ message: 'User already in project' });
    }



     // Standardize and validate role
     const standardizedRole = standardizeRole(role);
     if (!canModifyRole(req.userRole, standardizedRole)) {
       return res.status(403).json({ message: 'You cannot assign this role' });
     }

    // Add member to project.members[]
    project.members.push({
      userId: user._id,
      role: standardizedRole,
      joinedAt: new Date()
    });

    await project.save();

    
    // Reload populated member data
    const updatedProject = await Project.findById(projectId).populate('members.userId', 'name email profilePicture');
    const newMember = updatedProject.members.find(m => m.userId._id.toString() === user._id.toString());
 

    res.status(201).json({
      userId: newMember.userId._id,
      user: newMember.userId,
      role: newMember.role,
      joinedAt: newMember.joinedAt
  });
  } catch (error) {
    console.error('Add Member Error:', error);
    res.status(500).json({ message: 'Error adding member to project team' });
  }
};

// Remove member from project team
const removeMember = async (req, res) => {
  try {
    const { projectId, userId } = req.params;
    const currentUserId = req.user.id;

    // Prevent removing the project owner
    const project = await Project.findById(projectId);
    if (project.createdBy.toString() === userId) {
      return res.status(403).json({ message: 'Cannot remove project owner' });
    }

    // Check if trying to remove self
    if (userId === currentUserId) {
      return res.status(400).json({ message: 'Cannot remove yourself from the project' });
    }

    const member = await ProjectTeam.findOne({ projectId, userId });
    if (!member) {
      return res.status(404).json({ message: 'Member not found in project team' });
    }

    // Check if current user has permission to remove this member
    if (!canModifyRole(req.userRole, member.role)) {
      return res.status(403).json({ message: 'You do not have permission to remove this member' });
    }

    await member.remove();

    // Create notification
    const notification = new Notification({
      user: userId,
      type: 'project_team',
      message: `You have been removed from project "${project.title}"`,
      project: projectId
    });
    await notification.save();

    res.status(200).json({ message: 'Member removed successfully' });
  } catch (error) {
    console.error('Remove Member Error:', error);
    res.status(500).json({ message: 'Error removing member from project team' });
  }
};

// Update member role
const updateMemberRole = async (req, res) => {
  try {
    const { projectId, userId } = req.params;
    const { role } = req.body;

    // Prevent changing project owner's role
    const project = await Project.findById(projectId);
    if (project.createdBy.toString() === userId) {
      return res.status(403).json({ message: 'Cannot change project owner\'s role' });
    }

    const member = await ProjectTeam.findOne({ projectId, userId });
    if (!member) {
      return res.status(404).json({ message: 'Member not found in project team' });
    }

    // Standardize and validate new role
    const standardizedRole = standardizeRole(role);
    if (!canModifyRole(req.userRole, standardizedRole)) {
      return res.status(403).json({ message: 'You cannot assign this role' });
    }

    // Update role
    member.role = standardizedRole;
    await member.save();

    // Create notification
    const notification = new Notification({
      user: userId,
      type: 'project_team',
      message: `Your role in project "${project.title}" has been updated to ${standardizedRole}`,
      project: projectId
    });
    await notification.save();

    // Return updated member data
    const updatedMember = await ProjectTeam.findById(member._id)
      .populate('userId', 'name email profilePicture')
      .populate('addedBy', 'name email');

    res.status(200).json(updatedMember);
  } catch (error) {
    console.error('Update Role Error:', error);
    res.status(500).json({ message: 'Error updating member role' });
  }
};

// Get all project members
const getProjectMembers = async (req, res) => {
  try {
    const { projectId } = req.params;

    // Get the project with populated member data
    const project = await Project.findById(projectId)
      .populate({
        path: 'members.userId',
        select: 'name email profilePicture',
        strictPopulate: false
      });

    if (!project) {
      return res.status(404).json({ message: 'Project not found' });
    }

    const members = project.members.map(m => ({
      userId: m.userId._id || m.userId, // support both populated and raw ObjectId
      user: m.userId.name ? m.userId : {
        _id: m.userId,
        name: 'Unknown',
        email: 'unknown@example.com'
      },
      role: m.role,
      joinedAt: m.joinedAt
    }));

    res.status(200).json(members);
  } catch (error) {
    console.error('Error fetching members from project.members[]:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

module.exports = {
  addMember,
  removeMember,
  updateMemberRole,
  getProjectMembers
}; 
import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../models/team_model.dart';
import '../../models/user_model.dart';
import '../../services/team_service.dart';
import '../../services/user_service.dart';

class TeamMembersScreen extends StatefulWidget {
  final Team team;

  const TeamMembersScreen({Key? key, required this.team}) : super(key: key);

  @override
  State<TeamMembersScreen> createState() => _TeamMembersScreenState();
}

class _TeamMembersScreenState extends State<TeamMembersScreen> {
  final _teamService = TeamService();
  final _userService = UserService();
  bool _isLoading = true;
  List<User> _users = [];
  List<User> _availableUsers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      final users = await _userService.getAllUsers();
      setState(() {
        _users = users;
        _availableUsers = users.where((user) {
          return !widget.team.members.any((member) => member.userId == user.id);
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _showAddMemberDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Add Team Member'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _availableUsers.length,
            itemBuilder: (context, index) {
              final user = _availableUsers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryColor,
                  child: Text(
                    user.name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(user.name),
                subtitle: Text(user.email),
                onTap: () async {
                  Navigator.pop(context);
                  await _addMember(user);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showRoleUpdateDialog(TeamMember member) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Update Member Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Team Lead'),
              selected: member.role == 'team_lead',
              onTap: () async {
                Navigator.pop(context);
                await _updateMemberRole(member, 'team_lead');
              },
            ),
            ListTile(
              title: const Text('Member'),
              selected: member.role == 'member',
              onTap: () async {
                Navigator.pop(context);
                await _updateMemberRole(member, 'member');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _addMember(User user) async {
    try {
      await _teamService.addTeamMember(
        widget.team.id,
        user.id,
        'member',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member added successfully')),
        );
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add member: $e')),
        );
      }
    }
  }

  Future<void> _updateMemberRole(TeamMember member, String newRole) async {
    try {
      await _teamService.updateTeamMemberRole(
        widget.team.id,
        member.userId,
        newRole,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member role updated successfully')),
        );
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update member role: $e')),
        );
      }
    }
  }

  Future<void> _removeMember(TeamMember member) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: const Text(
          'Are you sure you want to remove this member from the team?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _teamService.removeTeamMember(
          widget.team.id,
          member.userId,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Member removed successfully')),
          );
          await _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove member: $e')),
          );
        }
      }
    }
  }

  Widget _buildMemberCard(User user, TeamMember member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      color: AppColors.cardColor,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryColor,
          child: Text(
            user.name[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(
            color: AppColors.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.email,
              style: const TextStyle(color: AppColors.secondaryTextColor),
            ),
            const SizedBox(height: 4),
            Chip(
              label: Text(
                member.role.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              backgroundColor: member.role == 'team_lead'
                  ? Colors.blue
                  : AppColors.primaryColor,
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Text('Update Role'),
              onTap: () => _showRoleUpdateDialog(member),
            ),
            PopupMenuItem(
              child: const Text(
                'Remove from Team',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () => _removeMember(member),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        title: Text(
          '${widget.team.name} Members',
          style: const TextStyle(
            color: AppColors.textColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showAddMemberDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Team Info
                  Card(
                    color: AppColors.cardColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Team Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Total Members: ${widget.team.members.length}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Team Members
                  Card(
                    color: AppColors.cardColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Team Members',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textColor,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _showAddMemberDialog,
                                icon: const Icon(Icons.person_add),
                                label: const Text('Add Member'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...widget.team.members.map((member) {
                            final user = _users.firstWhere(
                              (u) => u.id == member.userId,
                              orElse: () => User(
                                id: member.userId,
                                name: 'Unknown User',
                                email: 'unknown@example.com',
                                createdAt: DateTime.now(),
                                updatedAt: DateTime.now(),
                              ),
                            );
                            return _buildMemberCard(user, member);
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

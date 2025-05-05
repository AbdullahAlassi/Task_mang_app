import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../models/team_model.dart';
import '../../services/team_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../screens/teams/team_form_screen.dart';
import '../../screens/teams/team_members_screen.dart';

class TeamHierarchyScreen extends StatefulWidget {
  const TeamHierarchyScreen({Key? key}) : super(key: key);

  @override
  State<TeamHierarchyScreen> createState() => _TeamHierarchyScreenState();
}

class _TeamHierarchyScreenState extends State<TeamHierarchyScreen> {
  final TeamService _teamService = TeamService();
  final UserService _userService = UserService();
  bool _isLoading = true;
  List<Team> _teams = [];
  List<User> _users = [];
  Team? _selectedTeam;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      final teams = await _teamService.getAllTeams();
      final users = await _userService.getAllUsers();
      setState(() {
        _teams = teams;
        _users = users;
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

  void _showTeamOptions(Team team) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Team'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TeamFormScreen(team: team),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Manage Members'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TeamMembersScreen(team: team),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text(
              'Delete Team',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              Navigator.pop(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Team'),
                  content: const Text(
                    'Are you sure you want to delete this team? This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true && mounted) {
                try {
                  await _teamService.deleteTeam(team.id);
                  await _loadData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Team deleted successfully')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete team: $e')),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog() {
    final availableUsers = _users
        .where((user) =>
            !_selectedTeam!.members.any((member) => member.userId == user.id))
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Team Member'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableUsers.length,
            itemBuilder: (context, index) {
              final user = availableUsers[index];
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
                  try {
                    await _teamService.addTeamMember(
                      _selectedTeam!.id,
                      user.id,
                      'member',
                    );
                    await _loadData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Member added successfully')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to add member: $e')),
                      );
                    }
                  }
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

  Widget _buildTeamTree(Team team, {int level = 0}) {
    final childTeams = _teams.where((t) => t.parentId == team.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTeamCard(team, level),
        if (childTeams.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: 32.0),
            child: Column(
              children: childTeams
                  .map((child) => _buildTeamTree(child, level: level + 1))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildTeamCard(Team team, int level) {
    final isSelected = _selectedTeam?.id == team.id;

    return Card(
      margin: EdgeInsets.only(
        left: level * 16.0,
        right: 16.0,
        top: 8.0,
        bottom: 8.0,
      ),
      color: isSelected
          ? AppColors.primaryColor.withOpacity(0.1)
          : AppColors.cardColor,
      child: InkWell(
        onTap: () => setState(() => _selectedTeam = team),
        onLongPress: () => _showTeamOptions(team),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.group,
                      color: AppColors.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (team.description != null)
                          Text(
                            team.description!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.secondaryTextColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTeamTypeChip(team.type),
                        _buildTeamStatusChip(team.status),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people,
                          size: 14,
                          color: AppColors.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${team.members.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamTypeChip(String type) {
    Color color;
    IconData icon;

    switch (type) {
      case 'department':
        color = Colors.blue;
        icon = Icons.business;
        break;
      case 'project':
        color = Colors.green;
        icon = Icons.assignment;
        break;
      case 'functional':
        color = Colors.orange;
        icon = Icons.engineering;
        break;
      case 'cross-functional':
        color = Colors.purple;
        icon = Icons.groups;
        break;
      default:
        color = Colors.grey;
        icon = Icons.group;
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Text(
        type.replaceAll('-', ' ').toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }

  Widget _buildTeamStatusChip(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case 'active':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'inactive':
        color = Colors.grey;
        icon = Icons.pause_circle;
        break;
      case 'archived':
        color = Colors.red;
        icon = Icons.archive;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Text(
        status.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }

  Widget _buildTeamDetails() {
    if (_selectedTeam == null) {
      return const Center(
        child: Text(
          'Select a team to view details',
          style: TextStyle(
            color: AppColors.secondaryTextColor,
            fontSize: 16,
          ),
        ),
      );
    }

    return SingleChildScrollView(
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
                  _buildInfoRow('Name', _selectedTeam!.name),
                  if (_selectedTeam!.description != null)
                    _buildInfoRow('Description', _selectedTeam!.description!),
                  _buildInfoRow('Type', _selectedTeam!.type),
                  _buildInfoRow('Status', _selectedTeam!.status),
                  if (_selectedTeam!.department != null)
                    _buildInfoRow('Department', _selectedTeam!.department!),
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
                      IconButton(
                        icon: const Icon(Icons.person_add),
                        onPressed: _showAddMemberDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ..._selectedTeam!.members.map((member) {
                    final user = _users.firstWhere(
                      (u) => u.id == member.userId,
                      orElse: () => User(
                        id: member.userId,
                        name: 'Unknown User',
                        email: 'unknown@example.com',
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
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.secondaryTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(User user, TeamMember member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      color: AppColors.backgroundColor,
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
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            // TODO: Implement member options menu
          },
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
        title: const Text(
          'Team Hierarchy',
          style: TextStyle(
            color: AppColors.textColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TeamFormScreen(),
                ),
              ).then((_) => _loadData());
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Team Tree
                Expanded(
                  flex: 1,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _teams
                          .where((team) => team.parentId == null)
                          .map((team) => _buildTeamTree(team))
                          .toList(),
                    ),
                  ),
                ),
                // Team Details
                Expanded(
                  flex: 2,
                  child: _buildTeamDetails(),
                ),
              ],
            ),
    );
  }
}

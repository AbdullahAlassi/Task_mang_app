import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../models/team_model.dart';
import '../../services/team_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../screens/teams/team_form_screen.dart';
import '../../screens/teams/team_members_screen.dart';
import '../../widgets/horizontal_team_tree.dart';
import '../../services/auth_service.dart';
import '../../services/task_service.dart';
import '../../widgets/add_sub_team_dialog.dart';
import '../../main.dart';

class TeamHierarchyScreen extends StatefulWidget {
  const TeamHierarchyScreen({Key? key}) : super(key: key);

  @override
  State<TeamHierarchyScreen> createState() => _TeamHierarchyScreenState();
}

class _TeamHierarchyScreenState extends State<TeamHierarchyScreen> {
  final TeamService _teamService = TeamService();
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  final TaskService _taskService = TaskService();
  bool _isLoading = true;
  List<Team> _teams = [];
  List<User> _users = [];
  Team? _selectedTeam;
  String? _currentUserId;
  Map<String, int> _teamTaskCounts = {}; // teamId -> task count

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      final userId = await _authService.getCurrentUserId();
      final teams = await _teamService.getAllTeams();
      final users = await _userService.getAllUsers();
      // Filter teams: only show if current user is a member or team lead
      final filteredTeams = teams
          .where((team) => team.members.any((m) => m.userId == userId))
          .toList();
      // Fetch task counts for each team using backend endpoint
      final Map<String, int> teamTaskCounts = {};
      for (final team in filteredTeams) {
        try {
          final count = await _teamService.getTeamTaskCount(team.id);
          teamTaskCounts[team.id] = count;
        } catch (e) {
          teamTaskCounts[team.id] = 0;
        }
      }
      if (!mounted) return;
      setState(() {
        _currentUserId = userId;
        _teams = filteredTeams;
        _users = users;
        _teamTaskCounts = teamTaskCounts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
        setState(() => _isLoading = false);
      }
    } finally {
      if (mounted && _isLoading) setState(() => _isLoading = false);
    }
  }

  void _showTeamOptions(Team team) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add, color: AppColors.primaryColor),
              title: const Text('Create Sub-Team'),
              onTap: () async {
                Navigator.pop(context);
                final result = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AddSubTeamDialog(
                    parentTeam: team,
                    onTeamCreated: _loadData,
                  ),
                );
                if (result == true && mounted) {
                  setState(() {});
                  await _loadData();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primaryColor),
              title: const Text('Edit Team'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TeamFormScreen(team: team),
                  ),
                );
                if (result == true && mounted) {
                  await _loadData();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.people, color: AppColors.primaryColor),
              title: const Text('Manage Members'),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TeamMembersScreen(team: team),
                  ),
                );
                if (mounted) {
                  await _loadData();
                }
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
                await _handleDeleteTeam(team, context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddMemberDialogForSelectedTeam() async {
    if (_selectedTeam == null) return;
    String searchQuery = '';
    List<User> filteredUsers = [];
    final result = await showDialog<dynamic>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            filteredUsers = _users
                .where((user) =>
                    !_selectedTeam!.members
                        .any((member) => member.userId == user.id) &&
                    (user.name
                            .toLowerCase()
                            .contains(searchQuery.toLowerCase()) ||
                        user.email
                            .toLowerCase()
                            .contains(searchQuery.toLowerCase())))
                .toList();
            return AlertDialog(
              title: const Text('Add Team Member'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Search by name or email',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (searchQuery.isNotEmpty)
                      filteredUsers.isEmpty
                          ? const Text('No users found.')
                          : SizedBox(
                              height: 250,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: filteredUsers.length,
                                itemBuilder: (context, index) {
                                  final user = filteredUsers[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.primaryColor,
                                      child: Text(
                                        user.name.isNotEmpty
                                            ? user.name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    ),
                                    title: Text(user.name),
                                    subtitle: Text(user.email),
                                    onTap: () async {
                                      try {
                                        await _teamService.addTeamMember(
                                          _selectedTeam!.id,
                                          user.id,
                                          'member',
                                        );
                                        Navigator.pop(
                                            context, {'success': true});
                                      } catch (e) {
                                        String errorMsg =
                                            'Failed to add member: $e';
                                        if (e.toString().contains('403')) {
                                          final match =
                                              RegExp(r'message":\s*"([^"]+)')
                                                  .firstMatch(e.toString());
                                          if (match != null)
                                            errorMsg = match.group(1)!;
                                        }
                                        Navigator.pop(context, {
                                          'success': false,
                                          'error': errorMsg
                                        });
                                      }
                                    },
                                  );
                                },
                              ),
                            ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, {'success': false}),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
    if (result is Map && result['success'] == true) {
      setState(() {});
      await _loadData();
      if (mounted) {
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Member added successfully')),
        );
      }
    } else if (result is Map &&
        result['success'] == false &&
        result['error'] != null &&
        mounted) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(result['error'])),
      );
    }
  }

  Future<void> _showEditRoleDialog(TeamMember member) async {
    if (_selectedTeam == null) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Update Member Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Team Leader'),
              selected: member.role == 'team_leader',
              onTap: () async {
                Navigator.pop(context);
                await _updateMemberRole(member, 'team_leader');
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

  Future<void> _updateMemberRole(TeamMember member, String newRole) async {
    if (_selectedTeam == null) return;
    try {
      await _teamService.updateTeamMemberRole(
        _selectedTeam!.id,
        member.userId,
        newRole,
      );
      if (mounted) {
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Member role updated successfully')),
        );
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Failed to update member role: $e';
        if (e is Exception && e.toString().contains('403')) {
          final match =
              RegExp(r'message":\s*"([^"]+)').firstMatch(e.toString());
          if (match != null) errorMsg = match.group(1)!;
        }
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    }
  }

  Future<void> _removeMember(TeamMember member) async {
    if (_selectedTeam == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: const Text(
            'Are you sure you want to remove this member from the team?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      try {
        await _teamService.removeTeamMember(
          _selectedTeam!.id,
          member.userId,
        );
        if (mounted) {
          rootScaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(content: Text('Member removed successfully')),
          );
          setState(() {});
          await _loadData();
        }
      } catch (e) {
        if (mounted) {
          String errorMsg = 'Failed to remove member: $e';
          if (e is Exception && e.toString().contains('403')) {
            final match =
                RegExp(r'message":\s*"([^"]+)').firstMatch(e.toString());
            if (match != null) errorMsg = match.group(1)!;
          }
          rootScaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(content: Text(errorMsg)),
          );
        }
      }
    }
  }

  void _onTeamSelected(Team team) {
    setState(() => _selectedTeam = team);
  }

  Future<void> _handleDeleteTeam(Team team, BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
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
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        setState(() => _isLoading = true);
        await _teamService.deleteTeam(team.id);
        await _loadData();
        if (mounted) {
          rootScaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(content: Text('Team deleted successfully')),
          );
        }
      } catch (e) {
        print('Delete team error: $e');
        if (mounted) {
          String errorMessage = 'Failed to delete team';
          if (e is Exception) {
            errorMessage = e.toString().replaceAll('Exception: ', '');
          }
          rootScaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: () {
                  rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selectedTeam != null) {
          setState(() => _selectedTeam = null);
          return false;
        }
        return true;
      },
      child: Scaffold(
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
            ? const Center(
                child: Text('Loading teams...',
                    style: TextStyle(
                        color: AppColors.secondaryTextColor, fontSize: 18)))
            : _teams.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.group_off,
                            size: 64, color: AppColors.secondaryTextColor),
                        const SizedBox(height: 16),
                        const Text(
                          'You are not assigned to any team.',
                          style: TextStyle(
                              fontSize: 18,
                              color: AppColors.secondaryTextColor),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TeamFormScreen(),
                              ),
                            ).then((_) => _loadData());
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Create New Team'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 600) {
                        // Tablet/Desktop: horizontal layout
                        return Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: HorizontalTeamTree(
                                teams: _teams,
                                onTeamSelected: _onTeamSelected,
                                selectedTeam: _selectedTeam,
                                teamTaskCounts: _teamTaskCounts,
                                onDataChanged: _loadData,
                                onDeleteTeam: _handleDeleteTeam,
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    if (_selectedTeam != null)
                                      TeamInfoCard(team: _selectedTeam!),
                                    if (_selectedTeam != null)
                                      TeamMemberList(
                                        team: _selectedTeam!,
                                        users: _users,
                                        onMemberChanged: _loadData,
                                        onAddMember:
                                            _showAddMemberDialogForSelectedTeam,
                                        onEditRole: _showEditRoleDialog,
                                        onRemoveMember: _removeMember,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      } else {
                        // Mobile: vertical layout
                        return Column(
                          children: [
                            HorizontalTeamTree(
                              teams: _teams,
                              onTeamSelected: _onTeamSelected,
                              selectedTeam: _selectedTeam,
                              teamTaskCounts: _teamTaskCounts,
                              onDataChanged: _loadData,
                              onDeleteTeam: _handleDeleteTeam,
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    if (_selectedTeam != null)
                                      TeamInfoCard(team: _selectedTeam!),
                                    if (_selectedTeam != null)
                                      TeamMemberList(
                                        team: _selectedTeam!,
                                        users: _users,
                                        onMemberChanged: _loadData,
                                        onAddMember:
                                            _showAddMemberDialogForSelectedTeam,
                                        onEditRole: _showEditRoleDialog,
                                        onRemoveMember: _removeMember,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
      ),
    );
  }
}

class HorizontalTeamTree extends StatelessWidget {
  final List<Team> teams;
  final Function(Team) onTeamSelected;
  final Team? selectedTeam;
  final Map<String, int> teamTaskCounts;
  final VoidCallback onDataChanged;
  final Future<void> Function(Team, BuildContext) onDeleteTeam;

  const HorizontalTeamTree({
    Key? key,
    required this.teams,
    required this.onTeamSelected,
    required this.selectedTeam,
    required this.teamTaskCounts,
    required this.onDataChanged,
    required this.onDeleteTeam,
  }) : super(key: key);

  List<Team> _getChildren(String? parentId) {
    return teams.where((t) => t.parentId == parentId).toList();
  }

  List<Team> _getSelectedPath(Team? selected) {
    if (selected == null) return [];
    List<Team> path = [selected];
    while (path.first.parentId != null) {
      final parentCandidates = teams.where((t) => t.id == path.first.parentId);
      final parent = parentCandidates.isEmpty ? null : parentCandidates.first;
      if (parent == null) break;
      path.insert(0, parent);
    }
    return path;
  }

  void _handleTeamAction(BuildContext context, String action, Team team) async {
    switch (action) {
      case 'edit':
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => TeamFormScreen(team: team),
          ),
        );
        if (result == true && context.mounted) {
          final state =
              context.findAncestorStateOfType<_TeamHierarchyScreenState>();
          state?._loadData();
        }
        break;
      case 'delete':
        await onDeleteTeam(team, context);
        break;
      case 'manage':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TeamMembersScreen(team: team),
          ),
        );
        if (context.mounted) {
          final state =
              context.findAncestorStateOfType<_TeamHierarchyScreenState>();
          state?._loadData();
        }
        break;
      case 'subteam':
        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AddSubTeamDialog(
            parentTeam: team,
            onTeamCreated: () {
              final state =
                  context.findAncestorStateOfType<_TeamHierarchyScreenState>();
              state?._loadData();
            },
          ),
        );
        if (result == true && context.mounted) {
          final state =
              context.findAncestorStateOfType<_TeamHierarchyScreenState>();
          state?._loadData();
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final parentTeams = _getChildren(null);
    final selectedPath = _getSelectedPath(selectedTeam);
    List<Widget> columns = [];

    columns.add(_buildColumn(
      context: context,
      header: 'Parent Teams',
      teams: parentTeams,
      selectedId: selectedPath.isNotEmpty ? selectedPath[0].id : null,
      onTap: onTeamSelected,
      selectedPath: selectedPath,
      teamTaskCounts: teamTaskCounts,
    ));

    for (int i = 0; i < selectedPath.length; i++) {
      final parent = selectedPath[i];
      final subteams = _getChildren(parent.id);
      if (subteams.isNotEmpty) {
        columns.add(_buildColumn(
          context: context,
          header: i == 0 ? 'Subteams' : 'Level ${i + 1}',
          teams: subteams,
          selectedId:
              (i + 1 < selectedPath.length) ? selectedPath[i + 1].id : null,
          onTap: onTeamSelected,
          selectedPath: selectedPath,
          teamTaskCounts: teamTaskCounts,
        ));
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: columns,
      ),
    );
  }

  Widget _buildColumn({
    required BuildContext context,
    required String header,
    required List<Team> teams,
    required String? selectedId,
    required Function(Team) onTap,
    required List<Team> selectedPath,
    required Map<String, int> teamTaskCounts,
  }) {
    return Container(
      width: 200,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              header,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          ...teams.map((team) {
            final isSelected = selectedId == team.id;
            final isInPath = selectedPath.any((t) => t.id == team.id);
            return Card(
              color: isSelected
                  ? AppColors.primaryColor.withOpacity(0.3)
                  : isInPath
                      ? AppColors.primaryColor.withOpacity(0.12)
                      : AppColors.cardColor,
              elevation: isSelected
                  ? 6
                  : isInPath
                      ? 4
                      : 2,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: Icon(
                  team.parentId == null ? Icons.apartment : Icons.group,
                  color: AppColors.primaryColor,
                ),
                title: Text(
                  team.name,
                  style: TextStyle(
                    color: AppColors.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (teamTaskCounts[team.id] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${teamTaskCounts[team.id]}',
                          style: const TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        color: AppColors.secondaryTextColor,
                      ),
                      onSelected: (value) =>
                          _handleTeamAction(context, value, team),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'subteam',
                          child: ListTile(
                            leading:
                                Icon(Icons.add, color: AppColors.primaryColor),
                            title: Text('Create Sub-Team'),
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading:
                                Icon(Icons.edit, color: AppColors.primaryColor),
                            title: Text('Edit'),
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete, color: Colors.red),
                            title: Text('Delete'),
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'manage',
                          child: ListTile(
                            leading: Icon(Icons.people,
                                color: AppColors.primaryColor),
                            title: Text('Manage Members'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                onTap: () => onTap(team),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class TeamInfoCard extends StatelessWidget {
  final Team team;
  const TeamInfoCard({Key? key, required this.team}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardColor,
      margin: const EdgeInsets.all(12),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.group, color: AppColors.primaryColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Team Information',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _infoRow('Name', team.name),
            _infoRow('Type', team.type),
            _infoRow('Status', team.status),
            _infoRow('Description', team.description ?? 'No description'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: TextStyle(
                color: AppColors.secondaryTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.textColor,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TeamMemberList extends StatelessWidget {
  final Team team;
  final List<User> users;
  final VoidCallback onMemberChanged;
  final VoidCallback onAddMember;
  final Future<void> Function(TeamMember) onEditRole;
  final Future<void> Function(TeamMember) onRemoveMember;
  const TeamMemberList({
    Key? key,
    required this.team,
    required this.users,
    required this.onMemberChanged,
    required this.onAddMember,
    required this.onEditRole,
    required this.onRemoveMember,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final teamUsers = team.members
        .map((m) => users.firstWhere((u) => u.id == m.userId,
            orElse: () => User(
                id: m.userId,
                name: 'Unknown',
                email: '',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now())))
        .toList();

    return Card(
      color: AppColors.cardColor,
      margin: const EdgeInsets.all(12),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: AppColors.primaryColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Team Members',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.person_add,
                      color: AppColors.primaryColor),
                  tooltip: 'Add Member',
                  onPressed: onAddMember,
                ),
              ],
            ),
            const SizedBox(height: 12),
            team.members.isEmpty
                ? const Text('No members in this team.',
                    style: TextStyle(color: AppColors.secondaryTextColor))
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: team.members.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: Colors.white12, height: 16),
                    itemBuilder: (context, index) {
                      final member = team.members[index];
                      final user = teamUsers[index];
                      final initials = user.name.isNotEmpty
                          ? user.name
                              .trim()
                              .split(' ')
                              .map((e) => e.isNotEmpty ? e[0] : '')
                              .take(2)
                              .join()
                              .toUpperCase()
                          : '?';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.primaryColor.withOpacity(0.2),
                          child: Text(initials,
                              style: const TextStyle(
                                  color: AppColors.primaryColor)),
                        ),
                        title: Text(user.name,
                            style: const TextStyle(
                                color: AppColors.textColor,
                                fontWeight: FontWeight.bold)),
                        subtitle: Text(user.email,
                            style: const TextStyle(
                                color: AppColors.secondaryTextColor)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: member.role == 'team_leader'
                                    ? Colors.blue
                                    : AppColors.primaryColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Tooltip(
                                message: member.role == 'team_leader'
                                    ? 'Team Leader'
                                    : 'Member',
                                child: Text(
                                  member.role == 'team_leader'
                                      ? 'Team Leader'
                                      : 'Member',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert,
                                  color: AppColors.secondaryTextColor),
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  await onEditRole(member);
                                } else if (value == 'remove') {
                                  await onRemoveMember(member);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: ListTile(
                                    leading: Icon(Icons.edit,
                                        color: AppColors.primaryColor),
                                    title: Text('Edit Role'),
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'remove',
                                  child: ListTile(
                                    leading:
                                        Icon(Icons.delete, color: Colors.red),
                                    title: Text('Remove'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

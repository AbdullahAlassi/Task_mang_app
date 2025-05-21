import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/project_member.dart';
import '../../models/user_model.dart';
import '../../services/project_service.dart';
import '../../utils/project_permissions.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';

class ManageProjectTeamScreen extends StatefulWidget {
  final String projectId;
  final String projectTitle;

  const ManageProjectTeamScreen({
    Key? key,
    required this.projectId,
    required this.projectTitle,
  }) : super(key: key);

  @override
  State<ManageProjectTeamScreen> createState() =>
      _ManageProjectTeamScreenState();
}

class _ManageProjectTeamScreenState extends State<ManageProjectTeamScreen> {
  final ProjectService _projectService = ProjectService(AuthService());
  List<ProjectMember> _members = [];
  bool _isLoading = true;
  ProjectRole _currentUserRole = ProjectRole.viewer;
  final TextEditingController _searchController = TextEditingController();
  String _selectedRole = 'member';

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    debugPrint(
        '🔍 [ManageTeamScreen] Loading members for project: ${widget.projectId}');
    try {
      setState(() => _isLoading = true);
      final members = await _projectService.getProjectMembers(widget.projectId);
      debugPrint('[DEBUG] Total Members from API: [1m${members.length}[0m');
      for (var m in members) {
        debugPrint(
            ' -> Member: [1m${m.user.name}[0m (role: ${m.role}, id: ${m.userId}, email: ${m.user.email})');
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      debugPrint(
          '👤 [ManageTeamScreen] Current user: ${currentUser?.name} (${currentUser?.id})');

      if (currentUser == null) {
        debugPrint(
            '⚠️ [ManageTeamScreen] Current user is null in AuthProvider');
        throw Exception('User not authenticated');
      }

      final currentUserId = currentUser.id.trim();
      debugPrint('🆔 [ManageTeamScreen] Current user ID: $currentUserId');

      // First check if user is the project manager
      final project = await _projectService.getProjectDetails(widget.projectId);
      if (project.managerId.trim() == currentUserId) {
        debugPrint('👑 [ManageTeamScreen] User is project manager');
        setState(() {
          _members = members;
          _currentUserRole = ProjectRole.owner;
        });
        return;
      }

      // If not manager, find their role in members list
      final matched = members.firstWhere(
        (m) => m.userId.trim() == currentUserId,
        orElse: () {
          debugPrint('⚠️ [ManageTeamScreen] User not found in project members');
          return ProjectMember(
            userId: currentUserId,
            role: 'viewer',
            user: currentUser,
            joinedAt: DateTime.now(),
          );
        },
      );

      debugPrint('🎭 [ManageTeamScreen] User role: ${matched.role}');

      setState(() {
        _members = members;
        _currentUserRole = ProjectPermissions.standardizeRole(matched.role);
      });
      debugPrint('[DEBUG] _members.length set to: ${_members.length}');
    } catch (e, stack) {
      debugPrint('[ManageTeamScreen] Error loading members: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading members: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateMemberRole(ProjectMember member, String newRole) async {
    try {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Update Role'),
          content: Text(
            'Are you sure you want to change ${member.user.name}\'s role to ${newRole.toUpperCase()}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ).then((confirmed) async {
        if (confirmed == true) {
          await _projectService.updateProjectMemberRole(
            widget.projectId,
            member.userId,
            newRole,
          );
          await _loadMembers();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Member role updated successfully')),
            );
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating role: $e')),
        );
      }
    }
  }

  Future<void> _removeMember(ProjectMember member) async {
    try {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remove Member'),
          content: Text(
            'Are you sure you want to remove ${member.user.name} from the project?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remove'),
            ),
          ],
        ),
      ).then((confirmed) async {
        if (confirmed == true) {
          await _projectService.removeProjectMember(
            widget.projectId,
            member.userId,
          );
          await _loadMembers();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Member removed successfully')),
            );
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing member: $e')),
        );
      }
    }
  }

  Future<void> _inviteMember() async {
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Invite Member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Email or Name',
                  hintText: 'Enter email or name to search',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                ),
                items: ['admin', 'member', 'viewer']
                    .map(
                      (role) => DropdownMenuItem(
                        value: role,
                        child: Text(role.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedRole = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_searchController.text.isNotEmpty) {
                  try {
                    await _projectService.inviteProjectMember(
                      widget.projectId,
                      _searchController.text,
                      _selectedRole,
                    );
                    if (mounted) {
                      Navigator.pop(context);
                      await _loadMembers();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invitation sent successfully'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error inviting member: $e')),
                      );
                    }
                  }
                }
              },
              child: const Text('Invite'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return Colors.purple;
      case 'admin':
        return Colors.blue;
      case 'member':
        return Colors.green;
      case 'viewer':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Team Members - ${widget.projectTitle}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMembers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getRoleColor(
                              _currentUserRole.toString().split('.').last),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Your Role: ${_currentUserRole.toString().split('.').last.toUpperCase()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _members.length,
                    itemBuilder: (context, index) {
                      final member = _members[index];
                      final memberRole = ProjectPermissions.standardizeRole(
                        member.role,
                      );
                      final canModify = ProjectPermissions.canManageMember(
                        _currentUserRole,
                        memberRole,
                      );

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor: _getRoleColor(member.role),
                            backgroundImage: (member.user.profilePicture !=
                                        null &&
                                    member.user.profilePicture!.isNotEmpty &&
                                    member.user.profilePicture !=
                                        'default-profile.jpg')
                                ? NetworkImage(member.user.profilePicture!)
                                : null,
                            child: (member.user.profilePicture == null ||
                                    member.user.profilePicture!.isEmpty ||
                                    member.user.profilePicture ==
                                        'default-profile.jpg')
                                ? Text(
                                    member.user.name.isNotEmpty
                                        ? member.user.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(
                            member.user.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(member.user.email),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getRoleColor(member.role),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  member.role.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: canModify
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    DropdownButton<String>(
                                      value: member.role,
                                      items: ['admin', 'member', 'viewer']
                                          .map(
                                            (role) => DropdownMenuItem(
                                              value: role,
                                              child: Text(role.toUpperCase()),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (newRole) {
                                        if (newRole != null) {
                                          _updateMemberRole(member, newRole);
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                          Icons.remove_circle_outline),
                                      color: Colors.red,
                                      onPressed: () => _removeMember(member),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: ProjectPermissions.canManageMember(
        _currentUserRole,
        ProjectRole.member,
      )
          ? FloatingActionButton(
              onPressed: _inviteMember,
              child: const Icon(Icons.person_add),
            )
          : null,
    );
  }
}

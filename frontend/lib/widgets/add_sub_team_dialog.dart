import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../models/team_model.dart';
import '../models/user_model.dart';
import '../services/team_service.dart';
import '../services/user_service.dart';

class AddSubTeamDialog extends StatefulWidget {
  final Team parentTeam;
  final VoidCallback onTeamCreated;

  const AddSubTeamDialog({
    Key? key,
    required this.parentTeam,
    required this.onTeamCreated,
  }) : super(key: key);

  @override
  State<AddSubTeamDialog> createState() => _AddSubTeamDialogState();
}

class _AddSubTeamDialogState extends State<AddSubTeamDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _teamService = TeamService();
  final _userService = UserService();

  bool _isLoading = false;
  List<User> _availableUsers = [];
  List<User> _selectedUsers = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _userService.getAllUsers();
      setState(() {
        _availableUsers = users.where((user) {
          return !widget.parentTeam.members
              .any((member) => member.userId == user.id);
        }).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load users: $e')),
        );
      }
    }
  }

  List<User> get _filteredUsers {
    if (_searchQuery.isEmpty) {
      return _availableUsers;
    }
    return _availableUsers.where((user) {
      return user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _createSubTeam() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Map the parent team type to a valid enum value if needed
      String teamType = widget.parentTeam.type;
      if (!['Department', 'Cross-functional', 'Project-based']
          .contains(teamType)) {
        teamType = 'Department'; // Default to Department if type is invalid
      }

      final teamData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'parent': widget.parentTeam.id,
        'type': teamType,
        'members': _selectedUsers
            .map((user) => {
                  'user': user.id,
                  'role': 'member',
                })
            .toList(),
      };

      await _teamService.createTeam(teamData);

      if (mounted) {
        Navigator.pop(context);
        widget.onTeamCreated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create sub-team: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Create Sub-Team',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Parent Team: ${widget.parentTeam.name}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Team Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a team name';
                  }
                  if (value.length < 3) {
                    return 'Team name must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Select Team Members',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search users...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = _filteredUsers[index];
                    final isSelected = _selectedUsers.contains(user);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: (user.profilePicture != null &&
                                user.profilePicture!.startsWith('http'))
                            ? NetworkImage(user.profilePicture!)
                            : null,
                        child: (user.profilePicture == null ||
                                !user.profilePicture!.startsWith('http'))
                            ? Text(user.name[0].toUpperCase())
                            : null,
                      ),
                      title: Text(user.name),
                      subtitle: Text(user.email),
                      trailing: IconButton(
                        icon: Icon(
                          isSelected ? Icons.remove_circle : Icons.add_circle,
                          color: isSelected ? Colors.red : Colors.green,
                        ),
                        onPressed: () {
                          setState(() {
                            if (isSelected) {
                              _selectedUsers.remove(user);
                            } else {
                              _selectedUsers.add(user);
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _createSubTeam,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Create Sub-Team'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

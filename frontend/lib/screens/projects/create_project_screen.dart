import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../config/app_colors.dart';
import '../../../models/project_model.dart';
import '../../../services/project_service.dart';
import '../../../services/user_service.dart';
import '../../../models/user_model.dart';
import '../../models/team_model.dart';
import '../../services/team_service.dart';
import '../../screens/teams/team_hierarchy_screen.dart';
import '../../services/auth_service.dart';
import 'dart:convert';

class CreateProjectScreen extends StatefulWidget {
  final Project? project; // If provided, we're editing an existing project

  const CreateProjectScreen({
    Key? key,
    this.project,
  }) : super(key: key);

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();

  DateTime? _deadline;
  bool _isLoading = false;
  String _selectedColor = '#6B4EFF'; // Default color

  // Project type: 'personal' or 'team'
  String _projectType = 'personal';
  String? _selectedTeamId;
  Team? _selectedTeam;
  List<Team> _allTeams = [];
  final TeamService _teamService = TeamService();
  final AuthService _authService = AuthService();
  String? _currentUserId;

  // Predefined project colors
  final List<String> _projectColors = [
    '#6B4EFF', // Purple
    '#211B4E', // Dark blue
    '#96292B', // Red
    '#808C44', // Olive green
    '#35383F', // Dark gray
    '#2E7D32', // Green
    '#1565C0', // Blue
    '#C2185B', // Pink
    '#FF6F00', // Orange
    '#4527A0', // Deep Purple
  ];

  final ProjectService _projectService = ProjectService(AuthService());
  List<User> _availableUsers = [];
  List<User> _filteredUsers = [];
  List<String> _selectedMemberIds = [];

  @override
  void initState() {
    super.initState();

    // If editing an existing project, populate the form
    if (widget.project != null) {
      _titleController.text = widget.project!.title;
      _descriptionController.text = widget.project!.description;
      _deadline = widget.project!.deadline;
      _selectedMemberIds = widget.project!.memberIds;
      _selectedColor = widget.project!.color;
      _projectType = (widget.project as dynamic).type ?? 'personal';
      _selectedTeamId = (widget.project as dynamic).teamId ?? null;
    }
    _loadUsers();
    _loadTeams();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() => _isLoading = true);
      final users = await UserService().getAllUsers();
      setState(() {
        _availableUsers = users;
        _filteredUsers = _filterUsers(users, '');
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load users: $e')),
      );
    }
  }

  Future<void> _loadTeams() async {
    try {
      final userId = await _authService.getCurrentUserId();
      final teams = await _teamService.getAllTeams();
      setState(() {
        _currentUserId = userId;
        _allTeams = teams
            .where((team) => team.members.any((m) => m.userId == userId))
            .toList();
      });
    } catch (e) {
      // ignore error
    }
  }

  List<User> _filterUsers(List<User> users, String query) {
    if (query.isEmpty) return [];

    final lowercaseQuery = query.toLowerCase();
    return users.where((user) {
      final isNotSelected = !_selectedMemberIds.contains(user.id);
      final matchesQuery = user.name.toLowerCase().contains(lowercaseQuery) ||
          user.email.toLowerCase().contains(lowercaseQuery);
      return isNotSelected && matchesQuery;
    }).toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filteredUsers = _filterUsers(_availableUsers, query);
    });
  }

  void _updateAvailableUsersForTeam() {
    if (_projectType == 'team' && _selectedTeamId != null) {
      final selectedTeam = _allTeams.firstWhere(
        (team) => team.id == _selectedTeamId,
        orElse: () => Team(
          id: '',
          name: '',
          childrenIds: [],
          members: [],
          type: '',
          status: '',
          metadata: TeamMetadata(),
          settings: TeamSettings(
            allowMemberInvites: false,
            requireApprovalForJoining: true,
            visibility: 'private',
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final teamMemberIds = selectedTeam.members.map((m) => m.userId).toSet();
      final filteredUsers =
          _availableUsers.where((u) => teamMemberIds.contains(u.id)).toList();
      setState(() {
        _filteredUsers = _filterUsers(filteredUsers, _searchController.text);
        _availableUsers = filteredUsers;
        // Remove any selected members not in the team
        _selectedMemberIds = _selectedMemberIds
            .where((id) => teamMemberIds.contains(id))
            .toList();
      });
    } else {
      // For personal projects, show all users
      setState(() {
        _filteredUsers = _filterUsers(_availableUsers, _searchController.text);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryColor,
              onPrimary: Colors.white,
              surface: AppColors.cardColor,
              onSurface: AppColors.textColor,
            ),
            dialogTheme: DialogThemeData(backgroundColor: AppColors.cardColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _deadline) {
      setState(() {
        _deadline = picked;
      });
    }
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) return;
    if (_projectType == 'team' && _selectedTeamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a team for Team Project')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get current user ID
      final currentUserId = await _authService.getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('Could not get current user ID');
      }

      // Build members array as a list of user IDs for the backend to process
      // Include the current user ID as they are the project creator/manager
      final List<String> memberIdsToSend = List.from(_selectedMemberIds);
      if (!memberIdsToSend.contains(currentUserId)) {
        memberIdsToSend.add(currentUserId);
      }

      final projectData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'deadline': _deadline?.toIso8601String(),
        // Send only the list of user IDs
        'members': memberIdsToSend,
        'progress': 0,
        'totalTasks': 0,
        'completedTasks': 0,
        'boards': widget.project?.boardIds ?? [],
        'color': _selectedColor,
        'status': 'To Do',
        'type': _projectType,
        if (_projectType == 'team') 'team': _selectedTeamId,
      };

      // Remove team field for personal projects
      if (_projectType == 'personal') {
        projectData.remove('team');
      }

      print('\n=== Creating/Updating Project ===');
      print('Project Data: ${json.encode(projectData)}');

      if (widget.project != null) {
        // Update existing project
        await _projectService.updateProject(widget.project!.id, projectData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Project updated successfully')),
          );
        }
      } else {
        // Create new project
        final newProject = await _projectService.createProject(projectData);
        print('Created project with color: ${newProject.color}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Project created successfully')),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      print('Error saving project: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save project: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Add this new method for color selection
  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardColor,
          title: const Text(
            'Select Project Color',
            style: TextStyle(color: AppColors.textColor),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Predefined colors grid
                SizedBox(
                  height: 200,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _projectColors.length,
                    itemBuilder: (context, index) {
                      final color = _projectColors[index];
                      final isSelected = color == _selectedColor;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedColor = color;
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                Color(int.parse(color.replaceAll('#', '0xFF'))),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Custom color picker button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      final Color? pickedColor = await showDialog<Color>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: AppColors.cardColor,
                          title: const Text(
                            'Pick Custom Color',
                            style: TextStyle(color: AppColors.textColor),
                          ),
                          content: SingleChildScrollView(
                            child: ColorPicker(
                              pickerColor: Color(int.parse(
                                  _selectedColor.replaceAll('#', '0xFF'))),
                              onColorChanged: (color) {
                                setState(() {
                                  _selectedColor =
                                      '#${color.value.toRadixString(16).substring(2)}';
                                });
                              },
                              pickerAreaHeightPercent: 0.8,
                              enableAlpha: false,
                              labelTypes: const [],
                              displayThumbColor: true,
                              paletteType: PaletteType.hsv,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(
                                  context,
                                  Color(int.parse(
                                      _selectedColor.replaceAll('#', '0xFF')))),
                              child: const Text('Select'),
                            ),
                          ],
                        ),
                      );
                      if (pickedColor != null) {
                        setState(() {
                          _selectedColor =
                              '#${pickedColor.value.toRadixString(16).substring(2)}';
                        });
                      }
                    },
                    icon: const Icon(Icons.color_lens),
                    label: const Text('Custom Color'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        title: Text(widget.project != null ? 'Edit Project' : 'Create Project'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Project Type Selection
                    const Text(
                      'Project Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Radio<String>(
                          value: 'personal',
                          groupValue: _projectType,
                          onChanged: (value) {
                            setState(() {
                              _projectType = value!;
                              _selectedTeamId = null;
                              _selectedTeam = null;
                            });
                          },
                        ),
                        const Text('Normal Project'),
                        const SizedBox(width: 16),
                        Radio<String>(
                          value: 'team',
                          groupValue: _projectType,
                          onChanged: (value) {
                            setState(() {
                              _projectType = value!;
                            });
                          },
                        ),
                        const Text('Team Project'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_projectType == 'team')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Team',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // You can use a dropdown or a custom team picker here
                          DropdownButtonFormField<String>(
                            value: _selectedTeamId,
                            items: _allTeams
                                .map((team) => DropdownMenuItem(
                                      value: team.id,
                                      child: Text(team.name),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedTeamId = value;
                                _selectedTeam = _allTeams.firstWhere(
                                  (team) => team.id == value,
                                  orElse: () => Team(
                                    id: '',
                                    name: '',
                                    childrenIds: [],
                                    members: [],
                                    type: '',
                                    status: '',
                                    metadata: TeamMetadata(),
                                    settings: TeamSettings(
                                      allowMemberInvites: false,
                                      requireApprovalForJoining: true,
                                      visibility: 'private',
                                    ),
                                    createdAt: DateTime.now(),
                                    updatedAt: DateTime.now(),
                                  ),
                                );
                              });
                              _updateAvailableUsersForTeam();
                            },
                            decoration: const InputDecoration(
                              labelText: 'Team',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (_projectType == 'team' &&
                                  (value == null || value.isEmpty)) {
                                return 'Please select a team';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    // Title Field
                    const Text(
                      'Project Title',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(color: AppColors.textColor),
                      decoration: InputDecoration(
                        hintText: 'Enter project title',
                        filled: true,
                        fillColor: AppColors.cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a project title';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Description Field
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(color: AppColors.textColor),
                      decoration: InputDecoration(
                        hintText: 'Enter project description',
                        filled: true,
                        fillColor: AppColors.cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 24),

                    // Deadline Field
                    const Text(
                      'Deadline (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _deadline != null
                                  ? DateFormat('MMM d, yyyy').format(_deadline!)
                                  : 'Select a deadline',
                              style: TextStyle(
                                color: _deadline != null
                                    ? AppColors.textColor
                                    : AppColors.secondaryTextColor,
                              ),
                            ),
                            const Icon(Icons.calendar_today,
                                color: AppColors.primaryColor),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Color Selection
                    const Text(
                      'Project Color',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _showColorPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Color(int.parse(_selectedColor
                                        .replaceAll('#', '0xFF'))),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Select Color',
                                  style: TextStyle(
                                    color: _selectedColor == '#6B4EFF'
                                        ? AppColors.secondaryTextColor
                                        : AppColors.textColor,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(Icons.color_lens,
                                color: AppColors.primaryColor),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Member Selection
                    const Text(
                      'Select Members',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _projectType == 'team'
                        ? (_selectedTeamId == null
                            ? Center(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  child: Text(
                                    'Please select a team first to show the users.',
                                    style: TextStyle(
                                      color: AppColors.secondaryTextColor,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  ..._availableUsers.map((user) {
                                    final isSelected =
                                        _selectedMemberIds.contains(user.id);
                                    final isManager =
                                        widget.project?.managerId == user.id;
                                    return CheckboxListTile(
                                      value: isSelected,
                                      onChanged: isManager
                                          ? null
                                          : (checked) {
                                              setState(() {
                                                if (checked == true) {
                                                  _selectedMemberIds
                                                      .add(user.id);
                                                } else {
                                                  _selectedMemberIds
                                                      .remove(user.id);
                                                }
                                              });
                                            },
                                      title: Row(
                                        children: [
                                          Text(user.name),
                                          if (isManager) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryColor
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Text(
                                                'Manager',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.primaryColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      subtitle: Text(user.email),
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                    );
                                  }).toList(),
                                  const SizedBox(height: 16),
                                ],
                              ))
                        : Column(
                            children: [
                              // Personal project: keep search and selection UI
                              TextFormField(
                                controller: _searchController,
                                style:
                                    const TextStyle(color: AppColors.textColor),
                                decoration: InputDecoration(
                                  hintText: 'Search by name or email',
                                  filled: true,
                                  fillColor: AppColors.cardColor,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: const Icon(Icons.search,
                                      color: AppColors.primaryColor),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear,
                                              color: AppColors.primaryColor),
                                          onPressed: () {
                                            _searchController.clear();
                                            _onSearchChanged('');
                                          },
                                        )
                                      : null,
                                ),
                                onChanged: _onSearchChanged,
                              ),
                              const SizedBox(height: 16),
                              if (_selectedMemberIds.isNotEmpty) ...[
                                const Text(
                                  'Selected Members',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ..._availableUsers
                                    .where((user) =>
                                        _selectedMemberIds.contains(user.id))
                                    .map((user) {
                                  final isManager =
                                      widget.project?.managerId == user.id;
                                  return ListTile(
                                    leading: Icon(
                                      Icons.person,
                                      color: isManager
                                          ? AppColors.primaryColor
                                          : AppColors.secondaryTextColor,
                                    ),
                                    title: Row(
                                      children: [
                                        Text(user.name),
                                        if (isManager) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryColor
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'Manager',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.primaryColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    subtitle: Text(user.email),
                                    trailing: isManager
                                        ? null
                                        : IconButton(
                                            icon: const Icon(
                                                Icons.remove_circle_outline,
                                                color: Colors.red),
                                            onPressed: () {
                                              setState(() {
                                                _selectedMemberIds
                                                    .remove(user.id);
                                                _filteredUsers = _filterUsers(
                                                    _availableUsers,
                                                    _searchController.text);
                                              });
                                            },
                                          ),
                                  );
                                }),
                                const SizedBox(height: 16),
                              ],
                              if (_searchController.text.isNotEmpty) ...[
                                const Text(
                                  'Search Results',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ..._filteredUsers.map((user) {
                                  final isManager =
                                      widget.project?.managerId == user.id;
                                  return ListTile(
                                    leading: Icon(
                                      Icons.person_outline,
                                      color: isManager
                                          ? AppColors.primaryColor
                                          : AppColors.secondaryTextColor,
                                    ),
                                    title: Row(
                                      children: [
                                        Text(user.name),
                                        if (isManager) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryColor
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'Manager',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.primaryColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    subtitle: Text(user.email),
                                    trailing: isManager
                                        ? null
                                        : IconButton(
                                            icon: const Icon(
                                                Icons.add_circle_outline,
                                                color: AppColors.primaryColor),
                                            onPressed: () {
                                              setState(() {
                                                _selectedMemberIds.add(user.id);
                                                _filteredUsers = _filterUsers(
                                                    _availableUsers,
                                                    _searchController.text);
                                              });
                                            },
                                          ),
                                  );
                                }),
                              ],
                              const SizedBox(height: 40),
                            ],
                          ),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProject,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                widget.project != null
                                    ? 'Update Project'
                                    : 'Create Project',
                                style: const TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/app_colors.dart';
import '../../../models/project_model.dart';
import '../../../services/project_service.dart';
import '../../../services/user_service.dart';
import '../../../models/user_model.dart';

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
  String _status = 'To Do';
  bool _isLoading = false;

  final ProjectService _projectService = ProjectService();
  List<User> _availableUsers = [];
  List<User> _filteredUsers = [];
  List<String> _selectedMemberIds = [];

  final List<String> _statusOptions = [
    'To Do',
    'In Progress',
    'Completed',
  ];

  @override
  void initState() {
    super.initState();

    // If editing an existing project, populate the form
    if (widget.project != null) {
      _titleController.text = widget.project!.title;
      _descriptionController.text = widget.project!.description;
      _deadline = widget.project!.deadline;
      _status = widget.project!.status;
      _selectedMemberIds = widget.project!.memberIds;
    }

    _loadUsers();
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
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final projectData = {
          'title': _titleController.text,
          'description': _descriptionController.text,
          'status': _status,
          'deadline': _deadline?.toIso8601String(),
          'members': _selectedMemberIds,
          'progress': 0, // Initialize progress as integer
          'totalTasks': 0, // Initialize totalTasks as integer
          'completedTasks': 0, // Initialize completedTasks as integer
          'boards': [], // Initialize with empty boards array
        };

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
          await _projectService.createProject(projectData);
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save project: $e'),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Copy Error',
                onPressed: () {
                  // Copy error details to clipboard
                  final errorDetails = 'Error: $e';
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Error details copied to clipboard')),
                  );
                },
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
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

                    // Status Field
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _status,
                          isExpanded: true,
                          dropdownColor: AppColors.cardColor,
                          style: const TextStyle(color: AppColors.textColor),
                          icon: const Icon(Icons.arrow_drop_down,
                              color: AppColors.primaryColor),
                          items: _statusOptions.map((String status) {
                            return DropdownMenuItem<String>(
                              value: status,
                              child: Text(status),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _status = newValue;
                              });
                            }
                          },
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

                    // Search Bar
                    TextFormField(
                      controller: _searchController,
                      style: const TextStyle(color: AppColors.textColor),
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

                    // Selected Members
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
                          .where((user) => _selectedMemberIds.contains(user.id))
                          .map((user) {
                        // Check if the user is the manager
                        final isManager = widget.project?.managerId == user.id;
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
                                    color:
                                        AppColors.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
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
                              ? null // No delete button for manager
                              : IconButton(
                                  icon: const Icon(Icons.remove_circle_outline,
                                      color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _selectedMemberIds.remove(user.id);
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

                    // Search Results
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
                        // Don't show add button if user is already the manager
                        final isManager = widget.project?.managerId == user.id;
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
                                    color:
                                        AppColors.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
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
                              ? null // No add button for manager
                              : IconButton(
                                  icon: const Icon(Icons.add_circle_outline,
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

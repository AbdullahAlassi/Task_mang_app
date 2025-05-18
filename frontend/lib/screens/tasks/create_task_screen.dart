import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../services/task_service.dart';
import '../../services/project_service.dart';
import '../../services/user_service.dart';
import '../../services/board_service.dart';

class CreateTaskScreen extends StatefulWidget {
  final String projectId;
  final String boardId;
  final String? taskId; // If provided, we're editing an existing task

  const CreateTaskScreen({
    Key? key,
    required this.projectId,
    required this.boardId,
    this.taskId,
  }) : super(key: key);

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _taskService = TaskService();
  final _projectService = ProjectService();
  final _userService = UserService();
  final _boardService = BoardService();

  DateTime? _dueDate;
  List<String> _assignedTo = [];
  bool _isLoading = false;
  String _priority = 'Medium';
  Color _selectedColor = Colors.blue;
  List<User> _projectMembers = [];
  List<User> _filteredMembers = [];
  final _searchController = TextEditingController();

  // Priority options
  final List<String> _priorities = [
    'Low',
    'Medium',
    'High',
    'Urgent',
  ];

  // Color options
  final List<Color> _colors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.taskId != null) {
      _loadTaskDetails();
    }
    _loadProjectMembers();
  }

  Future<void> _loadProjectMembers() async {
    try {
      setState(() => _isLoading = true);
      print('\n=== Loading Project Members ===');

      // Get the project ID from the board
      final board = await _boardService.getBoardDetails(widget.boardId);
      final projectId = board.project;
      print('Project ID from board: $projectId');

      // First get the project details to get the member IDs
      final project = await _projectService.getProjectDetails(projectId);
      print('Project loaded: ${project.title}');
      print('Project member IDs: ${project.memberIds}');

      // Only fetch users that are members of this project
      final members = await _userService.getUsersByIds(project.memberIds);
      print('Fetched ${members.length} members');

      setState(() {
        _projectMembers = members;
        _filteredMembers = members;
        _isLoading = false;
      });
      print('Project members loaded successfully');
    } catch (e, stackTrace) {
      print('\nError loading project members:');
      print('Error message: $e');
      print('Stack trace:');
      print(stackTrace);
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load project members: $e')),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMembers = _projectMembers;
      } else {
        _filteredMembers = _projectMembers.where((user) {
          final lowercaseQuery = query.toLowerCase();
          return user.name.toLowerCase().contains(lowercaseQuery) ||
              user.email.toLowerCase().contains(lowercaseQuery);
        }).toList();
      }
    });
  }

  Future<void> _loadTaskDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('\n=== Loading Task Details ===');
      print('Task ID: ${widget.taskId}');
      print('Project ID: ${widget.projectId}');
      print('Board ID: ${widget.boardId}');

      final task = await _taskService.getTaskDetails(widget.taskId!);
      print('Task loaded: ${task.title}');
      print('Task color: ${task.color}');
      print('Task assigned to: ${task.assignedTo}');

      setState(() {
        _titleController.text = task.title;
        _descriptionController.text = task.description;
        _dueDate = task.deadline;
        _assignedTo = task.assignedTo;
        _priority = task.getPriority();
        _selectedColor = task.color ?? Colors.blue;
        _isLoading = false;
      });
      print('Task details loaded successfully');
    } catch (e, stackTrace) {
      print('\nError loading task details:');
      print('Error message: $e');
      print('Stack trace:');
      print(stackTrace);
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load task details: $e')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
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

    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _saveTask() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final taskData = {
          'title': _titleController.text,
          'description': _descriptionController.text,
          'deadline': _dueDate?.toIso8601String(),
          'assignedTo': _assignedTo,
          'priority': _priority,
          'color': '#${_selectedColor.value.toRadixString(16).substring(2)}',
          'board': widget.boardId,
          'projectId': widget.projectId,
        };

        if (widget.taskId != null) {
          // Update existing task
          await _taskService.updateTask(widget.taskId!, taskData);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Task updated successfully')),
            );
          }
        } else {
          // Create new task
          await _taskService.createTask(taskData);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Task created successfully')),
            );
          }
        }

        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate success
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save task: $e')),
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
        title: Text(widget.taskId != null ? 'Edit Task' : 'Create Task'),
      ),
      body: _isLoading && widget.taskId != null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Field
                    const Text(
                      'Task Title',
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
                        hintText: 'Enter task title',
                        filled: true,
                        fillColor: AppColors.cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a task title';
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
                        hintText: 'Enter task description',
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

                    // Due Date Field
                    const Text(
                      'Due Date (Optional)',
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
                              _dueDate != null
                                  ? DateFormat('MMM d, yyyy').format(_dueDate!)
                                  : 'Select a due date',
                              style: TextStyle(
                                color: _dueDate != null
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

                    // Priority Field
                    const Text(
                      'Priority',
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
                          value: _priority,
                          isExpanded: true,
                          dropdownColor: AppColors.cardColor,
                          style: const TextStyle(color: AppColors.textColor),
                          icon: const Icon(Icons.arrow_drop_down,
                              color: AppColors.primaryColor),
                          items: _priorities.map((String priority) {
                            return DropdownMenuItem<String>(
                              value: priority,
                              child: Text(priority),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _priority = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Color Selection
                    const Text(
                      'Color',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _colors.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedColor = _colors[index];
                              });
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: _colors[index],
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _selectedColor == _colors[index]
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: _selectedColor == _colors[index]
                                  ? const Icon(Icons.check, color: Colors.white)
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Member Selection Section
                    const Text(
                      'Assign Members',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Search Bar for Members
                    TextFormField(
                      controller: _searchController,
                      style: const TextStyle(color: AppColors.textColor),
                      decoration: InputDecoration(
                        hintText: 'Search project members',
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
                    if (_assignedTo.isNotEmpty) ...[
                      const Text(
                        'Selected Members',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._projectMembers
                          .where((user) => _assignedTo.contains(user.id))
                          .map((user) => ListTile(
                                leading: const Icon(Icons.person,
                                    color: AppColors.primaryColor),
                                title: Text(user.name),
                                subtitle: Text(user.email),
                                trailing: IconButton(
                                  icon: const Icon(Icons.remove_circle_outline,
                                      color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _assignedTo.remove(user.id);
                                    });
                                  },
                                ),
                              )),
                      const SizedBox(height: 16),
                    ],

                    // Available Members
                    const Text(
                      'Available Members',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _filteredMembers.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'No project members found',
                                style: TextStyle(
                                    color: AppColors.secondaryTextColor),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _filteredMembers.length,
                            itemBuilder: (context, index) {
                              final user = _filteredMembers[index];
                              final isSelected = _assignedTo.contains(user.id);
                              return ListTile(
                                leading: const Icon(Icons.person_outline,
                                    color: AppColors.primaryColor),
                                title: Text(user.name),
                                subtitle: Text(user.email),
                                trailing: IconButton(
                                  icon: Icon(
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.add_circle_outline,
                                    color: isSelected
                                        ? Colors.green
                                        : AppColors.primaryColor,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (isSelected) {
                                        _assignedTo.remove(user.id);
                                      } else {
                                        _assignedTo.add(user.id);
                                      }
                                    });
                                  },
                                ),
                              );
                            },
                          ),

                    const SizedBox(height: 40),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveTask,
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
                                widget.taskId != null
                                    ? 'Update Task'
                                    : 'Create Task',
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../models/team_model.dart';
import '../../services/task_service.dart';
import '../../services/project_service.dart';
import '../../services/user_service.dart';
import '../../services/board_service.dart';
import '../../services/team_service.dart';

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
  final ProjectService _projectService = ProjectService(AuthService());
  final _userService = UserService();
  final _boardService = BoardService();
  final TeamService _teamService = TeamService();

  DateTime? _dueDate;
  List<String> _assignedTo = [];
  String? _assignedTeamId;
  bool _isLoading = false;
  TaskPriority _priority = TaskPriority.medium;
  Color _selectedColor = Colors.blue;
  List<User> _projectMembers = [];
  List<User> _filteredMembers = [];
  List<Team> _subTeams = [];
  Team? _mainTeam;
  String? _projectType;
  String? _projectTeamId;
  final _searchController = TextEditingController();
  List<User> _mainTeamMembers = [];

  // Priority options
  final List<TaskPriority> _priorities = [
    TaskPriority.low,
    TaskPriority.medium,
    TaskPriority.high,
    TaskPriority.urgent,
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
    _loadProjectMembersAndTeams();
  }

  Future<void> _loadProjectMembersAndTeams() async {
    setState(() => _isLoading = true);
    try {
      final project = await _projectService.getProjectDetails(widget.projectId);
      _projectType = (project as dynamic).type ?? 'personal';
      _projectTeamId = (project as dynamic).teamId ?? null;
      List<User> members = [];
      List<Team> subTeams = [];
      Team? mainTeam;
      if (_projectType == 'team' && _projectTeamId != null) {
        mainTeam = await _teamService.getTeamById(_projectTeamId!);
        subTeams = mainTeam.childrenIds.isNotEmpty
            ? await Future.wait(
                mainTeam.childrenIds.map((id) => _teamService.getTeamById(id)))
            : [];
        // Fetch user details for all main team members
        if (mainTeam.members.isNotEmpty) {
          final userIds = mainTeam.members.map((m) => m.userId).toList();
          members = await _userService.getUsersByIds(userIds);
        }
      } else {
        // Fetch user details for all project members
        if (project.memberIds != null && project.memberIds.isNotEmpty) {
          members = await _userService
              .getUsersByIds(List<String>.from(project.memberIds));
        }
      }
      setState(() {
        _mainTeam = mainTeam;
        _subTeams = subTeams;
        _projectMembers = members;
        _filteredMembers = members;
        _mainTeamMembers = members;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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
        _priority = task.priority;
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
          'priority': _priority.name,
          'color': '#${_selectedColor.value.toRadixString(16).substring(2)}',
          'board': widget.boardId,
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
          final board = await _boardService.getBoardDetails(widget.boardId);
          print("Board's projectId: ${board.projectId}");
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
                        child: DropdownButton<TaskPriority>(
                          value: _priority,
                          isExpanded: true,
                          dropdownColor: AppColors.cardColor,
                          style: const TextStyle(color: AppColors.textColor),
                          icon: const Icon(Icons.arrow_drop_down,
                              color: AppColors.primaryColor),
                          items: _priorities.map((TaskPriority priority) {
                            return DropdownMenuItem<TaskPriority>(
                              value: priority,
                              child: Text(priority.name),
                            );
                          }).toList(),
                          onChanged: (TaskPriority? newValue) {
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

                    // Assignment Section
                    const Text(
                      'Assign To',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_projectType == 'team' && _mainTeam != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_subTeams.isNotEmpty)
                            DropdownButtonFormField<String>(
                              value: _assignedTeamId,
                              items: _subTeams
                                  .map((team) => DropdownMenuItem(
                                        value: team.id,
                                        child: Text(team.name),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _assignedTeamId = value;
                                });
                              },
                              decoration: const InputDecoration(
                                labelText: 'Assign to Sub-team (optional)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          const SizedBox(height: 12),
                          // Members of the main team
                          const Text(
                            'Or assign to individual team members:',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.secondaryTextColor,
                            ),
                          ),
                          ..._mainTeamMembers.map((user) => CheckboxListTile(
                                value: _assignedTo.contains(user.id),
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _assignedTo.add(user.id);
                                    } else {
                                      _assignedTo.remove(user.id);
                                    }
                                  });
                                },
                                title: Text(user.name.isNotEmpty
                                    ? user.name
                                    : user.email),
                                subtitle: user.email.isNotEmpty
                                    ? Text(user.email)
                                    : null,
                              )),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Assign to project members:',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.secondaryTextColor,
                            ),
                          ),
                          ..._projectMembers.map((user) => CheckboxListTile(
                                value: _assignedTo.contains(user.id),
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _assignedTo.add(user.id);
                                    } else {
                                      _assignedTo.remove(user.id);
                                    }
                                  });
                                },
                                title: Text(user.name.isNotEmpty
                                    ? user.name
                                    : user.email),
                                subtitle: user.email.isNotEmpty
                                    ? Text(user.email)
                                    : null,
                              )),
                        ],
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

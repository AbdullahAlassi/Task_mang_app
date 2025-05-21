import 'package:flutter/material.dart';
import 'package:frontend/screens/tasks/task_detail_screen.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../models/board_model.dart';
import '../../models/task_model.dart';
import '../../services/board_service.dart';
import '../../services/task_service.dart';
import '../tasks/create_task_screen.dart';
import '../../models/project_model.dart';
import '../../services/project_service.dart';
import '../../utils/project_permissions.dart';
import '../../services/auth_service.dart';

class BoardDetailScreen extends StatefulWidget {
  final Board board;

  const BoardDetailScreen({
    Key? key,
    required this.board,
  }) : super(key: key);

  @override
  State<BoardDetailScreen> createState() => _BoardDetailScreenState();
}

class _BoardDetailScreenState extends State<BoardDetailScreen> {
  bool _isLoading = true;
  late Board _board;
  List<Task> _tasks = [];
  Project? _project;
  ProjectRole? _currentUserRole;
  final ProjectService _projectService = ProjectService(AuthService());

  final _boardService = BoardService();
  final _taskService = TaskService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final board = await _boardService.getBoardDetails(widget.board.id);
      final tasks = await _taskService.getTasksForBoard(widget.board.id);
      final project = await _projectService.getProject(board.projectId);
      final userRole = await project.getCurrentUserRole();
      final role = ProjectPermissions.standardizeRole(userRole);
      setState(() {
        _board = board;
        _tasks = tasks;
        _project = project;
        _currentUserRole = role;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load board data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        title: Text(_board.title),
        actions: [
          if (_currentUserRole != null &&
              ProjectPermissions.canManageBoards(_currentUserRole!))
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // Navigate to edit board screen
              },
            ),
        ],
      ),
      floatingActionButton: (_currentUserRole != null &&
              ProjectPermissions.canCreateTasks(_currentUserRole!))
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateTaskScreen(
                      projectId: _board.projectId,
                      boardId: _board.id,
                    ),
                  ),
                ).then((value) {
                  if (value == true) {
                    _loadData();
                  }
                });
              },
              backgroundColor: AppColors.primaryColor,
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Board Info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Board Type Badge

                // Deadline
                if (_board.deadline != null)
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 16, color: AppColors.secondaryTextColor),
                      const SizedBox(width: 8),
                      Text(
                        'Due: ${DateFormat('MMM d, yyyy').format(_board.deadline!)}',
                        style: const TextStyle(
                          color: AppColors.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                // Task Count
                Text(
                  '${_tasks.length} Tasks',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor,
                  ),
                ),
              ],
            ),
          ),

          // Tasks List
          Expanded(
            child: _tasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.task_alt,
                            color: AppColors.secondaryTextColor, size: 64),
                        const SizedBox(height: 16),
                        const Text(
                          'No tasks yet',
                          style: TextStyle(
                            color: AppColors.textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Create a task to get started',
                          style: TextStyle(color: AppColors.secondaryTextColor),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: (_currentUserRole != null &&
                                  ProjectPermissions.canCreateTasks(
                                      _currentUserRole!))
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CreateTaskScreen(
                                        projectId: _board.projectId,
                                        boardId: _board.id,
                                      ),
                                    ),
                                  ).then((value) {
                                    if (value == true) {
                                      _loadData();
                                    }
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.add),
                          label: const Text('Create Task'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      return _buildTaskCard(task);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailScreen(
                taskId: task.id,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task Title and Priority
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(task.getPriority())
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      task.getPriority(),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getPriorityColor(task.getPriority()),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_currentUserRole != null &&
                      ProjectPermissions.canManageTasks(_currentUserRole!))
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert,
                          color: Colors.white, size: 18),
                      color: const Color(0xFF35383F),
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _editTask(task, _board);
                            break;
                          case 'delete':
                            _deleteTask(task, _board);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit',
                              style: TextStyle(color: Colors.white)),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                ],
              ),

              // Task Description
              if (task.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    task.description,
                    style: const TextStyle(
                      color: AppColors.secondaryTextColor,
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Task Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Due Date
                  if (task.deadline != null)
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 16, color: AppColors.secondaryTextColor),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d').format(task.deadline!),
                          style: const TextStyle(
                            color: AppColors.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),

                  // Assignees
                  if (task.assignedTo.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.person,
                            size: 16, color: AppColors.secondaryTextColor),
                        const SizedBox(width: 4),
                        Text(
                          '${task.assignedTo.length}',
                          style: const TextStyle(
                            color: AppColors.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),

                  // Status
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusColor(task.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      task.status,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(task.status),
                        fontWeight: FontWeight.bold,
                      ),
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

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Low':
        return Colors.green;
      case 'Medium':
        return Colors.blue;
      case 'High':
        return Colors.orange;
      case 'Urgent':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'To Do':
        return Colors.blue;
      case 'In Progress':
        return Colors.orange;
      case 'Done':
        return Colors.green;
      default:
        return Colors.purple;
    }
  }

  void _editTask(Task task, Board board) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTaskScreen(
          projectId: board.projectId,
          boardId: board.id,
          taskId: task.id,
        ),
      ),
    ).then((value) {
      if (value == true) {
        _loadData();
      }
    });
  }

  void _deleteTask(Task task, Board board) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        title: const Text('Delete Task',
            style: TextStyle(color: AppColors.textColor)),
        content: Text(
          'Are you sure you want to delete "${task.title}"? This action cannot be undone.',
          style: const TextStyle(color: AppColors.textColor),
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

    if (confirm == true) {
      try {
        await _taskService.deleteTask(task.id);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete task: $e')),
          );
        }
      }
    }
  }
}

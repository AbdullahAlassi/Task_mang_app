import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:intl/intl.dart';
import '../../../config/app_colors.dart';
import '../../../models/task_model.dart';
import '../../../models/board_model.dart';
import '../../../models/project_model.dart';
import '../../../services/task_service.dart';
import '../../../services/board_service.dart';
import '../../../services/project_service.dart';
import 'create_task_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailScreen({
    Key? key,
    required this.taskId,
  }) : super(key: key);

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TaskService _taskService = TaskService();
  final BoardService _boardService = BoardService();
  final ProjectService _projectService = ProjectService(Dio(), AuthService());
  bool _isLoading = true;
  Task? _task;
  Board? _board;
  Project? _project;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTaskDetails();
  }

  Future<void> _loadTaskDetails() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final task = await _taskService.getTaskDetails(widget.taskId);
      if (!mounted) return;

      // Fetch board details
      final board = await _boardService.getBoardDetails(task.boardId);
      if (!mounted) return;

      // Fetch project details
      final project = await _projectService.getProjectDetails(task.projectId);
      if (!mounted) return;

      setState(() {
        _task = task;
        _board = board;
        _project = project;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title:
            Text(_isLoading ? 'Task Details' : _task?.title ?? 'Task Details'),
        actions: [
          if (!_isLoading && _task != null)
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: _showTaskOptions,
            ),
        ],
      ),
      body: Column(
        children: [
          if (!_isLoading && _task != null && _project != null)
            _buildGradientBanner(),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientBanner() {
    // Get task color, default to status color if not set
    final taskColor = _task!.color ?? _task!.getStatusColor();

    // Get project color, default to primary color if not set
    final projectColor = _project!.getBannerColor();

    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            taskColor,
            projectColor,
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to load task details',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadTaskDetails,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_task == null) {
      return const Center(
        child: Text(
          'Task not found',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusBadge(),
          const SizedBox(height: 16),
          _buildTaskTitle(),
          const SizedBox(height: 16),
          _buildDescription(),
          const SizedBox(height: 24),
          _buildDetails(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(_task!.status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _task!.status,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTaskTitle() {
    return Text(
      _task!.title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.textColor,
      ),
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _task!.description,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.secondaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textColor,
          ),
        ),
        const SizedBox(height: 8),
        _buildAssignedMembersField(),
        const SizedBox(height: 8),
        _buildDetailItem(
          'Priority',
          _task!.priority.name,
          Icons.flag,
          color: _task!.priority.color,
          onTap: _showPriorityPicker,
        ),
        const SizedBox(height: 8),
        _buildDetailItem(
          'Deadline',
          _task!.deadline != null
              ? DateFormat('MMM d, yyyy').format(_task!.deadline!)
              : 'None',
          Icons.calendar_today,
        ),
        const SizedBox(height: 8),
        _buildDetailItem(
          'Status',
          _task!.status,
          Icons.info_outline,
        ),
        const SizedBox(height: 8),
        _buildDetailItem(
          'Board',
          _board?.title ?? 'Loading...',
          Icons.folder_outlined,
        ),
      ],
    );
  }

  Widget _buildAssignedMembersField() {
    final users = _task!.assignedUsers;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.people, color: AppColors.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: users == null || users.isEmpty
                ? const Text('No members assigned',
                    style: TextStyle(color: AppColors.secondaryTextColor))
                : Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: users.map((user) {
                      final initials = (user.name.isNotEmpty)
                          ? user.name
                              .trim()
                              .split(' ')
                              .map((e) => e.isNotEmpty ? e[0] : '')
                              .take(2)
                              .join()
                              .toUpperCase()
                          : '';
                      return Chip(
                        avatar: CircleAvatar(
                          backgroundColor:
                              AppColors.primaryColor.withOpacity(0.2),
                          child: Text(initials,
                              style: const TextStyle(
                                  color: AppColors.primaryColor, fontSize: 12)),
                        ),
                        label: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.name,
                                style: const TextStyle(
                                    color: AppColors.textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                            Text(user.email,
                                style: const TextStyle(
                                    color: AppColors.secondaryTextColor,
                                    fontSize: 11)),
                          ],
                        ),
                        backgroundColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                              color: AppColors.primaryColor.withOpacity(0.2)),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon,
      {Color? color, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? AppColors.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.secondaryTextColor,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color ?? AppColors.textColor,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.secondaryTextColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed,
      {Color? color}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: color ?? Colors.white),
      label: Text(label, style: TextStyle(color: color ?? Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            color != null ? Colors.transparent : AppColors.primaryColor,
        foregroundColor: color ?? Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        side: color != null ? BorderSide(color: color) : null,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'To Do':
        return AppColors.statusTodo;
      case 'In Progress':
        return AppColors.statusInProgress;
      case 'Done':
        return AppColors.statusDone;
      default:
        return AppColors.secondaryTextColor;
    }
  }

  void _updateTaskStatus(bool isCompleted) async {
    try {
      await _taskService.updateTaskStatus(_task!.id, isCompleted);
      _loadTaskDetails();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update task status: $e')),
        );
      }
    }
  }

  void _showTaskOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: AppColors.primaryColor),
                title: const Text('Edit Task',
                    style: TextStyle(color: AppColors.textColor)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateTaskScreen(
                        projectId: _task!.boardId,
                        boardId: _task!.boardId,
                        taskId: _task!.id,
                      ),
                    ),
                  ).then((_) => _loadTaskDetails());
                },
              ),
              ListTile(
                leading: Icon(
                  _task!.isCompleted ? Icons.close : Icons.check,
                  color: AppColors.primaryColor,
                ),
                title: Text(
                  _task!.isCompleted
                      ? 'Mark as Incomplete'
                      : 'Mark as Complete',
                  style: const TextStyle(color: AppColors.textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _updateTaskStatus(!_task!.isCompleted);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Task',
                    style: TextStyle(color: AppColors.textColor)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteTask();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteTask() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        title: const Text('Delete Task',
            style: TextStyle(color: AppColors.textColor)),
        content: Text(
          'Are you sure you want to delete "${_task!.title}"? This action cannot be undone.',
          style: const TextStyle(color: AppColors.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final success = await _taskService.deleteTask(_task!.id);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Task deleted successfully')),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete task: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showPriorityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Priority',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
              const SizedBox(height: 16),
              ...TaskPriority.values.map((priority) {
                return ListTile(
                  leading: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: priority.color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.flag,
                        size: 16,
                        color: priority.color,
                      ),
                    ),
                  ),
                  title: Text(
                    priority.name,
                    style: TextStyle(
                      color: priority.color,
                      fontWeight: _task!.priority == priority
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: _task!.priority == priority
                      ? const Icon(
                          Icons.check,
                          color: AppColors.primaryColor,
                        )
                      : null,
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      await _taskService.updateTask(
                        _task!.id,
                        {'priority': priority.name},
                      );
                      _loadTaskDetails();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update priority: $e'),
                          ),
                        );
                      }
                    }
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}

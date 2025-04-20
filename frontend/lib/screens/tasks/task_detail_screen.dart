import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/app_colors.dart';
import '../../../models/task_model.dart';
import '../../../services/task_service.dart';
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
  bool _isLoading = true;
  late Task _task;

  @override
  void initState() {
    super.initState();
    _loadTaskDetails();
  }

  Future<void> _loadTaskDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final task = await _taskService.getTaskDetails(widget.taskId);

      setState(() {
        _task = task;
        _isLoading = false;
      });
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        title: _isLoading ? const Text('Task Details') : Text(_task.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show task options
              if (!_isLoading) {
                _showTaskOptions();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Task Status
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(_task.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _task.status,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Task Title
                  Text(
                    _task.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColor,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Task Description
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
                    _task.description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.secondaryTextColor,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Task Details
                  const Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailItem(
                    'Deadline',
                    _task.deadline != null
                        ? DateFormat('MMM d, yyyy').format(_task.deadline!)
                        : 'None',
                    Icons.calendar_today,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailItem(
                    'Status',
                    _task.status,
                    Icons.info_outline,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailItem(
                    'Project',
                    'Project ${_task.boardId}',
                    Icons.folder_outlined,
                  ),

                  const SizedBox(height: 24),

                  // Task Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        'Edit',
                        Icons.edit,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateTaskScreen(
                                projectId: _task.boardId,
                                taskId: _task.id,
                              ),
                            ),
                          ).then((_) => _loadTaskDetails());
                        },
                      ),
                      _buildActionButton(
                        _task.isCompleted ? 'Mark Incomplete' : 'Mark Complete',
                        _task.isCompleted ? Icons.close : Icons.check,
                        () {
                          _updateTaskStatus(!_task.isCompleted);
                        },
                      ),
                      _buildActionButton(
                        'Delete',
                        Icons.delete,
                        () {
                          _confirmDeleteTask();
                        },
                        color: Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryColor),
          const SizedBox(width: 12),
          Column(
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
            ],
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      await _taskService.updateTaskStatus(_task.id, isCompleted);
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
                        projectId: _task.boardId,
                        taskId: _task.id,
                      ),
                    ),
                  ).then((_) => _loadTaskDetails());
                },
              ),
              ListTile(
                leading: Icon(
                  _task.isCompleted ? Icons.close : Icons.check,
                  color: AppColors.primaryColor,
                ),
                title: Text(
                  _task.isCompleted ? 'Mark as Incomplete' : 'Mark as Complete',
                  style: const TextStyle(color: AppColors.textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _updateTaskStatus(!_task.isCompleted);
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
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardColor,
          title: const Text('Delete Task',
              style: TextStyle(color: AppColors.textColor)),
          content: Text(
            'Are you sure you want to delete "${_task.title}"? This action cannot be undone.',
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
                  final success = await _taskService.deleteTask(_task.id);
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Task deleted successfully')),
                    );
                    Navigator.pop(context); // Return to previous screen
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
        );
      },
    );
  }
}

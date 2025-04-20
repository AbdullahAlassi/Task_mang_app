import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/app_colors.dart';
import '../../../services/task_service.dart';

class CreateTaskScreen extends StatefulWidget {
  final String projectId;
  final String? taskId; // If provided, we're editing an existing task

  const CreateTaskScreen({
    Key? key,
    required this.projectId,
    this.taskId,
  }) : super(key: key);

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _deadline;
  String _status = 'To Do';
  bool _isLoading = false;

  final TaskService _taskService = TaskService();

  final List<String> _statusOptions = [
    'To Do',
    'In Progress',
    'Done',
  ];

  @override
  void initState() {
    super.initState();

    // If editing an existing task, load its details
    if (widget.taskId != null) {
      _loadTaskDetails();
    }
  }

  Future<void> _loadTaskDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final task = await _taskService.getTaskDetails(widget.taskId!);

      setState(() {
        _titleController.text = task.title;
        _descriptionController.text = task.description;
        _deadline = task.deadline;
        _status = task.status;
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
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
            dialogBackgroundColor: AppColors.cardColor,
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

  Future<void> _saveTask() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final taskData = {
          'title': _titleController.text,
          'description': _descriptionController.text,
          'status': _status,
          'deadline': _deadline?.toIso8601String(),
          'board': widget.projectId, // In our API, board refers to the project
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
          Navigator.pop(context);
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
}

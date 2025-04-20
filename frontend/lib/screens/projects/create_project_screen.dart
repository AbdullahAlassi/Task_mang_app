import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/app_colors.dart';
import '../../../models/project_model.dart';
import '../../../services/project_service.dart';

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

  DateTime? _deadline;
  String _status = 'Not Started';
  bool _isLoading = false;

  final ProjectService _projectService = ProjectService();

  final List<String> _statusOptions = [
    'Not Started',
    'In Progress',
    'On Hold',
    'Completed',
    'Cancelled',
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
          'members': [], // Initialize with empty members array
          'progress': 0, // Initialize progress as number
          'totalTasks': 0, // Initialize totalTasks as number
          'completedTasks': 0, // Initialize completedTasks as number
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
          Navigator.pop(context);
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
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

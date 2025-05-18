import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../models/project_model.dart';
import '../../models/task_model.dart';
import '../../models/board_model.dart';
import '../../services/project_service.dart';
import '../../services/task_service.dart';
import '../../services/board_service.dart';
import '../tasks/create_task_screen.dart';
import '../tasks/task_detail_screen.dart';
import 'kanban_board_screen.dart';
import '../boards/create_board_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;

  const ProjectDetailScreen({
    Key? key,
    required this.projectId,
  }) : super(key: key);

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final ProjectService _projectService = ProjectService();
  final TaskService _taskService = TaskService();
  final BoardService _boardService = BoardService();
  bool _isLoading = true;
  Project? _project;
  List<Task> _tasks = [];
  bool _isManager = false;
  List<Board> _boards = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProjectDetails();
  }

  Future<void> _loadProjectDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final project = await _projectService.getProjectDetails(widget.projectId);
      final boards = await _boardService.getBoardsForProject(widget.projectId);
      final tasks = await _taskService.getTasksForProject(widget.projectId);
      final currentUserId = await _projectService.getCurrentUserId();

      if (!mounted) return;

      setState(() {
        _project = project;
        _boards = boards;
        _tasks = tasks;
        _isManager = project.managerId == currentUserId;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading project details: $e');
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load project details: ${e.toString()}'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _loadProjectDetails,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        title: _isLoading
            ? const Text('Project Details')
            : Text(_project?.title ?? 'Project Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.view_kanban),
            tooltip: 'Kanban Board View',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      KanbanBoardScreen(projectId: widget.projectId),
                ),
              ).then((_) => _loadProjectDetails());
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              if (!_isLoading && _project != null) {
                _showProjectOptions();
              }
            },
          ),
        ],
      ),
      body: _isLoading || _project == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProjectDetails,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Project Banner
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _project!.getBannerColor(),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Project Info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _project!.title,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _project!.description,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Progress Indicator
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: Stack(
                            children: [
                              CircularProgressIndicator(
                                value: _project!.progress / 100,
                                backgroundColor: AppColors.secondaryCardColor,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    _project!.getBannerColor()),
                                strokeWidth: 4,
                              ),
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      right: 23, bottom: 23),
                                  child: Text(
                                    '${_project!.progress}%',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Project Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard(
                          'Tasks',
                          '${_project!.completedTasks}/${_project!.totalTasks}',
                          Icons.task_alt,
                        ),
                        _buildStatCard(
                          'Status',
                          _project!.status,
                          Icons.info_outline,
                        ),
                        _buildStatCard(
                          'Deadline',
                          _project!.deadline != null
                              ? DateFormat('MMM d, yyyy')
                                  .format(_project!.deadline!)
                              : 'None',
                          Icons.calendar_today,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Boards Section
                    _boards.isEmpty
                        ? Center(
                            child: Column(
                              children: [
                                const Text(
                                  'No boards yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.secondaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final created = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CreateBoardScreen(
                                          projectId: widget.projectId,
                                        ),
                                      ),
                                    );
                                    if (created == true) {
                                      await _loadProjectDetails();
                                    }
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create Board'),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Boards',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textColor,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      final created = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CreateBoardScreen(
                                                  projectId: widget.projectId),
                                        ),
                                      );
                                      if (created == true) {
                                        await _loadProjectDetails();
                                      }
                                    },
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text('Add Board'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _boards.length,
                                itemBuilder: (context, index) {
                                  final board = _boards[index];
                                  return Card(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    color: AppColors.cardColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      title: Text(
                                        board.title,
                                        style: const TextStyle(
                                            color: AppColors.textColor),
                                      ),
                                      trailing: ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  CreateTaskScreen(
                                                projectId: _project!.id,
                                                boardId: board.id,
                                              ),
                                            ),
                                          ).then((_) => _loadProjectDetails());
                                        },
                                        icon: const Icon(Icons.add),
                                        label: const Text('Add Task'),
                                        style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8)),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),

                    const SizedBox(height: 24),

                    // Tasks Section
                    const Text(
                      'Tasks',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Tasks List
                    _tasks.isEmpty
                        ? Center(
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.task_outlined,
                                  size: 64,
                                  color: AppColors.secondaryTextColor,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No tasks found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: AppColors.secondaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CreateTaskScreen(
                                          projectId: _project!.id,
                                          boardId: _project!.boardIds.isNotEmpty
                                              ? _project!.boardIds.first
                                              : 'default',
                                        ),
                                      ),
                                    ).then((_) => _loadProjectDetails());
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create Task'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _tasks.length,
                            itemBuilder: (context, index) {
                              final task = _tasks[index];
                              return _buildTaskCard(task);
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryColor),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 4),
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
    );
  }

  Widget _buildTaskCard(Task task) {
    return Card(
      color: AppColors.cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (value) {
            // Update task status
            _updateTaskStatus(task.id, value ?? false);
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          activeColor: AppColors.primaryColor,
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textColor,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: task.deadline != null
            ? Text(
                'Due: ${DateFormat('MMM d').format(task.deadline!)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.secondaryTextColor,
                ),
              )
            : null,
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TaskDetailScreen(taskId: task.id),
              ),
            ).then((_) => _loadProjectDetails());
          },
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailScreen(taskId: task.id),
            ),
          ).then((_) => _loadProjectDetails());
        },
      ),
    );
  }

  Future<void> _updateTaskStatus(String taskId, bool isCompleted) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Update task status
      await _taskService.updateTaskStatus(taskId, isCompleted);

      // Update project status using the project ID, not the board ID
      await _projectService.updateProjectStatus(_project!.id);

      // Reload project details
      await _loadProjectDetails();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Task ${isCompleted ? 'completed' : 'marked as incomplete'}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error updating task status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update task status: $e'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _updateTaskStatus(taskId, isCompleted),
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

  void _showProjectOptions() {
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
                title: const Text('Edit Project',
                    style: TextStyle(color: AppColors.textColor)),
                onTap: () async {
                  Navigator.pop(context);
                  if (!_isManager) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Only the project manager can edit the project.')),
                    );
                    return;
                  }
                  // Navigate to edit project screen
                  Navigator.pushNamed(
                    context,
                    '/edit-project',
                    arguments: _project,
                  ).then((_) => _loadProjectDetails());
                },
              ),
              ListTile(
                leading: const Icon(Icons.view_kanban,
                    color: AppColors.primaryColor),
                title: const Text('Kanban Board View',
                    style: TextStyle(color: AppColors.textColor)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          KanbanBoardScreen(projectId: widget.projectId),
                    ),
                  ).then((_) => _loadProjectDetails());
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Project',
                    style: TextStyle(color: AppColors.textColor)),
                onTap: () async {
                  Navigator.pop(context);
                  if (!_isManager) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Only the project manager can delete the project.')),
                    );
                    return;
                  }
                  _confirmDeleteProject();
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: AppColors.primaryColor),
                title: const Text('Share Project',
                    style: TextStyle(color: AppColors.textColor)),
                onTap: () {
                  Navigator.pop(context);
                  // Implement share functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Share functionality coming soon')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteProject() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardColor,
          title: const Text('Delete Project',
              style: TextStyle(color: AppColors.textColor)),
          content: Text(
            'Are you sure you want to delete "${_project!.title}"? This action cannot be undone.',
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
                  final success =
                      await _projectService.deleteProject(_project!.id);
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Project deleted successfully')),
                    );
                    Navigator.pop(context); // Return to projects list
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete project: $e')),
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

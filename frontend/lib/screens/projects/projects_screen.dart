import 'package:flutter/material.dart';
import 'package:frontend/screens/profile/profile_screen.dart';
import 'package:intl/intl.dart';
import '../../../config/app_colors.dart';
import '../../../models/project_model.dart';
import '../../../models/project_status.dart';
import '../../../services/project_service.dart';
import '../../../widgets/bottom_navigation.dart';
import 'project_detail_screen.dart';
import 'create_project_screen.dart';
import 'kanban_board_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({Key? key}) : super(key: key);

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final ProjectService _projectService = ProjectService();
  bool _isLoading = true;
  List<Project> _projects = [];
  ProjectStatus _selectedStatus = ProjectStatus.todo;
  int _currentNavIndex = 1; // Project tab selected

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final projects =
          await _projectService.getProjectsByStatus(_selectedStatus);
      setState(() {
        _projects = projects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load projects: $e')),
        );
      }
    }
  }

  void _handleNavigation(int index) {
    if (index == _currentNavIndex) return;

    setState(() {
      _currentNavIndex = index;
    });

    // Handle navigation to different screens
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case 2:
        // Show create project dialog
        _showCreateProjectModal();
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/calendar');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/notifications');
        break;
    }
  }

  void _showCreateProjectModal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateProjectScreen(),
      ),
    ).then((_) => _loadProjects());
  }

  void _navigateToProjectDetail(Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectDetailScreen(projectId: project.id),
      ),
    ).then((_) => _loadProjects());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Menu and Title
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.grid_view,
                            color: AppColors.primaryColor),
                        onPressed: () {
                          // Open drawer or menu
                        },
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'My Projects',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor,
                        ),
                      ),
                    ],
                  ),

                  // Search and Profile
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.search,
                            color: AppColors.textColor),
                        onPressed: () {
                          // Show search
                        },
                      ),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.primaryColor, width: 2),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.person,
                              color: AppColors.primaryColor),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfileScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Status Filter Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _buildStatusTab(ProjectStatus.todo),
                  const SizedBox(width: 8),
                  _buildStatusTab(ProjectStatus.inProgress),
                  const SizedBox(width: 8),
                  _buildStatusTab(ProjectStatus.completed),
                  const SizedBox(width: 8),
                  _buildStatusTab(ProjectStatus.archived),
                ],
              ),
            ),

            // Projects List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _projects.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.folder_open,
                                size: 64,
                                color: AppColors.secondaryTextColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No ${_selectedStatus.name} projects found',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: AppColors.secondaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _showCreateProjectModal,
                                icon: const Icon(Icons.add),
                                label: const Text('Create Project'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadProjects,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: _projects.length,
                            itemBuilder: (context, index) {
                              final project = _projects[index];
                              return _buildProjectCard(project);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentNavIndex,
        onTap: _handleNavigation,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateProjectModal,
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusTab(ProjectStatus status) {
    final isSelected = _selectedStatus == status;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = status;
        });
        _loadProjects();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryColor
                : AppColors.primaryColor.withOpacity(0.5),
          ),
        ),
        child: Text(
          status.name,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.primaryColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildProjectCard(Project project) {
    final progress = project.progress / 100;
    final completedTasks = project.completedTasks;
    final totalTasks = project.totalTasks;
    final bannerColor = project.getBannerColor();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => KanbanBoardScreen(projectId: project.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project banner
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: bannerColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.more_horiz,
                            color: Colors.white, size: 20),
                        onPressed: () {
                          _showProjectOptions(project);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Project details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Project title and date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${project.completedTasks}/${project.totalTasks} tasks',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.secondaryTextColor,
                          ),
                        ),
                        Text(
                          project.deadline != null
                              ? 'Due: ${DateFormat('MMM d, yyyy').format(project.deadline!)}'
                              : 'No deadline',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Progress indicators
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Stack(
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          backgroundColor: AppColors.secondaryCardColor,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(bannerColor),
                          strokeWidth: 5,
                        ),
                        Center(
                          child: Text(
                            '${project.progress}%',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProjectOptions(Project project) {
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
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to edit project screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CreateProjectScreen(project: project),
                    ),
                  ).then((_) => _loadProjects());
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Project',
                    style: TextStyle(color: AppColors.textColor)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteProject(project);
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

  void _confirmDeleteProject(Project project) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardColor,
          title: const Text('Delete Project',
              style: TextStyle(color: AppColors.textColor)),
          content: Text(
            'Are you sure you want to delete "${project.title}"? This action cannot be undone.',
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
                      await _projectService.deleteProject(project.id);
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Project deleted successfully')),
                    );
                    _loadProjects();
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

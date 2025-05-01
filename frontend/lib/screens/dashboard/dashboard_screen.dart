import 'package:flutter/material.dart';
import 'package:frontend/screens/profile/profile_screen.dart';
import 'package:frontend/screens/projects/create_project_screen.dart';
import 'package:frontend/screens/projects/projects_screen.dart';
import 'package:frontend/screens/tasks/create_task_screen.dart';
import 'package:frontend/screens/tasks/task_detail_screen.dart';
import 'package:frontend/screens/tasks/ongoing_tasks_screen.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../models/project_model.dart';
import '../../models/task_model.dart';
import '../../services/project_service.dart';
import '../../services/task_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/project_card.dart';
import '../../widgets/search_bar.dart';
import '../../widgets/task_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  List<Project> _recentProjects = [];
  List<Task> _ongoingTasks = [];
  int _currentNavIndex = 0;

  final _projectService = ProjectService();
  final _taskService = TaskService();
  final _authService = AuthService();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // In a real app, these would be API calls
      final projects = await _projectService.getRecentProjects();
      final tasks = await _taskService.getOngoingTasks();

      setState(() {
        _recentProjects = projects;
        _ongoingTasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      // Handle error
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
    }
  }

  void _handleNavigation(int index) {
    setState(() {
      _currentNavIndex = index;
    });

    // Handle navigation to different screens
    switch (index) {
      case 0:
        // Already on dashboard
        break;
      case 1:
        // Navigate to projects screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProjectsScreen()),
        );
        break;
      case 2:
        // Show create project/task dialog
        _showCreateOptions();
        break;
      case 3:
        // Navigate to calendar screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Calendar screen coming soon')),
        );
        break;
      case 4:
        // Navigate to notifications screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notifications screen coming soon')),
        );
        break;
    }
  }

  void _showCreateOptions() {
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
                'Create New',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.task, color: AppColors.primaryColor),
                title: const Text('New Task',
                    style: TextStyle(color: AppColors.textColor)),
                onTap: () {
                  Navigator.pop(context);
                  // Show project selection dialog for the task
                  _showProjectSelectionDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showProjectSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardColor,
          title: const Text('Select Project',
              style: TextStyle(color: AppColors.textColor)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _recentProjects.length,
              itemBuilder: (context, index) {
                final project = _recentProjects[index];
                return ListTile(
                  title: Text(project.title,
                      style: const TextStyle(color: AppColors.textColor)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateTaskScreen(
                          projectId: project.id,
                          boardId: project.boardIds.isNotEmpty
                              ? project.boardIds.first
                              : 'default',
                        ),
                      ),
                    ).then((_) => _loadData());
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    try {
      print('Attempting to logout...');
      await _authService.logout();
      print('Logout successful');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e, stackTrace) {
      print('Logout Error:');
      print('Error message: $e');
      print('Stack trace:');
      print(stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to logout: $e'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Copy Error',
              onPressed: () {
                // Copy error details to clipboard
                final errorDetails = 'Error: $e\nStack trace:\n$stackTrace';
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Error details copied to clipboard')),
                );
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                color: AppColors.primaryColor,
                child: CustomScrollView(
                  slivers: [
                    // App Bar
                    SliverAppBar(
                      floating: true,
                      pinned: false,
                      snap: false,
                      backgroundColor: AppColors.backgroundColor,
                      elevation: 0,
                      leadingWidth: 60,
                      leading: IconButton(
                        icon: const Icon(Icons.grid_view,
                            color: AppColors.primaryColor),
                        onPressed: () {
                          // Open drawer or menu
                        },
                      ),
                      title: const Text(
                        'DASHBOARD',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor,
                        ),
                      ),
                      centerTitle: true,
                      actions: [
                        Container(
                          margin: const EdgeInsets.only(right: 16),
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

                    // Search Bar
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SearchBarWidget(
                          controller: _searchController,
                          onChanged: (value) {
                            // Handle search
                          },
                        ),
                      ),
                    ),

                    // Recent Projects Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recent Project',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textColor,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const ProjectsScreen()),
                                );
                              },
                              child: const Text(
                                'See All',
                                style: TextStyle(
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Recent Projects List
                    SliverToBoxAdapter(
                      child: _recentProjects.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'No recent projects',
                                  style: TextStyle(
                                      color: AppColors.secondaryTextColor),
                                ),
                              ),
                            )
                          : SizedBox(
                              height: 250,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                itemCount: _recentProjects.length,
                                itemBuilder: (context, index) {
                                  return ProjectCard(
                                      project: _recentProjects[index]);
                                },
                              ),
                            ),
                    ),

                    // Ongoing Tasks Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Ongoing Tasks',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textColor,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const OngoingTasksScreen(),
                                  ),
                                ).then((_) => _loadData());
                              },
                              child: const Text(
                                'See All',
                                style: TextStyle(
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Ongoing Tasks Grid
                    SliverPadding(
                      padding: const EdgeInsets.all(16.0),
                      sliver: _ongoingTasks.isEmpty
                          ? const SliverToBoxAdapter(
                              child: Center(
                                child: Text(
                                  'No ongoing tasks',
                                  style: TextStyle(
                                      color: AppColors.secondaryTextColor),
                                ),
                              ),
                            )
                          : SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 1.2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  return TaskCard(
                                    task: _ongoingTasks[index],
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              TaskDetailScreen(
                                            taskId: _ongoingTasks[index].id,
                                          ),
                                        ),
                                      ).then((_) => _loadData());
                                    },
                                  );
                                },
                                childCount: _ongoingTasks.length > 6
                                    ? 6
                                    : _ongoingTasks.length,
                              ),
                            ),
                    ),

                    // Bottom padding for navigation bar
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 80),
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentNavIndex,
        onTap: _handleNavigation,
      ),
    );
  }
}

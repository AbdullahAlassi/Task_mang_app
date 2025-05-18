import 'package:flutter/material.dart';
import 'package:frontend/screens/profile/profile_screen.dart';
import 'package:frontend/screens/projects/create_project_screen.dart';
import 'package:frontend/screens/projects/projects_screen.dart';
import 'package:frontend/screens/tasks/create_task_screen.dart';
import 'package:frontend/screens/tasks/task_detail_screen.dart';
import 'package:frontend/screens/tasks/ongoing_tasks_screen.dart';
import 'package:frontend/screens/calendar/calendar_screen.dart';
import 'package:frontend/screens/notifications/notifications_screen.dart';
import 'package:frontend/screens/teams/team_hierarchy_screen.dart';
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
import '../../screens/projects/kanban_board_screen.dart';

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
      print('=== Dashboard Data Loading Debug ===');
      print('1. Starting to fetch recent projects...');

      // Fetch recent projects
      final projects = await _projectService.getRecentProjects();
      print('2. Raw projects data received:');
      print(projects);

      print('3. Processing projects data...');
      for (var project in projects) {
        print('Project ID: ${project.id}');
        print('Project Title: ${project.title}');
        print('Project Progress: ${project.progress}');
        print('Project Total Tasks: ${project.totalTasks}');
        print('Project Completed Tasks: ${project.completedTasks}');
        print('Project Status: ${project.status}');
        print('---');
      }

      print('4. Starting to fetch ongoing tasks...');
      final tasks = await _taskService.getOngoingTasks();
      print('5. Tasks data received:');
      print(tasks);

      setState(() {
        _recentProjects = projects;
        _ongoingTasks = tasks;
        _isLoading = false;
      });

      print('6. Data loading completed successfully');
    } catch (e, stackTrace) {
      print('=== Error in Dashboard Data Loading ===');
      print('Error message: $e');
      print('Stack trace:');
      print(stackTrace);

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
        // Navigate to calendar screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CalendarScreen()),
        );
        break;
      case 3:
        // Navigate to notifications screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
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
                        icon: const Icon(Icons.workspace_premium_outlined,
                            color: AppColors.primaryColor),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const TeamHierarchyScreen()),
                          );
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
                                  final project = _recentProjects[index];
                                  return _buildProjectCard(project);
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
        ).then((_) => _loadData());
      },
      child: Container(
        width: 300,
        margin: const EdgeInsets.only(bottom: 16, right: 16),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project banner
            Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                color: bannerColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.more_horiz,
                            color: Colors.white, size: 18),
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
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Project title and date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${project.completedTasks}/${project.totalTasks} tasks',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.secondaryTextColor,
                              ),
                            ),
                            Text(
                              project.deadline != null
                                  ? 'Due: ${DateFormat('MMM d, yyyy').format(project.deadline!)}'
                                  : 'No deadline',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Progress indicators
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: progress,
                              backgroundColor: AppColors.secondaryCardColor,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(bannerColor),
                              strokeWidth: 4,
                            ),
                            Center(
                              child: Text(
                                '${(progress * 100).round()}%',
                                style: const TextStyle(
                                  fontSize: 9,
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
                  const SizedBox(height: 8),
                  // Project status
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(project.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      project.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(project.status),
                      ),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'To Do':
        return Colors.blue;
      case 'In Progress':
        return Colors.orange;
      case 'Completed':
        return Colors.green;
      case 'Archived':
        return Colors.grey;
      default:
        return AppColors.primaryColor;
    }
  }

  void _showProjectOptions(Project project) {
    // Implement the logic to show project options
  }
}

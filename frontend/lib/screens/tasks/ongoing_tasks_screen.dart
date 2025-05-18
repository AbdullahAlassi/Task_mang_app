import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../models/task_model.dart';
import '../../services/task_service.dart';
import '../../widgets/task_card.dart';
import 'task_detail_screen.dart';

class OngoingTasksScreen extends StatefulWidget {
  const OngoingTasksScreen({Key? key}) : super(key: key);

  @override
  State<OngoingTasksScreen> createState() => _OngoingTasksScreenState();
}

class _OngoingTasksScreenState extends State<OngoingTasksScreen>
    with SingleTickerProviderStateMixin {
  final _taskService = TaskService();
  bool _isLoading = true;
  List<Task> _tasks = [];
  String _sortBy = 'deadline'; // 'deadline' or 'status'
  bool _showOverdueTasks = false;
  late TabController _tabController;
  String _selectedTab = 'personal'; // 'personal' or 'team'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedTab = _tabController.index == 0 ? 'personal' : 'team';
        });
        _loadTasks();
      }
    });
    _loadTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tasks = _selectedTab == 'personal'
          ? await _taskService.getPersonalTasks()
          : await _taskService.getTeamTasks();

      setState(() {
        _tasks = tasks;
        _sortTasks();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load tasks: $e')),
        );
      }
    }
  }

  void _sortTasks() {
    switch (_sortBy) {
      case 'deadline':
        _tasks.sort((a, b) {
          if (a.deadline == null) return 1;
          if (b.deadline == null) return -1;
          return a.deadline!.compareTo(b.deadline!);
        });
        break;
      case 'status':
        _tasks.sort((a, b) => a.status.compareTo(b.status));
        break;
    }

    if (_showOverdueTasks) {
      _tasks.sort((a, b) {
        if (a.isOverdue() && !b.isOverdue()) return -1;
        if (!a.isOverdue() && b.isOverdue()) return 1;
        return 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        title: const Text('Ongoing Tasks'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: AppColors.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textColor,
              tabs: const [
                Tab(text: 'My Tasks'),
                Tab(text: 'Team Tasks'),
              ],
            ),
          ),
        ),
        actions: [
          // Sort button
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _sortTasks();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'deadline',
                child: Text('Sort by Deadline'),
              ),
              const PopupMenuItem(
                value: 'status',
                child: Text('Sort by Status'),
              ),
            ],
          ),
          // Filter button
          IconButton(
            icon: Icon(
              Icons.warning_amber_rounded,
              color: _showOverdueTasks ? Colors.orange : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _showOverdueTasks = !_showOverdueTasks;
                _sortTasks();
              });
            },
            tooltip: 'Show Overdue Tasks First',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTasks,
              child: _tasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.task_alt,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'No ${_selectedTab == 'personal' ? 'personal' : 'team'} tasks',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _loadTasks,
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        final task = _tasks[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TaskCard(
                            task: task,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TaskDetailScreen(taskId: task.id),
                                ),
                              ).then((_) => _loadTasks());
                            },
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

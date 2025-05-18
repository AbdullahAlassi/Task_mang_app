import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../models/project_model.dart';
import '../../models/task_model.dart';
import '../../services/project_service.dart';
import '../../services/task_service.dart';
import '../../widgets/bottom_navigation.dart';
import '../profile/profile_screen.dart';
import '../tasks/task_detail_screen.dart';
import '../projects/project_detail_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../projects/projects_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final ProjectService _projectService = ProjectService();
  final TaskService _taskService = TaskService();
  bool _isLoading = true;
  List<Project> _projects = [];
  List<Task> _tasks = [];
  CalendarView _currentView = CalendarView.month;
  int _currentNavIndex = 2; // Calendar tab selected
  DateTime _selectedDate = DateTime.now(); // Add selected date

  @override
  void initState() {
    super.initState();
    print('📅 CalendarScreen: Initializing...');
    print('📅 Current Navigation Index: $_currentNavIndex');
    _loadData();
  }

  Future<void> _loadData() async {
    print('📅 CalendarScreen: Loading data...');
    setState(() {
      _isLoading = true;
    });

    try {
      print('📅 Fetching projects...');
      final projects = await _projectService.getAllProjects();
      print('📅 Fetched ${projects.length} projects');

      print('📅 Fetching tasks...');
      List<Task> tasks = [];
      try {
        tasks = await _taskService.getAllTasks();
        print('📅 Fetched ${tasks.length} tasks');

        // Filter out tasks without deadlines
        tasks = tasks.where((task) => task.deadline != null).toList();
        print('📅 Found ${tasks.length} tasks with deadlines');
      } catch (e) {
        print('⚠️ Warning: Failed to load tasks: $e');
        // Continue with empty tasks list
      }

      setState(() {
        _projects = projects;
        _tasks = tasks;
        _isLoading = false;
      });
      print('📅 Data loaded successfully');
    } catch (e, stackTrace) {
      print('❌ Error loading data:');
      print('Error message: $e');
      print('Stack trace:');
      print(stackTrace);
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: $e'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadData,
            ),
          ),
        );
      }
    }
  }

  List<Appointment> _getCalendarAppointments() {
    print('📅 Generating calendar appointments...');
    final appointments = <Appointment>[];

    // Add project deadlines
    for (final project in _projects) {
      if (project.deadline != null) {
        print(
            '📅 Adding project deadline: ${project.title} - ${project.deadline}');
        appointments.add(
          Appointment(
            startTime: project.deadline!,
            endTime: project.deadline!.add(const Duration(hours: 1)),
            subject: '${project.title} (Project)',
            color: Color(int.parse(project.color.replaceAll('#', '0xFF'))),
            id: 'project_${project.id}',
            isAllDay: false, // Ensure it's not an all-day event
          ),
        );
      }
    }

    // Add task deadlines
    for (final task in _tasks) {
      if (task.deadline != null) {
        print('📅 Adding task deadline: ${task.title} - ${task.deadline}');
        // Find the project for this task
        final project = _projects.firstWhere(
          (p) => p.id == task.projectId,
          orElse: () => _projects.first,
        );

        // Use project color with 0.7 opacity for tasks
        final projectColor =
            Color(int.parse(project.color.replaceAll('#', '0xFF')));
        final taskColor = Color.fromRGBO(
          projectColor.red,
          projectColor.green,
          projectColor.blue,
          0.7,
        );

        appointments.add(
          Appointment(
            startTime: task.deadline!,
            endTime: task.deadline!.add(const Duration(hours: 1)),
            subject: task.title,
            color: taskColor,
            id: 'task_${task.id}',
            isAllDay: false, // Ensure it's not an all-day event
          ),
        );
      }
    }

    print('📅 Generated ${appointments.length} total appointments');
    return appointments;
  }

  void _handleNavigation(int index) {
    print('📅 Navigation requested to index: $index');
    print('📅 Current navigation index: $_currentNavIndex');

    if (index == _currentNavIndex) {
      print('📅 Already on this screen, ignoring navigation');
      return;
    }

    setState(() {
      _currentNavIndex = index;
    });

    switch (index) {
      case 0:
        print('📅 Navigating to Dashboard');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
        break;
      case 1:
        print('📅 Navigating to Projects');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProjectsScreen()),
        );
        break;
      case 2:
        print('📅 Already on Calendar');
        break;
      case 3:
        print('📅 Notifications screen requested');
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
              itemCount: _projects.length,
              itemBuilder: (context, index) {
                final project = _projects[index];
                return ListTile(
                  title: Text(project.title,
                      style: const TextStyle(color: AppColors.textColor)),
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to create task screen
                    Navigator.pushNamed(
                      context,
                      '/create-task',
                      arguments: {
                        'projectId': project.id,
                        'boardId': project.boardIds.isNotEmpty
                            ? project.boardIds.first
                            : 'default',
                      },
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

  void _handleCalendarTap(CalendarTapDetails details) {
    print('📅 Calendar tapped: ${details.targetElement}');

    if (details.targetElement == CalendarElement.appointment) {
      final String appointmentId = details.appointments![0].id as String;
      final String type = appointmentId.split('_')[0];
      final String id = appointmentId.split('_')[1];

      print('📅 Tapped appointment:');
      print('Type: $type');
      print('ID: $id');

      if (type == 'task') {
        print('📅 Navigating to task details');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailScreen(taskId: id),
          ),
        ).then((_) {
          print('📅 Returning from task details, refreshing data');
          _loadData();
        });
      } else if (type == 'project') {
        print('📅 Navigating to project details');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectDetailScreen(projectId: id),
          ),
        ).then((_) {
          print('📅 Returning from project details, refreshing data');
          _loadData();
        });
      }
    }
  }

  void _handleViewChanged(ViewChangedDetails details) {
    print('📅 View changed to: ${details.visibleDates}');
    print('📅 Current view type: $_currentView');
    _selectedDate = details.visibleDates.first;
  }

  Widget _buildViewButton(String label, CalendarView view) {
    final isSelected = _currentView == view;
    print('📅 Building view button: $label');
    print('📅 Is selected: $isSelected');
    print('📅 Current view: $_currentView');
    print('📅 Target view: $view');

    return TextButton(
      onPressed: () {
        print('📅 View button pressed: $label');
        print('📅 Current view before change: $_currentView');
        print('📅 Target view: $view');

        if (_currentView != view) {
          print('📅 View is different, updating state...');
          setState(() {
            _currentView = view;
          });
          print('📅 View updated to: $_currentView');
        } else {
          print('📅 View is already set to: $view');
        }
      },
      style: TextButton.styleFrom(
        backgroundColor:
            isSelected ? AppColors.primaryColor : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('📅 Building CalendarScreen');
    print('📅 Current view: $_currentView');
    print('📅 Loading state: $_isLoading');
    print('📅 Projects count: ${_projects.length}');
    print('📅 Tasks count: ${_tasks.length}');

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
                  // Left side - Menu button
                  IconButton(
                    icon: const Icon(Icons.grid_view,
                        color: AppColors.primaryColor),
                    onPressed: () {
                      // Open drawer or menu
                    },
                  ),

                  // Center - Title
                  const Text(
                    'Calendar',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColor,
                    ),
                  ),

                  // Right side - Profile button
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppColors.primaryColor, width: 2),
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
            ),

            // View Selection Buttons
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: AppColors.cardColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildViewButton('Day', CalendarView.day),
                  _buildViewButton('Week', CalendarView.week),
                  _buildViewButton('Month', CalendarView.month),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Calendar
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SfCalendar(
                      key: ValueKey(_currentView),
                      view: _currentView,
                      dataSource:
                          _CalendarDataSource(_getCalendarAppointments()),
                      onTap: _handleCalendarTap,
                      onViewChanged: _handleViewChanged,
                      monthViewSettings: const MonthViewSettings(
                        appointmentDisplayMode:
                            MonthAppointmentDisplayMode.appointment,
                        showAgenda: true,
                        navigationDirection: MonthNavigationDirection.vertical,
                        appointmentDisplayCount: 3,
                      ),
                      timeSlotViewSettings: const TimeSlotViewSettings(
                        startHour: 8,
                        endHour: 20,
                        timeInterval: Duration(minutes: 30),
                        timeIntervalHeight: 50,
                        dayFormat: 'EEE',
                        dateFormat: 'd',
                        timeFormat: 'HH:mm',
                        timeRulerSize: 60,
                      ),
                      allowDragAndDrop: true,
                      allowAppointmentResize: true,
                      initialSelectedDate: _selectedDate,
                      initialDisplayDate: _selectedDate,
                      headerStyle: const CalendarHeaderStyle(
                        textStyle: TextStyle(
                          color: AppColors.textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      viewHeaderStyle: const ViewHeaderStyle(
                        backgroundColor: AppColors.cardColor,
                        dayTextStyle: TextStyle(color: AppColors.textColor),
                        dateTextStyle: TextStyle(color: AppColors.textColor),
                      ),
                      backgroundColor: AppColors.backgroundColor,
                      todayHighlightColor: AppColors.primaryColor,
                      selectionDecoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        border: Border.all(color: AppColors.primaryColor),
                      ),
                      showCurrentTimeIndicator: true,
                      showWeekNumber: true,
                      showNavigationArrow: true,
                      showDatePickerButton: true,
                      onDragEnd: (AppointmentDragEndDetails details) async {
                        final appointment = details.appointment! as Appointment;
                        final String appointmentId = appointment.id as String;
                        final String type = appointmentId.split('_')[0];
                        final String id = appointmentId.split('_')[1];

                        try {
                          if (type == 'task') {
                            print(
                                '📅 Updating task deadline: $id to ${appointment.startTime}');
                            await _taskService.updateTaskDeadline(
                                id, appointment.startTime);
                          } else if (type == 'project') {
                            print(
                                '📅 Updating project deadline: $id to ${appointment.startTime}');
                            await _projectService.updateProject(id, {
                              'deadline':
                                  appointment.startTime.toIso8601String()
                            });
                          }
                          print('📅 Deadline updated successfully');
                          _loadData(); // Refresh data
                        } catch (e) {
                          print('❌ Error updating deadline: $e');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to update deadline: $e'),
                                duration: const Duration(seconds: 5),
                                action: SnackBarAction(
                                  label: 'Retry',
                                  onPressed: () => _loadData(),
                                ),
                              ),
                            );
                          }
                        }
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentNavIndex,
        onTap: _handleNavigation,
      ),
    );
  }
}

class _CalendarDataSource extends CalendarDataSource {
  _CalendarDataSource(List<Appointment> source) {
    appointments = source;
  }
}

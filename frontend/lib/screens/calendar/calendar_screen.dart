import 'package:flutter/material.dart';
import 'package:frontend/screens/notifications/notifications_screen.dart';
import 'package:frontend/screens/teams/team_hierarchy_screen.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../services/calendar_service.dart';
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
  final CalendarService _calendarService = CalendarService();
  bool _isLoading = true;
  List<CalendarEvent> _events = [];
  CalendarView _currentView = CalendarView.month;
  String _currentMode = 'month'; // 'day', 'week', 'month'
  int _currentNavIndex = 2; // Calendar tab selected
  DateTime _selectedDate = DateTime.now();
  DateTime _visibleStartDate = DateTime.now();
  DateTime _visibleEndDate = DateTime.now();
  bool _isViewChanging = false;
  final GlobalKey<State<StatefulWidget>> _calendarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    print('📅 CalendarScreen: Initializing...');
    _loadEvents();
  }

  void _updateVisibleDatesForView() {
    // Helper to update _visibleStartDate and _visibleEndDate based on _currentView and _selectedDate
    switch (_currentView) {
      case CalendarView.day:
        _visibleStartDate = DateTime(
            _selectedDate.year, _selectedDate.month, _selectedDate.day);
        _visibleEndDate = DateTime(_selectedDate.year, _selectedDate.month,
            _selectedDate.day, 23, 59, 59);
        break;
      case CalendarView.week:
        _visibleStartDate =
            _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        _visibleEndDate = _visibleStartDate
            .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        break;
      case CalendarView.month:
      default:
        _visibleStartDate =
            DateTime(_selectedDate.year, _selectedDate.month, 1);
        _visibleEndDate = DateTime(
            _selectedDate.year, _selectedDate.month + 1, 0, 23, 59, 59);
        break;
    }
    print('🔄 _updateVisibleDatesForView:');
    print('  _currentView: $_currentView');
    print('  _selectedDate: $_selectedDate');
    print('  _visibleStartDate: $_visibleStartDate');
    print('  _visibleEndDate: $_visibleEndDate');
  }

  Future<void> _loadEvents() async {
    if (_isViewChanging) return;
    print('📅 CalendarScreen: Loading events...');
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    // Always recalculate date range based on _currentView and _selectedDate
    _updateVisibleDatesForView();
    final startDate = _visibleStartDate;
    final endDate = _visibleEndDate;
    print('📅 Fetching events for date range:');
    print('Start: ${startDate.toIso8601String()}');
    print('End: ${endDate.toIso8601String()}');
    try {
      final events = await _calendarService.getEvents(startDate, endDate);
      print('📅 Fetched ${events.length} events');
      for (final e in events) {
        print('  - ${e.title} (${e.start} to ${e.end})');
      }
      if (!mounted) return;
      setState(() {
        _events = events;
        _isLoading = false;
        _isViewChanging = false;
      });
      print('📅 Events loaded successfully');
    } catch (e, stackTrace) {
      print('❌ Error loading events:');
      print('Error message: $e');
      print('Stack trace:');
      print(stackTrace);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isViewChanging = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load events: $e'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadEvents,
            ),
          ),
        );
      }
    }
  }

  List<Appointment> _getCalendarAppointments() {
    print('📅 Generating calendar appointments...');
    return _events.map((event) {
      final color = Color(int.parse(event.color.replaceAll('#', '0xFF')));
      return Appointment(
        startTime: event.start,
        endTime: event.end,
        subject: event.title,
        color: event.type == 'task' ? color.withOpacity(0.7) : color,
        id: event.id,
        isAllDay: false,
        notes: event.projectTitle,
      );
    }).toList();
  }

  void _handleNavigation(int index) {
    print('📅 Navigation requested to index: $index');
    if (index == _currentNavIndex) return;

    setState(() {
      _currentNavIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProjectsScreen()),
        );
        break;
      case 2:
        // Already on Calendar
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
        );
        break;
    }
  }

  void _handleCalendarTap(CalendarTapDetails details) {
    if (details.targetElement == CalendarElement.appointment) {
      final appointment = details.appointments![0];
      final String appointmentId = appointment.id as String;
      final String type = appointmentId.split('_')[0];
      final String id = appointmentId.split('_')[1];

      print('📅 Tapped appointment:');
      print('Type: $type');
      print('ID: $id');

      if (type == 'task') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailScreen(taskId: id),
          ),
        ).then((_) => _loadEvents());
      } else if (type == 'project') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectDetailScreen(projectId: id),
          ),
        ).then((_) => _loadEvents());
      }
    } else if (details.targetElement == CalendarElement.calendarCell &&
        details.date != null) {
      setState(() {
        _selectedDate = details.date!;
      });
    }
  }

  void _handleViewChanged(ViewChangedDetails details) {
    print('📅 View changed:');
    print('Visible dates: ${details.visibleDates}');
    print('Current view: $_currentView');
    if (_isViewChanging) return;
    _isViewChanging = true;
    // Update _selectedDate, _visibleStartDate, _visibleEndDate for all views
    if (details.visibleDates.isNotEmpty) {
      _selectedDate = details.visibleDates.first;
      _updateVisibleDatesForView();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadEvents();
      }
    });
  }

  Widget _buildViewButton(String label, String mode) {
    final isSelected = _currentMode == mode;
    return TextButton(
      onPressed: () {
        if (_currentMode != mode) {
          setState(() {
            _currentMode = mode;
            _currentView = mode == 'day'
                ? CalendarView.day
                : mode == 'week'
                    ? CalendarView.week
                    : CalendarView.month;
            _selectedDate = DateTime.now();
            _updateVisibleDatesForView();
            _calendarKey.currentState?.setState(() {});
          });
          _loadEvents();
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
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
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
                    const Text(
                      'Calendar',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor,
                      ),
                    ),
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
                    _buildViewButton('Day', 'day'),
                    _buildViewButton('Week', 'week'),
                    _buildViewButton('Month', 'month'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Calendar
              SizedBox(
                height: 600, // or MediaQuery.of(context).size.height * 0.7
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
                          navigationDirection:
                              MonthNavigationDirection.vertical,
                          appointmentDisplayCount: 3,
                          agendaViewHeight: 200,
                        ),
                        timeSlotViewSettings: TimeSlotViewSettings(
                          timeIntervalHeight: 60,
                          startHour: 0,
                          endHour: 24,
                          timeInterval: const Duration(hours: 1),
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
                        appointmentBuilder: (context, details) {
                          final appointment = details.appointments.first;
                          final String appointmentId = appointment.id as String;
                          final String type = appointmentId.split('_')[0];
                          final String projectTitle =
                              appointment.notes as String? ?? '';

                          return Container(
                            decoration: BoxDecoration(
                              color: appointment.color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    appointment.subject,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (type == 'task' && projectTitle.isNotEmpty)
                                    Text(
                                      projectTitle,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
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

class _CalendarDataSource extends CalendarDataSource {
  _CalendarDataSource(List<Appointment> source) {
    appointments = source;
  }
}

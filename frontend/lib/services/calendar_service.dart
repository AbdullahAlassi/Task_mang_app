import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import 'auth_service.dart';

class CalendarEvent {
  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final String color;
  final String type; // 'task' or 'project'
  final String status;
  final String? projectTitle; // Only for tasks

  CalendarEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.color,
    required this.type,
    required this.status,
    this.projectTitle,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'],
      title: json['title'],
      start: DateTime.parse(json['start']).toLocal(),
      end: DateTime.parse(json['end']).toLocal(),
      color: json['color'] ?? '#6B4EFF',
      type: json['type'],
      status: json['status'],
      projectTitle: json['projectTitle'],
    );
  }
}

class CalendarService {
  final AuthService _authService = AuthService();

  // Get calendar events for a date range
  Future<List<CalendarEvent>> getEvents(DateTime start, DateTime end) async {
    try {
      print('=== Fetching Calendar Events Debug ===');
      print(
          'Date Range: ${start.toIso8601String()} to ${end.toIso8601String()}');

      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/calendar/events')
            .replace(queryParameters: {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        }),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final events =
            data.map((json) => CalendarEvent.fromJson(json)).toList();
        print('Successfully fetched ${events.length} events');
        return events;
      } else {
        throw Exception('Failed to load calendar events: ${response.body}');
      }
    } catch (e) {
      print('Error fetching calendar events: $e');
      rethrow;
    }
  }

  // Get events for today
  Future<List<CalendarEvent>> getTodayEvents() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return getEvents(startOfDay, endOfDay);
  }

  // Get events for this week
  Future<List<CalendarEvent>> getWeekEvents() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek
        .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    return getEvents(startOfWeek, endOfWeek);
  }

  // Get events for this month
  Future<List<CalendarEvent>> getMonthEvents() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    return getEvents(startOfMonth, endOfMonth);
  }
}

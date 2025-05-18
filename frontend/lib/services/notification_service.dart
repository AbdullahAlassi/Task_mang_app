import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';
import 'auth_service.dart';

class NotificationService {
  static const String baseUrl = 'http://localhost:3003/api';
  final AuthService _authService = AuthService();

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final token = await _authService.getToken();
      print('🔐 Token: $token');

      if (token == null) {
        print('❌ Token is null');
        throw Exception('Authentication token is missing');
      }

      final url = '$baseUrl/notifications';
      print('🌍 Requesting: $url');
      print(
          '📤 Headers: {Authorization: Bearer $token, Content-Type: application/json}');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📥 Status: ${response.statusCode}');
      print('📦 Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => NotificationModel.fromJson(json)).toList();
      } else {
        print('❌ Failed: ${response.statusCode}');
        print('Body: ${response.body}');
        throw Exception('Failed to load notifications: ${response.body}');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      throw Exception('Failed to load notifications: $e');
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      final token = await _authService.getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark notification as read');
      }
    } catch (e) {
      print('Error marking notification as read: $e');
      throw Exception('Failed to mark notification as read');
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      final token = await _authService.getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/notifications/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete notification');
      }
    } catch (e) {
      print('Error deleting notification: $e');
      throw Exception('Failed to delete notification');
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final notifications = await getNotifications();
      return notifications.where((n) => !n.isRead).length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Authentication token is missing');
      }

      final url = '$baseUrl/notifications/mark-all-read';
      print('🌍 Requesting: $url');

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📥 Status: ${response.statusCode}');
      print('📦 Body: ${response.body}');

      if (response.statusCode != 200) {
        print('❌ Failed: ${response.statusCode}');
        print('Body: ${response.body}');
        throw Exception(
            'Failed to mark all notifications as read: ${response.body}');
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }
}

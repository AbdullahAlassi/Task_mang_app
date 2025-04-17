import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task_model.dart';

class TaskService {
  static const String baseUrl = 'http://localhost:3000/api';

  Future<List<Task>> getOngoingTasks() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tasks/ongoing'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Task.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load tasks');
      }
    } catch (e) {
      throw Exception('Failed to load tasks: $e');
    }
  }
}

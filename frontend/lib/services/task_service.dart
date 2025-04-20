import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/task_model.dart';

class TaskService {
  static const String baseUrl = 'http://localhost:3000/api';

  // Get token from shared preferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Get all tasks
  Future<List<Task>> getAllTasks() async {
    try {
      final token = await _getToken();

      if (token == null) {
        // For development/demo, return mock data if no token
        return _getMockTasks();
      }

      final response = await http.get(
        Uri.parse('$baseUrl/tasks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Task.fromJson(json)).toList();
      } else {
        // For demo purposes, return mock data if API call fails
        return _getMockTasks();
      }
    } catch (e) {
      // Return mock data for development/demo
      return _getMockTasks();
    }
  }

  // Get tasks for a specific project
  Future<List<Task>> getTasksForProject(String projectId) async {
    try {
      final token = await _getToken();

      if (token == null) {
        // For development/demo, return mock data if no token
        return _getMockTasks();
      }

      final response = await http.get(
        Uri.parse('$baseUrl/projects/$projectId/tasks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Task.fromJson(json)).toList();
      } else {
        // For demo purposes, return mock data if API call fails
        return _getMockTasks();
      }
    } catch (e) {
      // Return mock data for development/demo
      return _getMockTasks();
    }
  }

  // Get ongoing tasks for dashboard
  Future<List<Task>> getOngoingTasks() async {
    try {
      final token = await _getToken();

      if (token == null) {
        // For development/demo, return mock data if no token
        return _getMockTasks()
            .where((task) => task.status == 'In Progress')
            .toList();
      }

      final response = await http.get(
        Uri.parse('$baseUrl/tasks?status=In Progress'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Task.fromJson(json)).toList();
      } else {
        // Filter mock tasks by status
        return _getMockTasks()
            .where((task) => task.status == 'In Progress')
            .toList();
      }
    } catch (e) {
      // Filter mock tasks by status
      return _getMockTasks()
          .where((task) => task.status == 'In Progress')
          .toList();
    }
  }

  // Get task details
  Future<Task> getTaskDetails(String taskId) async {
    try {
      final token = await _getToken();

      if (token == null) {
        // For development/demo, return mock task if no token
        return _getMockTasks().firstWhere(
          (task) => task.id == taskId,
          orElse: () => _getMockTasks().first,
        );
      }

      final response = await http.get(
        Uri.parse('$baseUrl/tasks/$taskId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Task.fromJson(data);
      } else {
        // Return mock task for development/demo
        return _getMockTasks().firstWhere(
          (task) => task.id == taskId,
          orElse: () => _getMockTasks().first,
        );
      }
    } catch (e) {
      // Return mock task for development/demo
      return _getMockTasks().firstWhere(
        (task) => task.id == taskId,
        orElse: () => _getMockTasks().first,
      );
    }
  }

  // Create a new task
  Future<Task> createTask(Map<String, dynamic> taskData) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/tasks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(taskData),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Task.fromJson(data);
      } else {
        throw Exception('Failed to create task');
      }
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  // Update a task
  Future<Task> updateTask(String taskId, Map<String, dynamic> taskData) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/tasks/$taskId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(taskData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Task.fromJson(data);
      } else {
        throw Exception('Failed to update task');
      }
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  // Update task status
  Future<Task> updateTaskStatus(String taskId, bool isCompleted) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final status = isCompleted ? 'Done' : 'To Do';

      final response = await http.put(
        Uri.parse('$baseUrl/tasks/$taskId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'status': status,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Task.fromJson(data);
      } else {
        throw Exception('Failed to update task status');
      }
    } catch (e) {
      throw Exception('Failed to update task status: $e');
    }
  }

  // Delete a task
  Future<bool> deleteTask(String taskId) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/tasks/$taskId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  // Move task to a different board
  Future<Task> moveTaskToBoard(String taskId, String boardId) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/tasks/$taskId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'board': boardId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Task.fromJson(data);
      } else {
        throw Exception('Failed to move task');
      }
    } catch (e) {
      throw Exception('Failed to move task: $e');
    }
  }

  // Mock data for development/demo
  List<Task> _getMockTasks() {
    return [
      Task(
        id: '1',
        title: 'Design UI mockups',
        description: 'Create UI mockups for the new feature',
        status: 'In Progress',
        deadline: DateTime.now().add(const Duration(days: 2)),
        isCompleted: false,
        boardId: '1',
        assignedTo: ['user1'],
        color: const Color(0xFFB5B35C), // Yellowish-green color from the design
      ),
      Task(
        id: '2',
        title: 'Implement API endpoints',
        description: 'Implement the API endpoints for the new feature',
        status: 'To Do',
        deadline: DateTime.now().add(const Duration(days: 3)),
        isCompleted: false,
        boardId: '1',
        assignedTo: ['user1'],
      ),
      Task(
        id: '3',
        title: 'Write unit tests',
        description: 'Write unit tests for the new feature',
        status: 'In Progress',
        deadline: DateTime.now().add(const Duration(days: 1)),
        isCompleted: false,
        boardId: '2',
        assignedTo: ['user1', 'user2'],
      ),
      Task(
        id: '4',
        title: 'Review pull request',
        description: 'Review the pull request for the new feature',
        status: 'To Do',
        deadline: DateTime.now().add(const Duration(days: 4)),
        isCompleted: false,
        boardId: '2',
        assignedTo: ['user2'],
      ),
    ];
  }
}

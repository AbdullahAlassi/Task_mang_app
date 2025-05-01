import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';

class TaskService {
  // Update the baseUrl to match your actual backend URL
  static const String baseUrl =
      'http://10.0.2.2:3000/api'; // For Android emulator
  // static const String baseUrl = 'http://localhost:3000/api'; // For iOS simulator
  // static const String baseUrl = 'http://YOUR_ACTUAL_IP:3000/api'; // For physical device

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
        throw Exception('Authentication token not found');
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
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load tasks: $e');
    }
  }

  // Get tasks for a specific project
  Future<List<Task>> getTasksForProject(String projectId) async {
    try {
      print('=== Fetching Tasks for Project Debug ===');
      print('Project ID: $projectId');

      final token = await _getToken();
      print('Token: ${token != null ? 'Present' : 'Missing'}');

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final url = '$baseUrl/projects/$projectId/tasks';
      print('Request URL: $url');
      print('Request Headers: ${{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      }}');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Successfully fetched ${data.length} tasks');
        return data.map((json) => Task.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        print('No tasks found for project');
        return [];
      } else {
        throw Exception('Failed to load project tasks: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching tasks for project:');
      print('Error message: $e');
      print('Stack trace:');
      print(StackTrace.current);
      throw Exception('Failed to load project tasks: $e');
    }
  }

  // Get ongoing tasks for dashboard (tasks with deadlines in next 3 days)
  Future<List<Task>> getOngoingTasks() async {
    try {
      print('\n=== Fetching Ongoing Tasks Debug ===');
      final token = await _getToken();

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      // Calculate date range from today
      final now = DateTime.now();
      // Set time to start of day (00:00:00) in local timezone
      final startDate = DateTime(now.year, now.month, now.day);
      // Set end date to end of day 3 days from now (23:59:59) in local timezone
      final endDate = DateTime(
        now.year,
        now.month,
        now.day + 3,
        23,
        59,
        59,
      );

      // Convert to UTC for the API
      final startUtc = startDate.toUtc();
      final endUtc = endDate.toUtc();

      print('Fetching tasks between:');
      print('Local Start: ${startDate.toString()}');
      print('Local End: ${endDate.toString()}');
      print('UTC Start: ${startUtc.toIso8601String()}');
      print('UTC End: ${endUtc.toIso8601String()}');

      final response = await http.get(
        Uri.parse('$baseUrl/tasks/filter/upcoming'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'start-date': startUtc.toIso8601String(),
          'end-date': endUtc.toIso8601String(),
        },
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final tasks = data
            .map((json) => Task.fromJson(json))
            .where((task) => task.deadline != null) // Extra safety check
            .toList();
        print('Successfully fetched ${tasks.length} upcoming tasks');
        return tasks;
      } else if (response.statusCode == 404) {
        print('No upcoming tasks found');
        return [];
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to load upcoming tasks');
      }
    } catch (e) {
      print('Error loading upcoming tasks: $e');
      return []; // Return empty list instead of throwing error
    }
  }

  // Get task details
  Future<Task> getTaskDetails(String taskId) async {
    try {
      print('\n=== Fetching Task Details Debug ===');
      print('Task ID: $taskId');

      final token = await _getToken();
      print('Token: ${token != null ? 'Present' : 'Missing'}');

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final url = '$baseUrl/tasks/$taskId';
      print('Request URL: $url');
      print('Request Headers: ${{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      }}');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Successfully parsed task data');
        return Task.fromJson(data);
      } else if (response.statusCode == 404) {
        print('Task not found with ID: $taskId');
        throw Exception('Task not found');
      } else {
        print('Unexpected response status: ${response.statusCode}');
        throw Exception('Failed to get task details: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('\nError in getTaskDetails:');
      print('Error message: $e');
      print('Stack trace:');
      print(stackTrace);
      throw Exception('Failed to get task details: $e');
    }
  }

  // Create a new task
  Future<Task> createTask(Map<String, dynamic> taskData) async {
    try {
      print('=== Creating New Task Debug ===');
      print('Task Data: $taskData');

      final token = await _getToken();
      print('Token: ${token != null ? 'Present' : 'Missing'}');

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final boardId = taskData['board'];
      if (boardId == null) {
        throw Exception('Board ID is required to create a task');
      }

      // Format the task data according to the backend model
      final formattedTaskData = {
        'title': taskData['title'],
        'description': taskData['description'] ?? '',
        'status': taskData['status'] ?? 'To Do',
        'deadline': taskData['deadline'],
        'board': boardId,
        'assignedTo': taskData['assignedTo'] ?? [],
      };

      final url = '$baseUrl/tasks/$boardId';
      print('Request URL: $url');
      print('Request Headers: ${{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      }}');
      print('Request Body: ${json.encode(formattedTaskData)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(formattedTaskData),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        print('Task created successfully with ID: ${data['_id']}');
        return Task.fromJson(data);
      } else {
        throw Exception('Failed to create task: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating task:');
      print('Error message: $e');
      print('Stack trace:');
      print(StackTrace.current);
      throw Exception('Failed to create task: $e');
    }
  }

  // Get tasks for a board
  Future<List<Task>> getTasksForBoard(String boardId) async {
    try {
      print('\n=== Fetching Tasks for Board Debug ===');
      print('Board ID: $boardId');

      final token = await _getToken();
      print('Token: ${token != null ? 'Present' : 'Missing'}');

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final url = '$baseUrl/tasks/board/$boardId';
      print('Request URL: $url');
      print('Request Headers: ${{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      }}');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Successfully fetched ${data.length} tasks');
        return data.map((json) => Task.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        print('No tasks found for board');
        return [];
      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching tasks for board:');
      print('Error message: $e');
      print('Stack trace:');
      print(StackTrace.current);
      return []; // Return empty list instead of throwing error
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
        throw Exception('Failed to update task: ${response.statusCode}');
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
        throw Exception('Failed to update task status: ${response.statusCode}');
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
        throw Exception('Failed to move task: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to move task: $e');
    }
  }
}

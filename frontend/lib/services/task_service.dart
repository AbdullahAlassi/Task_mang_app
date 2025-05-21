import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import '../services/auth_service.dart';
import '../services/project_service.dart';

class TaskService {
  // Update the baseUrl to match your actual backend URL
  static const String baseUrl =
      'http://10.0.2.2:3000/api'; // For Android emulator
  //static const String baseUrl =
  //    'http://localhost:3003/api'; // For iOS simulator
  // static const String baseUrl = 'http://YOUR_ACTUAL_IP:3000/api'; // For physical device

  final AuthService _authService = AuthService();
  final ProjectService _projectService = ProjectService(AuthService());

  // Get token from shared preferences
  Future<String?> _getToken() async {
    try {
      return await _authService.getToken();
    } catch (e) {
      throw 'Failed to get auth token: $e';
    }
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
    print('=== Creating New Task Debug ===');
    print('Task Data: $taskData');
    print('Color value: ${taskData['color']}');

    final token = await _authService.getToken();
    print('Token: ${token != null ? 'Present' : 'Missing'}');

    if (token == null) {
      throw Exception('No authentication token found');
    }

    try {
      final boardId = taskData['board'];
      final projectId = taskData['projectId'];

      // Get current user ID
      final currentUserId = await _authService.getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('Could not get current user ID');
      }

      final requestBody = {
        'title': taskData['title'],
        'description': taskData['description'],
        'deadline': taskData['deadline'],
        'board': boardId,
        'assignedTo': taskData['assignedTo'],
        'color': taskData['color'],
        'priority': taskData['priority'],
        'createdBy': currentUserId, // Add the current user as creator
      };
      print('Request body: $requestBody');

      final response = await http.post(
        Uri.parse('${baseUrl}/tasks/$boardId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        print('Task created successfully with ID: ${data['_id']}');
        print('Task color in response: ${data['color']}');

        // Update project status using the correct project ID
        try {
          await _projectService.updateProjectStatus(projectId);
        } catch (e) {
          print('Warning: Failed to update project status: $e');
          // Don't throw the error, as the task was created successfully
        }

        return Task.fromJson(data);
      } else {
        throw Exception('Failed to create task: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('Error creating task:');
      print('Error message: $e');
      print('Stack trace:');
      print(stackTrace);
      rethrow;
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
      print('\n=== Updating Task Debug ===');
      print('Task ID: $taskId');
      print('Task Data: $taskData');

      final token = await _getToken();
      print('Token: ${token != null ? 'Present' : 'Missing'}');

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      print('\n1. Updating task...');
      final response = await http.put(
        Uri.parse('$baseUrl/tasks/$taskId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(taskData),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('\n2. Fetching board details...');

        // Get board details to get project ID
        final boardResponse = await http.get(
          Uri.parse('$baseUrl/boards/${data['board']}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        print('Board Response Status: ${boardResponse.statusCode}');
        print('Board Response Body: ${boardResponse.body}');

        if (boardResponse.statusCode == 200) {
          final boardData = json.decode(boardResponse.body);
          print('\n3. Updating project status...');
          print('Project ID from board: ${boardData['project']}');

          await _projectService.updateProjectStatus(boardData['project']);
          print('Project status update completed');
        } else {
          print('Failed to fetch board details: ${boardResponse.statusCode}');
          throw Exception('Failed to fetch board details');
        }

        return Task.fromJson(data);
      } else {
        print('Failed to update task: ${response.statusCode}');
        throw Exception('Failed to update task: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('\nError in updateTask:');
      print('Error message: $e');
      print('Stack trace:');
      print(stackTrace);
      throw Exception('Failed to update task: $e');
    }
  }

  // Update task status
  Future<void> updateTaskStatus(String taskId, bool isCompleted) async {
    print('\n=== Task Status Update Debug ===');
    print('Task ID: $taskId');
    print('Marking as completed: $isCompleted');

    final token = await _getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    try {
      // 1. Get task details to get current board and project
      print('\n1. Getting task details...');
      final taskResponse = await http.get(
        Uri.parse('$baseUrl/tasks/$taskId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (taskResponse.statusCode != 200) {
        throw Exception(
            'Failed to get task details: ${taskResponse.statusCode}');
      }

      final taskData = json.decode(taskResponse.body);
      final currentBoardId = taskData['board'];
      final projectId = taskData['board']['project'];

      // 2. Get all boards for the project
      print('\n2. Getting project boards...');
      final boardsResponse = await http.get(
        Uri.parse('$baseUrl/boards/project/$projectId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (boardsResponse.statusCode != 200) {
        throw Exception(
            'Failed to get project boards: ${boardsResponse.statusCode}');
      }

      final List<dynamic> boardsData = json.decode(boardsResponse.body);
      String targetBoardId;

      if (isCompleted) {
        // Check if there's a Done board
        final doneBoard = boardsData.firstWhere(
          (board) => board['type'] == 'Done',
          orElse: () => null,
        );

        if (doneBoard == null) {
          // Create a new Done board only if one doesn't exist
          print('\n3. Creating Done board...');
          final createBoardResponse = await http.post(
            Uri.parse('$baseUrl/boards/projects/$projectId/boards'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({
              'title': 'Done',
              'type': 'Done',
              'project': projectId,
            }),
          );

          if (createBoardResponse.statusCode != 201) {
            throw Exception(
                'Failed to create Done board: ${createBoardResponse.statusCode}');
          }

          final newBoardData = json.decode(createBoardResponse.body);
          targetBoardId = newBoardData['_id'];
          print('Created new Done board with ID: $targetBoardId');
        } else {
          targetBoardId = doneBoard['_id'];
          print('Found existing Done board with ID: $targetBoardId');
        }
      } else {
        // Check if there's an In Progress board
        final inProgressBoard = boardsData.firstWhere(
          (board) => board['type'] == 'In Progress',
          orElse: () => null,
        );

        if (inProgressBoard == null) {
          // Create a new In Progress board if one doesn't exist
          print('\n3. Creating In Progress board...');
          final createBoardResponse = await http.post(
            Uri.parse('$baseUrl/boards/projects/$projectId/boards'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({
              'title': 'In Progress',
              'type': 'In Progress',
              'project': projectId,
            }),
          );

          if (createBoardResponse.statusCode != 201) {
            throw Exception(
                'Failed to create In Progress board: ${createBoardResponse.statusCode}');
          }

          final newBoardData = json.decode(createBoardResponse.body);
          targetBoardId = newBoardData['_id'];
          print('Created new In Progress board with ID: $targetBoardId');
        } else {
          targetBoardId = inProgressBoard['_id'];
          print('Found existing In Progress board with ID: $targetBoardId');
        }
      }

      print('\n4. Moving task to board: $targetBoardId');

      final moveResponse = await http.put(
        Uri.parse('$baseUrl/tasks/$taskId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'board': targetBoardId,
          'status': isCompleted ? 'Done' : 'In Progress',
        }),
      );

      if (moveResponse.statusCode != 200) {
        throw Exception('Failed to update task: ${moveResponse.statusCode}');
      }

      print('Task updated successfully');
    } catch (e) {
      print('Error updating task status:');
      print('Error message: $e');
      print('Stack trace:');
      print(StackTrace.current);
      rethrow;
    }
  }

  // Delete a task
  Future<bool> deleteTask(String taskId) async {
    print('=== Deleting Task Debug ===');
    print('Task ID: $taskId');

    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    try {
      // First get the task to get the project ID
      final task = await getTaskDetails(taskId);
      final projectId = task.projectId;
      final boardId = task.boardId;

      print('Deleting task from board: $boardId');
      print('Associated project: $projectId');

      final response = await http.delete(
        Uri.parse('${baseUrl}/tasks/$taskId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        print('Task deleted successfully');

        // Update project status if we have a project ID
        if (projectId.isNotEmpty) {
          try {
            await _projectService.updateProjectStatus(projectId);
          } catch (e) {
            print('Warning: Failed to update project status: $e');
            // Don't throw here, as the task was successfully deleted
          }
        }

        return true;
      } else {
        throw Exception('Failed to delete task');
      }
    } catch (e) {
      print('Error deleting task: $e');
      return false;
    }
  }

  // Move task to a different board
  Future<Task> moveTaskToBoard(String taskId, String boardId) async {
    try {
      print('\n=== Moving Task to Board Debug ===');
      print('Task ID: $taskId');
      print('Board ID: $boardId');

      final token = await _getToken();
      print('Token: ${token != null ? 'Present' : 'Missing'}');

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      print('\n1. Updating task board...');
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

      print('Task Update Response Status: ${response.statusCode}');
      print('Task Update Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('\n2. Fetching board details...');

        final boardResponse = await http.get(
          Uri.parse('$baseUrl/boards/$boardId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        print('Board Response Status: ${boardResponse.statusCode}');
        print('Board Response Body: ${boardResponse.body}');

        if (boardResponse.statusCode == 200) {
          final boardData = json.decode(boardResponse.body);
          print('\n3. Updating project status...');
          print('Project ID from board: ${boardData['project']}');

          await _projectService.updateProjectStatus(boardData['project']);
          print('Project status update completed');

          return Task.fromJson(data);
        } else {
          print('Failed to fetch board details: ${boardResponse.statusCode}');
          throw Exception('Failed to fetch board details');
        }
      } else {
        print('Failed to update task: ${response.statusCode}');
        throw Exception('Failed to move task: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('\nError in moveTaskToBoard:');
      print('Error message: $e');
      print('Stack trace:');
      print(stackTrace);
      throw Exception('Failed to move task: $e');
    }
  }

  Future<void> updateTaskDeadline(String taskId, DateTime newDeadline) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.patch(
        Uri.parse('${baseUrl}/tasks/$taskId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'deadline': newDeadline.toIso8601String(),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update task deadline');
      }
    } catch (e) {
      print('Error updating task deadline: $e');
      rethrow;
    }
  }

  Future<List<Task>> getPersonalTasks() async {
    try {
      final token = await _getToken();
      if (token == null) throw 'Not authenticated';

      final response = await http.get(
        Uri.parse('$baseUrl/tasks').replace(
          queryParameters: {'type': 'personal'},
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw 'Failed to fetch personal tasks: ${response.body}';
      }

      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Task.fromJson(json)).toList();
    } catch (e) {
      throw 'Failed to fetch personal tasks: $e';
    }
  }

  Future<List<Task>> getTeamTasks() async {
    try {
      final token = await _getToken();
      if (token == null) throw 'Not authenticated';

      final response = await http.get(
        Uri.parse('$baseUrl/tasks').replace(
          queryParameters: {'type': 'team'},
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw 'Failed to fetch team tasks: ${response.body}';
      }

      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Task.fromJson(json)).toList();
    } catch (e) {
      throw 'Failed to fetch team tasks: $e';
    }
  }
}

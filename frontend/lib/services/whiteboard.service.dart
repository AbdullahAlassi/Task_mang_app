import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/whiteboard_model.dart';
import '../models/board_model.dart';
import '../models/task_model.dart';

class WhiteboardService {
  static const String baseUrl = 'http://localhost:3000/api';

  // Get token from shared preferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Get whiteboard for a project
  Future<Whiteboard> getWhiteboardForProject(String projectId) async {
    try {
      final token = await _getToken();

      if (token == null) {
        // For development/demo, return mock data if no token
        return _getMockWhiteboard(projectId);
      }

      final response = await http.get(
        Uri.parse('$baseUrl/projects/$projectId/whiteboard'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Whiteboard.fromJson(data);
      } else {
        // For demo purposes, return mock data if API call fails
        return _getMockWhiteboard(projectId);
      }
    } catch (e) {
      // Return mock data for development/demo
      return _getMockWhiteboard(projectId);
    }
  }

  // Save whiteboard
  Future<bool> saveWhiteboard(Whiteboard whiteboard) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/projects/${whiteboard.projectId}/whiteboard'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(whiteboard.toJson()),
      );

      return response.statusCode == 200;
    } catch (e) {
      // For development/demo, just return true
      return true;
    }
  }

  // Add board to whiteboard
  Future<WhiteboardBoard> addBoardToWhiteboard(
    String projectId,
    String title,
    Offset position,
  ) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/projects/$projectId/whiteboard/boards'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'title': title,
          'position': {
            'x': position.dx,
            'y': position.dy,
          },
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return WhiteboardBoard.fromJson(data);
      } else {
        throw Exception('Failed to add board to whiteboard');
      }
    } catch (e) {
      // For development/demo, create a mock board
      final boardId = DateTime.now().millisecondsSinceEpoch.toString();
      return WhiteboardBoard(
        id: boardId,
        position: position,
        size: const Size(300, 400),
        board: Board(
          id: boardId,
          title: title,
          deadline: DateTime.now().add(const Duration(days: 7)),
          assignedTo: [],
          tasks: [],
          commentCount: 0,
        ),
        tasks: [],
      );
    }
  }

  // Add task to board
  Future<WhiteboardTask> addTaskToBoard(
    String projectId,
    String boardId,
    String title,
    Offset position,
  ) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse(
            '$baseUrl/projects/$projectId/whiteboard/boards/$boardId/tasks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'title': title,
          'position': {
            'x': position.dx,
            'y': position.dy,
          },
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return WhiteboardTask.fromJson(data);
      } else {
        throw Exception('Failed to add task to board');
      }
    } catch (e) {
      // For development/demo, create a mock task
      final taskId = DateTime.now().millisecondsSinceEpoch.toString();
      return WhiteboardTask(
        id: taskId,
        position: position,
        size: const Size(280, 120),
        task: Task(
          id: taskId,
          title: title,
          description: '',
          status: 'To Do',
          isCompleted: false,
          boardId: boardId,
          assignedTo: [],
          color:
              const Color(0xFFB5B35C), // Yellowish-green color from the design
        ),
      );
    }
  }

  // Update board position
  Future<bool> updateBoardPosition(
    String projectId,
    String boardId,
    Offset position,
  ) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.put(
        Uri.parse(
            '$baseUrl/projects/$projectId/whiteboard/boards/$boardId/position'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'position': {
            'x': position.dx,
            'y': position.dy,
          },
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      // For development/demo, just return true
      return true;
    }
  }

  // Update task position
  Future<bool> updateTaskPosition(
    String projectId,
    String boardId,
    String taskId,
    Offset position,
  ) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.put(
        Uri.parse(
            '$baseUrl/projects/$projectId/whiteboard/boards/$boardId/tasks/$taskId/position'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'position': {
            'x': position.dx,
            'y': position.dy,
          },
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      // For development/demo, just return true
      return true;
    }
  }

  // Delete board
  Future<bool> deleteBoard(
    String projectId,
    String boardId,
  ) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/projects/$projectId/whiteboard/boards/$boardId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      // For development/demo, just return true
      return true;
    }
  }

  // Delete task
  Future<bool> deleteTask(
    String projectId,
    String boardId,
    String taskId,
  ) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.delete(
        Uri.parse(
            '$baseUrl/projects/$projectId/whiteboard/boards/$boardId/tasks/$taskId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      // For development/demo, just return true
      return true;
    }
  }

  // Mock data for development/demo
  Whiteboard _getMockWhiteboard(String projectId) {
    return Whiteboard(
      id: 'whiteboard-1',
      projectId: projectId,
      title: 'Project Whiteboard',
      boards: [
        WhiteboardBoard(
          id: 'board-1',
          position: const Offset(100, 200),
          size: const Size(300, 400),
          board: Board(
            id: 'board-1',
            title: 'To-Do',
            deadline: DateTime.now().add(const Duration(days: 7)),
            assignedTo: ['user1', 'user2', 'user3', 'user4'],
            tasks: [],
            commentCount: 8,
          ),
          tasks: [
            WhiteboardTask(
              id: 'task-1',
              position: const Offset(10, 60),
              size: const Size(280, 120),
              task: Task(
                id: 'task-1',
                title: 'Design UI mockups',
                description: 'Create UI mockups for the new feature',
                status: 'To Do',
                isCompleted: false,
                boardId: 'board-1',
                assignedTo: ['user1'],
                color: const Color(
                    0xFFB5B35C), // Yellowish-green color from the design
              ),
            ),
          ],
        ),
        WhiteboardBoard(
          id: 'board-2',
          position: const Offset(450, 200),
          size: const Size(300, 400),
          board: Board(
            id: 'board-2',
            title: 'In Progress',
            deadline: DateTime.now().add(const Duration(days: 14)),
            assignedTo: ['user1', 'user2', 'user3', 'user4'],
            tasks: [],
            commentCount: 6,
          ),
          tasks: [],
        ),
        WhiteboardBoard(
          id: 'board-3',
          position: const Offset(800, 200),
          size: const Size(300, 400),
          board: Board(
            id: 'board-3',
            title: 'Done',
            deadline: DateTime.now().add(const Duration(days: 21)),
            assignedTo: ['user1', 'user2', 'user3', 'user4'],
            tasks: [],
            commentCount: 5,
          ),
          tasks: [],
        ),
      ],
    );
  }
}

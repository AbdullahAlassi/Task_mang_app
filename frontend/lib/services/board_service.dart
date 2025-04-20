import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/board_model.dart';
import '../models/task_model.dart';

class BoardService {
  static const String baseUrl = 'http://localhost:3000/api';

  // Get token from shared preferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Get boards for a project
  Future<List<Board>> getBoardsForProject(String projectId) async {
    try {
      final token = await _getToken();

      if (token == null) {
        // For development/demo, return mock data if no token
        return _getMockBoards();
      }

      final response = await http.get(
        Uri.parse('$baseUrl/projects/$projectId/boards'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Board.fromJson(json)).toList();
      } else {
        // For demo purposes, return mock data if API call fails
        return _getMockBoards();
      }
    } catch (e) {
      // Return mock data for development/demo
      return _getMockBoards();
    }
  }

  // Create a new board
  Future<Board> createBoard(
      String projectId, Map<String, dynamic> boardData) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/projects/$projectId/boards'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(boardData),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Board.fromJson(data);
      } else {
        throw Exception('Failed to create board');
      }
    } catch (e) {
      throw Exception('Failed to create board: $e');
    }
  }

  // Update a board
  Future<Board> updateBoard(
      String boardId, Map<String, dynamic> boardData) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/boards/$boardId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(boardData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Board.fromJson(data);
      } else {
        throw Exception('Failed to update board');
      }
    } catch (e) {
      throw Exception('Failed to update board: $e');
    }
  }

  // Delete a board
  Future<bool> deleteBoard(String boardId) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/boards/$boardId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to delete board: $e');
    }
  }

  // Update board order
  Future<bool> updateBoardOrder(String projectId, List<String> boardIds) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/projects/$projectId/boards/order'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'boardIds': boardIds,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to update board order: $e');
    }
  }

  // Get kanban columns for a project
  Future<List<KanbanColumn>> getKanbanColumns(String projectId) async {
    try {
      final boards = await getBoardsForProject(projectId);

      // Group boards by status
      final Map<String, List<Board>> boardsByStatus = {};

      for (final board in boards) {
        final status = _getBoardStatus(board);
        if (!boardsByStatus.containsKey(status)) {
          boardsByStatus[status] = [];
        }
        boardsByStatus[status]!.add(board);
      }

      // Create kanban columns
      final List<KanbanColumn> columns = [];

      // Add To-Do column
      if (boardsByStatus.containsKey('To Do')) {
        columns.add(KanbanColumn(
          id: 'to-do',
          title: 'To-Do',
          boards: boardsByStatus['To Do']!,
        ));
      } else {
        columns.add(KanbanColumn(
          id: 'to-do',
          title: 'To-Do',
          boards: [],
        ));
      }

      // Add In Progress column
      if (boardsByStatus.containsKey('In Progress')) {
        columns.add(KanbanColumn(
          id: 'in-progress',
          title: 'In-Progress',
          boards: boardsByStatus['In Progress']!,
        ));
      } else {
        columns.add(KanbanColumn(
          id: 'in-progress',
          title: 'In-Progress',
          boards: [],
        ));
      }

      // Add Done column
      if (boardsByStatus.containsKey('Done')) {
        columns.add(KanbanColumn(
          id: 'done',
          title: 'Done',
          boards: boardsByStatus['Done']!,
        ));
      } else {
        columns.add(KanbanColumn(
          id: 'done',
          title: 'Done',
          boards: [],
        ));
      }

      return columns;
    } catch (e) {
      // Return mock kanban columns for development/demo
      return _getMockKanbanColumns();
    }
  }

  // Helper method to determine board status
  String _getBoardStatus(Board board) {
    // If all tasks are done, board is done
    if (board.tasks.isNotEmpty &&
        board.tasks.every((task) => task.status == 'Done')) {
      return 'Done';
    }

    // If any task is in progress, board is in progress
    if (board.tasks.any((task) => task.status == 'In Progress')) {
      return 'In Progress';
    }

    // Otherwise, board is to do
    return 'To Do';
  }

  // Mock data for development/demo
  List<Board> _getMockBoards() {
    return [
      Board(
        id: '1',
        title: 'Board 1',
        deadline: DateTime.now().add(const Duration(days: 7)),
        assignedTo: ['user1', 'user2', 'user3', 'user4'],
        tasks: [
          Task(
            id: '1',
            title: 'Task 1',
            description: 'This is a sample task',
            status: 'To Do',
            isCompleted: false,
            boardId: '1',
            assignedTo: ['user1'],
            color: const Color(
                0xFFB5B35C), // Yellowish-green color from the design
          ),
        ],
        commentCount: 8,
      ),
      Board(
        id: '2',
        title: 'Board 2',
        deadline: DateTime.now().add(const Duration(days: 14)),
        assignedTo: ['user1', 'user2', 'user3', 'user4'],
        tasks: [],
        commentCount: 6,
      ),
      Board(
        id: '3',
        title: 'Board 3',
        deadline: DateTime.now().add(const Duration(days: 21)),
        assignedTo: ['user1', 'user2', 'user3', 'user4'],
        tasks: [],
        commentCount: 5,
      ),
    ];
  }

  // Mock kanban columns for development/demo
  List<KanbanColumn> _getMockKanbanColumns() {
    final boards = _getMockBoards();

    return [
      KanbanColumn(
        id: 'to-do',
        title: 'To-Do',
        boards: boards,
      ),
      KanbanColumn(
        id: 'in-progress',
        title: 'In-Progress',
        boards: [],
      ),
      KanbanColumn(
        id: 'done',
        title: 'Done',
        boards: [],
      ),
    ];
  }
}

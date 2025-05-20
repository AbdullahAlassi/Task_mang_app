import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/board_model.dart';

class BoardService {
  // Update the baseUrl to match your actual backend URL
  //static const String baseUrl ='http://10.0.2.2:3000/api'; // For Android emulator
  static const String baseUrl =
      'http://localhost:3003/api'; // For iOS simulator
  // static const String baseUrl = 'http://YOUR_ACTUAL_IP:3000/api'; // For physical device

  // Get token from shared preferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Get boards for a project
  Future<List<Board>> getBoardsForProject(String projectId) async {
    try {
      print('=== Fetching Boards for Project Debug ===');
      print('Project ID: $projectId');

      final token = await _getToken();
      print('Token: ${token != null ? 'Present' : 'Missing'}');

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final url = '$baseUrl/boards/project/$projectId';
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
        print('Successfully fetched ${data.length} boards');
        return data.map((json) => Board.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        print('No boards found for project');
        return [];
      } else {
        throw Exception('Failed to load boards: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching boards for project:');
      print('Error message: $e');
      print('Stack trace:');
      print(StackTrace.current);
      return []; // Return empty list instead of throwing error
    }
  }

  // Create a new board
  Future<Board> createBoard(
      String projectId, Map<String, dynamic> boardData) async {
    try {
      print('=== Creating New Board Debug ===');
      print('Project ID: $projectId');
      print('Board Data: $boardData');

      final token = await _getToken();
      print('Token: ${token != null ? 'Present' : 'Missing'}');

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      // Ensure the board has a type
      if (!boardData.containsKey('type')) {
        boardData['type'] = 'Other';
      }

      // If type is not 'Other', ensure title matches type
      if (boardData['type'] != 'Other' &&
          boardData['title'] != boardData['type']) {
        boardData['title'] = boardData['type'];
      }

      final url = '$baseUrl/boards/projects/$projectId/boards';
      print('Request URL: $url');
      print('Request Headers: ${{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      }}');
      print('Request Body: ${json.encode(boardData)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(boardData),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        print('Board created successfully with ID: ${data['_id']}');
        return Board.fromJson(data);
      } else {
        throw Exception('Failed to create board: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating board:');
      print('Error message: $e');
      print('Stack trace:');
      print(StackTrace.current);
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

      // If type is not 'Other', ensure title matches type
      if (boardData['type'] != 'Other' &&
          boardData['title'] != boardData['type']) {
        boardData['title'] = boardData['type'];
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
        throw Exception('Failed to update board: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update board: $e');
    }
  }

  // Delete a board
  Future<bool> deleteBoard(String boardId) async {
    try {
      print('=== Deleting Board Debug ===');
      print('Board ID: $boardId');

      final token = await _getToken();
      print('Token: ${token != null ? 'Present' : 'Missing'}');

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final url = '$baseUrl/boards/$boardId';
      print('Request URL: $url');
      print('Request Headers: ${{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      }}');

      final response = await http.delete(
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
        print('Board deleted successfully');
        return true;
      } else if (response.statusCode == 404) {
        print('Board not found');
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Board not found');
      } else if (response.statusCode == 403) {
        print('Permission denied');
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ??
            'Only the project owner can delete this board');
      } else {
        print('Failed to delete board');
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to delete board');
      }
    } catch (e) {
      print('Error deleting board:');
      print('Error message: $e');
      print('Stack trace:');
      print(StackTrace.current);
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

      // Create predefined columns
      final Map<String, KanbanColumn> columns = {
        'To-do': KanbanColumn(
          id: 'to-do',
          title: 'To-Do',
          type: 'To-do',
          boards: [],
        ),
        'In Progress': KanbanColumn(
          id: 'in-progress',
          title: 'In-Progress',
          type: 'In Progress',
          boards: [],
        ),
        'Done': KanbanColumn(
          id: 'done',
          title: 'Done',
          type: 'Done',
          boards: [],
        ),
        'Other': KanbanColumn(
          id: 'other',
          title: 'Other',
          type: 'Other',
          boards: [],
        ),
      };

      // Distribute boards to their respective columns based on type
      for (final board in boards) {
        if (columns.containsKey(board.type)) {
          columns[board.type]!.boards.add(board);
        } else {
          // If board type doesn't match any predefined column, add to Other
          columns['Other']!.boards.add(board);
        }
      }

      // Return columns as a list
      return columns.values.toList();
    } catch (e) {
      print('Error getting kanban columns: $e');
      // Return empty columns instead of throwing error
      return [
        KanbanColumn(id: 'to-do', title: 'To-Do', type: 'To-do', boards: []),
        KanbanColumn(
            id: 'in-progress',
            title: 'In-Progress',
            type: 'In Progress',
            boards: []),
        KanbanColumn(id: 'done', title: 'Done', type: 'Done', boards: []),
        KanbanColumn(id: 'other', title: 'Other', type: 'Other', boards: []),
      ];
    }
  }

  // Get board details
  Future<Board> getBoardDetails(String boardId) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/boards/$boardId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Board.fromJson(data);
      } else {
        throw Exception('Failed to get board details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get board details: $e');
    }
  }

  Future<void> updateBoardPositions(
      String projectId, List<String> boardIds) async {
    try {
      print('=== Updating Board Positions Debug ===');
      print('Project ID: $projectId');
      print('Board IDs: $boardIds');

      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      print(
          'Request URL: $baseUrl/boards/projects/$projectId/boards/positions');
      print('Request Headers: ${{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      }}');
      print('Request Body: ${jsonEncode({'boardIds': boardIds})}');

      final response = await http.put(
        Uri.parse('$baseUrl/boards/projects/$projectId/boards/positions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'boardIds': boardIds}),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('Board positions updated successfully');
        return;
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw Exception(
            errorData['message'] ?? 'Invalid request: ${response.body}');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
            'Failed to update board positions: ${errorData['message'] ?? response.statusCode}\n'
            'Details: ${errorData['details'] ?? 'No additional details available'}');
      }
    } catch (e) {
      print('Error updating board positions: $e');
      rethrow;
    }
  }
}

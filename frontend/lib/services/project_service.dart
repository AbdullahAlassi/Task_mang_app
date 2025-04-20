import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/project_model.dart';
import '../models/project_status.dart';
import 'auth_service.dart';

class ProjectService {
  final AuthService _authService = AuthService();

  // Get token from shared preferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Handle token expiration
  Future<void> _handleTokenExpiration() async {
    await _authService.clearToken();
    // You might want to navigate to login screen here
    // Navigator.pushReplacementNamed(context, '/login');
  }

  // Get all projects
  Future<List<Project>> getAllProjects() async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/projects'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 401) {
        await _handleTokenExpiration();
        throw Exception('Session expired. Please log in again.');
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Project.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load projects: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load projects: $e');
    }
  }

  // Get projects filtered by status
  Future<List<Project>> getProjectsByStatus(ProjectStatus status) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/projects?status=${status.apiValue}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 401) {
        await _handleTokenExpiration();
        throw Exception('Session expired. Please log in again.');
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Project.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load projects: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load projects: $e');
    }
  }

  // Get project details
  Future<Project> getProjectDetails(String projectId) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/projects/$projectId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 401) {
        await _handleTokenExpiration();
        throw Exception('Session expired. Please log in again.');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Project.fromJson(data);
      } else {
        throw Exception(
            'Failed to load project details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load project details: $e');
    }
  }

  // Create a new project
  Future<Project> createProject(Map<String, dynamic> projectData) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/projects'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(projectData),
      );

      if (response.statusCode == 401) {
        await _handleTokenExpiration();
        throw Exception('Session expired. Please log in again.');
      }

      if (response.statusCode == 201) {
        try {
          final data = json.decode(response.body);
          return Project.fromJson(data);
        } catch (e) {
          // If we can't parse the response but the project was created (201)
          // we should still try to get the color from the response
          final responseData = json.decode(response.body);
          return Project(
            id: 'temp',
            title: projectData['title'],
            description: projectData['description'],
            createdAt: DateTime.now(),
            deadline: projectData['deadline'] != null
                ? DateTime.parse(projectData['deadline'])
                : null,
            status: projectData['status'] ?? 'Not Started',
            progress: 0,
            totalTasks: 0,
            completedTasks: 0,
            managerId: '',
            memberIds: [],
            boardIds: [],
            color:
                responseData['color'] ?? '#6B4EFF', // Get color from response
          );
        }
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to create project');
      }
    } catch (e) {
      throw Exception('Failed to create project: $e');
    }
  }

  // Update a project
  Future<Project> updateProject(
      String projectId, Map<String, dynamic> projectData) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/projects/$projectId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(projectData),
      );

      if (response.statusCode == 401) {
        await _handleTokenExpiration();
        throw Exception('Session expired. Please log in again.');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Project.fromJson(data);
      } else {
        throw Exception('Failed to update project: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update project: $e');
    }
  }

  // Delete a project
  Future<bool> deleteProject(String projectId) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/projects/$projectId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 401) {
        await _handleTokenExpiration();
        throw Exception('Session expired. Please log in again.');
      }

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to delete project: $e');
    }
  }

  // Get recent projects for dashboard
  Future<List<Project>> getRecentProjects() async {
    try {
      final token = await _getToken();

      if (token == null) {
        print('No authentication token found');
        throw Exception('Authentication token not found');
      }

      print('Fetching recent projects...');
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/projects?recent=true'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 401) {
        await _handleTokenExpiration();
        throw Exception('Session expired. Please log in again.');
      }

      if (response.statusCode == 200) {
        try {
          final List<dynamic> data = json.decode(response.body);
          print('Parsed ${data.length} projects');
          return data.map((json) {
            print('Processing project: ${json['title']}');
            return Project.fromJson(json);
          }).toList();
        } catch (e) {
          print('Error parsing recent projects response: $e');
          print('Response body that failed to parse: ${response.body}');
          return [];
        }
      } else {
        final errorBody = json.decode(response.body);
        print('Error response: $errorBody');
        throw Exception(
            errorBody['message'] ?? 'Failed to load recent projects');
      }
    } catch (e) {
      print('Error loading recent projects: $e');
      return [];
    }
  }
}

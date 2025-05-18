import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/project_model.dart';
import '../models/project_status.dart';
import 'auth_service.dart';

class ProjectService {
  final AuthService _authService = AuthService();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _handleTokenExpiration() async {
    await _authService.clearToken();
  }

  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId'); // Read the stored userId directly
  }

  // 📌 Get all projects (basic - rarely used)
  Future<List<Project>> getAllProjects() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/projects'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Project.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load projects: ${response.body}');
      }
    } catch (e) {
      print('Error fetching all projects: $e');
      rethrow;
    }
  }

  // 📌 Get projects by status and fetch full details
  Future<List<Project>> getProjectsByStatus(ProjectStatus status) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // For 'all' status, don't include status parameter
      final url = status == ProjectStatus.all
          ? '${ApiConstants.baseUrl}/projects'
          : '${ApiConstants.baseUrl}/projects?status=${status.apiValue}';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Project.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load projects: ${response.body}');
      }
    } catch (e) {
      print('Error fetching projects by status: $e');
      rethrow;
    }
  }

  // 📌 Get single project details including tasks
  Future<Project> getProjectDetails(String projectId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Authentication token not found');

    final projectResponse = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/projects/$projectId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (projectResponse.statusCode == 401) {
      await _handleTokenExpiration();
      throw Exception('Session expired. Please log in again.');
    }

    if (projectResponse.statusCode == 200) {
      final projectData = json.decode(projectResponse.body);

      // Fetch tasks
      final tasksResponse = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/projects/$projectId/tasks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (tasksResponse.statusCode == 200) {
        final List<dynamic> tasksData = json.decode(tasksResponse.body);

        final totalTasks = tasksData.length;
        final completedTasks =
            tasksData.where((task) => task['status'] == 'Done').length;
        final progress =
            totalTasks > 0 ? ((completedTasks / totalTasks) * 100).round() : 0;

        projectData['totalTasks'] = totalTasks;
        projectData['completedTasks'] = completedTasks;
        projectData['progress'] = progress;
      }

      return Project.fromJson(projectData);
    } else {
      throw Exception(
          'Failed to load project details: ${projectResponse.statusCode}');
    }
  }

  // 📌 Create project
  Future<Project> createProject(Map<String, dynamic> projectData) async {
    final token = await _getToken();
    if (token == null) throw Exception('Authentication token not found');

    print('Creating project with data: $projectData'); // Debug print

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
      final data = json.decode(response.body);
      print('Project created successfully: $data'); // Debug print
      return Project.fromJson(data);
    } else {
      final errorBody = json.decode(response.body);
      print('Failed to create project: $errorBody'); // Debug print
      throw Exception(errorBody['message'] ?? 'Failed to create project');
    }
  }

  // 📌 Update project
  Future<Project> updateProject(
      String projectId, Map<String, dynamic> projectData) async {
    final token = await _getToken();
    if (token == null) throw Exception('Authentication token not found');

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
      final errorBody = json.decode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to update project');
    }
  }

  // 📌 Delete project
  Future<bool> deleteProject(String projectId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Authentication token not found');

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
  }

  // 📌 Get recent projects (for Dashboard)
  Future<List<Project>> getRecentProjects() async {
    final token = await _getToken();
    if (token == null) throw Exception('Authentication token not found');

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/projects?recent=true'),
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

      final List<Project> projects = [];
      for (final projectJson in data) {
        try {
          final projectDetails = await getProjectDetails(
            projectJson['_id'] ?? projectJson['id'],
          );
          projects.add(projectDetails);
        } catch (e) {
          projects.add(Project.fromJson(projectJson));
        }
      }
      return projects;
    } else {
      final errorBody = json.decode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to load recent projects');
    }
  }

  Future<void> updateProjectStatus(String projectId) async {
    print('=== Updating Project Status Debug ===');
    print('Project ID: $projectId');

    final token = await _authService.getToken();
    print('Token: ${token != null ? 'Present' : 'Missing'}');

    if (token == null) {
      throw Exception('No authentication token found');
    }

    try {
      print('1. Sending status update request...');
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/projects/$projectId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 404) {
        throw Exception('Project not found. Please refresh the project list.');
      } else if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'Failed to update project status');
      }
    } catch (e, stackTrace) {
      print('Error in updateProjectStatus:');
      print('Error message: $e');
      print('Stack trace:');
      print(stackTrace);
      rethrow; // Rethrow to let the caller handle the error
    }
  }

  Future<void> updateProjectProgress(String projectId, int progress) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/projects/$projectId/progress'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _authService.getToken()}',
        },
        body: jsonEncode({'progress': progress}),
      );

      if (response.statusCode == 200) {
        // Progress updated successfully
        return;
      } else {
        throw Exception('Failed to update project progress');
      }
    } catch (e) {
      throw Exception('Error updating project progress: $e');
    }
  }
}

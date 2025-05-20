import 'package:dio/dio.dart';
import 'package:frontend/models/project_model.dart';
import 'package:frontend/models/project_member.dart' as member;
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/utils/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProjectService {
  final Dio _dio;
  final AuthService _authService;

  ProjectService(this._dio, this._authService) {
    _dio.options.baseUrl = ApiConfig.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 3);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add auth interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final token = await _authService.getToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            return handler.next(options);
          } catch (e) {
            return handler.reject(
              DioException(
                requestOptions: options,
                error: 'Failed to get auth token: $e',
              ),
            );
          }
        },
        onError: (DioException error, handler) {
          if (error.response?.statusCode == 401) {
            // Handle token expiration or invalid token
            _authService.logout();
          }
          return handler.next(error);
        },
      ),
    );
  }

  // Create project
  Future<Project> createProject(Map<String, dynamic> projectData) async {
    try {
      final response = await _dio.post('/api/projects', data: projectData);
      return Project.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create project: $e');
    }
  }

  // Update project
  Future<void> updateProject(
      String projectId, Map<String, dynamic> projectData) async {
    try {
      print('\n=== Updating Project Debug ===');
      print('Project ID: $projectId');
      print('Request Payload: $projectData');

      final response =
          await _dio.put('/api/projects/$projectId', data: projectData);

      print('Response Status Code: ${response.statusCode}');
      print('Response Data: ${response.data}');
    } catch (e) {
      print('\nError updating project:');
      print('Error message: $e');
      if (e is DioException && e.response != null) {
        print('Error Response Status: ${e.response!.statusCode}');
        print('Error Response Data: ${e.response!.data}');
      }
      throw Exception('Failed to update project: $e');
    }
  }

  // Get project by ID
  Future<Project> getProject(String projectId) async {
    try {
      final response = await _dio.get('/api/projects/$projectId');
      return Project.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch project: $e');
    }
  }

  // Get project members
  Future<List<member.ProjectMember>> getProjectMembers(String projectId) async {
    try {
      final response = await _dio.get('/api/projects/$projectId/members');
      return (response.data as List)
          .map((json) => member.ProjectMember.fromJson(json))
          .toList()
          .cast<member.ProjectMember>();
    } catch (e) {
      throw Exception('Failed to fetch project members: $e');
    }
  }

  // Update member role
  Future<void> updateProjectMemberRole(
    String projectId,
    String memberId,
    String newRole,
  ) async {
    try {
      await _dio.put(
        '/api/projects/$projectId/members/$memberId',
        data: {'role': newRole},
      );
    } catch (e) {
      throw Exception('Failed to update member role: $e');
    }
  }

  // Remove member
  Future<void> removeProjectMember(String projectId, String memberId) async {
    try {
      await _dio.delete('/api/projects/$projectId/members/$memberId');
    } catch (e) {
      throw Exception('Failed to remove member: $e');
    }
  }

  // Invite member
  Future<void> inviteProjectMember(
    String projectId,
    String email,
    String role,
  ) async {
    try {
      await _dio.post(
        '/api/project-teams/$projectId/members',
        data: {'email': email, 'role': role},
      );
    } catch (e) {
      throw Exception('Failed to invite member: $e');
    }
  }

  // Get personal projects
  Future<List<Project>> getPersonalProjects() async {
    try {
      final response = await _dio.get('/api/projects', queryParameters: {
        'type': 'personal',
      });
      print('Personal projects response: ${response.data}');
      return (response.data as List)
          .map((json) => Project.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching personal projects: $e');
      throw Exception('Failed to fetch personal projects: $e');
    }
  }

  // Get team projects
  Future<List<Project>> getTeamProjects() async {
    try {
      final response = await _dio.get('/api/projects', queryParameters: {
        'type': 'team',
      });
      print('Team projects response: ${response.data}');
      return (response.data as List)
          .map((json) => Project.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching team projects: $e');
      throw Exception('Failed to fetch team projects: $e');
    }
  }

  // Get recent projects
  Future<List<Project>> getRecentProjects() async {
    try {
      final response = await _dio.get('/api/projects', queryParameters: {
        'recent': 'true',
      });
      print('Recent projects response: ${response.data}');
      return (response.data as List)
          .map((json) => Project.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching recent projects: $e');
      throw Exception('Failed to fetch recent projects: $e');
    }
  }

  // Get projects by status
  Future<List<Project>> getProjectsByStatus(String status) async {
    try {
      final response = await _dio.get('/api/projects', queryParameters: {
        'status': status,
      });
      print('Projects by status response: ${response.data}');
      return (response.data as List)
          .map((json) => Project.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching projects by status: $e');
      throw Exception('Failed to fetch projects by status: $e');
    }
  }

  // Get current user ID from JWT token
  Future<String?> getCurrentUserId() async {
    try {
      print('=== Getting Current User ID from JWT ===');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(ApiConfig.tokenKey);

      if (token == null) {
        print('❌ No token found in SharedPreferences');
        return null;
      }

      print(
          '🔑 JWT Token: ${token.substring(0, 20)}...'); // Show first 20 chars for security

      final parts = token.split('.');
      if (parts.length != 3) {
        print('❌ Invalid JWT format: ${parts.length} parts found');
        return null;
      }

      final payload =
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final Map<String, dynamic> data = jsonDecode(payload);

      print('📦 Decoded payload: $data');

      final userId = data['id'];
      if (userId == null) {
        print('❌ No user ID found in JWT payload');
        return null;
      }

      print('✅ Extracted user ID: $userId');
      return userId;
    } catch (e) {
      print('❌ Error decoding JWT: $e');
      return null;
    }
  }

  // Get project details
  Future<Project> getProjectDetails(String projectId) async {
    try {
      print('Fetching project details for ID: $projectId');
      final response = await _dio.get('/api/projects/$projectId');

      if (response.data == null) {
        throw Exception('No data received from server');
      }

      print('Project details response: ${response.data}');

      try {
        return Project.fromJson(response.data);
      } catch (e) {
        print('Error parsing project data: $e');
        print('Raw project data: ${response.data}');
        throw Exception('Failed to parse project data: $e');
      }
    } on DioException catch (e) {
      print('Dio error fetching project details: ${e.message}');
      if (e.response != null) {
        print('Server response: ${e.response?.data}');
        print('Status code: ${e.response?.statusCode}');
      }
      throw Exception('Failed to fetch project details: ${e.message}');
    } catch (e) {
      print('Unexpected error fetching project details: $e');
      throw Exception('Failed to fetch project details: $e');
    }
  }

  // Update project status
  Future<void> updateProjectStatus(String projectId) async {
    try {
      await _dio.put('/api/projects/$projectId/status');
    } catch (e) {
      throw Exception('Failed to update project status: $e');
    }
  }

  // Delete project
  Future<void> deleteProject(String projectId) async {
    try {
      await _dio.delete('/api/projects/$projectId');
    } catch (e) {
      throw Exception('Failed to delete project: $e');
    }
  }
}

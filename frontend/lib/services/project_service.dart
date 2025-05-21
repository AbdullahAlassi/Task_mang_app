import 'package:http/http.dart' as http;
import 'package:frontend/models/project_model.dart';
import 'package:frontend/models/project_member.dart' as member;
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/utils/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProjectService {
  final AuthService _authService;

  ProjectService(this._authService);

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Create project
  Future<Project> createProject(Map<String, dynamic> projectData) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/projects');
    final headers = await _getHeaders();
    final response =
        await http.post(url, headers: headers, body: jsonEncode(projectData));
    if (response.statusCode == 201) {
      return Project.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create project: ${response.body}');
    }
  }

  // Update project
  Future<void> updateProject(
      String projectId, Map<String, dynamic> projectData) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/projects/$projectId');
    final headers = await _getHeaders();
    final response =
        await http.put(url, headers: headers, body: jsonEncode(projectData));
    if (response.statusCode != 200) {
      throw Exception('Failed to update project: ${response.body}');
    }
  }

  // Get project by ID
  Future<Project> getProject(String projectId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/projects/$projectId');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return Project.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch project: ${response.body}');
    }
  }

  // Get project members
  Future<List<member.ProjectMember>> getProjectMembers(String projectId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/projects/$projectId/members');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List)
          .map((json) => member.ProjectMember.fromJson(json))
          .toList()
          .cast<member.ProjectMember>();
    } else {
      throw Exception('Failed to fetch project members: ${response.body}');
    }
  }

  // Update member role
  Future<void> updateProjectMemberRole(
      String projectId, String memberId, String newRole) async {
    final url =
        Uri.parse('${ApiConfig.baseUrl}/projects/$projectId/members/$memberId');
    final headers = await _getHeaders();
    final response = await http.put(url,
        headers: headers, body: jsonEncode({'role': newRole}));
    if (response.statusCode != 200) {
      throw Exception('Failed to update member role: ${response.body}');
    }
  }

  // Remove member
  Future<void> removeProjectMember(String projectId, String memberId) async {
    final url =
        Uri.parse('${ApiConfig.baseUrl}/projects/$projectId/members/$memberId');
    final headers = await _getHeaders();
    final response = await http.delete(url, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to remove member: ${response.body}');
    }
  }

  // Invite member
  Future<void> inviteProjectMember(
      String projectId, String email, String role) async {
    final url = Uri.parse(
        '${ApiConfig.baseUrl.replaceAll('/api', '/api/project-teams')}/$projectId/members');
    final headers = await _getHeaders();
    final response = await http.post(url,
        headers: headers, body: jsonEncode({'email': email, 'role': role}));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to invite member: ${response.body}');
    }
  }

  // Get personal projects
  Future<List<Project>> getPersonalProjects() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/projects?type=personal');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List)
          .map((json) => Project.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to fetch personal projects: ${response.body}');
    }
  }

  // Get team projects
  Future<List<Project>> getTeamProjects() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/projects?type=team');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List)
          .map((json) => Project.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to fetch team projects: ${response.body}');
    }
  }

  // Get recent projects
  Future<List<Project>> getRecentProjects() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/projects?recent=true');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List)
          .map((json) => Project.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to fetch recent projects: ${response.body}');
    }
  }

  // Get projects by status
  Future<List<Project>> getProjectsByStatus(String status) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/projects?status=$status');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List)
          .map((json) => Project.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to fetch projects by status: ${response.body}');
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
      print('🔑 JWT Token: [1m${token.substring(0, 20)}...[0m');
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
    final url = Uri.parse('${ApiConfig.baseUrl}/projects/$projectId');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return Project.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch project details: ${response.body}');
    }
  }

  // Update project status
  Future<void> updateProjectStatus(String projectId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/projects/$projectId/status');
    final headers = await _getHeaders();
    final response = await http.put(url, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to update project status: ${response.body}');
    }
  }

  // Delete project
  Future<void> deleteProject(String projectId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/projects/$projectId');
    final headers = await _getHeaders();
    final response = await http.delete(url, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to delete project: ${response.body}');
    }
  }
}

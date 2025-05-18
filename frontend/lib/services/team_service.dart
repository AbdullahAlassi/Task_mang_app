import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/team_model.dart';
import 'auth_service.dart';

class TeamService {
  final AuthService _authService = AuthService();
  final String baseUrl = ApiConstants.baseUrl;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Get all teams
  Future<List<Team>> getAllTeams() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/teams'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Team.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load teams: ${response.body}');
      }
    } catch (e) {
      print('Error fetching teams: $e');
      rethrow;
    }
  }

  // Get team by ID
  Future<Team> getTeamById(String teamId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/teams/$teamId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Team.fromJson(data);
      } else {
        throw Exception('Failed to load team: ${response.body}');
      }
    } catch (e) {
      print('Error fetching team: $e');
      rethrow;
    }
  }

  // Create new team
  Future<Team> createTeam(Map<String, dynamic> teamData) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/teams'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(teamData),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Team.fromJson(data);
      } else {
        throw Exception('Failed to create team: ${response.body}');
      }
    } catch (e) {
      print('Error creating team: $e');
      rethrow;
    }
  }

  // Update team
  Future<Team> updateTeam(String teamId, Map<String, dynamic> teamData) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/teams/$teamId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(teamData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Team.fromJson(data);
      } else {
        throw Exception('Failed to update team: ${response.body}');
      }
    } catch (e) {
      print('Error updating team: $e');
      rethrow;
    }
  }

  // Delete team
  Future<bool> deleteTeam(String teamId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/teams/$teamId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting team: $e');
      rethrow;
    }
  }

  // Add member to team
  Future<Team> addTeamMember(String teamId, String userId, String role) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/teams/$teamId/members'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'userId': userId,
          'role': role,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Team.fromJson(data);
      } else {
        throw Exception('Failed to add team member: ${response.body}');
      }
    } catch (e) {
      print('Error adding team member: $e');
      rethrow;
    }
  }

  // Remove member from team
  Future<Team> removeTeamMember(String teamId, String userId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/teams/$teamId/members/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Team.fromJson(data);
      } else {
        throw Exception('Failed to remove team member: ${response.body}');
      }
    } catch (e) {
      print('Error removing team member: $e');
      rethrow;
    }
  }

  // Get team hierarchy
  Future<List<Team>> getTeamHierarchy(String teamId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/teams/$teamId/hierarchy'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Team.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load team hierarchy: ${response.body}');
      }
    } catch (e) {
      print('Error fetching team hierarchy: $e');
      rethrow;
    }
  }

  // Update team member role
  Future<void> updateTeamMemberRole(
      String teamId, String userId, String newRole) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/teams/$teamId/members/$userId/role'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'role': newRole,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update team member role');
      }
    } catch (e) {
      print('Error updating team member role: $e');
      rethrow;
    }
  }

  Future<int> getTeamTaskCount(String teamId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/teams/$teamId/taskCount'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['count'] ?? 0;
    } else {
      throw Exception('Failed to fetch team task count');
    }
  }
}

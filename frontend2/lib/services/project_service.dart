import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/project_model.dart';

class ProjectService {
  static const String baseUrl = 'http://localhost:3000/api';

  Future<List<Project>> getRecentProjects() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/projects/recent'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Project.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load projects');
      }
    } catch (e) {
      throw Exception('Failed to load projects: $e');
    }
  }
}

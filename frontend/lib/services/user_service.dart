import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../config/api_config.dart';
import '../exceptions/auth_exception.dart';
import '../exceptions/api_exception.dart';
import 'auth_service.dart';

class UserService {
  final AuthService _authService = AuthService();
  static const String _tokenKey = 'token'; // Match the key used in AuthService

  // Get current user profile
  Future<User> getCurrentUser() async {
    try {
      print('=== Fetching Current User Debug ===');
      final token = await _getToken();
      print('Token: ${token != null ? 'Present' : 'Missing'}');

      if (token == null) {
        throw AuthException('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return User.fromJson(data);
      } else if (response.statusCode == 401) {
        throw AuthException(ApiConfig.loginFailed);
      } else {
        throw ApiException('Failed to get user profile',
            statusCode: response.statusCode);
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      if (e is AuthException || e is ApiException) {
        rethrow;
      }
      throw ApiException(ApiConfig.loginFailed);
    }
  }

  // Get token from shared preferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConfig.tokenKey);
  }

  // Update current user profile
  Future<User> updateProfile(Map<String, dynamic> userData) async {
    try {
      print('=== Updating User Profile Debug ===');
      print('Update Data: $userData');

      final token = await _getToken();
      print('Token: ${token != null ? 'Present' : 'Missing'}');

      if (token == null) {
        throw AuthException('No authentication token found');
      }

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(userData),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return User.fromJson(data);
      } else if (response.statusCode == 401) {
        throw AuthException(ApiConfig.loginFailed);
      } else {
        throw ApiException('Failed to update profile',
            statusCode: response.statusCode);
      }
    } catch (e) {
      print('Error updating user profile: $e');
      if (e is AuthException || e is ApiException) {
        rethrow;
      }
      throw ApiException(ApiConfig.loginFailed);
    }
  }

  Future<User> updateUser(User user) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/users/${user.id}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': user.name,
        'email': user.email,
        'dateOfBirth': user.dateOfBirth?.toIso8601String(),
        'country': user.country,
        'phoneNumber': user.phoneNumber,
        'profilePicture': user.profilePicture,
      }),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update user: ${response.body}');
    }
  }

  // Get all users
  Future<List<User>> getAllUsers() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usersEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load users: $e');
    }
  }

  // Get users by their IDs
  Future<List<User>> getUsersByIds(List<String> userIds) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usersEndpoint}/by-ids'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'userIds': userIds}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load users: $e');
    }
  }
}

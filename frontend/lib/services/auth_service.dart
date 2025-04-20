import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      print('Sending registration request...');
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        try {
          final data = json.decode(response.body);
          print('Decoded response data: $data');

          // Create a User object with the provided data since the backend
          // only returns a success message
          return User(
            id: '', // You might want to get this from the backend
            name: name,
            email: email,
          );
        } catch (e) {
          print('Error parsing response: $e');
          throw Exception('Failed to parse server response: $e');
        }
      } else {
        try {
          final error = json.decode(response.body);
          print('Error response: $error');
          throw Exception(error['message'] ??
              'Registration failed with status ${response.statusCode}');
        } catch (e) {
          print('Error parsing error response: $e');
          throw Exception(
              'Registration failed with status ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Registration error: $e');
      throw Exception('Registration failed: $e');
    }
  }

  Future<String> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'];

        // Store token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        if (rememberMe) {
          await prefs.setBool('rememberMe', true);
        }

        return token;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('rememberMe') ?? false;

    if (rememberMe) {
      // Only remove token but keep user email
      await prefs.remove('token');
    } else {
      // Clear all auth data
      await prefs.remove('token');
      await prefs.remove('user');
      await prefs.remove('rememberMe');
    }
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') != null;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Clear token from shared preferences
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }
}

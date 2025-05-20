import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';

class AuthService {
  //static const String baseUrl = 'http://10.0.2.2:3000/api';
  static const String baseUrl = 'http://localhost:3003/api';
  static const String _tokenKey = 'token';
  static const String _tokenExpiryKey = 'token_expiry';

  Future<User> register({
    required String name,
    required String email,
    required String password,
    DateTime? dateOfBirth,
    String? country,
    String? phoneNumber,
    String? profilePicture,
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
          'dateOfBirth': dateOfBirth?.toIso8601String(),
          'country': country,
          'phoneNumber': phoneNumber,
          'profilePicture': profilePicture,
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
            dateOfBirth: dateOfBirth,
            country: country,
            phoneNumber: phoneNumber,
            profilePicture: profilePicture,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
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

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      print('=== AuthService Login Started ===');
      print('Attempting login for email: $email');
      print('Remember Me: $rememberMe');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Decoded response data: $data');

        final token = data['token'];
        print('Token received: ${token != null ? 'Yes' : 'No'}');

        if (token == null) {
          print('Error: Token is null in response');
          throw Exception('Invalid response: Token is missing');
        }

        // Decode token to get expiration
        final decodedToken = JwtDecoder.decode(token);
        print('Decoded token: $decodedToken');

        final expiryDate =
            DateTime.fromMillisecondsSinceEpoch(decodedToken['exp'] * 1000);
        print('Token expiry date: $expiryDate');

        // Use 'id' instead of 'userId' as that's what's in the token
        final userId = decodedToken['id'];
        final userRole = decodedToken['role'];
        print('User ID: $userId');
        print('User Role: $userRole');

        if (userId == null) {
          print('Error: User ID is null in token');
          throw Exception('Invalid token: User ID is missing');
        }

        // Store token and its expiry
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        await prefs.setString(_tokenExpiryKey, expiryDate.toIso8601String());

        // Store user details
        await prefs.setString('userId', userId);
        await prefs.setString('userRole', userRole);

        if (rememberMe) {
          print('Setting remember me to true');
          await prefs.setBool('rememberMe', true);
        }

        // Fetch user details
        try {
          final userResponse = await http.get(
            Uri.parse('$baseUrl/users/me'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );

          if (userResponse.statusCode == 200) {
            final userData = json.decode(userResponse.body);
            print('=== AuthService Login Successful ===');
            return {
              'token': token,
              'user': userData,
            };
          } else {
            // If we can't fetch user details, create a basic user object
            return {
              'token': token,
              'user': {
                'id': userId,
                'name': email.split('@')[0],
                'email': email,
                'role': userRole,
                'createdAt': DateTime.now().toIso8601String(),
                'updatedAt': DateTime.now().toIso8601String(),
              },
            };
          }
        } catch (e) {
          print('Error fetching user details: $e');
          // Return basic user data if we can't fetch details
          return {
            'token': token,
            'user': {
              'id': userId,
              'name': email.split('@')[0],
              'email': email,
              'role': userRole,
              'createdAt': DateTime.now().toIso8601String(),
              'updatedAt': DateTime.now().toIso8601String(),
            },
          };
        }
      } else {
        print('Login failed with status code: ${response.statusCode}');
        final error = json.decode(response.body);
        print('Error response: $error');
        throw Exception(error['message'] ?? 'Login failed');
      }
    } catch (e) {
      print('=== AuthService Login Error ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
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

  Future<bool> isTokenValid() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryString = prefs.getString(_tokenExpiryKey);

    if (expiryString == null) return false;

    final expiryDate = DateTime.parse(expiryString);
    return DateTime.now().isBefore(expiryDate);
  }

  Future<String?> getToken() async {
    if (!await isTokenValid()) {
      await clearToken();
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_tokenExpiryKey);
  }

  Future<String?> getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('userId');
    } catch (e) {
      print('Error getting current user ID: $e');
      return null;
    }
  }

  Future<String?> getCurrentUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userRole');
  }

  Future<User> fetchCurrentUser() async {
    final token = await getToken();
    if (token == null) throw Exception('No token found');
    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to fetch user');
    }
  }
}

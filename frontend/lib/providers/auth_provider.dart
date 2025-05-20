import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  String? _token;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _token != null;

  void setUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  void setToken(String token) {
    _token = token;
    notifyListeners();
  }

  void clearUser() {
    _currentUser = null;
    _token = null;
    notifyListeners();
  }

  // Load user from token on app start
  Future<void> loadUserFromToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      try {
        final user = await AuthService().fetchCurrentUser();
        setUser(user);
        setToken(token);
      } catch (e) {
        clearUser();
      }
    }
  }
}

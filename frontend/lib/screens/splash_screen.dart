import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../config/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final bool isTokenValid = await _authService.isTokenValid();
      final bool isLoggedIn = await _authService.isLoggedIn();

      if (mounted) {
        if (isLoggedIn && isTokenValid) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          // Clear token if it's invalid or not found
          await _authService.clearToken();
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      print('Error checking auth status: $e');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Add your app logo here
            const Icon(
              Icons.task_alt,
              size: 80,
              color: AppColors.primaryColor,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:frontend/screens/dashboard_screen.dart';
import 'package:frontend/screens/signup_screen.dart';

// Import existing components
import '../widgets/social_login.dart';
import '../widgets/input_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Color constants moved inside the class
  static const Color background = Color(0xFF1C1C1E);
  static const Color white = Colors.white;

  bool isLogin = false;
  bool isPasswordVisible = false;
  bool rememberMe = false;
  bool obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth <= 640;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main content
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      'Login to your Account',
                      style: TextStyle(
                        color: white,
                        fontSize: isSmallScreen ? 28 : 32,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Login/Signup toggle
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  isLogin = false;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      !isLogin
                                          ? const Color(0xFF0A84FF)
                                          : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'Login',
                                  style: TextStyle(
                                    color: white,
                                    fontSize: 16,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SignupScreen(),
                                  ),
                                );
                                setState(() {
                                  isLogin = false;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'SignUp',
                                  style: TextStyle(
                                    color: white,
                                    fontSize: 16,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Input fields - using existing InputField widget
                    InputField(
                      icon: Icons.mail_outline,
                      hintText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      isSmallScreen: isSmallScreen,
                    ),
                    const SizedBox(height: 24),

                    // Password field
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: isSmallScreen ? 12 : 15,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            color: const Color(0xFF8E8E93),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              obscureText: obscurePassword,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Inter',
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Password',
                                hintStyle: TextStyle(
                                  color: Color(0xFF8E8E93),
                                  fontSize: 16,
                                  fontFamily: 'Inter',
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                            child: Icon(
                              obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: const Color(0xFF8E8E93),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Remember me
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          rememberMe = !rememberMe;
                        });
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Color(0xFF0A84FF),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(5),
                              color:
                                  rememberMe
                                      ? const Color(0xFF0A84FF)
                                      : Colors.transparent,
                            ),
                            child:
                                rememberMe
                                    ? const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                    : null,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Remember me',
                            style: TextStyle(
                              color: white,
                              fontSize: 14,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sign in button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DashboardScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A84FF),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Login',
                          style: TextStyle(
                            color: white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Forgot password
                    Center(
                      child: GestureDetector(
                        onTap: () {},
                        child: Text(
                          'Forgot the password?',
                          style: TextStyle(
                            color: Color(0xFF0A84FF),
                            fontSize: 14,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Or continue with
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Divider(thickness: 1, color: Color(0xFF8E8E93)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          color: const Color(0xFF1C1C1E),
                          child: Text(
                            'or continue with',
                            style: TextStyle(
                              color: Color(0xFF8E8E93),
                              fontSize: 14,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Social login buttons - using existing SocialLoginButton widget
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SocialLoginButton(
                          icon: Icons.facebook,
                          isSmallScreen: isSmallScreen,
                          onPressed: () {},
                          altText: 'Facebook',
                        ),
                        const SizedBox(width: 20),
                        SocialLoginButton(
                          icon: Icons.g_mobiledata,
                          isSmallScreen: isSmallScreen,
                          onPressed: () {},
                          altText: 'Google',
                        ),
                        const SizedBox(width: 20),
                        SocialLoginButton(
                          icon: Icons.apple,
                          isSmallScreen: isSmallScreen,
                          onPressed: () {},
                          altText: 'Apple',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

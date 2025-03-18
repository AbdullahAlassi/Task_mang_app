import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/widgets/social_login.dart';
import '../widgets/input_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool isSignup = true;
  bool rememberMe = false;
  bool obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Set status bar to match dark theme
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 640;

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),

                // Heading
                Text(
                  'Create your Account',
                  style: TextStyle(
                    color: Colors.white,
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
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginScreen(),
                              ),
                            );
                            setState(() {
                              isSignup = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color:
                                  !isSignup
                                      ? const Color(0xFF0A84FF)
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                color: Colors.white,
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
                            setState(() {
                              isSignup = true;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color:
                                  isSignup
                                      ? const Color(0xFF0A84FF)
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'SignUp',
                              style: TextStyle(
                                color: Colors.white,
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

                const SizedBox(height: 30),

                // Input fields
                Column(
                  children: [
                    // Username field
                    InputField(
                      icon: Icons.person_outline,
                      hintText: 'Username',
                      isSmallScreen: isSmallScreen,
                    ),

                    const SizedBox(height: 15),

                    // Email field
                    InputField(
                      icon: Icons.mail_outline,
                      hintText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      isSmallScreen: isSmallScreen,
                    ),

                    const SizedBox(height: 15),

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

                    const SizedBox(height: 15),

                    // Remember me checkbox
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              rememberMe = !rememberMe;
                            });
                          },
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFF0A84FF),
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
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Remember me',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Sign up button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A84FF),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isSignup ? 'Sign up' : 'Login',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Forgot password
                    GestureDetector(
                      onTap: () {},
                      child: const Text(
                        'Forgot the password?',
                        style: TextStyle(
                          color: Color(0xFF0A84FF),
                          fontSize: 14,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Or continue with
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        const Divider(color: Color(0xFF8E8E93), thickness: 1),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          color: const Color(0xFF1C1C1E),
                          child: const Text(
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

                    const SizedBox(height: 30),

                    // Social login buttons
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

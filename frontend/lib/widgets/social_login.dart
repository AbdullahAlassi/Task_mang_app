import 'package:flutter/material.dart';

class SocialLoginButton extends StatelessWidget {
  final IconData icon; // Icon instead of imagePath
  final String altText;
  final bool isSmallScreen;
  final VoidCallback onPressed; // New onPressed function

  const SocialLoginButton({
    Key? key,
    required this.icon,
    required this.altText,
    required this.onPressed,
    this.isSmallScreen = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed, // Trigger onPressed when tapped
      child: Container(
        width: isSmallScreen ? 50 : 60,
        height: isSmallScreen ? 50 : 60,
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 24,
            color: Colors.white, // Icon color
          ),
        ),
      ),
    );
  }
}

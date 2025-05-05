import 'package:flutter/material.dart';

class SocialLoginButton extends StatelessWidget {
  final String iconPath;
  final VoidCallback onPressed;
  final bool isSmallScreen;

  const SocialLoginButton({
    Key? key,
    required this.iconPath,
    required this.onPressed,
    required this.isSmallScreen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF1F222A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Image.asset(
            iconPath,
            width: 24,
            height: 24,
            errorBuilder: (context, error, stackTrace) {
              // Return a placeholder icon if image fails to load
              return const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 24,
              );
            },
          ),
        ),
      ),
    );
  }
}

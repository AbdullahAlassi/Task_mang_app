import 'package:flutter/material.dart';

class InputField extends StatelessWidget {
  final IconData icon;
  final String hintText;
  final TextInputType keyboardType;
  final bool isSmallScreen;

  const InputField({
    Key? key,
    required this.icon,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.isSmallScreen = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Icon(icon, color: const Color(0xFF8E8E93), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              keyboardType: keyboardType,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Inter',
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
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
        ],
      ),
    );
  }
}

import 'user_model.dart';
import 'package:flutter/foundation.dart';

class ProjectMember {
  final String userId;
  final String role;
  final User user;
  final DateTime joinedAt;
  final User? invitedBy;

  ProjectMember({
    required this.userId,
    required this.role,
    required this.user,
    required this.joinedAt,
    this.invitedBy,
  });

  factory ProjectMember.fromJson(Map<String, dynamic> json) {
    debugPrint('🔍 [ProjectMember.fromJson] Raw JSON: $json');

    // Check if userId is an object or string

    String userId = '';
    User user;

    final userJson = json['userId'];
    if (userJson is Map<String, dynamic>) {
      user = User.fromJson(userJson);
      userId = user.id; // This is extracted from inside the User model
    } else if (userJson is String) {
      userId = userJson;
      final fallbackUser = json['user'];
      if (fallbackUser is Map<String, dynamic>) {
        user = User.fromJson(fallbackUser);
      } else {
        user = User(
          id: userId,
          name: 'Unknown',
          email: 'unknown@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
    } else {
      throw Exception('Invalid format for userId: $userJson');
    }

    return ProjectMember(
      userId: userId,
      user: user,
      role: json['role'] ?? 'member',
      joinedAt:
          DateTime.parse(json['joinedAt'] ?? DateTime.now().toIso8601String()),
      invitedBy:
          json['invitedBy'] != null ? User.fromJson(json['invitedBy']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'role': role,
      'user': user.toJson(),
      'joinedAt': joinedAt.toIso8601String(),
      'invitedBy': invitedBy?.toJson(),
    };
  }
}

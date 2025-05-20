import 'package:flutter/material.dart';
import 'user_model.dart';
import '../services/auth_service.dart';

class Project {
  final String id;
  final String title;
  final String description;
  final DateTime? deadline;
  final String managerId;
  final User manager;
  final List<ProjectMember> members;
  final String color;
  final String type;
  final String? teamId;
  final String? teamName;
  final String status;
  final int progress;
  final int totalTasks;
  final int completedTasks;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> boardIds;

  Project({
    required this.id,
    required this.title,
    required this.description,
    this.deadline,
    required this.managerId,
    required this.manager,
    required this.members,
    required this.color,
    required this.type,
    this.teamId,
    this.teamName,
    required this.status,
    required this.progress,
    required this.totalTasks,
    required this.completedTasks,
    required this.createdAt,
    required this.updatedAt,
    this.boardIds = const [],
  });

  // Get the status based on progress
  String getStatusBasedOnProgress() {
    if (progress >= 100) {
      return 'Completed';
    } else if (progress > 0) {
      return 'In Progress';
    } else {
      return 'To Do';
    }
  }

  // Get the current user's role in the project
  Future<String> getCurrentUserRole() async {
    final currentUserId = await AuthService().getCurrentUserId();
    if (currentUserId == managerId) return 'owner';
    final member = members.firstWhere(
      (m) => m.userId == currentUserId,
      orElse: () => ProjectMember(
        userId: '',
        role: 'viewer',
        user: User(
          id: '',
          name: '',
          email: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        joinedAt: DateTime.now(),
      ),
    );
    print('[DEBUG] currentUserRole for user $currentUserId: ${member.role}');
    return member.role;
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    print('\n=== [Project.fromJson] Starting JSON Parsing ===');
    print('Raw JSON: $json');

    // Parse manager
    print('\n=== Parsing Manager ===');
    final managerJson = json['manager'] as Map<String, dynamic>?;
    print('Manager JSON: $managerJson');
    final manager = User.fromJson(managerJson ?? {});
    print('Parsed Manager: ${manager.name} (${manager.id})');

    // Parse members
    print('\n=== Parsing Members ===');
    final membersJson = json['members'] as List<dynamic>?;
    print('Members JSON: $membersJson');

    List<ProjectMember> members = [];
    if (membersJson != null) {
      try {
        members = membersJson.map<ProjectMember>((memberJson) {
          print('\nProcessing member: $memberJson');
          if (memberJson is Map<String, dynamic>) {
            // If memberJson is a full user object
            if (memberJson.containsKey('_id') &&
                !memberJson.containsKey('userId')) {
              print('Member is a full user object');
              return ProjectMember(
                userId: memberJson['_id'] ?? '',
                user: User.fromJson(memberJson),
                role: 'member',
                joinedAt: DateTime.now(),
              );
            }
            // If memberJson is a ProjectMember object
            print('Member is a ProjectMember object');
            return ProjectMember.fromJson(memberJson);
          } else if (memberJson is String) {
            // If memberJson is just a user ID
            print('Member is a String (ID)');
            return ProjectMember(
              userId: memberJson,
              user: User(
                id: memberJson,
                name: '',
                email: '',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
              role: 'member',
              joinedAt: DateTime.now(),
            );
          }
          print('Member is neither Map nor String, skipping');
          throw Exception('Unexpected member type: ${memberJson.runtimeType}');
        }).toList();
      } catch (e) {
        print('Error parsing members list: $e');
        members = []; // Reset to empty list on error
      }
    }
    print('Parsed ${members.length} members');

    // Parse board IDs
    print('\n=== Parsing Board IDs ===');
    final boardIds = (json['boards'] as List<dynamic>?)
            ?.map((board) {
              print('Processing board: $board');
              if (board is String) {
                print('Board is a String, using as ID');
                return board;
              }
              if (board is Map) {
                print('Board is a Map, extracting ID');
                return board['_id'] ?? '';
              }
              print('Board is neither String nor Map, skipping');
              return '';
            })
            .where((id) => id.isNotEmpty)
            .toList()
            .cast<String>() ??
        [];
    print('Parsed ${boardIds.length} board IDs');

    print('\n=== Creating Project Object ===');
    final project = Project(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      deadline:
          json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      managerId: json['manager']?['_id'] ?? '',
      manager: manager,
      members: members,
      color: json['color'] ?? '#6B4EFF',
      type: json['type'] ?? 'personal',
      teamId: json['team'] is Map<String, dynamic> ? json['team']['_id'] : null,
      teamName:
          json['team'] is Map<String, dynamic> ? json['team']['name'] : null,
      status: json['status'] ?? 'To Do',
      progress: json['progress']?.toInt() ?? 0,
      totalTasks: json['totalTasks']?.toInt() ?? 0,
      completedTasks: json['completedTasks']?.toInt() ?? 0,
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      boardIds: boardIds,
    );

    print('\n=== Project Object Created ===');
    print('Project ID: ${project.id}');
    print('Project Title: ${project.title}');
    print('Project Type: ${project.type}');
    print('Project Team ID: ${project.teamId}');
    print('Project Team Name: ${project.teamName}');
    print('Project Members Count: ${project.members.length}');
    print('Project Board IDs Count: ${project.boardIds.length}');

    return project;
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'deadline': deadline?.toIso8601String(),
      'manager': manager.toJson(),
      'members': members.map((m) => m.toJson()).toList(),
      'color': color,
      'type': type,
      'team': teamId,
      'status': status,
      'progress': progress,
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'boards': boardIds,
    };
  }

  // Get color based on project ID for consistent coloring
  Color getBannerColor() {
    try {
      return Color(int.parse(color.replaceAll('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF6B4EFF); // Default purple color
    }
  }

  // Get member IDs from members list
  List<String> get memberIds => members.map((m) => m.userId).toList();
}

class ProjectMember {
  final String userId;
  final User user;
  final String role;
  final DateTime joinedAt;

  ProjectMember({
    required this.userId,
    required this.user,
    required this.role,
    required this.joinedAt,
  });

  factory ProjectMember.fromJson(Map<String, dynamic> json) {
    print('Parsing project member JSON: $json');

    // Handle both cases where userId could be a string or an object
    String userId;
    User user;

    if (json['userId'] is Map<String, dynamic>) {
      // If userId is an object, use it directly
      final userJson = json['userId'] as Map<String, dynamic>;
      userId = userJson['_id'] ?? '';
      user = User.fromJson(userJson);
    } else {
      // If userId is a string, use the entire json as user data
      userId = json['_id'] ?? '';
      user = User.fromJson(json);
    }

    return ProjectMember(
      userId: userId,
      user: user,
      role: json['role'] ?? 'member',
      joinedAt:
          DateTime.parse(json['joinedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': user.toJson(),
      'role': role,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }
}

// List of colors for project banners
final List<String> projectColors = [
  '#6B4EFF', // Purple
  '#211B4E', // Dark blue
  '#96292B', // Red
  '#808C44', // Olive green
  '#35383F', // Dark gray
];

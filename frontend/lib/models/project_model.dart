import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class Project {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime? deadline;
  final String status;
  final int progress;
  final int totalTasks;
  final int completedTasks;
  final String managerId;
  final List<String> memberIds;
  final List<String> boardIds;
  final String color;

  Project({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    this.deadline,
    required this.status,
    required this.progress,
    required this.totalTasks,
    required this.completedTasks,
    required this.managerId,
    required this.memberIds,
    required this.boardIds,
    required this.color,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    // Calculate progress if not provided
    int progress = json['progress'] ?? 0;
    int totalTasks = json['totalTasks'] ?? 0;
    int completedTasks = json['completedTasks'] ?? 0;

    if (progress == 0 && totalTasks > 0) {
      progress = ((completedTasks / totalTasks) * 100).round();
    }

    return Project(
      id: json['_id'] ?? json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      deadline:
          json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      status: json['status'] ?? 'Not Started',
      progress: progress,
      totalTasks: totalTasks,
      completedTasks: completedTasks,
      managerId: json['manager']?['_id'] ?? json['manager'],
      memberIds: json['members'] != null
          ? List<String>.from(json['members'].map((m) => m['_id'] ?? m))
          : [],
      boardIds: json['boards'] != null
          ? List<String>.from(json['boards'].map((b) => b['_id'] ?? b))
          : [],
      color: json['color'] ?? '#6B4EFF',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'deadline': deadline?.toIso8601String(),
      'status': status,
      'progress': progress,
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
      'manager': managerId,
      'members': memberIds,
      'boards': boardIds,
      'color': color,
    };
  }

  // Get color based on project ID for consistent coloring
  Color getBannerColor() {
    return Color(int.parse(color.replaceAll('#', '0xFF')));
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

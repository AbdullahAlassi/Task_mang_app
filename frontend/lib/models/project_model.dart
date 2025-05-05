import 'package:flutter/material.dart';

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

  factory Project.fromJson(Map<String, dynamic> json) {
    // Calculate progress if not provided
    int progress = json['progress'] is int ? json['progress'] : 0;
    int totalTasks = json['totalTasks'] is int ? json['totalTasks'] : 0;
    int completedTasks =
        json['completedTasks'] is int ? json['completedTasks'] : 0;

    if (progress == 0 && totalTasks > 0) {
      progress = ((completedTasks / totalTasks) * 100).round();
    }

    // Get status based on progress
    String status = json['status'] ?? 'To Do';
    if (progress >= 100) {
      status = 'Completed';
    } else if (progress > 0) {
      status = 'In Progress';
    } else {
      status = 'To Do';
    }

    // Handle boards field
    List<String> boardIds = [];
    if (json['boards'] != null && json['boards'] is List) {
      boardIds = (json['boards'] as List)
          .map((b) {
            if (b is String) {
              return b;
            } else if (b is Map) {
              return b['_id'] ?? b['id'] ?? '';
            }
            return '';
          })
          .where((id) => id.isNotEmpty)
          .cast<String>()
          .toList();
    }

    // Handle members field
    List<String> memberIds = [];
    if (json['members'] != null && json['members'] is List) {
      memberIds = (json['members'] as List)
          .map((m) {
            if (m is String) {
              return m;
            } else if (m is Map) {
              return m['_id'] ?? m['id'] ?? '';
            }
            return '';
          })
          .where((id) => id.isNotEmpty)
          .cast<String>()
          .toList();
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
      status: status,
      progress: progress,
      totalTasks: totalTasks,
      completedTasks: completedTasks,
      managerId: json['manager'] is String
          ? json['manager']
          : (json['manager']?['_id'] ?? json['manager']),
      memberIds: memberIds,
      boardIds: boardIds,
      color: json['color'] ?? '#6B4EFF',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'deadline': deadline?.toIso8601String(),
      'status': getStatusBasedOnProgress(), // Use the calculated status
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

import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final String status;
  final DateTime? deadline;
  final bool isCompleted;
  final String boardId; // This corresponds to the board ID
  final List<String> assignedTo;
  final Color? color;
  final String projectId;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.deadline,
    required this.isCompleted,
    required this.boardId,
    required this.assignedTo,
    this.color,
    required this.projectId,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    print('=== Parsing Task from JSON ===');
    print('Raw JSON: $json');

    Color? color;
    if (json['color'] != null) {
      print('Color value in JSON: ${json['color']}');
      try {
        // Handle hex color string (e.g., "#6B4EFF")
        if (json['color'] is String) {
          final hexColor = json['color'] as String;
          print('Parsing hex color: $hexColor');
          if (hexColor.startsWith('#')) {
            color = Color(int.parse(hexColor.replaceAll('#', '0xFF')));
            print('Parsed color value: ${color.value}');
          }
        }
        // Handle integer color value
        else if (json['color'] is int) {
          color = Color(json['color'] as int);
          print('Parsed integer color value: ${color.value}');
        }
      } catch (e) {
        print('Error parsing color: $e');
        color = null;
      }
    } else {
      print('No color value in JSON');
    }

    // Extract project ID from board object
    String projectId = '';
    if (json['board'] != null) {
      if (json['board'] is Map) {
        if (json['board']['project'] != null) {
          if (json['board']['project'] is Map) {
            projectId = json['board']['project']['_id'] ?? '';
          } else if (json['board']['project'] is String) {
            projectId = json['board']['project'];
          }
        }
      } else if (json['board'] is String) {
        // If board is a string, it might be the project ID itself
        projectId = json['board'];
      }
    }

    return Task(
      id: json['_id'] ?? json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      status: json['status'] ?? 'To Do',
      deadline:
          json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      isCompleted: json['status'] == 'Done',
      boardId:
          json['board'] is Map ? json['board']['_id'] : json['board'] ?? '',
      assignedTo: json['assignedTo'] != null
          ? (json['assignedTo'] as List)
              .map((a) => a is String ? a : a['_id'] ?? a['id'] ?? '')
              .where((id) => id.isNotEmpty)
              .cast<String>()
              .toList()
          : [],
      color: color,
      projectId: projectId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'deadline': deadline?.toIso8601String(),
      'board': boardId,
      'assignedTo': assignedTo,
      'color': color != null
          ? '#${color!.value.toRadixString(16).substring(2)}'
          : null,
      'project': projectId,
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? status,
    DateTime? deadline,
    bool? isCompleted,
    String? boardId,
    List<String>? assignedTo,
    Color? color,
    String? projectId,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      deadline: deadline ?? this.deadline,
      isCompleted: isCompleted ?? this.isCompleted,
      boardId: boardId ?? this.boardId,
      assignedTo: assignedTo ?? this.assignedTo,
      color: color ?? this.color,
      projectId: projectId ?? this.projectId,
    );
  }

  // Get color based on task status
  Color getStatusColor() {
    switch (status) {
      case 'To Do' || 'To-do':
        return AppColors.statusTodo;
      case 'In Progress':
        return AppColors.statusInProgress;
      case 'Done':
        return AppColors.statusDone;
      default:
        return AppColors.secondaryTextColor;
    }
  }

  // Get priority level (can be extended based on your requirements)
  String getPriority() {
    // This is a placeholder. In a real app, you might have a priority field
    if (deadline != null) {
      final daysLeft = deadline!.difference(DateTime.now()).inDays;
      if (daysLeft < 2) return 'High';
      if (daysLeft < 5) return 'Medium';
      return 'Low';
    }
    return 'Medium';
  }

  // Get priority color
  Color getPriorityColor() {
    final priority = getPriority();
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return AppColors.secondaryTextColor;
    }
  }

  // Check if task is overdue
  bool isOverdue() {
    if (deadline == null) return false;
    return deadline!.isBefore(DateTime.now()) && !isCompleted;
  }
}

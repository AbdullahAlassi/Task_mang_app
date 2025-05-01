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
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    // Handle nested board object
    final board = json['board'];
    final boardId = board is Map ? board['_id'] : board;

    return Task(
      id: json['_id'] ?? json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      status: json['status'],
      deadline:
          json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      isCompleted: json['status'] == 'Done',
      boardId: boardId,
      assignedTo: json['assignedTo'] != null
          ? (json['assignedTo'] as List)
              .map((a) => a is String ? a : a['_id'] ?? a['id'] ?? '')
              .where((id) => id.isNotEmpty)
              .cast<String>()
              .toList()
          : [],
      color: json['color'] != null
          ? Color(int.parse(json['color'], radix: 16))
          : null,
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
      'color': color?.value.toRadixString(16),
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
    );
  }

  // Get color based on task status
  Color getStatusColor() {
    switch (status) {
      case 'To Do':
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

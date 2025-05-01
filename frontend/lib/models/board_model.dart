import 'package:flutter/material.dart';
import 'task_model.dart';

class Board {
  final String id;
  final String title;
  final String type; // New field for board type
  final DateTime? deadline;
  final List<String> assignedTo;
  final List<Task> tasks;
  final int commentCount;
  final String projectId; // Add projectId field

  Board({
    required this.id,
    required this.title,
    required this.type, // Required type field
    this.deadline,
    required this.assignedTo,
    required this.tasks,
    this.commentCount = 0,
    required this.projectId, // Add projectId to constructor
  });

  factory Board.fromJson(Map<String, dynamic> json) {
    return Board(
      id: json['_id'] ?? json['id'],
      title: json['title'],
      type: json['type'] ?? 'Other', // Default to 'Other' if not specified
      deadline:
          json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      assignedTo: json['assignedTo'] != null
          ? List<String>.from(json['assignedTo'])
          : [],
      tasks: json['tasks'] != null
          ? List<Task>.from(json['tasks'].map((task) => Task.fromJson(task)))
          : [],
      commentCount: json['commentCount'] ?? 0,
      projectId:
          json['project'] ?? json['projectId'], // Add projectId from JSON
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type:': type,
      'deadline': deadline?.toIso8601String(),
      'assignedTo': assignedTo,
      'tasks': tasks.map((task) => task.toJson()).toList(),
      'commentCount': commentCount,
      'projectId': projectId, // Add projectId to JSON
    };
  }

  Board copyWith({
    String? id,
    String? title,
    String? type,
    DateTime? deadline,
    List<String>? assignedTo,
    List<Task>? tasks,
    int? commentCount,
    String? projectId, // Add projectId to copyWith
  }) {
    return Board(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      deadline: deadline ?? this.deadline,
      assignedTo: assignedTo ?? this.assignedTo,
      tasks: tasks ?? this.tasks,
      commentCount: commentCount ?? this.commentCount,
      projectId: projectId ?? this.projectId, // Add projectId to copyWith
    );
  }

  // Get color based on board type
  Color getBoardTypeColor() {
    switch (type) {
      case 'To-do':
        return Colors.blue;
      case 'In Progress':
        return Colors.orange;
      case 'Done':
        return Colors.green;
      default:
        return Colors.purple;
    }
  }
}

class KanbanColumn {
  final String id;
  final String title;
  final String type; // Add type field to match with boards
  final List<Board> boards;

  KanbanColumn({
    required this.id,
    required this.title,
    required this.type,
    required this.boards,
  });

  KanbanColumn copyWith({
    String? id,
    String? title,
    String? type,
    List<Board>? boards,
  }) {
    return KanbanColumn(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      boards: boards ?? this.boards,
    );
  }
}

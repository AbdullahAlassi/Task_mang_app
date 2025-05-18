import 'package:flutter/material.dart';
import 'task_model.dart';

class Board {
  final String id;
  final String title;
  final String project; // Add project field
  final List<String> members;
  final List<Task> tasks; // Changed from List<String> to List<Task>
  final String status;
  final int commentCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deadline; // Add deadline field
  final String type; // Add type field
  final List<String> assignedTo; // Add assignedTo field

  // Add projectId getter
  String get projectId => project;

  Board({
    required this.id,
    required this.title,
    required this.project, // Add project parameter
    required this.members,
    required this.tasks,
    required this.status,
    required this.commentCount,
    required this.createdAt,
    required this.updatedAt,
    this.deadline, // Add deadline parameter
    required this.type, // Add type parameter
    required this.assignedTo, // Add to constructor
  });

  factory Board.fromJson(Map<String, dynamic> json) {
    return Board(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      project: json['project'] ?? '',
      members: List<String>.from(json['members'] ?? []),
      tasks: (json['tasks'] as List<dynamic>?)
              ?.map((task) => Task.fromJson(task))
              .toList() ??
          [],
      status: json['status'] ?? 'To Do',
      commentCount: json['commentCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      deadline:
          json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      type: json['type'] ?? json['status'] ?? 'To Do',
      assignedTo: List<String>.from(json['assignedTo'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'project': project, // Include project in JSON
      'members': members,
      'tasks': tasks
          .map((task) => task.toJson())
          .toList(), // Updated to convert Task objects to JSON
      'status': status,
      'commentCount': commentCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deadline': deadline?.toIso8601String(), // Include deadline in JSON
      'type': type,
      'assignedTo': assignedTo, // Add to toJson
    };
  }

  Board copyWith({
    String? id,
    String? title,
    String? project,
    List<String>? members,
    List<Task>? tasks, // Updated type
    String? status,
    int? commentCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deadline,
    String? type,
    List<String>? assignedTo,
  }) {
    return Board(
      id: id ?? this.id,
      title: title ?? this.title,
      project: project ?? this.project,
      members: members ?? this.members,
      tasks: tasks ?? this.tasks,
      status: status ?? this.status,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deadline: deadline ?? this.deadline,
      type: type ?? this.type,
      assignedTo: assignedTo ?? this.assignedTo,
    );
  }

  // Get color based on board type
  Color getBoardTypeColor() {
    switch (status) {
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

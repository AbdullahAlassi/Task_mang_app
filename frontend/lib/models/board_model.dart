import 'package:flutter/material.dart';
import 'task_model.dart';

class Board {
  final String id;
  final String title;
  final DateTime? deadline;
  final List<String> assignedTo;
  final List<Task> tasks;
  final int commentCount;

  Board({
    required this.id,
    required this.title,
    this.deadline,
    required this.assignedTo,
    required this.tasks,
    this.commentCount = 0,
  });

  factory Board.fromJson(Map<String, dynamic> json) {
    return Board(
      id: json['_id'] ?? json['id'],
      title: json['title'],
      deadline:
          json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      assignedTo: json['assignedTo'] != null
          ? List<String>.from(json['assignedTo'])
          : [],
      tasks: json['tasks'] != null
          ? List<Task>.from(json['tasks'].map((task) => Task.fromJson(task)))
          : [],
      commentCount: json['commentCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'deadline': deadline?.toIso8601String(),
      'assignedTo': assignedTo,
      'tasks': tasks.map((task) => task.toJson()).toList(),
      'commentCount': commentCount,
    };
  }

  Board copyWith({
    String? id,
    String? title,
    DateTime? deadline,
    List<String>? assignedTo,
    List<Task>? tasks,
    int? commentCount,
  }) {
    return Board(
      id: id ?? this.id,
      title: title ?? this.title,
      deadline: deadline ?? this.deadline,
      assignedTo: assignedTo ?? this.assignedTo,
      tasks: tasks ?? this.tasks,
      commentCount: commentCount ?? this.commentCount,
    );
  }
}

class KanbanColumn {
  final String id;
  final String title;
  final List<Board> boards;

  KanbanColumn({
    required this.id,
    required this.title,
    required this.boards,
  });

  KanbanColumn copyWith({
    String? id,
    String? title,
    List<Board>? boards,
  }) {
    return KanbanColumn(
      id: id ?? this.id,
      title: title ?? this.title,
      boards: boards ?? this.boards,
    );
  }
}

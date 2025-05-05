import 'board_model.dart';

enum ProjectStatus {
  all,
  todo,
  inProgress,
  completed,
  archived,
}

extension ProjectStatusExtension on ProjectStatus {
  String get name {
    switch (this) {
      case ProjectStatus.all:
        return 'All';
      case ProjectStatus.todo:
        return 'To Do';
      case ProjectStatus.inProgress:
        return 'In Progress';
      case ProjectStatus.completed:
        return 'Completed';
      case ProjectStatus.archived:
        return 'Archived';
    }
  }
}

class Project {
  final String id;
  final String title;
  final String description;
  final DateTime? deadline;
  final List<String> members;
  final int progress;
  final int totalTasks;
  final int completedTasks;
  final List<Board> boards;
  final String color;
  final String status;

  Project({
    required this.id,
    required this.title,
    required this.description,
    this.deadline,
    required this.members,
    required this.progress,
    required this.totalTasks,
    required this.completedTasks,
    required this.boards,
    required this.color,
    required this.status,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    print('Creating Project from JSON: $json'); // Debug print
    return Project(
      id: json['_id'],
      title: json['title'],
      description: json['description'],
      deadline:
          json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      members: List<String>.from(json['members']),
      progress: json['progress'] ?? 0,
      totalTasks: json['totalTasks'] ?? 0,
      completedTasks: json['completedTasks'] ?? 0,
      boards: (json['boards'] as List<dynamic>?)
              ?.map((board) => Board.fromJson(board))
              .toList() ??
          [],
      color: json['color'] ?? '#6B4EFF', // Default color if not provided
      status: json['status'] ?? 'To Do',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'deadline': deadline?.toIso8601String(),
      'members': members,
      'progress': progress,
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
      'boards': boards.map((board) => board.toJson()).toList(),
      'color': color,
      'status': status,
    };
  }
}

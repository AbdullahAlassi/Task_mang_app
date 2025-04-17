class Project {
  final String title;
  final DateTime createdAt;
  final double progress;
  final int totalTasks;
  final DateTime? deadline;

  Project({
    required this.title,
    required this.createdAt,
    required this.progress,
    required this.totalTasks,
    this.deadline,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      title: json['title'],
      createdAt: DateTime.parse(json['createdAt']),
      progress: json['progress'].toDouble(),
      totalTasks: json['totalTasks'],
      deadline:
          json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
    );
  }
}

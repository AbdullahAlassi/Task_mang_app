class Task {
  final String title;
  final bool isCompleted;

  const Task({required this.title, this.isCompleted = false});

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      title: json['title'],
      isCompleted: json['isCompleted'],
    );
  }
}

enum ProjectStatus { todo, inProgress, completed, archived }

extension ProjectStatusExtension on ProjectStatus {
  String get name {
    switch (this) {
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

  String get apiValue {
    switch (this) {
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

  static ProjectStatus fromString(String status) {
    switch (status) {
      case 'To Do':
        return ProjectStatus.todo;
      case 'In Progress':
        return ProjectStatus.inProgress;
      case 'Completed':
        return ProjectStatus.completed;
      case 'Archived':
        return ProjectStatus.archived;
      default:
        return ProjectStatus.todo;
    }
  }
}

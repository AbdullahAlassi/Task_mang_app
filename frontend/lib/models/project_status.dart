enum ProjectStatus { todo, inProgress, completed, archived }

extension ProjectStatusExtension on ProjectStatus {
  String get name {
    switch (this) {
      case ProjectStatus.todo:
        return 'To-Do';
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
        return 'Not Started';
      case ProjectStatus.inProgress:
        return 'In Progress';
      case ProjectStatus.completed:
        return 'Completed';
      case ProjectStatus.archived:
        return 'Archived';
    }
  }
}

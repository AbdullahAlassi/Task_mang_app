enum ProjectRole { owner, admin, member, viewer }

class ProjectPermissions {
  static final Map<ProjectRole, List<String>> rolePermissions = {
    ProjectRole.owner: [
      'view',
      'create',
      'edit',
      'delete',
      'assign_roles',
      'invite_members',
      'remove_members',
      'manage_boards',
      'manage_tasks',
      'delete_project',
      'update_project_settings',
    ],
    ProjectRole.admin: [
      'view',
      'create',
      'edit',
      'invite_members',
      'remove_members',
      'manage_boards',
      'manage_tasks',
      'update_project_details',
      'assign_roles',
    ],
    ProjectRole.member: [
      'view',
      'create_tasks',
      'edit_own_tasks',
      'comment_tasks',
      'update_tasks',
    ],
    ProjectRole.viewer: ['view'],
  };

  static ProjectRole standardizeRole(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return ProjectRole.owner;
      case 'admin':
        return ProjectRole.admin;
      case 'member':
        return ProjectRole.member;
      case 'viewer':
        return ProjectRole.viewer;
      default:
        return ProjectRole.viewer;
    }
  }

  static bool canModifyRole(ProjectRole currentRole, ProjectRole targetRole) {
    final roleHierarchy = {
      ProjectRole.owner: [
        ProjectRole.admin,
        ProjectRole.member,
        ProjectRole.viewer,
      ],
      ProjectRole.admin: [
        ProjectRole.admin,
        ProjectRole.member,
        ProjectRole.viewer,
      ],
      ProjectRole.member: [],
      ProjectRole.viewer: [],
    };
    return roleHierarchy[currentRole]?.contains(targetRole) ?? false;
  }

  static bool canManageMember(ProjectRole currentRole, ProjectRole targetRole) {
    final roleHierarchy = {
      ProjectRole.owner: [
        ProjectRole.admin,
        ProjectRole.member,
        ProjectRole.viewer,
      ],
      ProjectRole.admin: [
        ProjectRole.admin,
        ProjectRole.member,
        ProjectRole.viewer,
      ],
      ProjectRole.member: [],
      ProjectRole.viewer: [],
    };
    return roleHierarchy[currentRole]?.contains(targetRole) ?? false;
  }

  static bool canManageProject(ProjectRole role) {
    return role == ProjectRole.owner || role == ProjectRole.admin;
  }

  static bool canManageBoards(ProjectRole role) {
    return role == ProjectRole.owner || role == ProjectRole.admin;
  }

  static bool canManageTasks(ProjectRole role) {
    return role == ProjectRole.owner || role == ProjectRole.admin;
  }

  static bool canCreateTasks(ProjectRole role) {
    return role == ProjectRole.owner ||
        role == ProjectRole.admin ||
        role == ProjectRole.member;
  }

  static bool canEditTasks(ProjectRole role) {
    return role == ProjectRole.owner ||
        role == ProjectRole.admin ||
        role == ProjectRole.member;
  }

  static bool canDeleteTasks(ProjectRole role) {
    return role == ProjectRole.owner || role == ProjectRole.admin;
  }

  static bool canCommentTasks(ProjectRole role) {
    return role == ProjectRole.owner ||
        role == ProjectRole.admin ||
        role == ProjectRole.member;
  }

  static bool canDeleteProject(ProjectRole role) {
    return role == ProjectRole.owner;
  }

  static bool hasPermission(ProjectRole role, String permission) {
    return rolePermissions[role]?.contains(permission) ?? false;
  }
}

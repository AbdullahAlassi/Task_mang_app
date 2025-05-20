const rolePermissions = {
  owner: ['create', 'edit', 'delete', 'assign_roles', 'invite_members', 'view', 'manage_tasks', 'manage_boards'],
  admin: ['create', 'edit', 'invite_members', 'view', 'manage_tasks', 'manage_boards'],
  member: ['create', 'edit_own', 'view','manage_tasks'],
  viewer: ['view']
};

const roleMapping = {
  'Admin': 'admin',
  'Member': 'member',
  'Viewer': 'viewer',
  'Owner': 'owner'
};

const standardizeRole = (role) => {
  if (!role) return 'viewer';
  return roleMapping[role] || role.toLowerCase();
};

const canPerformAction = (role, action) => {
  const permissions = rolePermissions[standardizeRole(role)] || [];
  return permissions.includes(action);
};

const getRoleHierarchy = (role) => {
  const hierarchy = {
    owner: ['owner', 'admin', 'member', 'viewer'],
    admin: ['admin', 'member', 'viewer'],
    member: ['member', 'viewer'],
    viewer: ['viewer']
  };
  return hierarchy[standardizeRole(role)] || ['viewer'];
};

const canModifyRole = (currentRole, targetRole) => {
  const hierarchy = getRoleHierarchy(currentRole);
  return hierarchy.includes(standardizeRole(targetRole));
};

module.exports = {
  rolePermissions,
  roleMapping,
  standardizeRole,
  canPerformAction,
  getRoleHierarchy,
  canModifyRole
}; 
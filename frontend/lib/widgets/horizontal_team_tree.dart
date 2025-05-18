import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../models/team_model.dart';
import '../../screens/teams/team_form_screen.dart';
import '../../screens/teams/team_members_screen.dart';
import '../../widgets/add_sub_team_dialog.dart';
import '../../screens/teams/team_hierarchy_screen.dart';

class HorizontalTeamTree extends StatelessWidget {
  final List<Team> teams;
  final Team? selectedTeam;
  final Function(Team) onTeamSelected;
  final Map<String, int> teamTaskCounts;
  final VoidCallback onDataChanged;

  const HorizontalTeamTree({
    Key? key,
    required this.teams,
    required this.selectedTeam,
    required this.onTeamSelected,
    required this.teamTaskCounts,
    required this.onDataChanged,
  }) : super(key: key);

  List<Team> _getChildren(String? parentId) {
    return teams.where((t) => t.parentId == parentId).toList();
  }

  List<Team> _getSelectedPath(Team? selected) {
    if (selected == null) return [];
    List<Team> path = [selected];
    while (path.first.parentId != null) {
      final parentCandidates = teams.where((t) => t.id == path.first.parentId);
      final parent = parentCandidates.isEmpty ? null : parentCandidates.first;
      if (parent == null) break;
      path.insert(0, parent);
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final parentTeams = _getChildren(null);
    final selectedPath = _getSelectedPath(selectedTeam);
    List<Widget> columns = [];

    // Add parent teams column
    columns.add(_buildColumn(
      context: context,
      header: 'Parent Teams',
      teams: parentTeams,
      selectedId: selectedPath.isNotEmpty ? selectedPath[0].id : null,
      onTap: onTeamSelected,
      selectedPath: selectedPath,
      teamTaskCounts: teamTaskCounts,
    ));

    // Add columns for each level in the selected path
    for (int i = 0; i < selectedPath.length; i++) {
      final parent = selectedPath[i];
      final subteams = _getChildren(parent.id);
      if (subteams.isNotEmpty) {
        columns.add(_buildColumn(
          context: context,
          header: i == 0 ? 'Level 2' : 'Level ${i + 2}',
          teams: subteams,
          selectedId:
              (i + 1 < selectedPath.length) ? selectedPath[i + 1].id : null,
          onTap: onTeamSelected,
          selectedPath: selectedPath,
          teamTaskCounts: teamTaskCounts,
        ));
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: columns,
      ),
    );
  }

  Widget _buildColumn({
    required BuildContext context,
    required String header,
    required List<Team> teams,
    required String? selectedId,
    required Function(Team) onTap,
    required List<Team> selectedPath,
    required Map<String, int> teamTaskCounts,
  }) {
    return Container(
      width: 200,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              header,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          ...teams.map((team) {
            final isSelected = selectedId == team.id;
            final isInPath = selectedPath.any((t) => t.id == team.id);
            return Card(
              color: isSelected
                  ? AppColors.primaryColor.withOpacity(0.3)
                  : isInPath
                      ? AppColors.primaryColor.withOpacity(0.12)
                      : AppColors.cardColor,
              elevation: isSelected
                  ? 6
                  : isInPath
                      ? 4
                      : 2,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: Icon(
                  team.parentId == null ? Icons.apartment : Icons.group,
                  color: AppColors.primaryColor,
                ),
                title: Text(
                  team.name,
                  style: TextStyle(
                    color: AppColors.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (teamTaskCounts[team.id] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${teamTaskCounts[team.id]}',
                          style: const TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        color: AppColors.secondaryTextColor,
                      ),
                      onSelected: (value) =>
                          _handleTeamAction(context, value, team),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'subteam',
                          child: ListTile(
                            leading:
                                Icon(Icons.add, color: AppColors.primaryColor),
                            title: Text('Create Sub-Team'),
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading:
                                Icon(Icons.edit, color: AppColors.primaryColor),
                            title: Text('Edit'),
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete, color: Colors.red),
                            title: Text('Delete'),
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'manage',
                          child: ListTile(
                            leading: Icon(Icons.people,
                                color: AppColors.primaryColor),
                            title: Text('Manage Members'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                onTap: () => onTap(team),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _handleTeamAction(BuildContext context, String action, Team team) async {
    switch (action) {
      case 'edit':
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => TeamFormScreen(team: team),
          ),
        );
        if (result == true && context.mounted) {
          onDataChanged();
        }
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Delete Team'),
            content: const Text(
              'Are you sure you want to delete this team? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
        if (confirm == true && context.mounted) {
          onDataChanged();
        }
        break;
      case 'manage':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TeamMembersScreen(team: team),
          ),
        );
        if (context.mounted) {
          onDataChanged();
        }
        break;
      case 'subteam':
        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AddSubTeamDialog(
            parentTeam: team,
            onTeamCreated: onDataChanged,
          ),
        );
        if (result == true && context.mounted) {
          onDataChanged();
        }
        break;
    }
  }
}

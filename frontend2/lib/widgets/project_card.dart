import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_colors.dart';
import '../models/project_model.dart';

class ProjectCard extends StatelessWidget {
  final Project project;

  const ProjectCard({Key? key, required this.project}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progress = project.progress / 100;
    final completedTasks = (project.totalTasks * progress).round();

    return Container(
      width: MediaQuery.of(context).size.width - 32,
      margin: const EdgeInsets.only(right: 16, bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project banner
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.projectPurple, // Purple color from the design
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.more_horiz,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        // Show project options
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Project details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Project title and date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${project.title} - (${DateFormat('MMM d, yyyy').format(project.createdAt)})',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Progress indicators
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Task count indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryCardColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$completedTasks / ${project.totalTasks}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Deadline
                    Row(
                      children: [
                        const Text(
                          'Deadline: ',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.secondaryTextColor,
                          ),
                        ),
                        Text(
                          project.deadline != null
                              ? DateFormat('MMM d').format(project.deadline!)
                              : 'None',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Circular progress indicator
                const SizedBox(width: 16),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Stack(
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.secondaryCardColor,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.projectPurple,
                        ),
                        strokeWidth: 5,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

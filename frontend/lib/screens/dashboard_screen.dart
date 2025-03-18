import 'package:flutter/material.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/widgets/bottom_navigiation.dart';
import 'package:frontend/widgets/project_card.dart';
import 'package:frontend/widgets/search_bar.dart';
import 'package:frontend/widgets/task_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1C1C1E),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      const SearchBarWidget(),
                      const SizedBox(height: 24),
                      _buildSectionHeader('Recent Project', onSeeAllTap: () {}),
                      const SizedBox(height: 16),
                      ProjectCard(
                        title: 'Project 1',
                        date: 'Project 1 - (Date)',
                        progress: '50 / 90',
                        onMoreTap: () {},
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader('Ongoing Tasks', onSeeAllTap: () {}),
                      const SizedBox(height: 16),
                      _buildTasksGrid(),
                    ],
                  ),
                ),
              ),
            ),

            BottomNavigation(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.grid_view, size: 24, color: AppColors.accent),
            const SizedBox(width: 8),
            Text(
              'DASHBOARD',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
        Icon(Icons.account_circle, size: 24, color: AppColors.accent),
      ],
    );
  }

  Widget _buildSectionHeader(
    String title, {
    required VoidCallback onSeeAllTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        GestureDetector(
          onTap: onSeeAllTap,
          child: Text(
            'See All',
            style: TextStyle(color: AppColors.accent, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildTasksGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(
        4,
        (index) => TaskCard(
          taskName: 'Task Name',
          dateTime: 'Date & Time',
          onCheckChanged: (value) {},
        ),
      ),
    );
  }
}

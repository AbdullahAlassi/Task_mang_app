import 'package:flutter/material.dart';
import 'package:frontend/screens/profile/edit_profile_screen.dart';
import '../../config/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../dashboard/dashboard_screen.dart';
import '../projects/projects_screen.dart';
import '../calendar/calendar_screen.dart';
import '../teams/team_hierarchy_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  bool _isLoading = true;
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => _isLoading = true);
      final user = await _userService.getCurrentUser();
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load user data: $e')),
        );
      }
    }
  }

  void _navigateToScreen(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProjectsScreen()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CalendarScreen()),
        );
        break;
      case 3:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notifications screen coming soon')),
        );
        break;
    }
  }

  Future<void> _showEditProfileDialog() async {
    if (_user == null) return;

    final nameController = TextEditingController(text: _user!.name);
    final emailController = TextEditingController(text: _user!.email);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditProfileScreen(user: _user!),
    );

    if (result == true) {
      try {
        await _userService.updateProfile({
          'name': nameController.text,
          'email': emailController.text,
        });
        _loadUserData(); // Reload user data
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update profile: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Profile Header
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Profile Avatar
                        const CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey,
                          child: Icon(
                            Icons.person_outline,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // User Name
                        Text(
                          _user?.name ?? 'No Name',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Email
                        Text(
                          _user?.email ?? 'No Email',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Menu Items
                  ListTile(
                    leading: const Icon(Icons.workspace_premium),
                    title: const Text('Workspace'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TeamHierarchyScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.person_outline,
                    title: 'Edit Profile',
                    onTap: _showEditProfileDialog,
                  ),
                  _buildMenuItem(
                    icon: Icons.notifications_none,
                    title: 'Notifications',
                    onTap: () {
                      // Handle notifications tap
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.security,
                    title: 'Security',
                    onTap: () {
                      // Handle security tap
                    },
                  ),
                  const SizedBox(height: 20),
                  // Logout Button
                  _buildMenuItem(
                    icon: Icons.logout,
                    title: 'Logout',
                    isLogout: true,
                    onTap: () async {
                      final authService = AuthService();
                      await authService.logout();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    },
                  ),
                  const Spacer(),
                  // Bottom Navigation Bar
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundColor,
                      border: Border(
                        top: BorderSide(
                          color: Colors.grey.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(Icons.home_outlined, 'Dashboard', false,
                            () => _navigateToScreen(0)),
                        _buildNavItem(Icons.description_outlined, 'Projects',
                            false, () => _navigateToScreen(1)),
                        _buildNavItem(Icons.calendar_today_outlined, 'Calendar',
                            false, () => _navigateToScreen(2)),
                        _buildNavItem(Icons.notifications_none, 'Notifications',
                            false, () => _navigateToScreen(3)),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isLogout ? Colors.red : Colors.white,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? Colors.red : Colors.white,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildNavItem(
      IconData icon, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.blue : Colors.grey,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.blue : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

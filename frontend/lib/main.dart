import 'package:flutter/material.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/screens/auth/signup_screen.dart';
import 'package:frontend/screens/calendar/calendar_screen.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/projects/projects_screen.dart';
import 'screens/projects/create_project_screen.dart';
import 'models/project_model.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authProvider = AuthProvider();
  await authProvider.loadUserFromToken();
  runApp(
    ChangeNotifierProvider.value(
      value: authProvider,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Management App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const SignupScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/projects': (context) => const ProjectsScreen(),
        '/calendar': (context) => const CalendarScreen(),
        '/edit-project': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          return CreateProjectScreen(project: args as Project?);
        },
      },
    );
  }
}

// Base URL for the API
const String baseUrl = 'http://10.0.2.2:3000/api'; // Android emulator localhost

// API endpoints
class ApiEndpoints {
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String profile = '/users/me';
  static const String projects = '/projects';
  static const String tasks = '/tasks';
  static const String boards = '/boards';
}

// Shared Preferences keys
class PreferenceKeys {
  static const String token = 'token';
  static const String userId = 'userId';
  static const String theme = 'theme';
}

// API response messages
class ApiMessages {
  static const String unauthorized = 'Unauthorized access';
  static const String serverError = 'Internal server error';
  static const String networkError = 'Network error occurred';
  static const String invalidCredentials = 'Invalid credentials';
}

class ApiConfig {
  // Use 10.0.2.2 for Android emulator to access host machine's localhost
  //static const String baseUrl = 'http://10.0.2.2:3000/api';
  static const String baseUrl = 'http://localhost:3003/api';

  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String usersEndpoint = '/users';
  static const String userProfileEndpoint = '/users/me';

  // API Messages
  static const String loginSuccess = 'Login successful';
  static const String loginFailed = 'Login failed';
  static const String registerSuccess = 'Registration successful';
  static const String registerFailed = 'Registration failed';
  static const String profileUpdateSuccess = 'Profile updated successfully';
  static const String profileUpdateFailed = 'Failed to update profile';

  // Preference Keys
  static const String tokenKey = 'token';
  static const String userKey = 'user';
}

class ApiConfig {
  static const String baseUrl =
      'http://localhost:3003'; // Change this to your backend URL
  static const int timeout = 30000; // 30 seconds
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  static const String usersEndpoint = '/api/users';
  static const String tokenKey = 'token';
  static const String loginFailed = 'Login failed. Please try again.';
}

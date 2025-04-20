class ApiConstants {
  static const String baseUrl =
      'http://10.0.2.2:3000/api'; // For Android emulator
  // static const String baseUrl = 'http://localhost:5000/api'; // For iOS simulator
  static const String authEndpoint = '/auth';
  static const String registerEndpoint = '$authEndpoint/register';
  static const String loginEndpoint = '$authEndpoint/login';
}

class AssetConstants {
  static const String facebookIcon = 'assets/icons/facebook.png';
  static const String googleIcon = 'assets/icons/google.png';
  static const String appleIcon = 'assets/icons/apple.png';
}

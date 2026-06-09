class AppConstants {
  static const String appName = 'SecondBrain';
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.5:8000/api/v1',
  );
  static const String tokenKey = 'access_token';
  static const String userIdKey = 'user_id';
  static const String nicknameKey = 'nickname';
}

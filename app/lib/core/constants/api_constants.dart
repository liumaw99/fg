class ApiConstants {
  static const String baseUrl = 'http://localhost:8080';
  static const String apiVersion = '/api/v1';

  static String get baseApiUrl => '$baseUrl$apiVersion';

  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/me';

  // User endpoints
  static const String users = '/users';

  // Media endpoints
  static const String media = '/media';

  // Post endpoints
  static const String posts = '/posts';

  // Timeline endpoints
  static const String timeline = '/timeline';

  // WebSocket
  static const String wsUrl = 'ws://localhost:8080/ws/v1/realtime';
}

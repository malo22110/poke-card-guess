class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const String socketBaseUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const String clientUrl = String.fromEnvironment(
    'CLIENT_URL',
    defaultValue: 'http://localhost:8080',
  );
}

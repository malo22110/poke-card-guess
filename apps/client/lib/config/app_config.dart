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

  static const String paypalClientId = String.fromEnvironment(
    'PAYPAL_CLIENT_ID',
    defaultValue: 'sb', // sb = sandbox
  );

  static const String paypalCurrency = String.fromEnvironment(
    'PAYPAL_CURRENCY',
    defaultValue: 'USD',
  );
}

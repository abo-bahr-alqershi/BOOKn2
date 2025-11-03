class ApiConstants {
  ApiConstants._();

  // Base URLs
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    // defaultValue: 'http://ameenalqershi-001-site1.mtempurl.com/',
    defaultValue: 'http://192.168.0.139:5000/',
  );

  static const String imageBaseUrl = String.fromEnvironment(
    'IMAGE_BASE_URL',
    // defaultValue: 'http://ameenalqershi-001-site1.mtempurl.com',
    defaultValue: 'http://192.168.0.139:5000',
  );

  static const String socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    // defaultValue: 'wss://ws.ameenalqershi-001-site1.mtempurl.com',
    defaultValue: 'ws://192.168.0.139:5000',
  );

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout =
      Duration(seconds: 600); // 10 minutes for large file uploads

  // Headers
  static const String contentType = 'Content-Type';
  static const String applicationJson = 'application/json';
  static const String authorization = 'Authorization';
  static const String bearer = 'Bearer';
  static const String acceptLanguage = 'Accept-Language';

  // API Versions
  static const String apiVersion = 'v1';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
}

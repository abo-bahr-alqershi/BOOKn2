import 'package:dio/dio.dart';

class ServerException implements Exception {
  final String message;
  const ServerException(this.message);
}

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
}

class CacheException implements Exception {
  final String message;
  const CacheException(this.message);
}

class AuthenticationException implements Exception {
  final String message;
  const AuthenticationException(this.message);
}

class UnauthorizedException implements Exception {
  final String message;
  const UnauthorizedException(this.message);
}

class ValidationException implements Exception {
  final String message;
  final Map<String, List<String>>? errors;
  const ValidationException(this.message, {this.errors});
}

class NotFoundException implements Exception {
  final String message;
  const NotFoundException(this.message);
}

class TimeoutException implements Exception {
  final String message;
  const TimeoutException(this.message);
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final DioExceptionType? type;
  
  const ApiException(this.message, {this.statusCode, this.type});
}
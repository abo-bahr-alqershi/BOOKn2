import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  
  const Failure([this.message = 'An unexpected error occurred']);

  @override
  List<Object> get props => [message];
}

// General failures
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server failure']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache failure']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network failure']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failure']);
}

class ValidationFailure extends Failure {
  final Map<String, List<String>>? errors;
  
  const ValidationFailure([super.message = 'Validation failure', this.errors]);
  
  @override
  List<Object> get props => [message, errors ?? {}];
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Resource not found']);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Unauthorized access']);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'Request timeout']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Unknown failure']);
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure([super.message = 'Authentication failure']);
}

class ApiFailure extends Failure {
  final String code;
  const ApiFailure({required String message, required this.code}) : super(message);
  
  @override
  List<Object> get props => [message, code];
}

class SessionExpiredFailure extends Failure {
  const SessionExpiredFailure([super.message = 'Session expired']);
}

class PermissionDeniedFailure extends Failure {
  const PermissionDeniedFailure([super.message = 'Permission denied']);
}

class ValidationFailureWithErrors extends Failure {
  final Map<String, List<String>> errors;
  const ValidationFailureWithErrors({required String message, required this.errors}) : super(message);
  
  @override
  List<Object> get props => [message, errors];
}
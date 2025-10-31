import 'package:equatable/equatable.dart';

class ResultDto<T> extends Equatable {
  final bool success;
  final T? data;
  final String? message;
  final List<String> errors;
  final String? errorCode;
  final DateTime timestamp;
  final String? code;

  const ResultDto({
    required this.success,
    this.data,
    this.message,
    this.errors = const [],
    this.errorCode,
    required this.timestamp,
    this.code,
  });

  bool get isSuccess => success;

  factory ResultDto.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>)? fromJsonT,
  ) {
    return ResultDto<T>(
      success: json['success'] ?? false,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
      message: json['message'],
      errors: json['errors'] != null
          ? List<String>.from(json['errors'])
          : [],
      errorCode: json['errorCode'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      code: json['code'],
    );
  }

  Map<String, dynamic> toJson([Map<String, dynamic> Function(T?)? toJsonT]) {
    return {
      'success': success,
      'data': data != null && toJsonT != null ? toJsonT(data) : data,
      'message': message,
      'errors': errors,
      'errorCode': errorCode,
      'timestamp': timestamp.toIso8601String(),
      'code': code,
    };
  }

  @override
  List<Object?> get props => [
        success,
        data,
        message,
        errors,
        errorCode,
        timestamp,
        code,
      ];
}

class ResultDtoVoid extends Equatable {
  final bool success;
  final String? message;
  final List<String> errors;
  final String? errorCode;
  final DateTime timestamp;
  final String? code;

  const ResultDtoVoid({
    required this.success,
    this.message,
    this.errors = const [],
    this.errorCode,
    required this.timestamp,
    this.code,
  });

  bool get isSuccess => success;

  factory ResultDtoVoid.fromJson(Map<String, dynamic> json) {
    return ResultDtoVoid(
      success: json['success'] ?? false,
      message: json['message'],
      errors: json['errors'] != null
          ? List<String>.from(json['errors'])
          : [],
      errorCode: json['errorCode'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      code: json['code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'errors': errors,
      'errorCode': errorCode,
      'timestamp': timestamp.toIso8601String(),
      'code': code,
    };
  }

  @override
  List<Object?> get props => [
        success,
        message,
        errors,
        errorCode,
        timestamp,
        code,
      ];
}
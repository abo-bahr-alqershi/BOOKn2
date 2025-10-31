import 'package:equatable/equatable.dart';

class ResultDto<T> extends Equatable {
  final bool success;
  final T? data;
  final String? message;
  final List<String> errors;
  final String? errorCode;
  final DateTime timestamp;
  final String? code;
  final bool showAsDialog;

  const ResultDto({
    required this.success,
    this.data,
    this.message,
    this.errors = const [],
    this.errorCode,
    required this.timestamp,
    this.code,
    this.showAsDialog = false,
  });

  bool get isSuccess => success;

  factory ResultDto.fromJson(
    Map<String, dynamic>? json,
    T Function(dynamic)? fromJsonT,
  ) {
    if (json == null) {
      return ResultDto<T>(
        success: false,
        data: null,
        message: 'استجابة غير صالحة',
        errors: const ['الاستجابة فارغة'],
        errorCode: 'INVALID_RESPONSE',
        timestamp: DateTime.now(),
        code: null,
        showAsDialog: false,
      );
    }

    // If backend returned the payload directly without wrapping, treat it as data
    final bool hasEnvelope = json.containsKey('success') || json.containsKey('data');

    T? parsedData;
    if (hasEnvelope) {
      if (json.containsKey('data')) {
        final raw = json['data'];
        if (raw != null && fromJsonT != null) {
          parsedData = fromJsonT(raw);
        } else {
          parsedData = raw as T?;
        }
      }
    } else {
      // No envelope -> parse whole object as data
      if (fromJsonT != null) {
        parsedData = fromJsonT(json);
      } else {
        parsedData = json as T?;
      }
    }

    List<String> parsedErrors = [];
    final errorsField = json['errors'];
    if (errorsField is List) {
      parsedErrors = errorsField.map((e) => e.toString()).toList();
    } else if (errorsField is String) {
      parsedErrors = [errorsField];
    }

    DateTime ts;
    if (json['timestamp'] != null) {
      try {
        ts = DateTime.parse(json['timestamp'].toString());
      } catch (_) {
        ts = DateTime.now();
      }
    } else {
      ts = DateTime.now();
    }

    return ResultDto<T>(
      success: hasEnvelope
          ? ((json['success'] is bool) ? json['success'] as bool : false)
          : true,
      data: parsedData,
      message: json['message']?.toString(),
      errors: parsedErrors,
      errorCode: json['errorCode']?.toString(),
      timestamp: ts,
      code: json['code']?.toString(),
      showAsDialog: (json['showAsDialog'] is bool)
          ? json['showAsDialog'] as bool
          : false,
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
      'showAsDialog': showAsDialog,
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
  final bool showAsDialog;

  const ResultDtoVoid({
    required this.success,
    this.message,
    this.errors = const [],
    this.errorCode,
    required this.timestamp,
    this.code,
    this.showAsDialog = false,
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
      showAsDialog: json['showAsDialog'] == true,
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
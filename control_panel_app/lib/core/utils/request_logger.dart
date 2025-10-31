import 'package:flutter/foundation.dart';

/// Lightweight request logging helpers to track where failures occur
void logRequestStart(String requestName, {Map<String, dynamic>? details}) {
  debugPrint('>>> [REQUEST START] $requestName${details != null ? ' | details: $details' : ''}');
}

void logRequestSuccess(String requestName, {int? statusCode, Map<String, dynamic>? details}) {
  debugPrint('<<< [REQUEST SUCCESS] $requestName${statusCode != null ? ' | status: $statusCode' : ''}${details != null ? ' | details: $details' : ''}');
}

void logRequestError(String requestName, Object error, {StackTrace? stackTrace, Map<String, dynamic>? details}) {
  debugPrint('xxx [REQUEST ERROR] $requestName | error: $error${details != null ? ' | details: $details' : ''}');
  if (stackTrace != null) {
    debugPrint(stackTrace.toString());
  }
}
import 'dart:async';
import 'dart:isolate';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashReportingService {
  static final CrashReportingService _instance = CrashReportingService._internal();
  factory CrashReportingService() => _instance;
  CrashReportingService._internal();

  late FirebaseCrashlytics _crashlytics;

  // Initialize crash reporting
  Future<void> initialize() async {
    _crashlytics = FirebaseCrashlytics.instance;

    // Enable crash collection
    await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

    // Pass all uncaught errors from the framework to Crashlytics
    FlutterError.onError = _crashlytics.recordFlutterFatalError;

    // Pass all uncaught asynchronous errors
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics.recordError(error, stack, fatal: true);
      return true;
    };

    // Catch errors in other isolates
    Isolate.current.addErrorListener(RawReceivePort((pair) async {
      final List<dynamic> errorAndStacktrace = pair;
      await _crashlytics.recordError(
        errorAndStacktrace.first,
        errorAndStacktrace.last,
        fatal: true,
      );
    }).sendPort);
  }

  // Log error
  Future<void> logError(
    dynamic error,
    StackTrace? stackTrace, {
    bool fatal = false,
    String? reason,
  }) async {
    await _crashlytics.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: fatal,
    );
  }

  // Log message
  void log(String message) {
    _crashlytics.log(message);
  }

  // Set user identifier
  Future<void> setUserId(String userId) async {
    await _crashlytics.setUserIdentifier(userId);
  }

  // Set custom key
  Future<void> setCustomKey(String key, dynamic value) async {
    await _crashlytics.setCustomKey(key, value);
  }

  // Set multiple custom keys
  Future<void> setCustomKeys(Map<String, dynamic> keysAndValues) async {
    for (final entry in keysAndValues.entries) {
      await _crashlytics.setCustomKey(entry.key, entry.value);
    }
  }

  // Test crash
  void testCrash() {
    _crashlytics.crash();
  }

  // Check if crash occurred on previous execution
  Future<bool> didCrashOnPreviousExecution() async {
    return await _crashlytics.didCrashOnPreviousExecution();
  }

  // Delete unsent reports
  Future<void> deleteUnsentReports() async {
    await _crashlytics.deleteUnsentReports();
  }

  // Send unsent reports
  Future<void> sendUnsentReports() async {
    await _crashlytics.sendUnsentReports();
  }

  // Check for unsent reports
  Future<bool> checkForUnsentReports() async {
    return await _crashlytics.checkForUnsentReports();
  }

  // Enable/disable crash collection
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {
    await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
  }

  // Log network error
  Future<void> logNetworkError({
    required String url,
    required int? statusCode,
    required String? message,
    StackTrace? stackTrace,
  }) async {
    await _crashlytics.recordError(
      'Network Error: $url',
      stackTrace,
      reason: 'Status: $statusCode, Message: $message',
      fatal: false,
    );
  }

  // Log API error
  Future<void> logApiError({
    required String endpoint,
    required dynamic error,
    StackTrace? stackTrace,
  }) async {
    await setCustomKeys({
      'api_endpoint': endpoint,
      'error_type': error.runtimeType.toString(),
    });
    
    await logError(
      error,
      stackTrace,
      reason: 'API Error at $endpoint',
      fatal: false,
    );
  }

  // Log authentication error
  Future<void> logAuthError({
    required String action,
    required dynamic error,
    StackTrace? stackTrace,
  }) async {
    await setCustomKeys({
      'auth_action': action,
      'error_type': error.runtimeType.toString(),
    });
    
    await logError(
      error,
      stackTrace,
      reason: 'Authentication Error during $action',
      fatal: false,
    );
  }

  // Log payment error
  Future<void> logPaymentError({
    required String paymentMethod,
    required dynamic error,
    StackTrace? stackTrace,
  }) async {
    await setCustomKeys({
      'payment_method': paymentMethod,
      'error_type': error.runtimeType.toString(),
    });
    
    await logError(
      error,
      stackTrace,
      reason: 'Payment Error with $paymentMethod',
      fatal: false,
    );
  }

  // Log booking error
  Future<void> logBookingError({
    required String propertyId,
    required dynamic error,
    StackTrace? stackTrace,
  }) async {
    await setCustomKeys({
      'property_id': propertyId,
      'error_type': error.runtimeType.toString(),
    });
    
    await logError(
      error,
      stackTrace,
      reason: 'Booking Error for property $propertyId',
      fatal: false,
    );
  }

  // Log navigation error
  Future<void> logNavigationError({
    required String route,
    required dynamic error,
    StackTrace? stackTrace,
  }) async {
    await setCustomKeys({
      'route': route,
      'error_type': error.runtimeType.toString(),
    });
    
    await logError(
      error,
      stackTrace,
      reason: 'Navigation Error to $route',
      fatal: false,
    );
  }

  // Record breadcrumb
  void recordBreadcrumb({
    required String message,
    Map<String, dynamic>? data,
  }) {
    final breadcrumb = StringBuffer(message);
    if (data != null && data.isNotEmpty) {
      breadcrumb.write(' | ');
      breadcrumb.write(data.entries.map((e) => '${e.key}: ${e.value}').join(', '));
    }
    log(breadcrumb.toString());
  }

  // Clear user data
  Future<void> clearUserData() async {
    await _crashlytics.setUserIdentifier('');
  }
}
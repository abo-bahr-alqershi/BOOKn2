import 'dart:async';
import 'dart:io'; // إضافة للحصول على Platform
import '../utils/timezone_helper.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../../services/local_storage_service.dart';
import '../../services/message_service.dart';
import '../constants/storage_constants.dart';
import '../constants/api_constants.dart';
import '../localization/locale_manager.dart';
import '../bloc/app_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../services/navigation_service.dart';
import '../../injection_container.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // Allow skipping auth header for specific requests
    if (options.extra['skipAuth'] == true) {
      return handler.next(options);
    }

    final localStorage = sl<LocalStorageService>();
    final token = localStorage.getData(StorageConstants.accessToken) as String?;

    if (token != null && token.isNotEmpty) {
      options.headers[ApiConstants.authorization] =
          '${ApiConstants.bearer} $token';
    }

    // propagate role/property context for backend if needed
    final accountRole =
        localStorage.getData(StorageConstants.accountRole)?.toString();
    final propertyId =
        localStorage.getData(StorageConstants.propertyId)?.toString();
    final propertyCurrency =
        localStorage.getData(StorageConstants.propertyCurrency)?.toString();

    if (accountRole != null && accountRole.isNotEmpty) {
      options.headers['X-Account-Role'] = accountRole;
    }
    if (propertyId != null && propertyId.isNotEmpty) {
      options.headers['X-Property-Id'] = propertyId;
    }
    if (propertyCurrency != null && propertyCurrency.isNotEmpty) {
      options.headers['X-Property-Currency'] = propertyCurrency;
    }

    // Add current language to headers
    final locale = LocaleManager.getCurrentLocale();
    options.headers[ApiConstants.acceptLanguage] = locale.languageCode;

    // إضافة معلومات المنطقة الزمنية
    await _addTimezoneHeaders(options);

    handler.next(options);
  }

  /// إضافة headers المنطقة الزمنية
  Future<void> _addTimezoneHeaders(RequestOptions options) async {
    try {
      // التأكد من التهيئة
      await TimezoneHelper.initialize();

      // الحصول على timezone
      final timezone = await TimezoneHelper.getDeviceTimezone();
      final offset = TimezoneHelper.getTimezoneOffset();

      // إضافة headers المنطقة الزمنية
      options.headers['X-TimeZone'] = timezone;
      options.headers['X-TimeZone-Offset'] = offset.toString();

      // إضافة معلومات إضافية مفيدة
      options.headers['X-User-Locale'] = Platform.localeName; // ar_SA مثلاً

      // يمكن حفظ timezone في localStorage للاستخدام offline
      final localStorage = sl<LocalStorageService>();
      await localStorage.saveData(StorageConstants.userTimezone, timezone);
      await localStorage.saveData(StorageConstants.userTimezoneOffset, offset);

      if (kDebugMode) {
        print('📍 Timezone Headers Added:');
        print('   - X-TimeZone: $timezone');
        print('   - X-TimeZone-Offset: $offset minutes');
        print('   - X-User-Locale: ${Platform.localeName}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error adding timezone headers: $e');
      }

      // محاولة استخدام القيم المحفوظة سابقاً
      try {
        final localStorage = sl<LocalStorageService>();
        final savedTimezone =
            localStorage.getData(StorageConstants.userTimezone);
        final savedOffset =
            localStorage.getData(StorageConstants.userTimezoneOffset);

        if (savedTimezone != null) {
          options.headers['X-TimeZone'] = savedTimezone.toString();
          options.headers['X-TimeZone-Offset'] = (savedOffset ?? 0).toString();
        } else {
          // Default to Yemen timezone
          options.headers['X-TimeZone'] = 'Asia/Aden';
          options.headers['X-TimeZone-Offset'] = '180'; // +3 hours in minutes
        }
      } catch (_) {
        // Last resort defaults
        options.headers['X-TimeZone'] = 'UTC';
        options.headers['X-TimeZone-Offset'] = '0';
      }
    }
  }
}

// يمكن أيضاً إنشاء interceptor منفصل للـ timezone إذا أردت
class TimezoneInterceptor extends Interceptor {
  static bool _initialized = false;

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // تهيئة مرة واحدة فقط
    if (!_initialized) {
      await TimezoneHelper.initialize();
      _initialized = true;
    }

    try {
      // إضافة timezone headers
      final headers = TimezoneHelper.getTimezoneHeaders();
      options.headers.addAll(headers);

      // معلومات إضافية
      options.headers['X-App-Platform'] = Platform.operatingSystem;
      options.headers['X-App-Platform-Version'] =
          Platform.operatingSystemVersion;
    } catch (e) {
      if (kDebugMode) {
        print('Error in TimezoneInterceptor: $e');
      }
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // يمكن هنا معالجة التواريخ المرجعة من الخادم إذا أردت
    try {
      if (response.data is Map<String, dynamic>) {
        _convertDatesInResponse(response.data);
      } else if (response.data is List) {
        for (var item in response.data) {
          if (item is Map<String, dynamic>) {
            _convertDatesInResponse(item);
          }
        }
      }
    } catch (_) {}

    handler.next(response);
  }

  /// تحويل التواريخ في الاستجابة من UTC إلى المحلي (اختياري)
  void _convertDatesInResponse(Map<String, dynamic> data) {
    // قائمة بأسماء الحقول التي تحتوي على تواريخ
    final dateFields = [
      'createdAt', 'updatedAt', 'deletedAt',
      'startDate', 'endDate', 'date',
      'checkInDate', 'checkOutDate',
      'bookingDate', 'paymentDate',
      // أضف المزيد حسب API الخاص بك
    ];

    for (final field in dateFields) {
      if (data.containsKey(field) && data[field] != null) {
        try {
          // تحويل string إلى DateTime ثم إلى التوقيت المحلي
          if (data[field] is String) {
            final utcDate = DateTime.parse(data[field]);
            final localDate = TimezoneHelper.convertFromUtc(utcDate);
            data['${field}Local'] = localDate.toIso8601String();
            data['${field}Formatted'] = _formatDateTime(localDate);
          }
        } catch (_) {}
      }
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// Interceptor to surface server messages on successful HTTP responses
/// when backend embeds ResultDto with success/isSuccess flags.
class UserFeedbackInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    try {
      final extra = response.requestOptions.extra;
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final hasSuccessKey =
            data.containsKey('success') || data.containsKey('isSuccess');
        final bool? isSuccess =
            data['success'] as bool? ?? data['isSuccess'] as bool?;
        final String message = _extractResponseMessage(data);

        if (hasSuccessKey && isSuccess == false) {
          final suppressed = (extra['suppressErrorToast'] == true);
          if (!suppressed && message.isNotEmpty) {
            MessageService.showError(message);
          }
        }
        // else if (hasSuccessKey && isSuccess == true) {
        //   final showSuccess = (extra['showSuccessToast'] == true);
        //   if (showSuccess && message.isNotEmpty) {
        //     MessageService.showSuccess(message);
        //   }
        // }
      }
    } catch (_) {}

    handler.next(response);
  }
}

String _extractResponseMessage(Map<String, dynamic> data) {
  final msg = (data['message'] ?? data['error'] ?? '').toString();
  if (msg.trim().isNotEmpty) return msg;
  final errors = data['errors'];
  if (errors is List) {
    final joined = errors.map((e) => e.toString()).join('\n');
    if (joined.trim().isNotEmpty) return joined;
  } else if (errors is Map) {
    final List<String> messages = [];
    errors.forEach((key, value) {
      if (value is List) {
        messages.addAll(value.map((e) => e.toString()));
      } else if (value != null) {
        messages.add(value.toString());
      }
    });
    final joined = messages.join('\n');
    if (joined.trim().isNotEmpty) return joined;
  }
  return '';
}

class ErrorInterceptor extends Interceptor {
  ErrorInterceptor(this._dio);

  final Dio _dio;
  static bool _isRefreshing = false;
  static Completer<void>? _refreshCompleter;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final int? status = err.response?.statusCode;
    final RequestOptions requestOptions = err.requestOptions;

    // Skip refresh flow for specific requests (e.g., refresh endpoint itself)
    if (requestOptions.extra['skipRefresh'] == true) {
      return handler.next(err);
    }

    // Show validation/server messages globally unless suppressed
    try {
      final suppressed = (requestOptions.extra['suppressErrorToast'] == true);
      // Don't show a toast for 401; we'll refresh/redirect immediately
      if (!suppressed && status != 401) {
        final message = _extractErrorMessage(err);
        if (message.isNotEmpty) {
          MessageService.showError(message);
        }
      }
    } catch (_) {}

    // Only handle 401 Unauthorized (token refresh flow)
    if (status == 401) {
      try {
        final localStorage = sl<LocalStorageService>();
        final String? refreshToken =
            localStorage.getData(StorageConstants.refreshToken) as String?;

        // If no refresh token, logout
        if (refreshToken == null || refreshToken.isEmpty) {
          await _forceLogout();
          // Resolve with a synthetic response to stop further error toasts
          return handler.resolve(Response(
            requestOptions: requestOptions,
            statusCode: 401,
            data: {
              'success': false,
              'message': 'انتهت صلاحية الجلسة، تم تسجيل الخروج.'
            },
          ));
        }

        // If already retried once, avoid infinite loop
        if (requestOptions.extra['retried'] == true) {
          await _forceLogout();
          return handler.resolve(Response(
            requestOptions: requestOptions,
            statusCode: 401,
            data: {
              'success': false,
              'message': 'انتهت صلاحية الجلسة، تم تسجيل الخروج.'
            },
          ));
        }

        // If a refresh is already happening, wait for it
        if (_isRefreshing) {
          try {
            await (_refreshCompleter ?? Completer<void>()
                  ..complete())
                .future;
          } catch (_) {}
        } else {
          // Start refresh
          _isRefreshing = true;
          _refreshCompleter = Completer<void>();
          try {
            await _refreshAccessToken(refreshToken);
            _refreshCompleter?.complete();
          } catch (e) {
            _refreshCompleter?.completeError(e);
            await _forceLogout();
            _isRefreshing = false;
            return handler.resolve(Response(
              requestOptions: requestOptions,
              statusCode: 401,
              data: {
                'success': false,
                'message': 'انتهت صلاحية الجلسة، تم تسجيل الخروج.'
              },
            ));
          }
          _isRefreshing = false;
        }

        // Retry the original request with updated token
        final String? newAccess =
            localStorage.getData(StorageConstants.accessToken) as String?;
        if (newAccess == null || newAccess.isEmpty) {
          await _forceLogout();
          return handler.resolve(Response(
            requestOptions: requestOptions,
            statusCode: 401,
            data: {
              'success': false,
              'message': 'انتهت صلاحية الجلسة، تم تسجيل الخروج.'
            },
          ));
        }

        final Options newOptions = Options(
          method: requestOptions.method,
          headers: {
            ...requestOptions.headers,
            ApiConstants.authorization: '${ApiConstants.bearer} $newAccess',
          },
          responseType: requestOptions.responseType,
          contentType: requestOptions.contentType,
          followRedirects: requestOptions.followRedirects,
          validateStatus: requestOptions.validateStatus,
          receiveDataWhenStatusError: requestOptions.receiveDataWhenStatusError,
          extra: {
            ...requestOptions.extra,
            'retried': true,
          },
        );

        final Response response = await _dio.request(
          requestOptions.path,
          data: requestOptions.data,
          queryParameters: requestOptions.queryParameters,
          options: newOptions,
          cancelToken: requestOptions.cancelToken,
          onReceiveProgress: requestOptions.onReceiveProgress,
          onSendProgress: requestOptions.onSendProgress,
        );
        return handler.resolve(response);
      } catch (_) {
        await _forceLogout();
        return handler.resolve(Response(
          requestOptions: requestOptions,
          statusCode: 401,
          data: {
            'success': false,
            'message': 'انتهت صلاحية الجلسة، تم تسجيل الخروج.'
          },
        ));
      }
    }

    handler.next(err);
  }

  Future<void> _refreshAccessToken(String refreshToken) async {
    final authRepository = sl<AuthRepository>();
    final result =
        await authRepository.refreshToken(refreshToken: refreshToken);
    // Throw on failure so the caller logs out immediately
    result.fold(
      (_) => throw Exception('Failed to refresh access token'),
      (_) => null,
    );
  }

  Future<void> _forceLogout() async {
    try {
      // Clear local storages first
      final localStorage = sl<LocalStorageService>();
      await localStorage.removeData(StorageConstants.accessToken);
      await localStorage.removeData(StorageConstants.refreshToken);
      // Also clear contextual headers to avoid stale context after logout
      await localStorage.removeData(StorageConstants.accountRole);
      await localStorage.removeData(StorageConstants.propertyId);
      await localStorage.removeData(StorageConstants.propertyName);
      await localStorage.removeData(StorageConstants.propertyCurrency);
    } catch (_) {}
    // Dispatch logout to trigger router redirect
    try {
      AppBloc.authBloc.add(const LogoutEvent());
      // Navigate immediately to login to avoid showing stale page/errors
      NavigationService.goToLogin();
    } catch (_) {}
  }
}

bool _isJwtExpired(String jwt, {int skewSeconds = 0}) {
  try {
    final parts = jwt.split('.');
    if (parts.length != 3) return false;
    final payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
    var normalized = payload;
    while (normalized.length % 4 != 0) {
      normalized += '=';
    }
    final decoded = String.fromCharCodes(base64Url.decode(normalized));
    final map = jsonDecode(decoded) as Map<String, dynamic>;
    final exp = map['exp'];
    if (exp is int) {
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now()
          .isAfter(expiresAt.subtract(Duration(seconds: skewSeconds)));
    }
    return false;
  } catch (_) {
    return false;
  }
}

Dio _dioForLogout() => Dio();

String _extractErrorMessage(DioException err) {
  final data = err.response?.data;
  // Backend ResultDto pattern: { success, message, errors, errorCode, ... }
  if (data is Map<String, dynamic>) {
    // Prefer explicit message when present
    final explicitMessage = (data['message'] ?? data['error'] ?? '').toString();
    if (explicitMessage.trim().isNotEmpty) return explicitMessage;

    // errors may be List or Map of field=>[errors]
    final errors = data['errors'];
    if (errors is List) {
      final joined = errors.map((e) => e.toString()).join('\n');
      if (joined.trim().isNotEmpty) return joined;
    } else if (errors is Map) {
      final List<String> messages = [];
      errors.forEach((key, value) {
        if (value is List) {
          messages.addAll(value.map((e) => e.toString()));
        } else if (value != null) {
          messages.add(value.toString());
        }
      });
      final joined = messages.join('\n');
      if (joined.trim().isNotEmpty) return joined;
    }
  }

  // Fallback based on status code
  final statusCode = err.response?.statusCode;
  switch (statusCode) {
    case 400:
      return 'طلب غير صحيح';
    case 401:
      return 'غير مصرح بالوصول';
    case 403:
      return 'ليس لديك صلاحية';
    case 404:
      return 'لم يتم العثور على البيانات';
    case 422:
      return 'البيانات المدخلة غير صحيحة';
    case 500:
      return 'خطأ في الخادم';
    default:
      return err.message ?? 'حدث خطأ غير متوقع';
  }
}

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('REQUEST[${options.method}] => PATH: ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint(
        'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
        'ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}');
    handler.next(err);
  }
}

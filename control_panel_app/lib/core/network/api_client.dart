import 'package:bookn_cp_app/core/utils/timezone_helper.dart';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/api_constants.dart';
import 'api_interceptors.dart';
import 'api_exceptions.dart';

class ApiClient {
  late final Dio _dio;
  static bool _timezoneInitialized = false;

  ApiClient(Dio dio) {
    _dio = dio;
    _setupDioClient();
    _initializeTimezone(); // إضافة
  }

  // تهيئة timezone مرة واحدة عند بدء التطبيق
  Future<void> _initializeTimezone() async {
    if (_timezoneInitialized) return;

    try {
      await TimezoneHelper.initialize();
      _timezoneInitialized = true;
      print('✅ Timezone initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize timezone: $e');
    }
  }

  void _setupDioClient() {
    final normalizedBaseUrl = _normalizeBaseUrl(ApiConstants.baseUrl);
    _dio.options = BaseOptions(
      baseUrl: normalizedBaseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      sendTimeout: ApiConstants.sendTimeout,
      // تنسيق المصفوفات في query parameters لـ ASP.NET Core
      listFormat: ListFormat.multi, // amenityIds=id1&amenityIds=id2
      contentType: ApiConstants.applicationJson,
      headers: {
        ApiConstants.acceptLanguage: 'ar',
      },
    );

    _dio.interceptors.addAll([
      AuthInterceptor(), // يحتوي الآن على منطق timezone
      // TimezoneInterceptor(), // أو استخدم interceptor منفصل
      RequestHeadersLoggingInterceptor(),
      UserFeedbackInterceptor(),
      ErrorInterceptor(_dio),
      if (const bool.fromEnvironment('DEBUG'))
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
        ),
    ]);
  }

  String _normalizeBaseUrl(String baseUrl) {
    var v = baseUrl.trim();
    // Remove trailing slash to avoid double slashes when passing relative paths
    if (v.endsWith('/')) {
      v = v.substring(0, v.length - 1);
    }
    return v;
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    int retries = 2,
  }) async {
    int attempt = 0;
    DioException? lastError;
    while (attempt <= retries) {
      try {
        final response = await _dio.get(
          path,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
          onReceiveProgress: onReceiveProgress,
        );
        return response;
      } on DioException catch (e) {
        lastError = e;
        // فقط أعد المحاولة على مهلات الاتصال أو أخطاء الشبكة المؤقتة
        final isTimeout = e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout;
        final isNetwork = e.type == DioExceptionType.unknown;
        if (attempt < retries && (isTimeout || isNetwork)) {
          final delay = Duration(milliseconds: 300 * (1 << attempt));
          await Future.delayed(delay);
          attempt++;
          continue;
        }
        break;
      }
    }
    throw ApiException.fromDioError(lastError!);
  }

  // Future<Response> post(
  //   String path, {
  //   dynamic data,
  //   Map<String, dynamic>? queryParameters,
  //   Options? options,
  //   CancelToken? cancelToken,
  //   ProgressCallback? onSendProgress,
  //   ProgressCallback? onReceiveProgress,
  // }) async {
  //   try {
  //     final response = await _dio.post(
  //       path,
  //       data: data,
  //       queryParameters: queryParameters,
  //       options: options,
  //       cancelToken: cancelToken,
  //       onSendProgress: onSendProgress,
  //       onReceiveProgress: onReceiveProgress,
  //     );
  //     return response;
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      // Auto-detect FormData and ensure proper Content-Type handling
      if (data is FormData) {
        options ??= Options();
        options.headers ??= {};

        // For FormData, always remove Content-Type to let Dio add the boundary
        // Dio will automatically add: Content-Type: multipart/form-data; boundary=...
        options.headers!.remove('Content-Type');
        options.headers!.remove('content-type');

        if (const bool.fromEnvironment('DEBUG') || true) {
          print(
              '🎯 FormData detected - removing Content-Type to let Dio handle boundary');
        }
      }

      // طباعة البيانات للتطوير
      if (const bool.fromEnvironment('DEBUG') || true) {
        // مؤقتاً للتطوير
        final bool isAbsolute =
            path.startsWith('http://') || path.startsWith('https://');
        final String fullUrl = isAbsolute
            ? path
            : '${_dio.options.baseUrl}${path.startsWith('/') ? path : '/$path'}';
        print('🔵 POST Request to: $path');
        print('🌐 Resolved URL: $fullUrl');
        print('📦 Data: $data');
        if (options?.extra != null && options!.extra!.isNotEmpty) {
          print('⚙️ Options.extra: ${options.extra}');
        }
      }

      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      if (const bool.fromEnvironment('DEBUG') || true) {
        print('✅ Response: ${response.data}');
      }

      return response;
    } on DioException catch (e) {
      // طباعة تفاصيل الخطأ
      if (e.response != null) {
        print('❌ Error Status: ${e.response?.statusCode}');
        print('❌ Error Data: ${e.response?.data}');

        // معالجة خاصة للخطأ 400
        if (e.response?.statusCode == 400) {
          final errorData = e.response?.data;
          String errorMessage = 'طلب غير صحيح';

          if (errorData is Map) {
            // محاولة استخراج رسالة الخطأ
            if (errorData['errors'] is Map) {
              // أخطاء التحقق من النموذج
              final errors = errorData['errors'] as Map;
              final List<String> errorMessages = [];

              errors.forEach((key, value) {
                if (value is List && value.isNotEmpty) {
                  // استخراج الرسائل من قائمة الأخطاء
                  errorMessages.addAll(value.map((e) => e.toString()));
                } else {
                  errorMessages.add(value.toString());
                }
              });

              errorMessage = errorMessages.join('\n');
            } else {
              // رسالة خطأ عامة
              errorMessage = errorData['message'] ??
                  errorData['error'] ??
                  'طلب غير صحيح: تحقق من البيانات المدخلة';
            }
          }

          throw ApiException(
            message: errorMessage,
            statusCode: 400,
          );
        }
      }

      throw ApiException.fromDioError(e);
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Response> upload(
    String path, {
    required FormData formData,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: formData,
        options: options ??
            Options(
              headers: {
                'Content-Type': 'multipart/form-data',
              },
            ),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );
      return response;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  void updateBaseUrl(String baseUrl) {
    _dio.options.baseUrl = _normalizeBaseUrl(baseUrl);
  }

  void updateHeaders(Map<String, dynamic> headers) {
    _dio.options.headers.addAll(headers);
  }

  void clearHeaders() {
    _dio.options.headers.clear();
  }
}

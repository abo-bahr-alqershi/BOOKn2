import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;
  final DioExceptionType? type;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
    this.type,
  });

  factory ApiException.fromDioError(DioException dioError) {
    String message;
    int? statusCode;
    dynamic data;

    switch (dioError.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'انتهت مهلة الاتصال';
        break;
      case DioExceptionType.badResponse:
        statusCode = dioError.response?.statusCode;
        data = dioError.response?.data;
        
        // Check if response contains ResultDto structure
        if (data is Map<String, dynamic>) {
          if (data.containsKey('success') && data['success'] == false) {
            message = data['message'] ?? 
                     (data['errors'] as List?)?.join(', ') ?? 
                     _handleStatusCode(statusCode, data);
          } else {
            message = _handleStatusCode(statusCode, data);
          }
        } else {
          message = _handleStatusCode(statusCode, data);
        }
        break;
      case DioExceptionType.cancel:
        message = 'تم إلغاء الطلب';
        break;
      case DioExceptionType.connectionError:
        message = 'لا يوجد اتصال بالإنترنت';
        break;
      case DioExceptionType.badCertificate:
        message = 'خطأ في شهادة الأمان';
        break;
      case DioExceptionType.unknown:
      default:
        message = dioError.message ?? 'حدث خطأ غير متوقع';
        break;
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      data: data,
      type: dioError.type,
    );
  }

  static String _handleStatusCode(int? statusCode, dynamic data) {
    final errorMessage = data is Map<String, dynamic> 
        ? (data['message'] ?? data['error'] ?? '') 
        : '';

    switch (statusCode) {
      case 400:
        return errorMessage.isNotEmpty ? errorMessage : 'طلب غير صحيح';
      case 401:
        return errorMessage.isNotEmpty ? errorMessage : 'غير مصرح بالوصول';
      case 403:
        return errorMessage.isNotEmpty ? errorMessage : 'ليس لديك صلاحية';
      case 404:
        return errorMessage.isNotEmpty ? errorMessage : 'لم يتم العثور على البيانات';
      case 422:
        return errorMessage.isNotEmpty ? errorMessage : 'البيانات المدخلة غير صحيحة';
      case 500:
        return errorMessage.isNotEmpty ? errorMessage : 'خطأ في الخادم';
      case 503:
        return errorMessage.isNotEmpty ? errorMessage : 'الخدمة غير متاحة حالياً';
      default:
        return errorMessage.isNotEmpty ? errorMessage : 'حدث خطأ غير متوقع';
    }
  }

  @override
  String toString() => message;
}
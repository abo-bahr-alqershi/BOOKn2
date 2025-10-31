import 'package:dio/dio.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/error/exceptions.dart';
import '../../../../../core/models/paginated_result.dart';
import '../../../../../core/models/result_dto.dart';
import '../../../../../core/enums/booking_status.dart';
import '../../domain/entities/booking_details.dart';
import '../../domain/usecases/register_booking_payment.dart';
import '../models/booking_model.dart';
import '../models/booking_details_model.dart';
import '../models/booking_report_model.dart';
import '../models/booking_trends_model.dart';
import '../models/booking_window_analysis_model.dart';
import '../models/payment_model.dart' as payment_models;

abstract class BookingsRemoteDataSource {
  // Commands
  Future<bool> cancelBooking({
    required String bookingId,
    required String cancellationReason,
    bool refundPayments = false,
  });

  Future<bool> updateBooking({
    required String bookingId,
    DateTime? checkIn,
    DateTime? checkOut,
    int? guestsCount,
  });

  Future<bool> confirmBooking({required String bookingId});
  Future<bool> checkIn({required String bookingId});
  Future<bool> checkOut({required String bookingId});
  Future<bool> completeBooking({required String bookingId});

  Future<Payment> registerBookingPayment(RegisterPaymentParams params);

  // Services
  Future<bool> addServiceToBooking({
    required String bookingId,
    required String serviceId,
  });

  Future<bool> removeServiceFromBooking({
    required String bookingId,
    required String serviceId,
  });

  Future<List<ServiceModel>> getBookingServices({required String bookingId});

  // Queries
  Future<BookingModel> getBookingById({required String bookingId});

  Future<BookingDetailsModel> getBookingDetails({required String bookingId});

  Future<PaginatedResult<BookingModel>> getBookingsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int? pageNumber,
    int? pageSize,
    String? userId,
    String? guestNameOrEmail,
    String? unitId,
    String? bookingSource,
    bool? isWalkIn,
    double? minTotalPrice,
    int? minGuestsCount,
    String? sortBy,
  });

  Future<PaginatedResult<BookingModel>> getBookingsByProperty({
    required String propertyId,
    DateTime? startDate,
    DateTime? endDate,
    int? pageNumber,
    int? pageSize,
    BookingStatus? status,
    String? paymentStatus,
    String? guestNameOrEmail,
    String? bookingSource,
    bool? isWalkIn,
    double? minTotalPrice,
    int? minGuestsCount,
    String? sortBy,
  });

  Future<PaginatedResult<BookingModel>> getBookingsByStatus({
    required BookingStatus status,
    int? pageNumber,
    int? pageSize,
  });

  Future<PaginatedResult<BookingModel>> getBookingsByUnit({
    required String unitId,
    DateTime? startDate,
    DateTime? endDate,
    int? pageNumber,
    int? pageSize,
  });

  Future<PaginatedResult<BookingModel>> getBookingsByUser({
    required String userId,
    int? pageNumber,
    int? pageSize,
    BookingStatus? status,
    String? guestNameOrEmail,
    String? unitId,
    String? bookingSource,
    bool? isWalkIn,
    double? minTotalPrice,
    int? minGuestsCount,
    String? sortBy,
  });

  // Reports
  Future<BookingReportModel> getBookingReport({
    required DateTime startDate,
    required DateTime endDate,
    String? propertyId,
  });

  Future<BookingTrendsModel> getBookingTrends({
    String? propertyId,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<BookingWindowAnalysisModel> getBookingWindowAnalysis({
    required String propertyId,
  });
}

class BookingsRemoteDataSourceImpl implements BookingsRemoteDataSource {
  final ApiClient apiClient;
  static const String _baseEndpoint = '/api/admin/bookings';

  BookingsRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<bool> cancelBooking({
    required String bookingId,
    required String cancellationReason,
    bool refundPayments = false,
  }) async {
    try {
      final response = await apiClient.post(
        '$_baseEndpoint/$bookingId/cancel',
        data: {
          'bookingId': bookingId,
          'cancellationReason': cancellationReason,
          'refundPayments': refundPayments,
        },
      );

      final result = ResultDto<bool>.fromJson(
        response.data,
        (json) => json as bool,
      );

      if (result.success) {
        return result.data ?? false;
      } else {
        throw ServerException(
          result.message ?? 'Failed to cancel booking',
          code: result.errorCode ?? result.code,
          showAsDialog: result.showAsDialog,
        );
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = (data is Map<String, dynamic>)
          ? (data['message']?.toString() ?? 'Network error occurred')
          : 'Network error occurred';
      final code = (data is Map<String, dynamic>) ? (data['errorCode']?.toString() ?? data['code']?.toString()) : null;
      final showAsDialog = (data is Map<String, dynamic>) ? (data['showAsDialog'] == true) : false;
      throw ServerException(msg, code: code, showAsDialog: showAsDialog);
    }
  }

  @override
  Future<bool> updateBooking({
    required String bookingId,
    DateTime? checkIn,
    DateTime? checkOut,
    int? guestsCount,
  }) async {
    try {
      final response = await apiClient.put(
        '$_baseEndpoint/$bookingId/update',
        data: {
          'bookingId': bookingId,
          if (checkIn != null) 'checkIn': checkIn.toIso8601String(),
          if (checkOut != null) 'checkOut': checkOut.toIso8601String(),
          if (guestsCount != null) 'guestsCount': guestsCount,
        },
      );

      final result = ResultDto<bool>.fromJson(
        response.data,
        (json) => json as bool,
      );

      if (result.success) {
        return result.data ?? false;
      } else {
        throw ServerException(result.message ?? 'Failed to update booking');
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Network error occurred',
      );
    }
  }

  @override
  Future<bool> confirmBooking({required String bookingId}) async {
    try {
      final response = await apiClient.post(
        '$_baseEndpoint/$bookingId/confirm',
        data: {'bookingId': bookingId},
      );

      final result = ResultDto<bool>.fromJson(
        response.data,
        (json) => json as bool,
      );

      if (result.success) {
        return result.data ?? false;
      } else {
        throw ServerException(result.message ?? 'Failed to confirm booking');
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Network error occurred',
      );
    }
  }

  @override
  Future<bool> checkIn({required String bookingId}) async {
    try {
      final response = await apiClient.post(
        '$_baseEndpoint/$bookingId/check-in',
        data: {'bookingId': bookingId},
      );

      final result = ResultDto<bool>.fromJson(
        response.data,
        (json) => json as bool,
      );

      if (result.success) {
        return result.data ?? false;
      } else {
        throw ServerException(result.message ?? 'Failed to check in');
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Network error occurred',
      );
    }
  }

  @override
  Future<bool> checkOut({required String bookingId}) async {
    try {
      final response = await apiClient.post(
        '$_baseEndpoint/$bookingId/check-out',
        data: {'bookingId': bookingId},
      );

      final result = ResultDto<bool>.fromJson(
        response.data,
        (json) => json as bool,
      );

      if (result.success) {
        return result.data ?? false;
      } else {
        throw ServerException(result.message ?? 'Failed to check out');
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Network error occurred',
      );
    }
  }

  @override
  Future<bool> completeBooking({required String bookingId}) async {
    try {
      final response = await apiClient.post(
        '$_baseEndpoint/$bookingId/complete',
        data: {'bookingId': bookingId},
      );

      final result = ResultDto<bool>.fromJson(
        response.data,
        (json) => json as bool,
      );

      if (result.success) {
        return result.data ?? false;
      } else {
        throw ServerException(result.message ?? 'Failed to complete booking');
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Network error occurred',
      );
    }
  }

  @override
  Future<Payment> registerBookingPayment(RegisterPaymentParams params) async {
    try {
      final response = await apiClient.post(
        '$_baseEndpoint/${params.bookingId}/register-payment',
        data: {
          'bookingId': params.bookingId,
          'amount': {
            'amount': params.amount,
            'currency': params.currency,
            'exchangeRate': 1.0,
          },
          'paymentMethod': params.paymentMethod.index + 1, // Convert enum to backend value
          'transactionId': params.transactionId ?? '',
          'notes': params.notes ?? '',
          'paymentDate': params.paymentDate?.toIso8601String(),
        },
      );

      final result = ResultDto<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (result.success && result.data != null) {
        return payment_models.PaymentModel.fromJson(result.data!);
      } else {
        throw ServerException(
          result.message ?? 'Failed to register payment',
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Network error occurred',
      );
    }
  }

  @override
  Future<bool> addServiceToBooking({
    required String bookingId,
    required String serviceId,
  }) async {
    try {
      final response = await apiClient.post(
        '$_baseEndpoint/$bookingId/services/add',
        data: {
          'bookingId': bookingId,
          'serviceId': serviceId,
        },
      );

      final result = ResultDto<bool>.fromJson(
        response.data,
        (json) => json as bool,
      );

      if (result.success) {
        return result.data ?? false;
      } else {
        throw ServerException(result.message ?? 'Failed to add service');
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Network error occurred',
      );
    }
  }

  @override
  Future<bool> removeServiceFromBooking({
    required String bookingId,
    required String serviceId,
  }) async {
    try {
      final response = await apiClient.post(
        '$_baseEndpoint/$bookingId/services/remove',
        data: {
          'bookingId': bookingId,
          'serviceId': serviceId,
        },
      );

      final result = ResultDto<bool>.fromJson(
        response.data,
        (json) => json as bool,
      );

      if (result.success) {
        return result.data ?? false;
      } else {
        throw ServerException(result.message ?? 'Failed to remove service');
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Network error occurred',
      );
    }
  }

  @override
  Future<List<ServiceModel>> getBookingServices(
      {required String bookingId}) async {
    try {
      final response = await apiClient.get(
        '$_baseEndpoint/$bookingId/services',
      );

      final result = ResultDto<List<dynamic>>.fromJson(
        response.data,
        (json) => json as List<dynamic>,
      );

      if (result.success) {
        return (result.data ?? [])
            .map((json) => ServiceModel.fromJson(json))
            .toList();
      } else {
        throw ServerException(result.message ?? 'Failed to get services');
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Network error occurred',
      );
    }
  }

  @override
  Future<BookingModel> getBookingById({required String bookingId}) async {
    try {
      final response = await apiClient.get('$_baseEndpoint/$bookingId');

      final result = ResultDto<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (result.success && result.data != null) {
        return BookingModel.fromJson(result.data!);
      } else {
        final String serverMessage = _joinMessageAndErrors(
          result.message,
          response.data,
        );
        throw ServerException(serverMessage);
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = _joinMessageAndErrors(
        data is Map<String, dynamic> ? data['message'] : null,
        data,
      );
      throw ServerException(message);
    }
  }

  @override
  Future<BookingDetailsModel> getBookingDetails(
      {required String bookingId}) async {
    try {
      final response = await apiClient.get('$_baseEndpoint/$bookingId/details');

      final result = ResultDto<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (result.success && result.data != null) {
        return BookingDetailsModel.fromJson(result.data!);
      } else {
        final String serverMessage = _joinMessageAndErrors(
          result.message,
          response.data,
        );
        throw ServerException(serverMessage);
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = _joinMessageAndErrors(
        data is Map<String, dynamic> ? data['message'] : null,
        data,
      );
      throw ServerException(message);
    }
  }

  String _joinMessageAndErrors(String? message, dynamic responseData) {
    try {
      if (responseData is Map<String, dynamic>) {
        final errs = responseData['errors'];
        if (errs is List) {
          final combined = errs.map((e) => e.toString()).where((e) => e.isNotEmpty).join(' / ');
          if (combined.isNotEmpty) {
            if (message != null && message.isNotEmpty && message != 'حدثت أخطاء متعددة') {
              return '$message\n$combined';
            }
            return combined;
          }
        }
      }
    } catch (_) {}
    return message ?? 'Network error occurred';
  }

  @override
  Future<PaginatedResult<BookingModel>> getBookingsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int? pageNumber,
    int? pageSize,
    String? userId,
    String? guestNameOrEmail,
    String? unitId,
    String? bookingSource,
    bool? isWalkIn,
    double? minTotalPrice,
    int? minGuestsCount,
    String? sortBy,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        if (pageNumber != null) 'pageNumber': pageNumber,
        if (pageSize != null) 'pageSize': pageSize,
        if (userId != null) 'userId': userId,
        if (guestNameOrEmail != null) 'guestNameOrEmail': guestNameOrEmail,
        if (unitId != null) 'unitId': unitId,
        if (bookingSource != null) 'bookingSource': bookingSource,
        if (isWalkIn != null) 'isWalkIn': isWalkIn,
        if (minTotalPrice != null) 'minTotalPrice': minTotalPrice,
        if (minGuestsCount != null) 'minGuestsCount': minGuestsCount,
        if (sortBy != null) 'sortBy': sortBy,
      };

      final response = await apiClient.get(
        '$_baseEndpoint/by-date-range',
        queryParameters: queryParams,
      );

      final raw = response.data;
      final Map<String, dynamic> normalized = raw is List
          ? {
              'items': raw,
              'pageNumber': 1,
              'pageSize': raw.length,
              'totalCount': raw.length,
            }
          : Map<String, dynamic>.from(raw as Map);

      return PaginatedResult<BookingModel>.fromJson(
        normalized,
        (json) => BookingModel.fromJson(json),
      );
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Network error occurred',
      );
    }
  }

  @override
  Future<PaginatedResult<BookingModel>> getBookingsByProperty({
    required String propertyId,
    DateTime? startDate,
    DateTime? endDate,
    int? pageNumber,
    int? pageSize,
    BookingStatus? status,
    String? paymentStatus,
    String? guestNameOrEmail,
    String? bookingSource,
    bool? isWalkIn,
    double? minTotalPrice,
    int? minGuestsCount,
    String? sortBy,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'propertyId': propertyId,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
        if (pageNumber != null) 'pageNumber': pageNumber,
        if (pageSize != null) 'pageSize': pageSize,
        if (status != null) 'status': status.displayNameEn,
        if (paymentStatus != null) 'paymentStatus': paymentStatus,
        if (guestNameOrEmail != null) 'guestNameOrEmail': guestNameOrEmail,
        if (bookingSource != null) 'bookingSource': bookingSource,
        if (isWalkIn != null) 'isWalkIn': isWalkIn,
        if (minTotalPrice != null) 'minTotalPrice': minTotalPrice,
        if (minGuestsCount != null) 'minGuestsCount': minGuestsCount,
        if (sortBy != null) 'sortBy': sortBy,
      };

      // Backend route uses path parameter: /api/admin/bookings/property/{propertyId}
      final response = await apiClient.get(
        '$_baseEndpoint/property/$propertyId',
        queryParameters: queryParams,
      );

      final raw = response.data;
      final Map<String, dynamic> normalized = raw is List
          ? {
              'items': raw,
              'pageNumber': 1,
              'pageSize': raw.length,
              'totalCount': raw.length,
            }
          : Map<String, dynamic>.from(raw as Map);

      return PaginatedResult<BookingModel>.fromJson(
        normalized,
        (json) => BookingModel.fromJson(json),
      );
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Network error occurred',
      );
    }
  }

  @override
  Future<PaginatedResult<BookingModel>> getBookingsByStatus({
    required BookingStatus status,
    int? pageNumber,
    int? pageSize,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'status': status.apiValue,
        if (pageNumber != null) 'pageNumber': pageNumber,
        if (pageSize != null) 'pageSize': pageSize,
      };

      // Backend route: /api/admin/bookings/status
      final response = await apiClient.get(
        '$_baseEndpoint/status',
        queryParameters: queryParams,
      );

      final raw = response.data;
      final Map<String, dynamic> normalized = raw is List
          ? {
              'items': raw,
              'pageNumber': 1,
              'pageSize': raw.length,
              'totalCount': raw.length,
            }
          : Map<String, dynamic>.from(raw as Map);

      return PaginatedResult<BookingModel>.fromJson(
        normalized,
        (json) => BookingModel.fromJson(json),
      );
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Network error occurred',
      );
    }
  }

  @override
  Future<PaginatedResult<BookingModel>> getBookingsByUnit({
    required String unitId,
    DateTime? startDate,
    DateTime? endDate,
    int? pageNumber,
    int? pageSize,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'unitId': unitId,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
        if (pageNumber != null) 'pageNumber': pageNumber,
        if (pageSize != null) 'pageSize': pageSize,
      };

      // Backend route: /api/admin/bookings/unit/{unitId}
      final response = await apiClient.get(
        '$_baseEndpoint/unit/$unitId',
        queryParameters: queryParams,
      );

      final raw = response.data;
      final Map<String, dynamic> normalized = raw is List
          ? {
              'items': raw,
              'pageNumber': 1,
              'pageSize': raw.length,
              'totalCount': raw.length,
            }
          : Map<String, dynamic>.from(raw as Map);

      return PaginatedResult<BookingModel>.fromJson(
        normalized,
        (json) => BookingModel.fromJson(json),
      );
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Network error occurred',
      );
    }
  }

  @override
  Future<PaginatedResult<BookingModel>> getBookingsByUser({
    required String userId,
    int? pageNumber,
    int? pageSize,
    BookingStatus? status,
    String? guestNameOrEmail,
    String? unitId,
    String? bookingSource,
    bool? isWalkIn,
    double? minTotalPrice,
    int? minGuestsCount,
    String? sortBy,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'userId': userId,
        if (pageNumber != null) 'pageNumber': pageNumber,
        if (pageSize != null) 'pageSize': pageSize,
        if (status != null) 'status': status.apiValue,
        if (guestNameOrEmail != null) 'guestNameOrEmail': guestNameOrEmail,
        if (unitId != null) 'unitId': unitId,
        if (bookingSource != null) 'bookingSource': bookingSource,
        if (isWalkIn != null) 'isWalkIn': isWalkIn,
        if (minTotalPrice != null) 'minTotalPrice': minTotalPrice,
        if (minGuestsCount != null) 'minGuestsCount': minGuestsCount,
        if (sortBy != null) 'sortBy': sortBy,
      };

      // Backend route: /api/admin/bookings/user/{userId}
      final response = await apiClient.get(
        '$_baseEndpoint/user/$userId',
        queryParameters: queryParams,
      );

      final raw = response.data;
      final Map<String, dynamic> normalized = raw is List
          ? {
              'items': raw,
              'pageNumber': 1,
              'pageSize': raw.length,
              'totalCount': raw.length,
            }
          : Map<String, dynamic>.from(raw as Map);

      return PaginatedResult<BookingModel>.fromJson(
        normalized,
        (json) => BookingModel.fromJson(json),
      );
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Network error occurred',
      );
    }
  }

  @override
  Future<BookingReportModel> getBookingReport({
    required DateTime startDate,
    required DateTime endDate,
    String? propertyId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        if (propertyId != null) 'propertyId': propertyId,
      };

      final response = await apiClient.get(
        '$_baseEndpoint/report',
        queryParameters: queryParams,
      );

      final result = ResultDto<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (result.success && result.data != null) {
        return BookingReportModel.fromJson(result.data!);
      } else {
        throw ServerException(result.message ?? 'Failed to get report');
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Network error occurred',
      );
    }
  }

  @override
  Future<BookingTrendsModel> getBookingTrends({
    String? propertyId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        if (propertyId != null) 'propertyId': propertyId,
      };

      final response = await apiClient.get(
        '$_baseEndpoint/trends',
        queryParameters: queryParams,
      );

      final result = ResultDto<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (result.success && result.data != null) {
        return BookingTrendsModel.fromJson(result.data!);
      } else {
        throw ServerException(result.message ?? 'Failed to get trends');
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Network error occurred',
      );
    }
  }

  @override
  Future<BookingWindowAnalysisModel> getBookingWindowAnalysis({
    required String propertyId,
  }) async {
    try {
      final response = await apiClient.get(
        '$_baseEndpoint/window-analysis',
        queryParameters: {'propertyId': propertyId},
      );

      final result = ResultDto<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (result.success && result.data != null) {
        return BookingWindowAnalysisModel.fromJson(result.data!);
      } else {
        throw ServerException(result.message ?? 'Failed to get analysis');
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Network error occurred',
      );
    }
  }
}

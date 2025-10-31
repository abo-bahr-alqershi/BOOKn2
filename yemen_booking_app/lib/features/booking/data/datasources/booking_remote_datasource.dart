import 'package:dio/dio.dart';
import 'package:yemen_booking_app/core/enums/booking_status.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/models/result_dto.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/request_logger.dart';
import '../models/booking_model.dart';
import '../models/booking_request_model.dart';

abstract class BookingRemoteDataSource {
  Future<ResultDto<BookingModel>> createBooking(BookingRequestModel request);
  
  Future<ResultDto<BookingModel>> getBookingDetails({
    required String bookingId,
    required String userId,
  });
  
  Future<ResultDto<bool>> cancelBooking({
    required String bookingId,
    required String userId,
    required String reason,
  });
  
  Future<ResultDto<PaginatedResult<BookingModel>>> getUserBookings({
    required String userId,
    String? status,
    int pageNumber = 1,
    int pageSize = 10,
  });
  
  Future<ResultDto<Map<String, dynamic>>> getUserBookingSummary({
    required String userId,
    int? year,
  });
  
  Future<ResultDto<BookingModel>> addServicesToBooking({
    required String bookingId,
    required String serviceId,
    required int quantity,
  });
  
  Future<ResultDto<bool>> checkAvailability({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guestsCount,
  });
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final ApiClient apiClient;

  BookingRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<ResultDto<BookingModel>> createBooking(BookingRequestModel request) async {
    const requestName = 'booking.createBooking';
    logRequestStart(requestName, details: {
      'request': request.toJson(),
    });
    try {
      final response = await apiClient.post(
        '/api/client/booking',
        data: request.toJson(),
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final resultDto = ResultDto.fromJson(
          response.data,
          (json) => _parseCreateBookingResponse(json),
        );
        
        if (resultDto.success && resultDto.data != null) {
          return resultDto;
        } else {
          throw ServerException(resultDto.message ?? 'Failed to create booking');
        }
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to create booking');
      }
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<ResultDto<BookingModel>> getBookingDetails({
    required String bookingId,
    required String userId,
  }) async {
    const requestName = 'booking.getBookingDetails';
    logRequestStart(requestName, details: {
      'bookingId': bookingId,
      'userId': userId,
    });
    try {
      final response = await apiClient.get(
        '/api/client/booking/$bookingId',
        queryParameters: {'userId': userId},
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.statusCode == 200) {
        return ResultDto.fromJson(
          response.data,
          (json) => BookingModel.fromJson(json),
        );
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to get booking details');
      }
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<ResultDto<bool>> cancelBooking({
    required String bookingId,
    required String userId,
    required String reason,
  }) async {
    const requestName = 'booking.cancelBooking';
    logRequestStart(requestName, details: {
      'bookingId': bookingId,
      'userId': userId,
      'reason': reason,
    });
    try {
      final response = await apiClient.post(
        '/api/client/booking/cancel',
        data: {
          'bookingId': bookingId,
          'userId': userId,
          'cancellationReason': reason,
        },
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.statusCode == 200) {
        final resultDto = ResultDto.fromJson(
          response.data,
          (json) => json['success'] ?? false,
        );
        
        if (resultDto.success) {
          return ResultDto<bool>(
            success: true,
            data: true,
            message: resultDto.message,
            timestamp: DateTime.now(),
          );
        } else {
          throw ServerException(resultDto.message ?? 'Failed to cancel booking');
        }
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to cancel booking');
      }
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<ResultDto<PaginatedResult<BookingModel>>> getUserBookings({
    required String userId,
    String? status,
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    const requestName = 'booking.getUserBookings';
    logRequestStart(requestName, details: {
      'userId': userId,
      if (status != null) 'status': status,
      'pageNumber': pageNumber,
      'pageSize': pageSize,
    });
    try {
      final queryParams = <String, dynamic>{
        'userId': userId,
        'pageNumber': pageNumber,
        'pageSize': pageSize,
      };
      
      if (status != null) {
        queryParams['status'] = status;
      }

      final response = await apiClient.get(
        '/api/client/booking',
        queryParameters: queryParams,
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.statusCode == 200) {
        return ResultDto.fromJson(
          response.data,
          (json) => PaginatedResult.fromJson(
            json,
            (bookingJson) => BookingModel.fromJson(bookingJson),
          ),
        );
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to get user bookings');
      }
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<ResultDto<Map<String, dynamic>>> getUserBookingSummary({
    required String userId,
    int? year,
  }) async {
    const requestName = 'booking.getUserBookingSummary';
    logRequestStart(requestName, details: {
      'userId': userId,
      if (year != null) 'year': year,
    });
    try {
      final queryParams = <String, dynamic>{
        'userId': userId,
      };
      
      if (year != null) {
        queryParams['year'] = year;
      }

      final response = await apiClient.get(
        '/api/client/booking/summary/$userId',
        queryParameters: queryParams,
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.statusCode == 200) {
        return ResultDto.fromJson(
          response.data,
          (json) => json,
        );
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to get booking summary');
      }
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<ResultDto<BookingModel>> addServicesToBooking({
    required String bookingId,
    required String serviceId,
    required int quantity,
  }) async {
    const requestName = 'booking.addServicesToBooking';
    logRequestStart(requestName, details: {
      'bookingId': bookingId,
      'serviceId': serviceId,
      'quantity': quantity,
    });
    try {
      final response = await apiClient.post(
        '/api/client/booking/add-service',
        data: {
          'bookingId': bookingId,
          'serviceId': serviceId,
          'quantity': quantity,
        },
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.statusCode == 200) {
        final resultDto = ResultDto.fromJson(
          response.data,
          (json) => _parseAddServiceResponse(json, bookingId),
        );
        
        if (resultDto.success && resultDto.data != null) {
          return resultDto;
        } else {
          throw ServerException(resultDto.message ?? 'Failed to add service');
        }
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to add service to booking');
      }
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<ResultDto<bool>> checkAvailability({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guestsCount,
  }) async {
    const requestName = 'booking.checkAvailability';
    logRequestStart(requestName, details: {
      'unitId': unitId,
      'checkIn': checkIn.toIso8601String(),
      'checkOut': checkOut.toIso8601String(),
      'guestsCount': guestsCount,
    });
    try {
      final response = await apiClient.post(
        '/api/client/units/check-availability',
        data: {
          'unitId': unitId,
          'checkInDate': checkIn.toIso8601String(),
          'checkOutDate': checkOut.toIso8601String(),
          'adults': guestsCount,
          'children': 0,
        },
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.statusCode == 200) {
        return ResultDto.fromJson(
          response.data,
          (json) => (json['isAvailable'] as bool? ?? false),
        );
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to check availability');
      }
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ServerException('Unexpected error: $e');
    }
  }

  // Helper method to parse create booking response
  BookingModel _parseCreateBookingResponse(Map<String, dynamic> json) {
    return BookingModel(
      id: json['bookingId'] ?? '',
      bookingNumber: json['bookingNumber'] ?? '',
      userId: '',
      userName: '',
      propertyId: '',
      propertyName: '',
      checkInDate: DateTime.now(),
      checkOutDate: DateTime.now(),
      numberOfNights: 0,
      adultGuests: 0,
      childGuests: 0,
      totalGuests: 0,
      totalAmount: (json['totalPrice']?['amount'] ?? 0).toDouble(),
      currency: json['totalPrice']?['currency'] ?? 'YER',
      status: BookingModel.parseBookingStatus(json['status']),
      bookingDate: DateTime.now(),
      services: const [],
      payments: const [],
      unitImages: const [],
      contactInfo: const ContactInfoModel(
        phoneNumber: '',
        email: '',
      ),
    );
  }

  BookingModel _parseAddServiceResponse(Map<String, dynamic> json, String bookingId) {
    return BookingModel(
      id: bookingId,
      bookingNumber: '',
      userId: '',
      userName: '',
      propertyId: '',
      propertyName: '',
      checkInDate: DateTime.now(),
      checkOutDate: DateTime.now(),
      numberOfNights: 0,
      adultGuests: 0,
      childGuests: 0,
      totalGuests: 0,
      totalAmount: (json['newTotalPrice']?['amount'] ?? 0).toDouble(),
      currency: json['newTotalPrice']?['currency'] ?? 'YER',
      status: BookingStatus.confirmed,
      bookingDate: DateTime.now(),
      services: const [],
      payments: const [],
      unitImages: const [],
      contactInfo: const ContactInfoModel(
        phoneNumber: '',
        email: '',
      ),
    );
  }
}
import 'package:dio/dio.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_exceptions.dart';
import '../../../../../core/error/exceptions.dart' hide ApiException;
import '../../../../../core/models/paginated_result.dart';
import '../../../../../core/models/result_dto.dart';
import '../../../../../core/enums/payment_method_enum.dart';
import '../models/payment_model.dart';
import '../models/payment_details_model.dart';
import '../models/refund_model.dart';
import '../models/payment_analytics_model.dart';
import '../models/money_model.dart';
import '../../domain/entities/payment.dart';

abstract class PaymentsRemoteDataSource {
  // Commands
  Future<bool> refundPayment({
    required String paymentId,
    required Money refundAmount,
    required String refundReason,
  });

  Future<bool> voidPayment({required String paymentId});

  Future<bool> updatePaymentStatus({
    required String paymentId,
    required PaymentStatus newStatus,
  });

  Future<String> processPayment({
    required String bookingId,
    required Money amount,
    required PaymentMethod method,
  });

  // Queries
  Future<PaymentModel> getPaymentById({required String paymentId});

  Future<PaymentDetailsModel> getPaymentDetails({required String paymentId});

  Future<PaginatedResult<PaymentModel>> getAllPayments({
    PaymentStatus? status,
    PaymentMethod? method,
    String? bookingId,
    String? userId,
    String? propertyId,
    String? unitId,
    double? minAmount,
    double? maxAmount,
    DateTime? startDate,
    DateTime? endDate,
    int? pageNumber,
    int? pageSize,
  });

  Future<PaginatedResult<PaymentModel>> getPaymentsByBooking({
    required String bookingId,
    int? pageNumber,
    int? pageSize,
  });

  Future<PaginatedResult<PaymentModel>> getPaymentsByStatus({
    required PaymentStatus status,
    int? pageNumber,
    int? pageSize,
  });

  Future<PaginatedResult<PaymentModel>> getPaymentsByUser({
    required String userId,
    int? pageNumber,
    int? pageSize,
  });

  Future<PaginatedResult<PaymentModel>> getPaymentsByMethod({
    required PaymentMethod method,
    int? pageNumber,
    int? pageSize,
  });

  Future<PaginatedResult<PaymentModel>> getPaymentsByProperty({
    required String propertyId,
    DateTime? startDate,
    DateTime? endDate,
    int? pageNumber,
    int? pageSize,
  });

  // Analytics
  Future<PaymentAnalyticsModel> getPaymentAnalytics({
    DateTime? startDate,
    DateTime? endDate,
    String? propertyId,
  });

  Future<Map<String, dynamic>> getRevenueReport({
    required DateTime startDate,
    required DateTime endDate,
    String? propertyId,
  });

  Future<List<PaymentTrendModel>> getPaymentTrends({
    required DateTime startDate,
    required DateTime endDate,
    String? propertyId,
  });

  Future<RefundAnalyticsModel> getRefundStatistics({
    DateTime? startDate,
    DateTime? endDate,
    String? propertyId,
  });
}

class PaymentsRemoteDataSourceImpl implements PaymentsRemoteDataSource {
  final ApiClient apiClient;
  static const String _baseEndpoint = '/api/admin/payments';

  PaymentsRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<bool> refundPayment({
    required String paymentId,
    required Money refundAmount,
    required String refundReason,
  }) async {
    try {
      final response = await apiClient.post(
        '$_baseEndpoint/refund',
        data: {
          'paymentId': paymentId,
          'refundAmount': (refundAmount as MoneyModel).toJson(),
          'refundReason': refundReason,
        },
      );

      final result = ResultDto<bool>.fromJson(
        response.data,
        (json) => json as bool,
      );

      if (result.success) {
        return result.data ?? false;
      } else {
        throw ServerException(result.message ?? 'Failed to refund payment');
      }
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        // If refund endpoint not found or payment missing, treat as failed refund
        return false;
      }
      throw ServerException(e.message);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Network error occurred',
      );
    }
  }

  @override
  Future<bool> voidPayment({required String paymentId}) async {
    try {
      final response = await apiClient.post(
        '$_baseEndpoint/void',
        data: {'paymentId': paymentId},
      );

      final result = ResultDto<bool>.fromJson(
        response.data,
        (json) => json as bool,
      );

      if (result.success) {
        return result.data ?? false;
      } else {
        throw ServerException(result.message ?? 'Failed to void payment');
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Network error occurred',
      );
    }
  }

  @override
  Future<bool> updatePaymentStatus({
    required String paymentId,
    required PaymentStatus newStatus,
  }) async {
    try {
      final response = await apiClient.put(
        '$_baseEndpoint/$paymentId/status',
        data: {
          'paymentId': paymentId,
          'newStatus': newStatus.backendKey,
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
            result.message ?? 'Failed to update payment status');
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Network error occurred',
      );
    }
  }

  @override
  Future<String> processPayment({
    required String bookingId,
    required Money amount,
    required PaymentMethod method,
  }) async {
    try {
      final response = await apiClient.post(
        '$_baseEndpoint/process',
        data: {
          'bookingId': bookingId,
          'amount': (amount as MoneyModel).toJson(),
          'method': method.backendValue,
        },
      );

      final result = ResultDto<String>.fromJson(
        response.data,
        (json) => json.toString(),
      );

      if (result.success && result.data != null) {
        return result.data!;
      } else {
        throw ServerException(result.message ?? 'Failed to process payment');
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Network error occurred',
      );
    }
  }

  @override
  Future<PaymentModel> getPaymentById({required String paymentId}) async {
    try {
      final response = await apiClient.get('$_baseEndpoint/$paymentId');

      final result = ResultDto<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (result.success && result.data != null) {
        return PaymentModel.fromJson(result.data!);
      } else {
        throw ServerException(result.message ?? 'Failed to get payment');
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Network error occurred',
      );
    }
  }

  @override
  Future<PaymentDetailsModel> getPaymentDetails(
      {required String paymentId}) async {
    try {
      final response = await apiClient.get('$_baseEndpoint/$paymentId/details');

      final result = ResultDto<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (result.success && result.data != null) {
        return PaymentDetailsModel.fromJson(result.data!);
      } else {
        throw ServerException(
            result.message ?? 'Failed to get payment details');
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Network error occurred',
      );
    }
  }

  @override
  Future<PaginatedResult<PaymentModel>> getAllPayments({
    PaymentStatus? status,
    PaymentMethod? method,
    String? bookingId,
    String? userId,
    String? propertyId,
    String? unitId,
    double? minAmount,
    double? maxAmount,
    DateTime? startDate,
    DateTime? endDate,
    int? pageNumber,
    int? pageSize,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status.backendKey;
      if (method != null) queryParams['method'] = method.backendValue;
      if (bookingId != null) queryParams['bookingId'] = bookingId;
      if (userId != null) queryParams['userId'] = userId;
      if (propertyId != null) queryParams['propertyId'] = propertyId;
      if (unitId != null) queryParams['unitId'] = unitId;
      if (minAmount != null) queryParams['minAmount'] = minAmount;
      if (maxAmount != null) queryParams['maxAmount'] = maxAmount;
      if (startDate != null)
        queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      if (pageNumber != null) queryParams['pageNumber'] = pageNumber;
      if (pageSize != null) queryParams['pageSize'] = pageSize;

      final response = await apiClient.get(
        _baseEndpoint,
        queryParameters: queryParams,
      );

      return PaginatedResult<PaymentModel>.fromJson(
        response.data,
        (json) => PaymentModel.fromJson(json),
      );
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Network error occurred',
      );
    }
  }

  @override
  Future<PaginatedResult<PaymentModel>> getPaymentsByBooking({
    required String bookingId,
    int? pageNumber,
    int? pageSize,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'bookingId': bookingId,
        if (pageNumber != null) 'pageNumber': pageNumber,
        if (pageSize != null) 'pageSize': pageSize,
      };

      final response = await apiClient.get(
        '$_baseEndpoint/by-booking',
        queryParameters: queryParams,
      );

      return PaginatedResult<PaymentModel>.fromJson(
        response.data,
        (json) => PaymentModel.fromJson(json),
      );
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Network error occurred',
      );
    }
  }

  @override
  Future<PaginatedResult<PaymentModel>> getPaymentsByStatus({
    required PaymentStatus status,
    int? pageNumber,
    int? pageSize,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'status': status.backendKey,
        if (pageNumber != null) 'pageNumber': pageNumber,
        if (pageSize != null) 'pageSize': pageSize,
      };

      final response = await apiClient.get(
        '$_baseEndpoint/by-status',
        queryParameters: queryParams,
      );

      return PaginatedResult<PaymentModel>.fromJson(
        response.data,
        (json) => PaymentModel.fromJson(json),
      );
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Network error occurred',
      );
    }
  }

  @override
  Future<PaginatedResult<PaymentModel>> getPaymentsByUser({
    required String userId,
    int? pageNumber,
    int? pageSize,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'userId': userId,
        if (pageNumber != null) 'pageNumber': pageNumber,
        if (pageSize != null) 'pageSize': pageSize,
      };

      final response = await apiClient.get(
        '$_baseEndpoint/by-user',
        queryParameters: queryParams,
      );

      return PaginatedResult<PaymentModel>.fromJson(
        response.data,
        (json) => PaymentModel.fromJson(json),
      );
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Network error occurred',
      );
    }
  }

  @override
  Future<PaginatedResult<PaymentModel>> getPaymentsByMethod({
    required PaymentMethod method,
    int? pageNumber,
    int? pageSize,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'paymentMethod': method.backendValue,
        if (pageNumber != null) 'pageNumber': pageNumber,
        if (pageSize != null) 'pageSize': pageSize,
      };

      final response = await apiClient.get(
        '$_baseEndpoint/by-method',
        queryParameters: queryParams,
      );

      return PaginatedResult<PaymentModel>.fromJson(
        response.data,
        (json) => PaymentModel.fromJson(json),
      );
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Network error occurred',
      );
    }
  }

  @override
  Future<PaginatedResult<PaymentModel>> getPaymentsByProperty({
    required String propertyId,
    DateTime? startDate,
    DateTime? endDate,
    int? pageNumber,
    int? pageSize,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'propertyId': propertyId,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
        if (pageNumber != null) 'pageNumber': pageNumber,
        if (pageSize != null) 'pageSize': pageSize,
      };

      final response = await apiClient.get(
        '$_baseEndpoint/by-property',
        queryParameters: queryParams,
      );

      return PaginatedResult<PaymentModel>.fromJson(
        response.data,
        (json) => PaymentModel.fromJson(json),
      );
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Network error occurred',
      );
    }
  }

  @override
  Future<PaymentAnalyticsModel> getPaymentAnalytics({
    DateTime? startDate,
    DateTime? endDate,
    String? propertyId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null)
        queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      if (propertyId != null) queryParams['propertyId'] = propertyId;

      Response response;
      try {
        response = await apiClient.get(
          '$_baseEndpoint/analytics',
          queryParameters: queryParams,
        );
      } on ApiException catch (e) {
        // Fallback: try capitalized endpoint if not found
        if (e.statusCode == 404) {
          response = await apiClient.get(
            '$_baseEndpoint/Analytics',
            queryParameters: queryParams,
          );
        } else {
          rethrow;
        }
      }

      final result = ResultDto<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (result.success && result.data != null) {
        return PaymentAnalyticsModel.fromJson(result.data!);
      } else {
        throw ServerException(result.message ?? 'Failed to get analytics');
      }
    } on ApiException catch (e) {
      // Return empty analytics for 404 to avoid hard-failing the UI
      if (e.statusCode == 404) {
        return _createEmptyAnalytics(startDate, endDate);
      }
      throw ServerException(e.message);
    } on DioException catch (e) {
      // Return empty analytics for 404 to avoid hard-failing the UI
      if (e.response?.statusCode == 404) {
        return _createEmptyAnalytics(startDate, endDate);
      }
      throw ServerException(
        e.response?.data['message'] ?? 'Network error occurred',
      );
    }
  }

  PaymentAnalyticsModel _createEmptyAnalytics(DateTime? startDate, DateTime? endDate) {
    return PaymentAnalyticsModel.fromJson({
      'summary': const PaymentSummaryModel(
        totalTransactions: 0,
        totalAmount: MoneyModel(
            amount: 0, currency: 'YER', formattedAmount: '0 ر.ي'),
        averageTransactionValue: MoneyModel(
            amount: 0, currency: 'YER', formattedAmount: '0 ر.ي'),
        successRate: 0,
        successfulTransactions: 0,
        failedTransactions: 0,
        pendingTransactions: 0,
        totalRefunded: MoneyModel(
            amount: 0, currency: 'YER', formattedAmount: '0 ر.ي'),
        refundCount: 0,
      ).toJson(),
      'trends': const <dynamic>[],
      'methodAnalytics': const {},
      'statusAnalytics': const {},
      'refundAnalytics': const RefundAnalyticsModel(
        totalRefunds: 0,
        totalRefundedAmount: MoneyModel(
            amount: 0, currency: 'YER', formattedAmount: '0 ر.ي'),
        refundRate: 0,
        averageRefundTime: 0,
        refundReasons: {},
        trends: [],
      ).toJson(),
      'startDate':
          (startDate ?? DateTime.now().subtract(const Duration(days: 30)))
              .toIso8601String(),
      'endDate': (endDate ?? DateTime.now()).toIso8601String(),
    });
  }

  @override
  Future<Map<String, dynamic>> getRevenueReport({
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

      Response response;
      try {
        response = await apiClient.get(
          '$_baseEndpoint/revenue-report',
          queryParameters: queryParams,
        );
      } on ApiException catch (e) {
        if (e.statusCode == 404) {
          response = await apiClient.get(
            '$_baseEndpoint/RevenueReport',
            queryParameters: queryParams,
          );
        } else {
          rethrow;
        }
      }

      final result = ResultDto<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (result.success && result.data != null) {
        return result.data!;
      } else {
        throw ServerException(result.message ?? 'Failed to get revenue report');
      }
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return <String, dynamic>{};
      }
      throw ServerException(e.message);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Network error occurred',
      );
    }
  }

  @override
  Future<List<PaymentTrendModel>> getPaymentTrends({
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

      Response response;
      try {
        response = await apiClient.get(
          '$_baseEndpoint/trends',
          queryParameters: queryParams,
        );
      } on ApiException catch (e) {
        if (e.statusCode == 404) {
          response = await apiClient.get(
            '$_baseEndpoint/Trends',
            queryParameters: queryParams,
          );
        } else {
          rethrow;
        }
      }

      final result = ResultDto<List<dynamic>>.fromJson(
        response.data,
        (json) => json as List<dynamic>,
      );

      if (result.success && result.data != null) {
        return result.data!
            .map((json) => PaymentTrendModel.fromJson(json))
            .toList();
      } else {
        throw ServerException(result.message ?? 'Failed to get trends');
      }
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return <PaymentTrendModel>[];
      }
      throw ServerException(e.message);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return <PaymentTrendModel>[];
      }
      throw ServerException(
        e.response?.data['message'] ?? 'Network error occurred',
      );
    }
  }

  @override
  Future<RefundAnalyticsModel> getRefundStatistics({
    DateTime? startDate,
    DateTime? endDate,
    String? propertyId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null)
        queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      if (propertyId != null) queryParams['propertyId'] = propertyId;

      Response response;
      try {
        response = await apiClient.get(
          '$_baseEndpoint/refund-statistics',
          queryParameters: queryParams,
        );
      } on ApiException catch (e) {
        if (e.statusCode == 404) {
          response = await apiClient.get(
            '$_baseEndpoint/RefundStatistics',
            queryParameters: queryParams,
          );
        } else {
          rethrow;
        }
      }

      final result = ResultDto<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (result.success && result.data != null) {
        return RefundAnalyticsModel.fromJson(result.data!);
      } else {
        throw ServerException(
            result.message ?? 'Failed to get refund statistics');
      }
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return const RefundAnalyticsModel(
          totalRefunds: 0,
          totalRefundedAmount: MoneyModel(
              amount: 0, currency: 'USD', formattedAmount: 'USD 0.00'),
          refundRate: 0,
          averageRefundTime: 0,
          refundReasons: {},
          trends: [],
        );
      }
      throw ServerException(e.message);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const RefundAnalyticsModel(
          totalRefunds: 0,
          totalRefundedAmount: MoneyModel(
              amount: 0, currency: 'USD', formattedAmount: 'USD 0.00'),
          refundRate: 0,
          averageRefundTime: 0,
          refundReasons: {},
          trends: [],
        );
      }
      throw ServerException(
        e.response?.data['message'] ?? 'Network error occurred',
      );
    }
  }
}

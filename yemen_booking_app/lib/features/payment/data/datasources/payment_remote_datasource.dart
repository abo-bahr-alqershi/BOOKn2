/// features/payment/data/datasources/payment_remote_datasource.dart

import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/models/result_dto.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/request_logger.dart';
import '../models/transaction_model.dart';

abstract class PaymentRemoteDataSource {
  Future<ResultDto<TransactionModel>> processPayment({
    required String bookingId,
    required String userId,
    required double amount,
    required String paymentMethod,
    required String currency,
    String? cardNumber,
    String? cardHolderName,
    String? expiryDate,
    String? cvv,
    String? walletNumber,
    String? walletPin,
  });

  Future<ResultDto<PaginatedResult<TransactionModel>>> getPaymentHistory({
    required String userId,
    int pageNumber = 1,
    int pageSize = 10,
    String? status,
    String? paymentMethod,
    DateTime? fromDate,
    DateTime? toDate,
    double? minAmount,
    double? maxAmount,
  });
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final ApiClient apiClient;

  PaymentRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<ResultDto<TransactionModel>> processPayment({
    required String bookingId,
    required String userId,
    required double amount,
    required String paymentMethod,
    required String currency,
    String? cardNumber,
    String? cardHolderName,
    String? expiryDate,
    String? cvv,
    String? walletNumber,
    String? walletPin,
  }) async {
    const requestName = 'payment.processPayment';
    logRequestStart(requestName, details: {
      'bookingId': bookingId,
      'userId': userId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'currency': currency,
    });
    try {
      final Map<String, dynamic> data = {
        'bookingId': bookingId,
        'userId': userId,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'currency': currency,
      };

      if (paymentMethod.toLowerCase().contains('credit')) {
        data.addAll({
          'cardNumber': cardNumber,
          'cardHolderName': cardHolderName,
          'expiryDate': expiryDate,
          'cvv': cvv,
        });
      }

      if (paymentMethod.toLowerCase().contains('wallet')) {
        data.addAll({
          'walletNumber': walletNumber,
          'walletPin': walletPin,
        });
      }

      final response = await apiClient.post(
        '/api/client/payments/process',
        data: data,
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final resultDto = ResultDto.fromJson(
          response.data,
          (json) => TransactionModel.fromProcessPaymentResponse(json),
        );

        if (resultDto.success && resultDto.data != null) {
          return resultDto;
        } else {
          throw ServerException(resultDto.message ?? 'فشل في معالجة الدفع');
        }
      } else {
        throw ServerException(response.data['message'] ?? 'فشل في معالجة الدفع');
      }
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ServerException(e.message ?? 'حدث خطأ في الشبكة');
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ServerException('خطأ غير متوقع: $e');
    }
  }

  @override
  Future<ResultDto<PaginatedResult<TransactionModel>>> getPaymentHistory({
    required String userId,
    int pageNumber = 1,
    int pageSize = 10,
    String? status,
    String? paymentMethod,
    DateTime? fromDate,
    DateTime? toDate,
    double? minAmount,
    double? maxAmount,
  }) async {
    const requestName = 'payment.getPaymentHistory';
    logRequestStart(requestName, details: {
      'userId': userId,
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      if (status != null) 'status': status,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
    });
    try {
      final queryParams = <String, dynamic>{
        'userId': userId,
        'pageNumber': pageNumber,
        'pageSize': pageSize,
      };

      if (status != null) queryParams['status'] = status;
      if (paymentMethod != null) queryParams['paymentMethod'] = paymentMethod;
      if (fromDate != null) queryParams['fromDate'] = fromDate.toIso8601String();
      if (toDate != null) queryParams['toDate'] = toDate.toIso8601String();
      if (minAmount != null) queryParams['minAmount'] = minAmount;
      if (maxAmount != null) queryParams['maxAmount'] = maxAmount;

      final response = await apiClient.get(
        '/api/client/payments/history',
        queryParameters: queryParams,
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.statusCode == 200) {
        return ResultDto.fromJson(
          response.data,
          (json) => PaginatedResult.fromJson(
            json,
            (paymentJson) => TransactionModel.fromJson(paymentJson),
          ),
        );
      } else {
        throw ServerException(response.data['message'] ?? 'فشل في جلب سجل المدفوعات');
      }
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ServerException(e.message ?? 'حدث خطأ في الشبكة');
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ServerException('خطأ غير متوقع: $e');
    }
  }
}
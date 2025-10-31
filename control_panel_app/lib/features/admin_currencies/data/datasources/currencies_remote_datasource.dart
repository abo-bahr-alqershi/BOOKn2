import 'package:bookn_cp_app/core/network/api_exceptions.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/currency_model.dart';

abstract class CurrenciesRemoteDataSource {
  Future<List<CurrencyModel>> getCurrencies();
  Future<bool> saveCurrencies(List<CurrencyModel> currencies);
  Future<bool> deleteCurrency(String code);
  Future<Map<String, dynamic>> getCurrencyStats({DateTime? startDate, DateTime? endDate});
}

class CurrenciesRemoteDataSourceImpl implements CurrenciesRemoteDataSource {
  final ApiClient apiClient;

  CurrenciesRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<CurrencyModel>> getCurrencies() async {
    try {
      final response = await apiClient.get(
        '${ApiConstants.commonBaseUrl}/system-settings/currencies',
      );

      if (response.data['data'] != null) {
        return (response.data['data'] as List)
            .map((json) => CurrencyModel.fromJson(json))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<bool> saveCurrencies(List<CurrencyModel> currencies) async {
    try {
      final response = await apiClient.put(
        '${ApiConstants.adminBaseUrl}/system-settings/currencies',
        data: currencies.map((c) => c.toJson()).toList(),
      );

      return response.data['data'] ?? false;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<bool> deleteCurrency(String code) async {
    try {
      final response = await apiClient.delete(
        '${ApiConstants.adminBaseUrl}/system-settings/currencies/$code',
      );
      // API returns ResultDto without data; Success indicates deletion
      return response.data['success'] == true;
    } on DioException catch (e) {
      // Fallback for servers that don't support DELETE endpoint yet (legacy behavior)
      if (e.response?.statusCode == 404) {
        try {
          final current = await getCurrencies();
          final updated = current.where((c) => c.code != code).toList();
          final saved = await saveCurrencies(updated);
          return saved;
        } on DioException catch (inner) {
          throw _handleDioError(inner);
        }
      }
      throw _handleDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getCurrencyStats({DateTime? startDate, DateTime? endDate}) async {
    try {
      final params = <String, dynamic>{};
      if (startDate != null) params['startDate'] = startDate.toIso8601String();
      if (endDate != null) params['endDate'] = endDate.toIso8601String();
      final response = await apiClient.get(
        '${ApiConstants.adminBaseUrl}/system-settings/currencies/stats',
        queryParameters: params,
      );
      final data = response.data;
      if (data is Map && (data['data'] is Map)) {
        return Map<String, dynamic>.from(data['data'] as Map);
      }
      // Some deployments might return bare object
      if (data is Map<String, dynamic>) return data;
      return <String, dynamic>{};
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    if (e.response != null) {
      final message = e.response?.data['message'] ?? 'خطأ في الخادم';
      final code = e.response?.data['errorCode'] as String?;
      throw ApiException(message: message, code: code);
    }
    return ApiException(message: 'خطأ في الاتصال');
  }
}
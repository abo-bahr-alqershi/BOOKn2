import 'package:yemen_booking_app/core/network/api_client.dart';
import 'package:yemen_booking_app/core/error/exceptions.dart';
import 'package:dio/dio.dart';

import '../models/city_model.dart';
import '../models/currency_model.dart';

abstract class ReferenceRemoteDataSource {
  Future<List<CityModel>> getCities();
  Future<List<CurrencyModel>> getCurrencies();
}

class ReferenceRemoteDataSourceImpl implements ReferenceRemoteDataSource {
  final ApiClient apiClient;

  ReferenceRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<CityModel>> getCities() async {
    try {
      final response = await apiClient.get('/api/admin/system-settings/cities');
      if (response.statusCode == 200) {
        final data = response.data;
        final list = (data is Map<String, dynamic>) ? data['data'] : data;
        if (list is List) {
          return list.map((e) => CityModel.fromJson(e)).toList();
        }
      }
      throw const ServerException('Invalid response structure for cities');
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Network error');
    }
  }

  @override
  Future<List<CurrencyModel>> getCurrencies() async {
    try {
      final response = await apiClient.get('/api/common/system-settings/currencies');
      if (response.statusCode == 200) {
        final data = response.data;
        final list = (data is Map<String, dynamic>) ? data['data'] : data;
        if (list is List) {
          return list.map((e) => CurrencyModel.fromJson(e)).toList();
        }
      }
      throw const ServerException('Invalid response structure for currencies');
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Network error');
    }
  }
}


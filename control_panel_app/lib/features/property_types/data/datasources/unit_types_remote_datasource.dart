import 'package:dio/dio.dart';
import 'dart:convert';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/models/result_dto.dart';
import '../../../../core/network/api_client.dart';
import '../models/unit_type_model.dart';

abstract class UnitTypesRemoteDataSource {
  Future<PaginatedResult<UnitTypeModel>> getUnitTypesByPropertyType({
    required String propertyTypeId,
    required int pageNumber,
    required int pageSize,
  });
  
  Future<UnitTypeModel> getUnitTypeById(String id);
  
  Future<String> createUnitType({
    required String propertyTypeId,
    required String name,
    required int maxCapacity,
    required String icon,
    double? systemCommissionRate,
    required bool isHasAdults,
    required bool isHasChildren,
    required bool isMultiDays,
    required bool isRequiredToDetermineTheHour,
  });
  
  Future<bool> updateUnitType({
    required String unitTypeId,
    required String name,
    required int maxCapacity,
    required String icon,
    double? systemCommissionRate,
    required bool isHasAdults,
    required bool isHasChildren,
    required bool isMultiDays,
    required bool isRequiredToDetermineTheHour,
  });
  
  Future<bool> deleteUnitType(String unitTypeId);
}

class UnitTypesRemoteDataSourceImpl implements UnitTypesRemoteDataSource {
  final ApiClient apiClient;
  static const String _baseEndpoint = '/api/admin/unit-types';

  UnitTypesRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<PaginatedResult<UnitTypeModel>> getUnitTypesByPropertyType({
    required String propertyTypeId,
    required int pageNumber,
    required int pageSize,
  }) async {
    try {
      final response = await apiClient.get(
        '$_baseEndpoint/property-type/$propertyTypeId',
        queryParameters: {
          'pageNumber': pageNumber,
          'pageSize': pageSize,
        },
      );
      
      dynamic raw = response.data;
      if (raw is String) {
        try { raw = json.decode(raw); } catch (_) {}
      }

      dynamic payload = (raw is Map<String, dynamic> && raw.containsKey('data'))
          ? raw['data']
          : raw;

      if (payload is String) {
        try { payload = json.decode(payload); } catch (_) {}
      }

      if (payload is Map<String, dynamic>) {
      return PaginatedResult<UnitTypeModel>.fromJson(
          payload,
        (json) => UnitTypeModel.fromJson(json as Map<String, dynamic>),
      );
      }

      if (payload is List) {
        final items = payload
            .whereType<Map<String, dynamic>>()
            .map((e) => UnitTypeModel.fromJson(e))
            .toList();
        return PaginatedResult<UnitTypeModel>(
          items: items,
          pageNumber: pageNumber,
          pageSize: pageSize,
          totalCount: items.length,
        );
      }

      throw const ServerException('Invalid response structure for unit types');
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Server error occurred');
    }
  }

  @override
  Future<UnitTypeModel> getUnitTypeById(String id) async {
    try {
      final response = await apiClient.get('$_baseEndpoint/$id');
      dynamic raw = response.data;
      if (raw is String) {
        try { raw = json.decode(raw); } catch (_) {}
      }
      final result = ResultDto.fromJson((raw as Map<String, dynamic>), null);
      final data = result.data;
      if (result.isSuccess && data != null) {
        final map = data is String ? json.decode(data) : data;
        return UnitTypeModel.fromJson(map as Map<String, dynamic>);
      }
        throw ServerException(result.message ?? 'Failed to get unit type');
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Server error occurred');
    }
  }

  @override
  Future<String> createUnitType({
    required String propertyTypeId,
    required String name,
    required int maxCapacity,
    required String icon,
    double? systemCommissionRate,
    required bool isHasAdults,
    required bool isHasChildren,
    required bool isMultiDays,
    required bool isRequiredToDetermineTheHour,
  }) async {
    try {
      final response = await apiClient.post(
        _baseEndpoint,
        data: {
          'propertyTypeId': propertyTypeId,
          'name': name,
          'maxCapacity': maxCapacity,
          'icon': icon,
          if (systemCommissionRate != null) 'systemCommissionRate': systemCommissionRate,
          'isHasAdults': isHasAdults,
          'isHasChildren': isHasChildren,
          'isMultiDays': isMultiDays,
          'isRequiredToDetermineTheHour': isRequiredToDetermineTheHour,
        },
      );
      
      final result = ResultDto.fromJson(response.data, null);
      
      if (result.isSuccess && result.data != null) {
        return result.data as String;
      } else {
        throw ServerException(result.message ?? 'Failed to create unit type');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Server error occurred');
    }
  }

  @override
  Future<bool> updateUnitType({
    required String unitTypeId,
    required String name,
    required int maxCapacity,
    required String icon,
    double? systemCommissionRate,
    required bool isHasAdults,
    required bool isHasChildren,
    required bool isMultiDays,
    required bool isRequiredToDetermineTheHour,
  }) async {
    try {
      final response = await apiClient.put(
        '$_baseEndpoint/$unitTypeId',
        data: {
          'unitTypeId': unitTypeId,
          'name': name,
          'maxCapacity': maxCapacity,
          'icon': icon,
          if (systemCommissionRate != null) 'systemCommissionRate': systemCommissionRate,
          'isHasAdults': isHasAdults,
          'isHasChildren': isHasChildren,
          'isMultiDays': isMultiDays,
          'isRequiredToDetermineTheHour': isRequiredToDetermineTheHour,
        },
      );
      
      final result = ResultDto.fromJson(response.data, null);
      return result.isSuccess;
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Server error occurred');
    }
  }

  @override
  Future<bool> deleteUnitType(String unitTypeId) async {
    try {
      final response = await apiClient.delete('$_baseEndpoint/$unitTypeId');
      final result = ResultDto.fromJson(response.data, null);
      return result.isSuccess;
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Server error occurred');
    }
  }
}
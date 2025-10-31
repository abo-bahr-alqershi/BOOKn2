import 'package:dio/dio.dart';
import 'dart:convert';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/models/result_dto.dart';
import '../../../../core/network/api_client.dart';
import '../models/property_type_model.dart';

abstract class PropertyTypesRemoteDataSource {
  Future<PaginatedResult<PropertyTypeModel>> getAllPropertyTypes({
    required int pageNumber,
    required int pageSize,
  });
  
  Future<PropertyTypeModel> getPropertyTypeById(String id);
  
  Future<String> createPropertyType({
    required String name,
    required String description,
    required List<String> defaultAmenities,
    required String icon,
  });
  
  Future<bool> updatePropertyType({
    required String propertyTypeId,
    required String name,
    required String description,
    required List<String> defaultAmenities,
    required String icon,
  });
  
  Future<bool> deletePropertyType(String propertyTypeId);
}

class PropertyTypesRemoteDataSourceImpl implements PropertyTypesRemoteDataSource {
  final ApiClient apiClient;
  static const String _baseEndpoint = '/api/admin/property-types';

  PropertyTypesRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<PaginatedResult<PropertyTypeModel>> getAllPropertyTypes({
    required int pageNumber,
    required int pageSize,
  }) async {
    try {
      final response = await apiClient.get(
        _baseEndpoint,
        queryParameters: {
          'pageNumber': pageNumber,
          'pageSize': pageSize,
        },
      );
      
      dynamic raw = response.data;
      if (raw is String) {
        try {
          raw = json.decode(raw);
        } catch (_) {}
      }

      // Support both ResultDto-wrapped and direct paginated payloads
      dynamic payload;
      if (raw is Map<String, dynamic> && raw.containsKey('data')) {
        payload = raw['data'];
      } else {
        payload = raw;
      }

      if (payload is String) {
        try {
          payload = json.decode(payload);
        } catch (_) {}
      }

      if (payload is Map<String, dynamic>) {
      return PaginatedResult<PropertyTypeModel>.fromJson(
          payload,
          (json) => PropertyTypeModel.fromJson(json as Map<String, dynamic>),
      );
      }

      if (payload is List) {
        final items = payload
            .whereType<Map<String, dynamic>>()
            .map((e) => PropertyTypeModel.fromJson(e))
            .toList();
        return PaginatedResult<PropertyTypeModel>(
          items: items,
          pageNumber: pageNumber,
          pageSize: pageSize,
          totalCount: items.length,
        );
      }

      throw const ServerException('Invalid response structure for property types');
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Server error occurred');
    }
  }

  @override
  Future<PropertyTypeModel> getPropertyTypeById(String id) async {
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
        return PropertyTypeModel.fromJson(map as Map<String, dynamic>);
      }
        throw ServerException(result.message ?? 'Failed to get property type');
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Server error occurred');
    }
  }

  @override
  Future<String> createPropertyType({
    required String name,
    required String description,
    required List<String> defaultAmenities,
    required String icon,
  }) async {
    try {
      final response = await apiClient.post(
        _baseEndpoint,
        data: {
          'name': name,
          'description': description,
          'defaultAmenities': defaultAmenities,
          'icon': icon,
        },
      );
      
      final result = ResultDto.fromJson(response.data, null);
      
      if (result.isSuccess && result.data != null) {
        return result.data as String;
      } else {
        throw ServerException(result.message ?? 'Failed to create property type');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Server error occurred');
    }
  }

  @override
  Future<bool> updatePropertyType({
    required String propertyTypeId,
    required String name,
    required String description,
    required List<String> defaultAmenities,
    required String icon,
  }) async {
    try {
      final response = await apiClient.put(
        '$_baseEndpoint/$propertyTypeId',
        data: {
          'propertyTypeId': propertyTypeId,
          'name': name,
          'description': description,
          'defaultAmenities': defaultAmenities,
          'icon': icon,
        },
      );
      
      final result = ResultDto.fromJson(response.data, null);
      return result.isSuccess;
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Server error occurred');
    }
  }

  @override
  Future<bool> deletePropertyType(String propertyTypeId) async {
    try {
      final response = await apiClient.delete('$_baseEndpoint/$propertyTypeId');
      final result = ResultDto.fromJson(response.data, null);
      return result.isSuccess;
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Server error occurred');
    }
  }
}
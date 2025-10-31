// lib/features/admin_properties/data/datasources/property_types_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:bookn_cp_app/core/network/api_client.dart';
import 'package:bookn_cp_app/core/error/exceptions.dart';
import 'package:bookn_cp_app/core/models/paginated_result.dart';
import '../models/property_type_model.dart';

abstract class PropertyTypesRemoteDataSource {
  Future<PaginatedResult<PropertyTypeModel>> getAllPropertyTypes({
    int? pageNumber,
    int? pageSize,
  });
  Future<PropertyTypeModel> getPropertyTypeById(String propertyTypeId);
  Future<String> createPropertyType(Map<String, dynamic> data);
  Future<bool> updatePropertyType(String propertyTypeId, Map<String, dynamic> data);
  Future<bool> deletePropertyType(String propertyTypeId);
}

class PropertyTypesRemoteDataSourceImpl implements PropertyTypesRemoteDataSource {
  final ApiClient apiClient;
  static const String _baseEndpoint = '/api/admin/property-types';
  
  PropertyTypesRemoteDataSourceImpl({required this.apiClient});
  
  @override
  Future<PaginatedResult<PropertyTypeModel>> getAllPropertyTypes({
    int? pageNumber,
    int? pageSize,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (pageNumber != null) 'pageNumber': pageNumber,
        if (pageSize != null) 'pageSize': pageSize,
      };
      
      final response = await apiClient.get(
        _baseEndpoint,
        queryParameters: queryParams,
      );
      
      return PaginatedResult<PropertyTypeModel>.fromJson(
        response.data,
        (json) => PropertyTypeModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? 'Failed to fetch property types');
    }
  }
  
  @override
  Future<PropertyTypeModel> getPropertyTypeById(String propertyTypeId) async {
    try {
      final response = await apiClient.get('$_baseEndpoint/$propertyTypeId');
      
      if (response.data['success'] == true) {
        return PropertyTypeModel.fromJson(response.data['data']);
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to get property type');
      }
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? 'Failed to fetch property type');
    }
  }
  
  @override
  Future<String> createPropertyType(Map<String, dynamic> data) async {
    try {
      final response = await apiClient.post(_baseEndpoint, data: data);
      
      if (response.data['success'] == true) {
        return response.data['data'] as String;
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to create property type');
      }
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? 'Failed to create property type');
    }
  }
  
  @override
  Future<bool> updatePropertyType(String propertyTypeId, Map<String, dynamic> data) async {
    try {
      final response = await apiClient.put(
        '$_baseEndpoint/$propertyTypeId',
        data: data,
      );
      
      return response.data['success'] == true;
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? 'Failed to update property type');
    }
  }
  
  @override
  Future<bool> deletePropertyType(String propertyTypeId) async {
    try {
      final response = await apiClient.delete('$_baseEndpoint/$propertyTypeId');
      return response.data['success'] == true;
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? 'Failed to delete property type');
    }
  }
}
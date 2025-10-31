// lib/features/admin_properties/data/datasources/properties_remote_datasource.dart

import 'package:bookn_cp_app/core/constants/api_constants.dart';
import 'package:dio/dio.dart';
import 'package:bookn_cp_app/core/network/api_client.dart';
import 'package:bookn_cp_app/core/network/api_exceptions.dart' as api;
import 'package:bookn_cp_app/core/error/exceptions.dart';
import 'package:bookn_cp_app/core/models/paginated_result.dart';
import '../models/property_model.dart';

abstract class PropertiesRemoteDataSource {
  Future<PaginatedResult<PropertyModel>> getAllProperties({
    int? pageNumber,
    int? pageSize,
    String? searchTerm,
    String? propertyTypeId,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    bool? isAscending,
    List<String>? amenityIds,
    List<int>? starRatings,
    double? minAverageRating,
    bool? isApproved,
    bool? hasActiveBookings,
  });
  
  Future<PropertyModel> getPropertyById(String propertyId);
  Future<PropertyModel> getPropertyDetails(String propertyId, {bool includeUnits = false});
  Future<PropertyModel> getPropertyDetailsPublic(String propertyId, {bool includeUnits = false});
  Future<String> createProperty(Map<String, dynamic> propertyData);
  Future<bool> updateProperty(String propertyId, Map<String, dynamic> propertyData);
  Future<bool> updatePropertyAsOwner(String propertyId, Map<String, dynamic> propertyData);
  Future<bool> deleteProperty(String propertyId);
  Future<bool> approveProperty(String propertyId);
  Future<bool> rejectProperty(String propertyId);
  Future<PaginatedResult<PropertyModel>> getPendingProperties({
    int? pageNumber,
    int? pageSize,
  });
  Future<bool> addPropertyToSections(String propertyId, List<String> sectionIds);
}

class PropertiesRemoteDataSourceImpl implements PropertiesRemoteDataSource {
  final ApiClient apiClient;
  static const String _baseEndpoint = '/api/admin/properties';
  
  PropertiesRemoteDataSourceImpl({required this.apiClient});
  
  @override
  Future<PaginatedResult<PropertyModel>> getAllProperties({
    int? pageNumber,
    int? pageSize,
    String? searchTerm,
    String? propertyTypeId,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    bool? isAscending,
    List<String>? amenityIds,
    List<int>? starRatings,
    double? minAverageRating,
    bool? isApproved,
    bool? hasActiveBookings,
  }) async {
    try {
      // Enforce backend max page size to prevent server errors
      final effectivePageSize = (pageSize == null)
          ? ApiConstants.defaultPageSize
          : (pageSize > ApiConstants.maxPageSize
              ? ApiConstants.maxPageSize
              : pageSize);
      final queryParams = <String, dynamic>{
        if (pageNumber != null) 'pageNumber': pageNumber,
        if (effectivePageSize != null) 'pageSize': effectivePageSize,
        if (searchTerm != null) 'searchTerm': searchTerm,
        if (propertyTypeId != null) 'propertyTypeId': propertyTypeId,
        if (minPrice != null) 'minPrice': minPrice,
        if (maxPrice != null) 'maxPrice': maxPrice,
        if (sortBy != null) 'sortBy': sortBy,
        if (isAscending != null) 'isAscending': isAscending,
        if (amenityIds != null && amenityIds.isNotEmpty) 'amenityIds': amenityIds,
        if (starRatings != null && starRatings.isNotEmpty) 'starRatings': starRatings,
        if (minAverageRating != null) 'minAverageRating': minAverageRating,
        if (isApproved != null) 'isApproved': isApproved,
        if (hasActiveBookings != null) 'hasActiveBookings': hasActiveBookings,
      };
      
      final response = await apiClient.get(
        _baseEndpoint,
        queryParameters: queryParams,
      );
      
      return PaginatedResult<PropertyModel>.fromJson(
        response.data,
        (json) => PropertyModel.fromJson(json as Map<String, dynamic>),
      );
    } on api.ApiException catch (e) {
      throw ServerException(e.message);
    } on DioException catch (e) { // Fallback if ApiClient throws DioException in some paths
      throw ServerException(e.response?.data['message'] ?? 'Failed to fetch properties');
    }
  }
  
  @override
  Future<PropertyModel> getPropertyById(String propertyId) async {
    try {
      final response = await apiClient.get('$_baseEndpoint/$propertyId');
      
      if (response.data['success'] == true) {
        return PropertyModel.fromJson(response.data['data']);
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to get property');
      }
    } on api.ApiException catch (e) {
      throw ServerException(e.message);
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? 'Failed to fetch property');
    }
  }
  
  @override
  Future<PropertyModel> getPropertyDetails(String propertyId, {bool includeUnits = false}) async {
    try {
      final response = await apiClient.get(
        '$_baseEndpoint/$propertyId/details',
        queryParameters: {'includeUnits': includeUnits},
      );
      
      if (response.data['success'] == true) {
        return PropertyModel.fromJson(response.data['data']);
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to get property details');
      }
    } on api.ApiException catch (e) {
      throw ServerException(e.message);
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? 'Failed to fetch property details');
    }
  }

  @override
  Future<PropertyModel> getPropertyDetailsPublic(String propertyId, {bool includeUnits = false}) async {
    try {
      final response = await apiClient.get(
        '/api/client/properties/$propertyId',
        queryParameters: {'includeUnits': includeUnits},
      );

      if (response.data['success'] == true || response.statusCode == 200) {
        final data = response.data is Map && response.data['data'] != null
            ? response.data['data']
            : response.data;
        return PropertyModel.fromJson(data as Map<String, dynamic>);
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to get public property details');
      }
    } on api.ApiException catch (e) {
      throw ServerException(e.message);
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? 'Failed to fetch public property details');
    }
  }
  
  @override
  Future<String> createProperty(Map<String, dynamic> propertyData) async {
    try {
      // Remove http:// from image URLs before saving
      if (propertyData['images'] != null) {
        final images = propertyData['images'] as List;
        for (int i = 0; i < images.length; i++) {
          if (images[i] is String) {
            images[i] = (images[i] as String).replaceAll(ApiConstants.imageBaseUrl, '');
          }
        }
      }
      // Ensure currency is sent via header for context if provided
      final currency = propertyData['currency'];
      final headers = <String, dynamic>{};
      if (currency != null && currency is String && currency.isNotEmpty) {
        headers[ApiConstants.xPropertyCurrency] = currency;
      }
      
      final response = await apiClient.post(
        _baseEndpoint,
        data: propertyData,
        options: Options(headers: headers),
      );
      
      if (response.data['success'] == true) {
        return response.data['data'] as String;
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to create property');
      }
    } on api.ApiException catch (e) {
      throw ServerException(e.message);
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? 'Failed to create property');
    }
  }
  
  @override
  Future<bool> updateProperty(String propertyId, Map<String, dynamic> propertyData) async {
    try {
      // Remove http:// from image URLs before saving
      if (propertyData['images'] != null) {
        final images = propertyData['images'] as List;
        for (int i = 0; i < images.length; i++) {
          if (images[i] is String) {
            images[i] = (images[i] as String).replaceAll(ApiConstants.imageBaseUrl, '');
          }
        }
      }
      // Ensure currency header if provided
      final currency = propertyData['currency'];
      final headers = <String, dynamic>{};
      if (currency != null && currency is String && currency.isNotEmpty) {
        headers[ApiConstants.xPropertyCurrency] = currency;
      }
      
      final response = await apiClient.put(
        '$_baseEndpoint/$propertyId',
        data: propertyData,
        options: Options(headers: headers),
      );

      final data = response.data;
      if (data is Map) {
        final success = data['success'] == true;
        if (success) return true;
        final message = data['message'] ?? data['error'] ?? 'فشل تحديث العقار';
        throw ServerException(message);
      }
      throw ServerException('فشل تحديث العقار: رد غير متوقع من الخادم');
    } on api.ApiException catch (e) {
      throw ServerException(e.message);
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? 'Failed to update property');
    }
  }

  @override
  Future<bool> updatePropertyAsOwner(String propertyId, Map<String, dynamic> propertyData) async {
    try {
      // Normalize images and currency header similar to admin update
      if (propertyData['images'] != null) {
        final images = propertyData['images'] as List;
        for (int i = 0; i < images.length; i++) {
          if (images[i] is String) {
            images[i] = (images[i] as String).replaceAll(ApiConstants.imageBaseUrl, '');
          }
        }
      }
      final currency = propertyData['currency'];
      final headers = <String, dynamic>{};
      if (currency != null && currency is String && currency.isNotEmpty) {
        headers[ApiConstants.xPropertyCurrency] = currency;
      }

      final response = await apiClient.put(
        '/api/client/properties/$propertyId',
        data: propertyData,
        options: Options(headers: headers),
      );

      final data = response.data;
      if (data is Map) {
        final success = data['success'] == true || response.statusCode == 200;
        if (success) return true;
        final message = data['message'] ?? data['error'] ?? 'Failed to update property as owner';
        throw ServerException(message);
      }
      return response.statusCode == 200;
    } on api.ApiException catch (e) {
      throw ServerException(e.message);
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? 'Failed to update property as owner');
    }
  }
  
  @override
  Future<bool> deleteProperty(String propertyId) async {
    try {
      final response = await apiClient.delete('$_baseEndpoint/$propertyId');
      if (response.data is Map && response.data['success'] == true) {
        return true;
      }
      // إذا أعاد الخادم رسالة فشل بأسباب الارتباطات
      final msg = (response.data is Map) ? response.data['message'] : null;
      throw ServerException(msg ?? 'Failed to delete property');
    } on api.ApiException catch (e) {
      throw ServerException(e.message);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map ? (data['message'] ?? data['error']) : e.message;
      throw ServerException(message ?? 'Failed to delete property');
    }
  }
  
  @override
  Future<bool> approveProperty(String propertyId) async {
    try {
      final response = await apiClient.post('$_baseEndpoint/$propertyId/approve');
      return response.data['success'] == true;
    } on api.ApiException catch (e) {
      throw ServerException(e.message);
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? 'Failed to approve property');
    }
  }
  
  @override
  Future<bool> rejectProperty(String propertyId) async {
    try {
      final response = await apiClient.post('$_baseEndpoint/$propertyId/reject');
      return response.data['success'] == true;
    } on api.ApiException catch (e) {
      throw ServerException(e.message);
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? 'Failed to reject property');
    }
  }
  
  @override
  Future<PaginatedResult<PropertyModel>> getPendingProperties({
    int? pageNumber,
    int? pageSize,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (pageNumber != null) 'pageNumber': pageNumber,
        if (pageSize != null) 'pageSize': pageSize,
      };
      
      final response = await apiClient.get(
        '$_baseEndpoint/pending',
        queryParameters: queryParams,
      );
      
      return PaginatedResult<PropertyModel>.fromJson(
        response.data,
        (json) => PropertyModel.fromJson(json as Map<String, dynamic>),
      );
    } on api.ApiException catch (e) {
      throw ServerException(e.message);
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? 'Failed to fetch pending properties');
    }
  }
  
  @override
  Future<bool> addPropertyToSections(String propertyId, List<String> sectionIds) async {
    try {
      final response = await apiClient.post(
        '/api/admin/properties/$propertyId/sections',
        data: {'sectionIds': sectionIds},
      );
      return response.data['success'] == true;
    } on api.ApiException catch (e) {
      throw ServerException(e.message);
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? 'Failed to add property to sections');
    }
  }
}
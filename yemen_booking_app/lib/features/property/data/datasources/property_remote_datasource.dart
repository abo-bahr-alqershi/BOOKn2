import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/request_logger.dart';
import '../models/property_detail_model.dart';
import '../models/unit_model.dart';
import '../models/review_model.dart';

abstract class PropertyRemoteDataSource {
  Future<PropertyDetailModel> getPropertyDetails({
    required String propertyId,
    String? userId,
  });

  Future<List<UnitModel>> getPropertyUnits({
    required String propertyId,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    required int guestsCount,
  });

  Future<List<ReviewModel>> getPropertyReviews({
    required String propertyId,
    int pageNumber = 1,
    int pageSize = 20,
    String? sortBy,
    String? sortDirection,
    bool withImagesOnly = false,
    String? userId,
  });

  Future<bool> addToFavorites({
    required String propertyId,
    required String userId,
    String? notes,
    DateTime? desiredVisitDate,
    double? expectedBudget,
    String currency = 'YER',
  });

  Future<bool> removeFromFavorites({
    required String propertyId,
    required String userId,
  });

  Future<bool> updateViewCount({
    required String propertyId,
  });
}

class PropertyRemoteDataSourceImpl implements PropertyRemoteDataSource {
  final ApiClient apiClient;

  PropertyRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<PropertyDetailModel> getPropertyDetails({
    required String propertyId,
    String? userId,
  }) async {
    const requestName = 'getPropertyDetails';
    logRequestStart(requestName, details: {
      'propertyId': propertyId,
      if (userId != null) 'userId': userId,
    });
    try {
      final queryParams = <String, dynamic>{};
      if (userId != null) {
        queryParams['userId'] = userId;
      }

      final response = await apiClient.get(
        '/api/client/properties/$propertyId',
        queryParameters: queryParams,
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.statusCode == 200) {
        final data = response.data['data'];
        return PropertyDetailModel.fromJson(data);
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to load property details');
      }
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<List<UnitModel>> getPropertyUnits({
    required String propertyId,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    required int guestsCount,
  }) async {
    const requestName = 'getPropertyUnits';
    logRequestStart(requestName, details: {
      'propertyId': propertyId,
      if (checkInDate != null) 'checkInDate': checkInDate.toIso8601String(),
      if (checkOutDate != null) 'checkOutDate': checkOutDate.toIso8601String(),
      'guestsCount': guestsCount,
    });
    try {
      final response = await apiClient.get(
        '/api/client/units/available',
        queryParameters: <String, dynamic>{
          'propertyId': propertyId,
          if (checkInDate != null) 'checkIn': checkInDate.toIso8601String(),
          if (checkOutDate != null) 'checkOut': checkOutDate.toIso8601String(),
          'guestsCount': guestsCount,
        },
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.statusCode == 200) {
        final body = response.data;
        List<dynamic>? unitsJson;
        if (body is Map<String, dynamic>) {
          final rootData = body['data'];
          if (rootData is Map<String, dynamic> && rootData['units'] is List) {
            unitsJson = rootData['units'] as List<dynamic>;
          } else if (rootData is List) {
            unitsJson = rootData;
          } else if (body['units'] is List) {
            unitsJson = body['units'] as List<dynamic>;
          } else if (body['items'] is List) {
            unitsJson = body['items'] as List<dynamic>;
          }
        } else if (body is List) {
          unitsJson = body;
        }
        if (unitsJson == null) {
          // Graceful fallback: empty list when response has no units array
          return <UnitModel>[];
        }
        return unitsJson.map((json) => UnitModel.fromJson(json)).toList();
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to load units');
      }
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<List<ReviewModel>> getPropertyReviews({
    required String propertyId,
    int pageNumber = 1,
    int pageSize = 20,
    String? sortBy,
    String? sortDirection,
    bool withImagesOnly = false,
    String? userId,
  }) async {
    const requestName = 'getPropertyReviews';
    logRequestStart(requestName, details: {
      'propertyId': propertyId,
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      if (sortBy != null) 'sortBy': sortBy,
      if (sortDirection != null) 'sortDirection': sortDirection,
      'withImagesOnly': withImagesOnly,
      if (userId != null) 'userId': userId,
    });
    try {
      final response = await apiClient.get(
        '/api/client/reviews/property',
        queryParameters: <String, dynamic>{
          'propertyId': propertyId,
          'pageNumber': pageNumber,
          'pageSize': pageSize,
          if (sortBy != null) 'sortBy': sortBy,
          if (sortDirection != null) 'sortDirection': sortDirection,
          'withImagesOnly': withImagesOnly,
          if (userId != null) 'userId': userId,
        },
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.statusCode == 200) {
        final data = response.data['data']['items'] as List;
        return data.map((json) => ReviewModel.fromJson(json)).toList();
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to load reviews');
      }
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<bool> addToFavorites({
    required String propertyId,
    required String userId,
    String? notes,
    DateTime? desiredVisitDate,
    double? expectedBudget,
    String currency = 'YER',
  }) async {
    const requestName = 'addToFavorites';
    logRequestStart(requestName, details: {
      'propertyId': propertyId,
      'userId': userId,
      if (notes != null) 'notes': notes,
      if (desiredVisitDate != null) 'desiredVisitDate': desiredVisitDate.toIso8601String(),
      if (expectedBudget != null) 'expectedBudget': expectedBudget,
      'currency': currency,
    });
    try {
      final response = await apiClient.post(
        '/api/client/favorites',
        data: <String, dynamic>{
          'userId': userId,
          'propertyId': propertyId,
        },
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.data;
        bool success = false;
        if (body is Map<String, dynamic>) {
          if (body['success'] is bool) success = body['success'] as bool;
          final data = body['data'];
          if (data is bool) {
            success = data;
          } else if (data is Map) {
            final map = Map<String, dynamic>.from(data as Map);
            if (map['success'] is bool) success = map['success'] as bool;
            if (map['Success'] is bool) success = map['Success'] as bool;
          }
        }
        return success;
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to add to favorites');
      }
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<bool> removeFromFavorites({
    required String propertyId,
    required String userId,
  }) async {
    const requestName = 'removeFromFavorites';
    logRequestStart(requestName, details: {
      'propertyId': propertyId,
      'userId': userId,
    });
    try {
      final response = await apiClient.delete(
        '/api/client/favorites',
        data: {
          'propertyId': propertyId,
          'userId': userId,
        },
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.statusCode == 200) {
        final body = response.data;
        bool success = false;
        if (body is Map<String, dynamic>) {
          if (body['success'] is bool) success = body['success'] as bool;
          final data = body['data'];
          if (data is bool) {
            success = data;
          } else if (data is Map) {
            final map = Map<String, dynamic>.from(data as Map);
            if (map['success'] is bool) success = map['success'] as bool;
            if (map['Success'] is bool) success = map['Success'] as bool;
          }
        }
        return success;
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to remove from favorites');
      }
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<bool> updateViewCount({
    required String propertyId,
  }) async {
    const requestName = 'updateViewCount';
    logRequestStart(requestName, details: {
      'propertyId': propertyId,
    });
    try {
      final response = await apiClient.post(
        '/api/client/properties/view-count',
        data: {
          'propertyId': propertyId,
        },
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.statusCode == 200) {
        return response.data['data'] ?? false;
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to update view count');
      }
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ServerException('Unexpected error: $e');
    }
  }
}
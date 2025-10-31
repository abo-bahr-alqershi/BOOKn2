import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/models/result_dto.dart';
import '../../../../core/network/api_client.dart';
import '../models/amenity_model.dart';
import '../models/property_detail_model.dart';
import '../models/review_model.dart';
import '../models/unit_model.dart';

abstract class PropertyRemoteDataSource {
  Future<ResultDto<PropertyDetailModel>> getPropertyDetails({
    required String propertyId,
    String? userId,
  });

  Future<ResultDto<List<UnitModel>>> getPropertyUnits({
    required String propertyId,
    DateTime? checkInDate,
    DateTime? checkOutDate,
  });

  Future<ResultDto<PaginatedResult<ReviewModel>>> getPropertyReviews({
    required String propertyId,
    int pageNumber = 1,
    int pageSize = 20,
    String? sortBy,
    int? filterByRating,
  });

  Future<ResultDto<bool>> addToFavorites({
    required String propertyId,
    required String userId,
    String? notes,
    DateTime? desiredVisitDate,
    double? expectedBudget,
    String currency = 'YER',
  });

  Future<ResultDto<bool>> removeFromFavorites({
    required String propertyId,
    required String userId,
  });

  Future<ResultDto<bool>> updateViewCount({
    required String propertyId,
  });

  Future<ResultDto<bool>> checkAvailability({
    required String propertyId,
    required DateTime checkInDate,
    required DateTime checkOutDate,
  });

  Future<ResultDto<List<AmenityModel>>> getPropertyAmenities({
    required String propertyId,
  });

  Future<ResultDto<List<PropertyPolicyModel>>> getPropertyPolicies({
    required String propertyId,
  });

  Future<ResultDto<Map<String, dynamic>>> searchProperties({
    String? searchQuery,
    String? city,
    String? propertyType,
    double? minPrice,
    double? maxPrice,
    int? minRating,
    List<String>? amenities,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    int? guests,
    double? latitude,
    double? longitude,
    double? radiusKm,
    String? sortBy,
    int pageNumber = 1,
    int pageSize = 20,
  });

  Future<ResultDto<List<PropertyDetailModel>>> getNearbyProperties({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
    int limit = 20,
  });
}

class PropertyRemoteDataSourceImpl implements PropertyRemoteDataSource {
  final ApiClient apiClient;

  PropertyRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<ResultDto<PropertyDetailModel>> getPropertyDetails({
    required String propertyId,
    String? userId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (userId != null) {
        queryParams['userId'] = userId;
      }

      final response = await apiClient.get(
        '/api/client/properties/$propertyId',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return ResultDto.fromJson(
          response.data,
          (json) => PropertyDetailModel.fromJson(json),
        );
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to load property details');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<ResultDto<List<UnitModel>>> getPropertyUnits({
    required String propertyId,
    DateTime? checkInDate,
    DateTime? checkOutDate,
  }) async {
    try {
      final response = await apiClient.get(
        '/api/client/units/available',
        queryParameters: <String, dynamic>{
          'propertyId': propertyId,
          if (checkInDate != null) 'checkIn': checkInDate.toIso8601String(),
          if (checkOutDate != null) 'checkOut': checkOutDate.toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        // map the 'units' list from the response data
        return ResultDto.fromJson(
          response.data,
          (json) => (json['units'] as List)
              .map((e) => UnitModel.fromJson(e))
              .toList(),
        );
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to load units');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<ResultDto<PaginatedResult<ReviewModel>>> getPropertyReviews({
    required String propertyId,
    int pageNumber = 1,
    int pageSize = 20,
    String? sortBy,
    int? filterByRating,
  }) async {
    try {
      final response = await apiClient.get(
        '/api/client/properties/$propertyId/reviews',
        queryParameters: {
          'pageNumber': pageNumber,
          'pageSize': pageSize,
          if (sortBy != null) 'sortBy': sortBy,
          if (filterByRating != null) 'rating': filterByRating,
        },
      );

      if (response.statusCode == 200) {
        return ResultDto.fromJson(
          response.data,
          (json) => PaginatedResult(
            items: (json['items'] as List).map((e) => ReviewModel.fromJson(e)).toList(),
            pageNumber: json['pageNumber'] ?? pageNumber,
            pageSize: json['pageSize'] ?? pageSize,
            totalCount: json['totalCount'] ?? 0,
          ),
        );
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to load reviews');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<ResultDto<bool>> addToFavorites({
    required String propertyId,
    required String userId,
    String? notes,
    DateTime? desiredVisitDate,
    double? expectedBudget,
    String currency = 'YER',
  }) async {
    try {
      final response = await apiClient.post(
        '/api/client/properties/wishlist',
        data: {
          'propertyId': propertyId,
          if (notes != null) 'notes': notes,
          if (desiredVisitDate != null) 'desiredVisitDate': desiredVisitDate.toIso8601String(),
          if (expectedBudget != null) 'expectedBudget': expectedBudget,
          'currency': currency,
          'userId': userId,
        },
      );

      if (response.statusCode == 200) {
        return ResultDto.fromJson(response.data, (json) => json as bool);
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to add to favorites');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<ResultDto<bool>> removeFromFavorites({
    required String propertyId,
    required String userId,
  }) async {
    try {
      final response = await apiClient.delete(
        '/api/client/favorites',
        data: {
          'userId': userId,
          'propertyId': propertyId,
        },
      );

      if (response.statusCode == 200) {
        return ResultDto.fromJson(response.data, (json) => json as bool);
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to remove from favorites');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<ResultDto<bool>> updateViewCount({
    required String propertyId,
  }) async {
    try {
      final response = await apiClient.post(
        '/api/client/properties/view-count',
        data: {
          'propertyId': propertyId,
        },
      );

      if (response.statusCode == 200) {
        return ResultDto.fromJson(response.data, (json) => json as bool);
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to update view count');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<ResultDto<bool>> checkAvailability({
    required String propertyId,
    required DateTime checkInDate,
    required DateTime checkOutDate,
  }) async {
    try {
      final response = await apiClient.get(
        '/api/client/properties/availability',
        queryParameters: {
          'id': propertyId,
          'checkIn': checkInDate.toIso8601String(),
          'checkOut': checkOutDate.toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        return ResultDto.fromJson(
          response.data,
          (json) => json as bool,
        );
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to check availability');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<ResultDto<List<AmenityModel>>> getPropertyAmenities({
    required String propertyId,
  }) async {
    try {
      // Fetch global amenities (server does not support property-specific)
      final response = await apiClient.get(
        '/api/client/amenities',
      );

      if (response.statusCode == 200) {
        return ResultDto.fromJson(
          response.data,
          (json) => (json as List).map((e) => AmenityModel.fromJson(e)).toList(),
        );
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to load amenities');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<ResultDto<List<PropertyPolicyModel>>> getPropertyPolicies({
    required String propertyId,
  }) async {
    try {
      final response = await apiClient.get(
        '/api/client/properties/$propertyId/policies',
      );

      if (response.statusCode == 200) {
        return ResultDto.fromJson(
          response.data,
          (json) => (json as List).map((e) => PropertyPolicyModel.fromJson(e)).toList(),
        );
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to load policies');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<ResultDto<Map<String, dynamic>>> searchProperties({
    String? searchQuery,
    String? city,
    String? propertyType,
    double? minPrice,
    double? maxPrice,
    int? minRating,
    List<String>? amenities,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    int? guests,
    double? latitude,
    double? longitude,
    double? radiusKm,
    String? sortBy,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'pageNumber': pageNumber,
        'pageSize': pageSize,
      };

      if (searchQuery != null) queryParams['searchQuery'] = searchQuery;
      if (city != null) queryParams['city'] = city;
      if (propertyType != null) queryParams['propertyType'] = propertyType;
      if (minPrice != null) queryParams['minPrice'] = minPrice;
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice;
      if (minRating != null) queryParams['minRating'] = minRating;
      if (amenities != null && amenities.isNotEmpty) {
        queryParams['amenities'] = amenities.join(',');
      }
      if (checkInDate != null) queryParams['checkInDate'] = checkInDate.toIso8601String();
      if (checkOutDate != null) queryParams['checkOutDate'] = checkOutDate.toIso8601String();
      if (guests != null) queryParams['guests'] = guests;
      if (latitude != null) queryParams['latitude'] = latitude;
      if (longitude != null) queryParams['longitude'] = longitude;
      if (radiusKm != null) queryParams['radiusKm'] = radiusKm;
      if (sortBy != null) queryParams['sortBy'] = sortBy;

      final response = await apiClient.get(
        '/api/client/properties/search',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return ResultDto.fromJson(
          response.data,
          (json) => json,
        );
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to search properties');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<ResultDto<List<PropertyDetailModel>>> getNearbyProperties({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
    int limit = 20,
  }) async {
    try {
      final queryParams = {
        'latitude': latitude,
        'longitude': longitude,
        'radiusKm': radiusKm,
        'limit': limit,
      };

      final response = await apiClient.get(
        '/api/client/properties/nearby',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return ResultDto.fromJson(
          response.data,
          (json) => (json as List).map((e) => PropertyDetailModel.fromJson(e)).toList(),
        );
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to load nearby properties');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }
}
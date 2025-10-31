import 'package:dio/dio.dart';
import 'package:yemen_booking_app/core/models/paginated_result.dart';
import '../../../../core/error/exceptions.dart';
import '../models/search_properties_response_model.dart';
import '../../../../core/models/result_dto.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/request_logger.dart';
import '../models/search_filter_model.dart';
import '../models/search_result_model.dart';

abstract class SearchRemoteDataSource {
  Future<ResultDto<SearchPropertiesResponseModel>> searchProperties({
    String? searchTerm,
    String? city,
    String? propertyTypeId,
    double? minPrice,
    double? maxPrice,
    int? minStarRating,
    List<String>? requiredAmenities,
    String? unitTypeId,
    List<String>? serviceIds,
    Map<String, dynamic>? dynamicFieldFilters,
    DateTime? checkIn,
    DateTime? checkOut,
    int? guestsCount,
    double? latitude,
    double? longitude,
    double? radiusKm,
    String? preferredCurrency,
    String? sortBy,
    int pageNumber = 1,
    int pageSize = 20,
  });

  Future<ResultDto<SearchFiltersModel>> getSearchFilters();

  Future<ResultDto<List<String>>> getSearchSuggestions({
    required String query,
    int limit = 10,
  });

  Future<ResultDto<PaginatedResult<SearchResultModel>>> getRecommendedProperties({
    String? userId,
    int limit = 10,
  });

  Future<ResultDto<List<String>>> getPopularDestinations({
    int limit = 10,
  });
}

class SearchRemoteDataSourceImpl implements SearchRemoteDataSource {
  final ApiClient apiClient;

  SearchRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<ResultDto<SearchPropertiesResponseModel>> searchProperties({
    String? searchTerm,
    String? city,
    String? propertyTypeId,
    double? minPrice,
    double? maxPrice,
    int? minStarRating,
    List<String>? requiredAmenities,
    String? unitTypeId,
    List<String>? serviceIds,
    Map<String, dynamic>? dynamicFieldFilters,
    DateTime? checkIn,
    DateTime? checkOut,
    int? guestsCount,
    double? latitude,
    double? longitude,
    double? radiusKm,
    String? preferredCurrency,
    String? sortBy,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    const requestName = 'search.searchProperties';
    logRequestStart(requestName, details: {
      if (searchTerm != null) 'searchTerm': searchTerm,
      if (city != null) 'city': city,
      if (propertyTypeId != null) 'propertyTypeId': propertyTypeId,
      if (minPrice != null) 'minPrice': minPrice,
      if (maxPrice != null) 'maxPrice': maxPrice,
      if (minStarRating != null) 'minStarRating': minStarRating,
      if (unitTypeId != null) 'unitTypeId': unitTypeId,
      if (serviceIds != null && serviceIds.isNotEmpty) 'serviceIds': serviceIds,
      if (checkIn != null) 'checkIn': checkIn.toIso8601String(),
      if (checkOut != null) 'checkOut': checkOut.toIso8601String(),
      if (guestsCount != null) 'guestsCount': guestsCount,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (radiusKm != null) 'radiusKm': radiusKm,
      if (preferredCurrency != null) 'preferredCurrency': preferredCurrency,
      if (sortBy != null) 'sortBy': sortBy,
      'pageNumber': pageNumber,
      'pageSize': pageSize,
    });
    try {
      // Build query parameters to match backend GET endpoint
      final queryParams = <String, dynamic>{
        'pageNumber': pageNumber,
        'pageSize': pageSize,
        if (searchTerm != null) 'searchTerm': searchTerm,
        if (city != null) 'city': city,
        if (propertyTypeId != null) 'propertyTypeId': propertyTypeId,
        if (minPrice != null) 'minPrice': minPrice,
        if (maxPrice != null) 'maxPrice': maxPrice,
        if (minStarRating != null) 'minStarRating': minStarRating,
        if (unitTypeId != null) 'unitTypeId': unitTypeId,
        if (checkIn != null) 'checkIn': checkIn.toIso8601String(),
        if (checkOut != null) 'checkOut': checkOut.toIso8601String(),
        if (guestsCount != null) 'guestsCount': guestsCount,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (radiusKm != null) 'radiusKm': radiusKm,
        if (preferredCurrency != null) 'preferredCurrency': preferredCurrency,
        if (sortBy != null) 'sortBy': sortBy,
      };

      // Encode lists for ASP.NET Core binder: requiredAmenities[0]=..&requiredAmenities[1]=..
      if (requiredAmenities != null && requiredAmenities.isNotEmpty) {
        for (var i = 0; i < requiredAmenities.length; i++) {
          queryParams['requiredAmenities[$i]'] = requiredAmenities[i];
        }
      }
      if (serviceIds != null && serviceIds.isNotEmpty) {
        for (var i = 0; i < serviceIds.length; i++) {
          queryParams['serviceIds[$i]'] = serviceIds[i];
        }
      }
      // Encode dynamic field filters as: dynamicFieldFilters[key]=value
      if (dynamicFieldFilters != null && dynamicFieldFilters.isNotEmpty) {
        dynamicFieldFilters.forEach((key, value) {
          queryParams['dynamicFieldFilters[$key]'] = value;
        });
      }

      final response = await apiClient.get(
        '/api/client/properties/search',
        queryParameters: queryParams,
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.statusCode == 200) {
        return ResultDto.fromJson(
          response.data,
          (dataJson) => SearchPropertiesResponseModel.fromJson(
            dataJson,
          ),
        );
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to search properties');
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
  Future<ResultDto<SearchFiltersModel>> getSearchFilters() async {
    const requestName = 'search.getSearchFilters';
    logRequestStart(requestName);
    try {
      final response = await apiClient.get('/api/client/search-filters/filters');

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.statusCode == 200) {
        return ResultDto.fromJson(
          response.data,
          (json) => SearchFiltersModel.fromJson(json),
        );
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to load search filters');
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
  Future<ResultDto<List<String>>> getSearchSuggestions({
    required String query,
    int limit = 10,
  }) async {
    const requestName = 'search.getSearchSuggestions';
    logRequestStart(requestName, details: {
      'query': query,
      'limit': limit,
    });
    try {
      final response = await apiClient.get(
        '/api/client/search/suggestions',
        queryParameters: {
          'query': query,
          'limit': limit,
        },
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.statusCode == 200) {
        return ResultDto.fromJson(
          response.data,
          (json) => (json as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
        );
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to get suggestions');
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
  Future<ResultDto<PaginatedResult<SearchResultModel>>> getRecommendedProperties({
    String? userId,
    int limit = 10,
  }) async {
    const requestName = 'search.getRecommendedProperties';
    logRequestStart(requestName, details: {
      if (userId != null) 'userId': userId,
      'limit': limit,
    });
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
      };
      if (userId != null) queryParams['userId'] = userId;

      final response = await apiClient.get(
        '/api/client/search-filters/recommended-properties',
        queryParameters: queryParams,
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.statusCode == 200) {
        return ResultDto.fromJson(
          response.data,
          (json) => PaginatedResult.fromJson(
            json,
            (itemJson) => SearchResultModel.fromJson(itemJson),
          ),
        );
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to get recommended properties');
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
  Future<ResultDto<List<String>>> getPopularDestinations({
    int limit = 10,
  }) async {
    const requestName = 'search.getPopularDestinations';
    logRequestStart(requestName, details: {'limit': limit});
    try {
      final response = await apiClient.get(
        '/api/client/search-filters/popular-destinations',
        queryParameters: {
          'limit': limit,
        },
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.statusCode == 200) {
        return ResultDto.fromJson(
          response.data,
          (dataJson) => (dataJson as List)
              .map<String>((e) => (e as Map<String, dynamic>)['cityName'] as String)
              .toList(),
        );
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to get popular destinations');
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
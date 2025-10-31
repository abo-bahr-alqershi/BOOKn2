import 'package:dio/dio.dart';
import 'package:yemen_booking_app/core/error/exceptions.dart';
import 'package:yemen_booking_app/core/network/api_client.dart';
import 'package:yemen_booking_app/core/utils/request_logger.dart';
import 'package:yemen_booking_app/core/models/paginated_result.dart' as core;
import 'package:yemen_booking_app/features/home/data/models/section_item_models.dart';
import '../models/section_model.dart';
import '../models/property_type_model.dart';
import '../models/unit_type_model.dart';
import '../models/property_type_with_units_model.dart';
import 'package:yemen_booking_app/services/local_storage_service.dart';

abstract class HomeRemoteDataSource {
  // Analytics
  Future<void> recordSectionImpression({required String sectionId});
  Future<void> recordSectionInteraction({
    required String sectionId,
    required String interactionType,
    String? itemId,
    Map<String, dynamic>? metadata,
  });

  // Sections
  Future<core.PaginatedResult<SectionModel>> getSections({
    int pageNumber = 1,
    int pageSize = 10,
    String? target,
    String? type,
  });

  // Section Property Items (properties target)
  Future<core.PaginatedResult<SectionPropertyItemModel>>
      getSectionPropertyItems({
    required String sectionId,
    int pageNumber = 1,
    int pageSize = 10,
  });

  // Property Types
  Future<List<PropertyTypeModel>> getPropertyTypes();

  // Unit Types
  Future<List<UnitTypeModel>> getUnitTypes({required String propertyTypeId});

  // Combined: Property Types with Unit Types
  Future<List<PropertyTypeWithUnitsModel>> getPropertyTypesWithUnits();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final ApiClient apiClient;
  final LocalStorageService localStorage;

  HomeRemoteDataSourceImpl(
      {required this.apiClient, required this.localStorage});

  @override
  Future<void> recordSectionImpression({required String sectionId}) async {
    const requestName = 'recordSectionImpression';
    logRequestStart(requestName, details: {'sectionId': sectionId});

    try {
      final response = await apiClient.post(
        '/api/client/analytics/section-impression',
        data: {'sectionId': sectionId},
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException(
            response.data['message'] ?? 'Failed to record section impression');
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
  Future<void> recordSectionInteraction({
    required String sectionId,
    required String interactionType,
    String? itemId,
    Map<String, dynamic>? metadata,
  }) async {
    const requestName = 'recordSectionInteraction';
    logRequestStart(requestName, details: {
      'sectionId': sectionId,
      'interactionType': interactionType,
      if (itemId != null) 'itemId': itemId,
      if (metadata != null) 'metadata': metadata,
    });

    try {
      final response = await apiClient.post(
        '/api/client/analytics/section-interaction',
        data: {
          'sectionId': sectionId,
          'interactionType': interactionType,
          if (itemId != null) 'itemId': itemId,
          if (metadata != null) 'metadata': metadata,
        },
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException(
            response.data['message'] ?? 'Failed to record section interaction');
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
  Future<core.PaginatedResult<SectionModel>> getSections({
    int pageNumber = 1,
    int pageSize = 10,
    String? target,
    String? type,
  }) async {
    const requestName = 'getSections';
    logRequestStart(requestName, details: {
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      if (target != null) 'target': target,
      if (type != null) 'type': type,
    });

    try {
      final queryParams = <String, dynamic>{
        'pageNumber': pageNumber,
        'pageSize': pageSize,
      };

      if (target != null) queryParams['target'] = target;
      if (type != null) queryParams['type'] = type;
      final selectedCity = localStorage.getSelectedCity();
      if (selectedCity.isNotEmpty) {
        queryParams['cityName'] = selectedCity;
      }

      final response = await apiClient.get(
        '/api/client/sections',
        queryParameters: queryParams,
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Handle different response structures
        if (responseData is Map<String, dynamic>) {
          // Check if it's wrapped in a 'data' field
          final dataField = responseData['data'];
          if (dataField != null) {
            if (dataField is Map<String, dynamic>) {
              // Paginated response structure
              return core.PaginatedResult.fromJson(
                dataField,
                (json) => SectionModel.fromJson(json),
              );
            } else if (dataField is List) {
              // Simple list response wrapped in data
              final sections = (dataField)
                  .map((json) => SectionModel.fromJson(json))
                  .toList();
              return core.PaginatedResult<SectionModel>(
                items: sections,
                pageNumber: pageNumber,
                pageSize: pageSize,
                totalCount: sections.length,
              );
            }
          }

          // Direct paginated response
          if (responseData.containsKey('items')) {
            return core.PaginatedResult.fromJson(
              responseData,
              (json) => SectionModel.fromJson(json),
            );
          }
        } else if (responseData is List) {
          // Direct list response (unwrapped array)
          final sections =
              responseData.map((json) => SectionModel.fromJson(json)).toList();
          return core.PaginatedResult<SectionModel>(
            items: sections,
            pageNumber: pageNumber,
            pageSize: pageSize,
            totalCount: sections.length,
          );
        }

        throw const ServerException('Invalid response structure for sections');
      } else {
        throw ServerException(
            response.data['message'] ?? 'Failed to load sections');
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
  Future<core.PaginatedResult<SectionPropertyItemModel>>
      getSectionPropertyItems({
    required String sectionId,
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    const requestName = 'getSectionPropertyItems';
    logRequestStart(requestName, details: {
      'sectionId': sectionId,
      'pageNumber': pageNumber,
      'pageSize': pageSize,
    });

    try {
      final response = await apiClient.get(
        '/api/client/sections/$sectionId/items',
        queryParameters: {
          'pageNumber': pageNumber,
          'pageSize': pageSize,
        },
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Handle different response structures
        if (responseData is Map<String, dynamic>) {
          // Check if it's wrapped in a 'data' field
          final dataField = responseData['data'];
          if (dataField != null) {
            if (dataField is Map<String, dynamic>) {
              // Paginated response structure
              return core.PaginatedResult.fromJson(
                dataField,
                (json) => SectionPropertyItemModel.fromJson(json),
              );
            } else if (dataField is List) {
              // Simple list response wrapped in data
              final items = (dataField)
                  .map((json) => SectionPropertyItemModel.fromJson(json))
                  .toList();
              return core.PaginatedResult<SectionPropertyItemModel>(
                items: items,
                pageNumber: pageNumber,
                pageSize: pageSize,
                totalCount: items.length,
              );
            }
          }

          // Direct paginated response
          if (responseData.containsKey('items')) {
            return core.PaginatedResult.fromJson(
              responseData,
              (json) => SectionPropertyItemModel.fromJson(json),
            );
          }
        } else if (responseData is List) {
          // Direct list response
          final items = responseData
              .map((json) => SectionPropertyItemModel.fromJson(json))
              .toList();
          return core.PaginatedResult<SectionPropertyItemModel>(
            items: items,
            pageNumber: pageNumber,
            pageSize: pageSize,
            totalCount: items.length,
          );
        }

        throw const ServerException(
            'Invalid response structure for section property items');
      } else {
        throw ServerException(response.data['message'] ??
            'Failed to load section property items');
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
  Future<List<PropertyTypeModel>> getPropertyTypes() async {
    const requestName = 'getPropertyTypes';
    logRequestStart(requestName);

    try {
      final response = await apiClient.get('/api/client/property-types');

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.statusCode == 200) {
        final responseData = response.data;
        List<dynamic> propertyTypesJson;

        // Handle different response structures
        if (responseData is Map<String, dynamic>) {
          // Check if it's wrapped in a 'data' field
          final dataField = responseData['data'];
          if (dataField is List) {
            propertyTypesJson = dataField;
          } else if (dataField is Map<String, dynamic> &&
              dataField['items'] is List) {
            propertyTypesJson = dataField['items'] as List<dynamic>;
          } else {
            throw const ServerException(
                'Invalid response structure for property types');
          }
        } else if (responseData is List) {
          propertyTypesJson = responseData;
        } else {
          throw const ServerException(
              'Invalid response structure for property types');
        }

        return propertyTypesJson
            .map((json) => PropertyTypeModel.fromJson(json))
            .toList();
      } else {
        throw ServerException(
            response.data['message'] ?? 'Failed to load property types');
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
  Future<List<UnitTypeModel>> getUnitTypes(
      {required String propertyTypeId}) async {
    const requestName = 'getUnitTypes';
    logRequestStart(requestName, details: {'propertyTypeId': propertyTypeId});

    try {
      final response = await apiClient.get(
        '/api/client/unit-types',
        queryParameters: {'propertyTypeId': propertyTypeId},
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.statusCode == 200) {
        final responseData = response.data;
        List<dynamic> unitTypesJson;

        // Handle different response structures
        if (responseData is Map<String, dynamic>) {
          // Check if it's wrapped in a 'data' field
          final dataField = responseData['data'];
          if (dataField is List) {
            unitTypesJson = dataField;
          } else if (dataField is Map<String, dynamic> &&
              dataField['items'] is List) {
            unitTypesJson = dataField['items'] as List<dynamic>;
          } else {
            throw const ServerException(
                'Invalid response structure for unit types');
          }
        } else if (responseData is List) {
          unitTypesJson = responseData;
        } else {
          throw const ServerException(
              'Invalid response structure for unit types');
        }

        return unitTypesJson
            .map((json) => UnitTypeModel.fromJson(json))
            .toList();
      } else {
        throw ServerException(
            response.data['message'] ?? 'Failed to load unit types');
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
  Future<List<PropertyTypeWithUnitsModel>> getPropertyTypesWithUnits() async {
    const requestName = 'getPropertyTypesWithUnits';
    logRequestStart(requestName);

    try {
      final response = await apiClient.get('/api/client/property-types/with-units');

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.statusCode == 200) {
        final responseData = response.data;
        List<dynamic> listJson;

        if (responseData is Map<String, dynamic>) {
          final dataField = responseData['data'];
          if (dataField is List) {
            listJson = dataField;
          } else if (dataField is Map<String, dynamic> && dataField['items'] is List) {
            listJson = dataField['items'] as List<dynamic>;
          } else {
            throw const ServerException('Invalid response structure for property types with units');
          }
        } else if (responseData is List) {
          listJson = responseData;
        } else {
          throw const ServerException('Invalid response structure for property types with units');
        }

        return listJson
            .map((json) => PropertyTypeWithUnitsModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to load property types with units');
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

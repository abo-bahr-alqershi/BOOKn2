import 'package:bookn_cp_app/core/error/exceptions.dart';
import 'package:bookn_cp_app/core/network/api_client.dart';
import 'package:dio/dio.dart';
import '../models/unit_model.dart';
import '../models/unit_type_model.dart';
import '../../domain/entities/unit_type.dart';
import 'package:bookn_cp_app/core/network/api_exceptions.dart' as api;

import 'package:bookn_cp_app/core/models/paginated_result.dart';

abstract class UnitsRemoteDataSource {
  Future<PaginatedResult<UnitModel>> getUnits({
    int? pageNumber,
    int? pageSize,
    String? propertyId,
    String? unitTypeId,
    bool? isAvailable,
    double? minPrice,
    double? maxPrice,
    String? searchQuery,
    String? pricingMethod,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    int? numberOfGuests,
    bool? hasActiveBookings,
    String? location,
    String? sortBy,
    double? latitude,
    double? longitude,
    double? radiusKm,
  });

  Future<UnitModel> getUnitDetails(String unitId);

  Future<String> createUnit(Map<String, dynamic> unitData);

  Future<bool> updateUnit(String unitId, Map<String, dynamic> unitData);

  Future<bool> deleteUnit(String unitId);

  Future<List<UnitTypeModel>> getUnitTypesByProperty(String propertyTypeId);

  Future<List<UnitTypeField>> getUnitFields(String unitTypeId);

  Future<bool> assignUnitToSections(String unitId, List<String> sectionIds);
}

class UnitsRemoteDataSourceImpl implements UnitsRemoteDataSource {
  final ApiClient apiClient;

  UnitsRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<PaginatedResult<UnitModel>> getUnits({
    int? pageNumber,
    int? pageSize,
    String? propertyId,
    String? unitTypeId,
    bool? isAvailable,
    double? minPrice,
    double? maxPrice,
    String? searchQuery,
    String? pricingMethod,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    int? numberOfGuests,
    bool? hasActiveBookings,
    String? location,
    String? sortBy,
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (pageNumber != null) queryParams['pageNumber'] = pageNumber;
      if (pageSize != null) queryParams['pageSize'] = pageSize;
      if (propertyId != null) queryParams['propertyId'] = propertyId;
      if (unitTypeId != null) queryParams['unitTypeId'] = unitTypeId;
      if (isAvailable != null) queryParams['isAvailable'] = isAvailable;
      if (minPrice != null) queryParams['minPrice'] = minPrice;
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice;
      if (searchQuery != null) queryParams['nameContains'] = searchQuery;
      if (pricingMethod != null) queryParams['pricingMethod'] = pricingMethod;
      if (checkInDate != null) queryParams['checkInDate'] = checkInDate.toIso8601String();
      if (checkOutDate != null) queryParams['checkOutDate'] = checkOutDate.toIso8601String();
      if (numberOfGuests != null) queryParams['numberOfGuests'] = numberOfGuests;
      if (hasActiveBookings != null) queryParams['hasActiveBookings'] = hasActiveBookings;
      if (location != null) queryParams['location'] = location;
      if (sortBy != null) queryParams['sortBy'] = sortBy;
      if (latitude != null) queryParams['latitude'] = latitude;
      if (longitude != null) queryParams['longitude'] = longitude;
      if (radiusKm != null) queryParams['radiusKm'] = radiusKm;

      final response = await apiClient.get(
        '/api/admin/Units',
        queryParameters: queryParams,
      );

      return PaginatedResult<UnitModel>.fromJson(
        response.data is Map<String, dynamic>
            ? Map<String, dynamic>.from(response.data)
            : <String, dynamic>{
                'items': (response.data as List?) ?? const [],
                'pageNumber': pageNumber ?? 1,
                'pageSize': pageSize ?? ((response.data as List?)?.length ?? 0),
                'totalCount': ((response.data as List?)?.length ?? 0),
              },
        (json) => UnitModel.fromJson(json),
      );
    } on api.ApiException catch (e) {
      throw ServerException(e.message);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<UnitModel> getUnitDetails(String unitId) async {
    try {
      final response = await apiClient.get('/api/admin/Units/$unitId/details');
      return UnitModel.fromJson(response.data['data']);
    } on api.ApiException catch (e) {
      throw ServerException(e.message);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<String> createUnit(Map<String, dynamic> unitData) async {
    try {
      // إضافة logging لمعرفة البيانات المرسلة
      print('=== Creating Unit with Data ===');
      print(unitData);

      final response = await apiClient.post('/api/admin/Units', data: unitData);

      // التحقق من استجابة السيرفر
      print('=== Server Response ===');
      print(response.data);

      // تحسين استخراج ID
      if (response.data is Map && response.data.containsKey('data')) {
        return response.data['data'].toString();
      } else if (response.data is String) {
        return response.data;
      } else {
        throw Exception('Invalid response format');
      }
    } on api.ApiException catch (e) {
      return Future.error(ServerException(e.message));
    } on DioException catch (e) {
      // تحسين معالجة الأخطاء
      print('=== DioException Details ===');
      print('Status Code: ${e.response?.statusCode}');
      print('Response Data: ${e.response?.data}');
      print('Request Data: ${e.requestOptions.data}');

      throw _handleDioError(e);
    }
  }

  @override
  Future<bool> updateUnit(String unitId, Map<String, dynamic> unitData) async {
    try {
      final response =
          await apiClient.put('/api/admin/Units/$unitId', data: unitData);
      final data = response.data;
      if (data is Map) {
        final success = data['success'] == true;
        if (success) return true;
        final message = data['message'] ?? data['error'] ?? 'فشل تحديث الوحدة';
        throw ServerException(message);
      }
      // Unexpected shape: treat as failure with generic message
      throw ServerException('فشل تحديث الوحدة: رد غير متوقع من الخادم');
    } on api.ApiException catch (e) {
      throw ServerException(e.message);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<bool> deleteUnit(String unitId) async {
    try {
      final response = await apiClient.delete('/api/admin/Units/$unitId');
      if (response.data is Map && response.data['success'] == true) return true;
      final msg = (response.data is Map) ? response.data['message'] : null;
      throw ServerException(msg ?? 'Failed to delete unit');
    } on api.ApiException catch (e) {
      throw ServerException(e.message);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<UnitTypeModel>> getUnitTypesByProperty(
      String propertyTypeId) async {
    try {
      final response = await apiClient.get(
        '/api/admin/unit-types/property-type/$propertyTypeId',
      );
      final List<dynamic> items = response.data['items'] ?? [];
      return items.map((json) => UnitTypeModel.fromJson(json)).toList();
    } on api.ApiException catch (e) {
      throw ServerException(e.message);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<UnitTypeField>> getUnitFields(String unitTypeId) async {
    try {
      final response = await apiClient.get(
        '/api/admin/unit-type-fields/unit-type/$unitTypeId',
      );
      final List<dynamic> items = response.data ?? [];
      return items.map((json) => UnitTypeFieldModel.fromJson(json)).toList();
    } on api.ApiException catch (e) {
      throw ServerException(e.message);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<bool> assignUnitToSections(
      String unitId, List<String> sectionIds) async {
    try {
      final response = await apiClient.post(
        '/api/admin/units/$unitId/sections',
        data: {'sectionIds': sectionIds},
      );
      return response.data['success'] ?? false;
    } on api.ApiException catch (e) {
      throw ServerException(e.message);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException error) {
    if (error.response != null) {
      // إظهار تفاصيل الخطأ من السيرفر
      final responseData = error.response?.data;
      String message = 'حدث خطأ في الخادم';

      if (responseData is Map) {
        message = responseData['message'] ??
            responseData['error'] ??
            responseData['errors']?.toString() ??
            message;
      } else if (responseData is String) {
        message = responseData;
      }

      print('Server Error Message: $message');
      return ServerException(message);
    } else if (error.type == DioExceptionType.connectionTimeout) {
      return const ServerException('انتهت مهلة الاتصال');
    } else if (error.type == DioExceptionType.connectionError) {
      return const ServerException('لا يوجد اتصال بالإنترنت');
    } else {
      return ServerException('حدث خطأ غير متوقع: ${error.message}');
    }
  }
}

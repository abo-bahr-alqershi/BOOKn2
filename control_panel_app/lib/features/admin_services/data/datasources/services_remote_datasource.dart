import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/models/paginated_result.dart';
import '../models/service_model.dart';
import '../models/service_details_model.dart';
import '../../domain/entities/money.dart';
import '../../domain/entities/pricing_model.dart';

/// 🌐 Remote Data Source للخدمات
abstract class ServicesRemoteDataSource {
  Future<String> createService({
    required String propertyId,
    required String name,
    required Money price,
    required PricingModel pricingModel,
    required String icon,
    String? description,
  });

  Future<bool> updateService({
    required String serviceId,
    String? name,
    Money? price,
    PricingModel? pricingModel,
    String? icon,
    String? description,
  });

  Future<bool> deleteService(String serviceId);
  Future<List<ServiceModel>> getServicesByProperty(String propertyId);
  Future<ServiceDetailsModel> getServiceDetails(String serviceId);
  Future<PaginatedResult<ServiceModel>> getServicesByType({
    required String serviceType,
    int? pageNumber,
    int? pageSize,
  });
}

class ServicesRemoteDataSourceImpl implements ServicesRemoteDataSource {
  final ApiClient apiClient;
  static const String _adminBasePath = '/api/admin/property-services';

  ServicesRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<String> createService({
    required String propertyId,
    required String name,
    required Money price,
    required PricingModel pricingModel,
    required String icon,
    String? description,
  }) async {
    try {
      final response = await apiClient.post(
        _adminBasePath,
        data: {
          'propertyId': propertyId,
          'name': name,
          'price': {
            'amount': price.amount,
            'currency': price.currency,
          },
          // Map app enum values to backend-supported enum strings
          'pricingModel': _toServerPricingModel(pricingModel),
          'icon': icon,
          if (description != null) 'description': description,
        },
      );
      
      if (response.data['success'] == true) {
        return response.data['data'] ?? '';
      }
      throw ApiException(message: response.data['message'] ?? 'Failed to create service');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<bool> updateService({
    required String serviceId,
    String? name,
    Money? price,
    PricingModel? pricingModel,
    String? icon,
    String? description,
  }) async {
    try {
      final data = <String, dynamic>{
        'serviceId': serviceId,
      };
      
      if (name != null) data['name'] = name;
      if (price != null) {
        data['price'] = {
          'amount': price.amount,
          'currency': price.currency,
        };
      }
      if (pricingModel != null) data['pricingModel'] = _toServerPricingModel(pricingModel);
      if (icon != null) data['icon'] = icon;
      if (description != null) data['description'] = description;

      final response = await apiClient.put(
        '$_adminBasePath/$serviceId',
        data: data,
      );
      
      return response.data['success'] == true;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<bool> deleteService(String serviceId) async {
    try {
      final response = await apiClient.delete('$_adminBasePath/$serviceId');
      if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        if (map['success'] == true || map['isSuccess'] == true) return true;
        // surface backend reason on conflict
        if (response.statusCode == 409 || map['errorCode'] == 'SERVICE_DELETE_CONFLICT') {
          throw ApiException(message: map['message'] ?? 'Deletion conflict');
        }
      }
      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<List<ServiceModel>> getServicesByProperty(String propertyId) async {
    try {
      final response = await apiClient.get('$_adminBasePath/property/$propertyId');
      
      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => ServiceModel.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<ServiceDetailsModel> getServiceDetails(String serviceId) async {
    try {
      final response = await apiClient.get('$_adminBasePath/$serviceId');
      
      if (response.data['success'] == true) {
        return ServiceDetailsModel.fromJson(response.data['data']);
      }
      throw ApiException(message: 'Failed to get service details');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<PaginatedResult<ServiceModel>> getServicesByType({
    required String serviceType,
    int? pageNumber,
    int? pageSize,
  }) async {
    try {
      final response = await apiClient.get(
        '$_adminBasePath/type/$serviceType',
        queryParameters: {
          if (pageNumber != null) 'pageNumber': pageNumber,
          if (pageSize != null) 'pageSize': pageSize,
        },
      );
      
      return PaginatedResult<ServiceModel>.fromJson(
        response.data,
        (json) => ServiceModel.fromJson(json),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  String _toServerPricingModel(PricingModel model) {
    // Backend enum YemenBooking.Core.Enums.PricingModel supports: Fixed, PerPerson, PerNight
    switch (model) {
      case PricingModel.fixed:
        return 'Fixed';
      case PricingModel.perPerson:
        return 'PerPerson';
      case PricingModel.perDay:
      case PricingModel.perBooking:
      case PricingModel.perUnit:
      case PricingModel.perHour:
        return 'PerNight';
    }
  }
}
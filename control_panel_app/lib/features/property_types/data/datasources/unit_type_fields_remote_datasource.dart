import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/models/result_dto.dart';
import '../../../../core/network/api_client.dart';
import '../models/unit_type_field_model.dart';

abstract class UnitTypeFieldsRemoteDataSource {
  Future<List<UnitTypeFieldModel>> getFieldsByUnitType({
    required String unitTypeId,
    String? searchTerm,
    bool? isActive,
    bool? isSearchable,
    bool? isPublic,
    bool? isForUnits,
    String? category,
  });

  Future<UnitTypeFieldModel> getFieldById(String fieldId);

  Future<String> createField({
    required String unitTypeId,
    required String fieldTypeId,
    required String fieldName,
    required String displayName,
    String? description,
    Map<String, dynamic>? fieldOptions,
    Map<String, dynamic>? validationRules,
    required bool isRequired,
    required bool isSearchable,
    required bool isPublic,
    required int sortOrder,
    String? category,
    required bool isForUnits,
    String? groupId,
    required bool showInCards,
    required bool isPrimaryFilter,
    required int priority,
  });

  Future<bool> updateField({
    required String fieldId,
    String? fieldTypeId,
    String? fieldName,
    String? displayName,
    String? description,
    Map<String, dynamic>? fieldOptions,
    Map<String, dynamic>? validationRules,
    bool? isRequired,
    bool? isSearchable,
    bool? isPublic,
    int? sortOrder,
    String? category,
    bool? isForUnits,
    String? groupId,
    bool? showInCards,
    bool? isPrimaryFilter,
    int? priority,
  });

  Future<bool> deleteField(String fieldId);
}

class UnitTypeFieldsRemoteDataSourceImpl
    implements UnitTypeFieldsRemoteDataSource {
  final ApiClient apiClient;
  static const String _baseEndpoint = '/api/admin/unit-type-fields';

  UnitTypeFieldsRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<UnitTypeFieldModel>> getFieldsByUnitType({
    required String unitTypeId,
    String? searchTerm,
    bool? isActive,
    bool? isSearchable,
    bool? isPublic,
    bool? isForUnits,
    String? category,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (searchTerm != null) queryParams['searchTerm'] = searchTerm;
      if (isActive != null) queryParams['isActive'] = isActive;
      if (isSearchable != null) queryParams['isSearchable'] = isSearchable;
      if (isPublic != null) queryParams['isPublic'] = isPublic;
      if (isForUnits != null) queryParams['isForUnits'] = isForUnits;
      if (category != null) queryParams['category'] = category;

      final response = await apiClient.get(
        '$_baseEndpoint/unit-type/$unitTypeId',
        queryParameters: queryParams,
      );

      return (response.data as List)
          .map((field) => UnitTypeFieldModel.fromJson(field))
          .toList();
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Server error occurred');
    }
  }

  @override
  Future<UnitTypeFieldModel> getFieldById(String fieldId) async {
    try {
      final response = await apiClient.get('$_baseEndpoint/$fieldId');
      final result = ResultDto.fromJson(response.data, null);

      if (result.isSuccess && result.data != null) {
        return UnitTypeFieldModel.fromJson(result.data);
      } else {
        throw ServerException(result.message ?? 'Failed to get field');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Server error occurred');
    }
  }

  @override
  Future<String> createField({
    required String unitTypeId,
    required String fieldTypeId,
    required String fieldName,
    required String displayName,
    String? description,
    Map<String, dynamic>? fieldOptions,
    Map<String, dynamic>? validationRules,
    required bool isRequired,
    required bool isSearchable,
    required bool isPublic,
    required int sortOrder,
    String? category,
    required bool isForUnits,
    String? groupId,
    required bool showInCards,
    required bool isPrimaryFilter,
    required int priority,
  }) async {
    try {
      final response = await apiClient.post(
        _baseEndpoint,
        data: {
          'unitTypeId': unitTypeId,
          'fieldTypeId': fieldTypeId,
          'fieldName': fieldName,
          'displayName': displayName,
          'description': description,
          'fieldOptions': fieldOptions,
          'validationRules': validationRules,
          'isRequired': isRequired,
          'isSearchable': isSearchable,
          'isPublic': isPublic,
          'sortOrder': sortOrder,
          'category': category,
          'isForUnits': isForUnits,
          'groupId': groupId,
          'showInCards': showInCards,
          'isPrimaryFilter': isPrimaryFilter,
          'priority': priority,
        },
      );

      final result = ResultDto.fromJson(response.data, null);

      if (result.isSuccess && result.data != null) {
        return result.data as String;
      } else {
        throw ServerException(result.message ?? 'Failed to create field');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Server error occurred');
    }
  }

  @override
  Future<bool> updateField({
    required String fieldId,
    String? fieldTypeId,
    String? fieldName,
    String? displayName,
    String? description,
    Map<String, dynamic>? fieldOptions,
    Map<String, dynamic>? validationRules,
    bool? isRequired,
    bool? isSearchable,
    bool? isPublic,
    int? sortOrder,
    String? category,
    bool? isForUnits,
    String? groupId,
    bool? showInCards,
    bool? isPrimaryFilter,
    int? priority,
  }) async {
    try {
      final data = <String, dynamic>{'fieldId': fieldId};
      if (fieldTypeId != null) data['fieldTypeId'] = fieldTypeId;
      if (fieldName != null) data['fieldName'] = fieldName;
      if (displayName != null) data['displayName'] = displayName;
      if (description != null) data['description'] = description;
      if (fieldOptions != null) data['fieldOptions'] = fieldOptions;
      if (validationRules != null) data['validationRules'] = validationRules;
      if (isRequired != null) data['isRequired'] = isRequired;
      if (isSearchable != null) data['isSearchable'] = isSearchable;
      if (isPublic != null) data['isPublic'] = isPublic;
      if (sortOrder != null) data['sortOrder'] = sortOrder;
      if (category != null) data['category'] = category;
      if (isForUnits != null) data['isForUnits'] = isForUnits;
      if (groupId != null) data['groupId'] = groupId;
      if (showInCards != null) data['showInCards'] = showInCards;
      if (isPrimaryFilter != null) data['isPrimaryFilter'] = isPrimaryFilter;
      if (priority != null) data['priority'] = priority;

      final response = await apiClient.put(
        '$_baseEndpoint/$fieldId',
        data: data,
      );

      final result = ResultDto.fromJson(response.data, null);
      return result.isSuccess;
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Server error occurred');
    }
  }

  @override
  Future<bool> deleteField(String fieldId) async {
    try {
      final response = await apiClient.delete('$_baseEndpoint/$fieldId');
      final result = ResultDto.fromJson(response.data, null);
      return result.isSuccess;
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Server error occurred');
    }
  }
}

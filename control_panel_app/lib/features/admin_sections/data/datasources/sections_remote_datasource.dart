import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/models/section_item_dto.dart';
import '../../domain/entities/section.dart' as domain;
import '../../domain/entities/property_in_section.dart' as domain;
import '../../domain/entities/unit_in_section.dart' as domain;
import '../models/section_model.dart';
import '../models/property_in_section_model.dart';
import '../models/unit_in_section_model.dart';

/// 🌐 Remote Data Source للأقسام
abstract class SectionsRemoteDataSource {
  Future<PaginatedResult<SectionModel>> getSections({
    int? pageNumber,
    int? pageSize,
    String? target,
    String? type,
    String? contentType,
  });

  Future<SectionModel> getSectionById(String sectionId);

  Future<SectionModel> createSection(Map<String, dynamic> payload);
  Future<SectionModel> updateSection(String sectionId, Map<String, dynamic> payload);
  Future<bool> deleteSection(String sectionId);
  Future<bool> toggleSectionStatus(String sectionId, bool isActive);

  Future<void> assignItems(String sectionId, AssignSectionItemsDto payload);
  Future<void> addItems(String sectionId, AddItemsToSectionDto payload);
  Future<void> removeItems(String sectionId, RemoveItemsFromSectionDto payload);
  Future<void> reorderItems(String sectionId, UpdateItemOrderDto payload);

  Future<PaginatedResult<PropertyInSectionModel>> getPropertyItems(String sectionId, {int? pageNumber, int? pageSize});
  Future<PaginatedResult<UnitInSectionModel>> getUnitItems(String sectionId, {int? pageNumber, int? pageSize});
}

class SectionsRemoteDataSourceImpl implements SectionsRemoteDataSource {
  final ApiClient apiClient;

  static const String _adminBase = '/api/admin/sections';
  static const String _clientBase = '/api/client/sections';

  SectionsRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<PaginatedResult<SectionModel>> getSections({
    int? pageNumber,
    int? pageSize,
    String? target,
    String? type,
    String? contentType,
  }) async {
    final resp = await apiClient.get(
      _adminBase,
      queryParameters: {
        if (pageNumber != null) 'pageNumber': pageNumber,
        if (pageSize != null) 'pageSize': pageSize,
        if (target != null) 'target': target,
        if (type != null) 'type': type,
        if (contentType != null) 'contentType': contentType,
      },
    );
    return PaginatedResult<SectionModel>.fromJson(
      resp.data,
      (json) => SectionModel.fromJson(json),
    );
  }

  @override
  Future<SectionModel> getSectionById(String sectionId) async {
    final resp = await apiClient.get('$_adminBase/$sectionId');
    final data = (resp.data is Map && resp.data['data'] != null)
        ? resp.data['data']
        : resp.data;
    return SectionModel.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<SectionModel> createSection(Map<String, dynamic> payload) async {
    final resp = await apiClient.post(_adminBase, data: payload);
    final data = (resp.data is Map && resp.data['data'] != null)
        ? resp.data['data']
        : resp.data;
    return SectionModel.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<SectionModel> updateSection(String sectionId, Map<String, dynamic> payload) async {
    final resp = await apiClient.put('$_adminBase/$sectionId', data: payload);
    final data = (resp.data is Map && resp.data['data'] != null)
        ? resp.data['data']
        : resp.data;
    return SectionModel.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<bool> deleteSection(String sectionId) async {
    final resp = await apiClient.delete('$_adminBase/$sectionId');
    if (resp.data is Map<String, dynamic>) {
      final map = resp.data as Map<String, dynamic>;
      if (map['success'] == true || map['isSuccess'] == true) return true;
    }
    return resp.statusCode == 200 || resp.statusCode == 204;
  }

  @override
  Future<bool> toggleSectionStatus(String sectionId, bool isActive) async {
    final resp = await apiClient.post('$_adminBase/$sectionId/toggle-status', data: {
      'isActive': isActive,
    });
    if (resp.data is Map<String, dynamic>) {
      final map = resp.data as Map<String, dynamic>;
      return map['success'] == true || map['isSuccess'] == true;
    }
    return resp.statusCode == 200;
  }

  @override
  Future<void> assignItems(String sectionId, AssignSectionItemsDto payload) async {
    await apiClient.post('$_adminBase/$sectionId/assign-items', data: payload.toJson());
  }

  @override
  Future<void> addItems(String sectionId, AddItemsToSectionDto payload) async {
    await apiClient.post('$_adminBase/$sectionId/add-items', data: payload.toJson());
  }

  @override
  Future<void> removeItems(String sectionId, RemoveItemsFromSectionDto payload) async {
    await apiClient.post('$_adminBase/$sectionId/remove-items', data: payload.toJson());
  }

  @override
  Future<void> reorderItems(String sectionId, UpdateItemOrderDto payload) async {
    await apiClient.post('$_adminBase/$sectionId/reorder-items', data: payload.toJson());
  }

  @override
  Future<PaginatedResult<PropertyInSectionModel>> getPropertyItems(String sectionId, {int? pageNumber, int? pageSize}) async {
    final resp = await apiClient.get('$_clientBase/$sectionId/items', queryParameters: {
      if (pageNumber != null) 'pageNumber': pageNumber,
      if (pageSize != null) 'pageSize': pageSize,
    });
    return PaginatedResult<PropertyInSectionModel>.fromJson(
      resp.data is Map<String, dynamic> ? resp.data : {'items': resp.data},
      (json) => PropertyInSectionModel.fromJson(json),
    );
  }

  @override
  Future<PaginatedResult<UnitInSectionModel>> getUnitItems(String sectionId, {int? pageNumber, int? pageSize}) async {
    final resp = await apiClient.get('$_clientBase/$sectionId/items', queryParameters: {
      if (pageNumber != null) 'pageNumber': pageNumber,
      if (pageSize != null) 'pageSize': pageSize,
    });
    return PaginatedResult<UnitInSectionModel>.fromJson(
      resp.data is Map<String, dynamic> ? resp.data : {'items': resp.data},
      (json) => UnitInSectionModel.fromJson(json),
    );
  }
}


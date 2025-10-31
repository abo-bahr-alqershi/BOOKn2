// lib/features/admin_properties/data/datasources/policies_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:bookn_cp_app/core/network/api_client.dart';
import 'package:bookn_cp_app/core/error/exceptions.dart';
import 'package:bookn_cp_app/core/models/paginated_result.dart';
import '../models/policy_model.dart';

abstract class PoliciesRemoteDataSource {
  Future<List<PolicyModel>> getPropertyPolicies(String propertyId);
  Future<PolicyModel> getPolicyById(String policyId);
  Future<String> createPolicy(Map<String, dynamic> data);
  Future<bool> updatePolicy(String policyId, Map<String, dynamic> data);
  Future<bool> deletePolicy(String policyId);
  Future<PaginatedResult<PolicyModel>> getPoliciesByType({
    required String policyType,
    int? pageNumber,
    int? pageSize,
  });
}

class PoliciesRemoteDataSourceImpl implements PoliciesRemoteDataSource {
  final ApiClient apiClient;
  static const String _baseEndpoint = '/api/admin/PropertyPolicies';
  
  PoliciesRemoteDataSourceImpl({required this.apiClient});
  
  @override
  Future<List<PolicyModel>> getPropertyPolicies(String propertyId) async {
    try {
      final response = await apiClient.get(
        _baseEndpoint,
        queryParameters: {'propertyId': propertyId},
      );
      
      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => PolicyModel.fromJson(json)).toList();
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to get policies');
      }
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? 'Failed to fetch property policies');
    }
  }
  
  @override
  Future<PolicyModel> getPolicyById(String policyId) async {
    try {
      final response = await apiClient.get('$_baseEndpoint/$policyId');
      
      if (response.data['success'] == true) {
        return PolicyModel.fromJson(response.data['data']);
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to get policy');
      }
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? 'Failed to fetch policy');
    }
  }
  
  @override
  Future<String> createPolicy(Map<String, dynamic> data) async {
    try {
      final response = await apiClient.post(_baseEndpoint, data: data);
      
      if (response.data['success'] == true) {
        return response.data['data'] as String;
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to create policy');
      }
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? 'Failed to create policy');
    }
  }
  
  @override
  Future<bool> updatePolicy(String policyId, Map<String, dynamic> data) async {
    try {
      final response = await apiClient.put(
        '$_baseEndpoint/$policyId',
        data: data,
      );
      
      return response.data['success'] == true;
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? 'Failed to update policy');
    }
  }
  
  @override
  Future<bool> deletePolicy(String policyId) async {
    try {
      final response = await apiClient.delete('$_baseEndpoint/$policyId');
      return response.data['success'] == true;
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? 'Failed to delete policy');
    }
  }
  
  @override
  Future<PaginatedResult<PolicyModel>> getPoliciesByType({
    required String policyType,
    int? pageNumber,
    int? pageSize,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'policyType': policyType,
        if (pageNumber != null) 'pageNumber': pageNumber,
        if (pageSize != null) 'pageSize': pageSize,
      };
      
      final response = await apiClient.get(
        '$_baseEndpoint/by-type',
        queryParameters: queryParams,
      );
      
      return PaginatedResult<PolicyModel>.fromJson(
        response.data,
        (json) => PolicyModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? 'Failed to fetch policies by type');
    }
  }
}
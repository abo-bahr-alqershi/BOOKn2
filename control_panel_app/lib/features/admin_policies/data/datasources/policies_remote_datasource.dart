import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/policy.dart';
import '../models/policy_model.dart';

abstract class PoliciesRemoteDataSource {
  Future<String> createPolicy({
    required String propertyId,
    required PolicyType type,
    required String description,
    required String rules,
    int cancellationWindowDays = 0,
    bool requireFullPaymentBeforeConfirmation = false,
    double minimumDepositPercentage = 0.0,
    int minHoursBeforeCheckIn = 0,
  });

  Future<void> updatePolicy({
    required String policyId,
    required PolicyType type,
    required String description,
    required String rules,
    int? cancellationWindowDays,
    bool? requireFullPaymentBeforeConfirmation,
    double? minimumDepositPercentage,
    int? minHoursBeforeCheckIn,
  });

  Future<void> deletePolicy(String policyId);

  Future<PaginatedResult<PolicyModel>> getAllPolicies({
    int pageNumber = 1,
    int pageSize = 20,
    String? searchTerm,
    String? propertyId,
    PolicyType? policyType,
  });

  Future<PolicyModel> getPolicyById(String policyId);

  Future<List<PolicyModel>> getPoliciesByProperty(String propertyId);

  Future<PaginatedResult<PolicyModel>> getPoliciesByType({
    required PolicyType type,
    int pageNumber = 1,
    int pageSize = 20,
  });

  Future<void> togglePolicyStatus(String policyId);

  Future<PolicyStatsModel> getPolicyStats({String? propertyId});
}

class PoliciesRemoteDataSourceImpl implements PoliciesRemoteDataSource {
  final ApiClient apiClient;

  PoliciesRemoteDataSourceImpl({required this.apiClient});

  String get _baseUrl => '${ApiConstants.adminBaseUrl}/property-policies';

  @override
  Future<String> createPolicy({
    required String propertyId,
    required PolicyType type,
    required String description,
    required String rules,
    int cancellationWindowDays = 0,
    bool requireFullPaymentBeforeConfirmation = false,
    double minimumDepositPercentage = 0.0,
    int minHoursBeforeCheckIn = 0,
  }) async {
    try {
      final response = await apiClient.post(
        _baseUrl,
        data: {
          'propertyId': propertyId,
          'type': type.apiValue,
          'description': description,
          'rules': rules,
          'cancellationWindowDays': cancellationWindowDays,
          'requireFullPaymentBeforeConfirmation': requireFullPaymentBeforeConfirmation,
          'minimumDepositPercentage': minimumDepositPercentage,
          'minHoursBeforeCheckIn': minHoursBeforeCheckIn,
        },
      );

      if (response.data['isSuccess'] == true) {
        return (response.data['data'] ?? response.data['result'] ?? '').toString();
      }
      throw Exception(response.data['message'] ?? 'فشل إنشاء السياسة');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updatePolicy({
    required String policyId,
    required PolicyType type,
    required String description,
    required String rules,
    int? cancellationWindowDays,
    bool? requireFullPaymentBeforeConfirmation,
    double? minimumDepositPercentage,
    int? minHoursBeforeCheckIn,
  }) async {
    try {
      final data = <String, dynamic>{
        'policyId': policyId,
        'type': type.apiValue,
        'description': description,
        'rules': rules,
      };

      if (cancellationWindowDays != null) data['cancellationWindowDays'] = cancellationWindowDays;
      if (requireFullPaymentBeforeConfirmation != null) data['requireFullPaymentBeforeConfirmation'] = requireFullPaymentBeforeConfirmation;
      if (minimumDepositPercentage != null) data['minimumDepositPercentage'] = minimumDepositPercentage;
      if (minHoursBeforeCheckIn != null) data['minHoursBeforeCheckIn'] = minHoursBeforeCheckIn;

      final response = await apiClient.put(
        '$_baseUrl/$policyId',
        data: data,
      );

      if (response.data['isSuccess'] != true) {
        throw Exception(response.data['message'] ?? 'فشل تحديث السياسة');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deletePolicy(String policyId) async {
    try {
      final response = await apiClient.delete('$_baseUrl/$policyId');

      if (response.data['isSuccess'] != true) {
        throw Exception(response.data['message'] ?? 'فشل حذف السياسة');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<PaginatedResult<PolicyModel>> getAllPolicies({
    int pageNumber = 1,
    int pageSize = 20,
    String? searchTerm,
    String? propertyId,
    PolicyType? policyType,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'pageNumber': pageNumber,
        'pageSize': pageSize,
      };

      if (searchTerm != null && searchTerm.isNotEmpty) {
        queryParameters['searchTerm'] = searchTerm;
      }
      if (propertyId != null && propertyId.isNotEmpty) {
        queryParameters['propertyId'] = propertyId;
      }
      if (policyType != null) {
        queryParameters['policyType'] = policyType.apiValue;
      }

      final response = await apiClient.get(
        '$_baseUrl/all',
        queryParameters: queryParameters,
      );

      // التعامل مع Response مباشر (بدون wrapper)
      final data = response.data;
      
      if (data == null) {
        return PaginatedResult(
          items: [],
          pageNumber: pageNumber,
          pageSize: pageSize,
          totalCount: 0,
        );
      }
      
      // التعامل مع PaginatedResult مباشر من الباك إند
      if (data is Map<String, dynamic>) {
        // Check if it has 'isSuccess' wrapper (ResultDto)
        if (data.containsKey('isSuccess')) {
          if (data['isSuccess'] == true) {
            final innerData = data['data'] ?? data['result'];
            if (innerData is Map<String, dynamic> && innerData.containsKey('items')) {
              final items = (innerData['items'] as List?)
                  ?.map((item) => PolicyModel.fromJson(item))
                  .toList() ?? [];
              
              return PaginatedResult(
                items: items,
                pageNumber: innerData['pageNumber'] ?? pageNumber,
                pageSize: innerData['pageSize'] ?? pageSize,
                totalCount: innerData['totalCount'] ?? items.length,
              );
            }
          }
        }
        // Direct PaginatedResult (no wrapper)
        else if (data.containsKey('items')) {
          final itemsList = data['items'] as List?;
          
          final items = itemsList
              ?.map((item) {
                try {
                  return PolicyModel.fromJson(item);
                } catch (e) {
                  print('❌ Failed to parse item: $e');
                  return null;
                }
              })
              .where((item) => item != null)
              .cast<PolicyModel>()
              .toList() ?? [];
          
          return PaginatedResult(
            items: items,
            pageNumber: data['pageNumber'] ?? pageNumber,
            pageSize: data['pageSize'] ?? pageSize,
            totalCount: data['totalCount'] ?? items.length,
          );
        }
      }
      
      return PaginatedResult(
        items: [],
        pageNumber: pageNumber,
        pageSize: pageSize,
        totalCount: 0,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<PolicyModel> getPolicyById(String policyId) async {
    try {
      final response = await apiClient.get('$_baseUrl/$policyId');

      if (response.data['isSuccess'] == true) {
        final data = response.data['data'] ?? response.data['result'];
        return PolicyModel.fromJson(data);
      }
      throw Exception(response.data['message'] ?? 'فشل جلب بيانات السياسة');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<PolicyModel>> getPoliciesByProperty(String propertyId) async {
    try {
      final response = await apiClient.get(
        _baseUrl,
        queryParameters: {'propertyId': propertyId},
      );

      if (response.data['isSuccess'] == true) {
        final data = response.data['data'] ?? response.data['result'];
        
        if (data is Map<String, dynamic> && data.containsKey('items')) {
          return (data['items'] as List)
              .map((item) => PolicyModel.fromJson(item))
              .toList();
        } else if (data is List) {
          return data.map((item) => PolicyModel.fromJson(item)).toList();
        }
      }
      
      return [];
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<PaginatedResult<PolicyModel>> getPoliciesByType({
    required PolicyType type,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await apiClient.get(
        '$_baseUrl/by-type',
        queryParameters: {
          'type': type.apiValue,
          'pageNumber': pageNumber,
          'pageSize': pageSize,
        },
      );

      if (response.data['isSuccess'] == true) {
        final data = response.data['data'] ?? response.data['result'];
        
        if (data is Map<String, dynamic>) {
          final items = (data['items'] as List?)
              ?.map((item) => PolicyModel.fromJson(item))
              .toList() ?? [];
          
          return PaginatedResult(
            items: items,
            pageNumber: data['pageNumber'] ?? pageNumber,
            pageSize: data['pageSize'] ?? pageSize,
            totalCount: data['totalCount'] ?? items.length,
          );
        }
      }
      
      return PaginatedResult(
        items: [],
        pageNumber: pageNumber,
        pageSize: pageSize,
        totalCount: 0,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> togglePolicyStatus(String policyId) async {
    try {
      final response = await apiClient.patch('$_baseUrl/$policyId/toggle-status');

      if (response.data['isSuccess'] != true) {
        throw Exception(response.data['message'] ?? 'فشل تغيير حالة السياسة');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<PolicyStatsModel> getPolicyStats({String? propertyId}) async {
    try {
      final response = await apiClient.get(
        '$_baseUrl/stats',
        queryParameters: propertyId != null && propertyId.isNotEmpty
            ? {'propertyId': propertyId}
            : null,
      );

      if (response.data['isSuccess'] == true) {
        final data = response.data['data'] ?? response.data['result'];
        return PolicyStatsModel.fromJson(data);
      }
      
      return PolicyStatsModel(
        totalPolicies: 0,
        activePolicies: 0,
        policiesByType: 0,
        policyTypeDistribution: {},
        averageCancellationWindow: 0,
      );
    } catch (e) {
      return PolicyStatsModel(
        totalPolicies: 0,
        activePolicies: 0,
        policiesByType: 0,
        policyTypeDistribution: {},
        averageCancellationWindow: 0,
      );
    }
  }
}

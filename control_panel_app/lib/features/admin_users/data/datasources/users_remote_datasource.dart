import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/models/result_dto.dart';
import '../models/user_model.dart';
import '../models/user_details_model.dart';
import '../models/user_lifetime_stats_model.dart';

abstract class UsersRemoteDataSource {
  Future<PaginatedResult<UserModel>> getAllUsers({
    int? pageNumber,
    int? pageSize,
    String? searchTerm,
    String? sortBy,
    bool? isAscending,
    String? roleId,
    bool? isActive,
    DateTime? createdAfter,
    DateTime? createdBefore,
    DateTime? lastLoginAfter,
    String? loyaltyTier,
    double? minTotalSpent,
  });

  Future<UserDetailsModel> getUserDetails(String userId);

  Future<String> createUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    String? profileImage,
  });

  /// Register an Owner user and create a linked Property in one operation
  Future<Map<String, String>> registerOwnerWithProperty({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String propertyTypeId,
    required String propertyName,
    required String city,
    required String address,
    double? latitude,
    double? longitude,
    int starRating = 3,
    String? description,
    String? currency,
  });

  Future<bool> updateUser({
    required String userId,
    String? name,
    String? email,
    String? phone,
    String? profileImage,
  });

  Future<bool> activateUser(String userId);
  Future<bool> deactivateUser(String userId);
  Future<bool> assignRole({
    required String userId,
    required String roleId,
  });

  Future<UserLifetimeStatsModel> getUserLifetimeStats(String userId);
}

class UsersRemoteDataSourceImpl implements UsersRemoteDataSource {
  final ApiClient _apiClient;

  UsersRemoteDataSourceImpl(this._apiClient);

  @override
  Future<PaginatedResult<UserModel>> getAllUsers({
    int? pageNumber,
    int? pageSize,
    String? searchTerm,
    String? sortBy,
    bool? isAscending,
    String? roleId,
    bool? isActive,
    DateTime? createdAfter,
    DateTime? createdBefore,
    DateTime? lastLoginAfter,
    String? loyaltyTier,
    double? minTotalSpent,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (pageNumber != null) queryParams['pageNumber'] = pageNumber;
      if (pageSize != null) queryParams['pageSize'] = pageSize;
      if (searchTerm != null && searchTerm.isNotEmpty) {
        queryParams['searchTerm'] = searchTerm;
      }
      if (sortBy != null) queryParams['sortBy'] = sortBy;
      if (isAscending != null) queryParams['isAscending'] = isAscending;
      if (roleId != null) queryParams['roleId'] = roleId;
      if (isActive != null) queryParams['isActive'] = isActive;
      if (createdAfter != null) {
        queryParams['createdAfter'] = createdAfter.toIso8601String();
      }
      if (createdBefore != null) {
        queryParams['createdBefore'] = createdBefore.toIso8601String();
      }
      if (lastLoginAfter != null) {
        queryParams['lastLoginAfter'] = lastLoginAfter.toIso8601String();
      }
      if (loyaltyTier != null) queryParams['loyaltyTier'] = loyaltyTier;
      if (minTotalSpent != null) queryParams['minTotalSpent'] = minTotalSpent;

      final response = await _apiClient.get(
        '/api/admin/Users',
        queryParameters: queryParams,
      );

      return PaginatedResult<UserModel>.fromJson(
        response.data,
        (json) => UserModel.fromJson(json),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<UserDetailsModel> getUserDetails(String userId) async {
    try {
      final response = await _apiClient.get('/api/admin/Users/$userId/details');
      final result = ResultDto<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (result.isSuccess && result.data != null) {
        return UserDetailsModel.fromJson(result.data!);
      } else {
        throw ApiException(
            message: result.message ?? 'Failed to get user details');
      }
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<String> createUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    String? profileImage,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/admin/Users',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          'profileImage': profileImage ?? '', // إرسال string فارغ بدلاً من null
        },
      );

      final result = ResultDto<String>.fromJson(
        response.data,
        (dynamic json) => json as String,
      );

      if (result.isSuccess && result.data != null) {
        return result.data!;
      } else {
        throw ApiException(message: result.message ?? 'Failed to create user');
      }
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Map<String, String>> registerOwnerWithProperty({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String propertyTypeId,
    required String propertyName,
    required String city,
    required String address,
    double? latitude,
    double? longitude,
    int starRating = 3,
    String? description,
    String? currency,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/admin/Users/register-owner',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          'propertyTypeId': propertyTypeId,
          'propertyName': propertyName,
          'city': city,
          'address': address,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          'starRating': starRating,
          if (description != null) 'description': description,
          if (currency != null) 'currency': currency,
        },
      );

      final result = ResultDto<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (result.isSuccess && result.data != null) {
        final data = result.data!;
        return {
          'userId': (data['userId'] ?? '').toString(),
          'propertyId': (data['propertyId'] ?? '').toString(),
        };
      } else {
        throw ApiException(
            message: result.message ?? 'Failed to register owner');
      }
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<bool> updateUser({
    required String userId,
    String? name,
    String? email,
    String? phone,
    String? profileImage,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (email != null) data['email'] = email;
      if (phone != null) data['phone'] = phone;
      if (profileImage != null) data['profileImage'] = profileImage;

      final response = await _apiClient.put(
        '/api/admin/Users/$userId',
        data: data,
      );

      final result = ResultDto<bool>.fromJson(
        response.data,
        (dynamic json) => json as bool,
      );

      return result.isSuccess && (result.data ?? false);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<bool> activateUser(String userId) async {
    try {
      final response =
          await _apiClient.post('/api/admin/Users/$userId/activate');
      final result = ResultDto<bool>.fromJson(
        response.data,
        (dynamic json) => json as bool,
      );
      return result.isSuccess && (result.data ?? false);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<bool> deactivateUser(String userId) async {
    try {
      final response =
          await _apiClient.post('/api/admin/Users/$userId/deactivate');
      final result = ResultDto<bool>.fromJson(
        response.data,
        (dynamic json) => json as bool,
      );
      return result.isSuccess && (result.data ?? false);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<bool> assignRole({
    required String userId,
    required String roleId,
  }) async {
    try {
      // Ensure we send a GUID roleId. If a role name/alias is passed (e.g., "admin"),
      // resolve it to its GUID using the roles endpoint.
      String roleGuid = roleId;
      if (!_isGuid(roleGuid)) {
        final resolved = await _resolveRoleIdByName(roleGuid);
        if (resolved == null) {
          throw ApiException(message: 'Invalid role: $roleId');
        }
        roleGuid = resolved;
      }

      final response = await _apiClient.post(
        '/api/admin/Users/$userId/assign-role',
        data: {
          // Backend binds UserId from route; only RoleId is required in body
          'roleId': roleGuid,
        },
      );

      final result = ResultDto<bool>.fromJson(
        response.data,
        (json) => json as bool,
      );

      return result.isSuccess && (result.data ?? false);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  bool _isGuid(String value) {
    final guidRegex = RegExp(
        r'^[{(]?[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}[)}]?$');
    return guidRegex.hasMatch(value);
  }

  Future<String?> _resolveRoleIdByName(String roleName) async {
    try {
      final response = await _apiClient.get(
        '/api/admin/Roles',
        queryParameters: {
          'pageNumber': 1,
          'pageSize': 1000,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final items = data['items'];
        if (items is List) {
          final match = items.cast<dynamic>().firstWhere(
            (item) {
              if (item is Map<String, dynamic>) {
                final name = (item['name'] ?? '').toString();
                return name.toLowerCase() == roleName.toLowerCase();
              }
              return false;
            },
            orElse: () => null,
          );
          if (match is Map<String, dynamic>) {
            final id = (match['id'] ?? '').toString();
            if (_isGuid(id)) return id;
          }
        }
      }
      return null;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<UserLifetimeStatsModel> getUserLifetimeStats(String userId) async {
    try {
      final response =
          await _apiClient.get('/api/admin/Users/$userId/lifetime-stats');

      // التحقق من أن response.data ليس null
      if (response.data == null) {
        throw ApiException(message: 'No data received from server');
      }

      // التحقق من أن response.data هو Map
      if (response.data is! Map<String, dynamic>) {
        throw ApiException(message: 'Invalid response format from server');
      }

      final result = ResultDto<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) {
          // التحقق من أن json ليس null قبل التحويل
          if (json == null) {
            // إرجاع Map فارغ بدلاً من رمي استثناء
            return <String, dynamic>{};
          }
          if (json is! Map<String, dynamic>) {
            // إرجاع Map فارغ بدلاً من رمي استثناء
            return <String, dynamic>{};
          }
          return json;
        },
      );

      if (result.isSuccess) {
        // حتى لو كانت البيانات فارغة، نعيد نموذج بقيم افتراضية
        if (result.data != null && result.data!.isNotEmpty) {
          return UserLifetimeStatsModel.fromJson(result.data!);
        } else {
          // إرجاع بيانات افتراضية إذا كانت البيانات فارغة
          return const UserLifetimeStatsModel(
            totalNightsStayed: 0,
            totalMoneySpent: 0.0,
            favoriteCity: null,
          );
        }
      } else {
        throw ApiException(
            message: result.message ?? 'Failed to get lifetime stats');
      }
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      // معالجة أي أخطاء أخرى قد تحدث
      throw ApiException(message: 'Unexpected error: ${e.toString()}');
    }
  }
}

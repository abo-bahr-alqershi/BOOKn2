import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/network/api_client.dart';
import '../../../admin_users/data/models/user_model.dart';
import '../../../admin_properties/data/models/property_model.dart';
import '../../../admin_units/data/models/unit_model.dart';
import '../../../admin_cities/data/models/city_model.dart';
import '../../domain/entities/search_result.dart';
import '../models/search_result_model.dart';

abstract class HelpersRemoteDataSource {
  Future<PaginatedResult<SearchResult>> searchUsers({
    String? searchTerm,
    String? role,
    bool? isActive,
    int pageNumber = 1,
    int pageSize = 20,
  });

  Future<PaginatedResult<SearchResult>> searchProperties({
    String? searchTerm,
    String? typeId,
    String? city,
    bool? isApproved,
    int pageNumber = 1,
    int pageSize = 20,
  });

  Future<PaginatedResult<SearchResult>> searchUnits({
    String? searchTerm,
    String? propertyId,
    String? unitTypeId,
    bool? isAvailable,
    int pageNumber = 1,
    int pageSize = 20,
  });

  Future<PaginatedResult<SearchResult>> searchCities({
    String? searchTerm,
    String? country,
    int pageNumber = 1,
    int pageSize = 20,
  });

  Future<PaginatedResult<SearchResult>> searchBookings({
    String? searchTerm,
    String? userId,
    String? unitId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int pageNumber = 1,
    int pageSize = 20,
  });
}

class HelpersRemoteDataSourceImpl implements HelpersRemoteDataSource {
  final ApiClient _apiClient;

  HelpersRemoteDataSourceImpl(this._apiClient);

  @override
  Future<PaginatedResult<SearchResult>> searchUsers({
    String? searchTerm,
    String? role,
    bool? isActive,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    final trimmedTerm = searchTerm?.trim();
    final hasSearchTerm = trimmedTerm != null && trimmedTerm.isNotEmpty;

    final endpoint = hasSearchTerm
        ? '${ApiConstants.adminBaseUrl}/Users/search'
        : '${ApiConstants.adminBaseUrl}/Users';

    final queryParameters = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      'isActive': isActive,
      if (hasSearchTerm) 'searchTerm': trimmedTerm,
      if (role != null && !_isGuid(role)) 'roleName': _mapRoleAlias(role),
      if (_isGuid(role)) 'roleId': role,
    }..removeWhere((key, value) => value == null);

    final response = await _apiClient.get(
      endpoint,
      queryParameters: queryParameters,
    );

    final paginatedResult = PaginatedResult<UserModel>.fromJson(
      response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{},
      (json) => UserModel.fromJson(json),
    );

    return PaginatedResult<SearchResult>(
      items: paginatedResult.items.map((user) {
        return SearchResultModel(
          item: user,
          id: user.id,
          title: user.name,
          subtitle:
              [user.email, user.role].where((s) => (s).isNotEmpty).join(' • '),
          imageUrl: user.profileImage,
          metadata: {
            'email': user.email,
            'phone': user.phone,
            'role': user.role,
            'isActive': user.isActive,
          },
        );
      }).toList(),
      pageNumber: paginatedResult.pageNumber,
      pageSize: paginatedResult.pageSize,
      totalCount: paginatedResult.totalCount,
    );
  }

  bool _isGuid(String? value) {
    if (value == null) return false;
    final guidRegex = RegExp(
        r'^[{(]?[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}[)}]?$');
    return guidRegex.hasMatch(value);
  }

  String _mapRoleAlias(String role) {
    // Normalize to the 5 canonical roles: Admin, Owner, Client, Staff, Guest
    final lower = role.trim().toLowerCase();
    if (lower == 'admin' || lower == 'administrator' || lower == 'super_admin') return 'Admin';
    if (lower == 'owner' || lower == 'hotel_owner' || lower == 'property_owner') return 'Owner';
    if (lower == 'client' || lower == 'customer') return 'Client';
    if (lower == 'staff' || lower == 'manager' || lower == 'hotel_manager' || lower == 'receptionist') return 'Staff';
    if (lower == 'guest' || lower == 'visitor') return 'Guest';
    // Fallback to original capitalized
    return role;
  }

  @override
  Future<PaginatedResult<SearchResult>> searchProperties({
    String? searchTerm,
    String? typeId,
    String? city,
    bool? isApproved,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.get(
      '${ApiConstants.adminBaseUrl}/Properties',
      queryParameters: {
        'searchTerm': searchTerm,
        'propertyTypeId': typeId,
        'city': city,
        'isApproved': isApproved,
        'pageNumber': pageNumber,
        'pageSize': pageSize,
      }..removeWhere((key, value) => value == null),
    );

    final paginatedResult = PaginatedResult<PropertyModel>.fromJson(
      response.data,
      (json) => PropertyModel.fromJson(json),
    );

    return PaginatedResult<SearchResult>(
      items: paginatedResult.items.map((property) {
        return SearchResultModel(
          item: property,
          id: property.id,
          title: property.name,
          subtitle: '${property.city} • ${property.typeName}',
          imageUrl:
              property.images.isNotEmpty ? property.images.first.url : null,
          metadata: {
            'address': property.address,
            'city': property.city,
            'type': property.typeName,
            'rating': property.starRating,
            'isApproved': property.isApproved,
          },
        );
      }).toList(),
      pageNumber: paginatedResult.pageNumber,
      pageSize: paginatedResult.pageSize,
      totalCount: paginatedResult.totalCount,
    );
  }

  @override
  Future<PaginatedResult<SearchResult>> searchUnits({
    String? searchTerm,
    String? propertyId,
    String? unitTypeId,
    bool? isAvailable,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.get(
      '${ApiConstants.adminBaseUrl}/Units',
      queryParameters: {
        'nameContains': searchTerm,
        'propertyId': propertyId,
        'unitTypeId': unitTypeId,
        'isAvailable': isAvailable,
        'pageNumber': pageNumber,
        'pageSize': pageSize,
      }..removeWhere((key, value) => value == null),
    );

    final paginatedResult = PaginatedResult<UnitModel>.fromJson(
      response.data,
      (json) => UnitModel.fromJson(json),
    );

    // Filter out experimental/test/demo units on client-side to prevent accidental selection
    bool isExperimental(UnitModel unit) {
      final name = unit.name.toLowerCase();
      final propertyName = unit.propertyName.toLowerCase();
      final features = unit.customFeatures.toLowerCase();
      const experimentalHints = [
        'test',
        'demo',
        'dummy',
        'sample',
        'تجريبي',
        'تجريب',
        'اختبار',
        'ديمو',
        'عينه',
        'عينة'
      ];
      final hasHint = experimentalHints.any((h) =>
          name.contains(h) || propertyName.contains(h) || features.contains(h));
      // Also treat obviously invalid GUID-like ids as experimental safeguards (length != 36)
      final looksInvalidId = unit.id.length != 36;
      return hasHint || looksInvalidId;
    }

    final filteredUnits =
        paginatedResult.items.where((u) => !isExperimental(u)).toList();

    return PaginatedResult<SearchResult>(
      items: filteredUnits.map((unit) {
        return SearchResultModel(
          item: unit,
          id: unit.id,
          title: unit.name,
          subtitle: '${unit.propertyName} • ${unit.unitTypeName}',
          imageUrl: unit.images?.isNotEmpty == true ? unit.images!.first : null,
          metadata: {
            'propertyName': unit.propertyName,
            'unitType': unit.unitTypeName,
            'price': unit.basePrice.toJson(),
            'isAvailable': unit.isAvailable,
            'capacity': unit.maxCapacity,
          },
        );
      }).toList(),
      pageNumber: paginatedResult.pageNumber,
      pageSize: paginatedResult.pageSize,
      totalCount: filteredUnits.length,
    );
  }

  @override
  Future<PaginatedResult<SearchResult>> searchCities({
    String? searchTerm,
    String? country,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    // Since there's no specific search endpoint for cities, we'll use the get all endpoint
    final response = await _apiClient.get(
      '${ApiConstants.commonBaseUrl}/Cities',
      queryParameters: {
        'searchTerm': searchTerm,
        'country': country,
        'pageNumber': pageNumber,
        'pageSize': pageSize,
      }..removeWhere((key, value) => value == null),
    );

    List<CityModel> cities = [];
    if (response.data is List) {
      cities = (response.data as List)
          .map((json) => CityModel.fromJson(json))
          .toList();
    }

    // Filter cities locally if searchTerm is provided
    if (searchTerm != null && searchTerm.isNotEmpty) {
      cities = cities.where((city) {
        return city.name.toLowerCase().contains(searchTerm.toLowerCase()) ||
            city.country.toLowerCase().contains(searchTerm.toLowerCase());
      }).toList();
    }

    // Implement manual pagination
    final startIndex = (pageNumber - 1) * pageSize;
    final paginatedCities = cities.skip(startIndex).take(pageSize).toList();

    return PaginatedResult<SearchResult>(
      items: paginatedCities.map((city) {
        return SearchResultModel(
          item: city,
          id: city.name, // Using name as ID since cities don't have ID
          title: city.name,
          subtitle: city.country,
          imageUrl: city.images.isNotEmpty ? city.images.first : null,
          metadata: {
            'country': city.country,
            'propertiesCount': city.propertiesCount,
            'isActive': city.isActive,
          },
        );
      }).toList(),
      pageNumber: pageNumber,
      pageSize: pageSize,
      totalCount: cities.length,
    );
  }

  @override
  Future<PaginatedResult<SearchResult>> searchBookings({
    String? searchTerm,
    String? userId,
    String? unitId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.get(
      '${ApiConstants.adminBaseUrl}/Bookings/by-date-range',
      queryParameters: {
        'guestNameOrEmail': searchTerm,
        'userId': userId,
        'unitId': unitId,
        'status': status,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'pageNumber': pageNumber,
        'pageSize': pageSize,
      }..removeWhere((key, value) => value == null),
    );

    final paginatedResult = PaginatedResult.fromJson(
      response.data,
      (json) => json, // We'll handle BookingDto manually
    );

    return PaginatedResult<SearchResult>(
      items: paginatedResult.items.map((booking) {
        return SearchResultModel(
          item: booking,
          id: booking['id'],
          title: 'حجز #${booking['id'].toString().substring(0, 8)}',
          subtitle: '${booking['userName']} • ${booking['unitName']}',
          imageUrl: null,
          metadata: {
            'userId': booking['userId'],
            'unitId': booking['unitId'],
            'checkIn': booking['checkIn'],
            'checkOut': booking['checkOut'],
            'status': booking['status'],
            'totalPrice': booking['totalPrice'],
          },
        );
      }).toList(),
      pageNumber: paginatedResult.pageNumber,
      pageSize: paginatedResult.pageSize,
      totalCount: paginatedResult.totalCount,
    );
  }
}

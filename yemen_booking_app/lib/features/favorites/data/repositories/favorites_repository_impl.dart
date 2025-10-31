import 'package:dartz/dartz.dart';
import 'package:yemen_booking_app/core/error/error_handler.dart';
import 'package:yemen_booking_app/core/error/failures.dart';
import 'package:yemen_booking_app/core/network/network_info.dart';
import 'package:yemen_booking_app/core/network/api_client.dart';
import 'package:yemen_booking_app/core/utils/request_logger.dart';
import 'package:yemen_booking_app/services/local_storage_service.dart';
import 'package:yemen_booking_app/core/constants/storage_constants.dart';
import '../../../favorites/domain/repositories/favorites_repository.dart';
import '../../../favorites/domain/entities/favorite.dart';

/// Temporary implementation of FavoritesRepository.
/// NOTE: Replace endpoints and mapping once backend contract is finalized.
class FavoritesRepositoryImpl implements FavoritesRepository {
  final ApiClient apiClient;
  final NetworkInfo networkInfo;
  final LocalStorageService localStorage;

  FavoritesRepositoryImpl({
    required this.apiClient,
    required this.networkInfo,
    required this.localStorage,
  });

  @override
  Future<Either<Failure, List<Favorite>>> getFavorites() async {
    if (await networkInfo.isConnected) {
      try {
        const requestName = 'favorites.getFavorites';
        logRequestStart(requestName);
        final uid = (localStorage.getData(StorageConstants.userId) ?? '').toString();
        if (uid.isEmpty) {
          return const Left(AuthenticationFailure('يجب تسجيل الدخول'));
        }
        final response = await apiClient.get(
          '/api/client/favorites',
          queryParameters: {
            'userId': uid,
            'pageNumber': 1,
            'pageSize': 100,
          },
        );
        logRequestSuccess(requestName, statusCode: response.statusCode);
        final data = response.data;
        final payload = (data is Map) ? data['data'] : null;
        List<dynamic> list = const [];
        if (payload is Map) {
          if (payload['favorites'] is List) {
            list = payload['favorites'] as List;
          } else if (payload['Favorites'] is List) {
            list = payload['Favorites'] as List;
          } else if (payload['items'] is List) {
            list = payload['items'] as List;
          }
        } else if (data is Map) {
          if (data['favorites'] is List) {
            list = data['favorites'] as List;
          } else if (data['Favorites'] is List) {
            list = data['Favorites'] as List;
          } else if (data['items'] is List) {
            list = data['items'] as List;
          }
        } else if (data is List) {
          list = data;
        }
        final favorites = list
            .map((e) => _mapFavorite(e as Map<String, dynamic>? ?? const {}))
            .toList();
        return Right(favorites);
      } catch (e) {
        logRequestError('favorites.getFavorites', e);
        return ErrorHandler.handle(e);
      }
    }
    return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
  }

  @override
  Future<Either<Failure, bool>> addToFavorites({
    required String propertyId,
    required String userId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        const requestName = 'favorites.add';
        logRequestStart(requestName, details: {
          'propertyId': propertyId,
          'userId': userId,
        });
        final uid = (localStorage.getData(StorageConstants.userId) ?? userId).toString();
        final response = await apiClient.post(
          '/api/client/favorites',
          data: {
            'userId': uid,
            'propertyId': propertyId,
          },
        );
        logRequestSuccess(requestName, statusCode: response.statusCode);
        final data = response.data;
        final topSuccess = (data is Map && data['success'] is bool) ? data['success'] as bool : true;
        return Right(topSuccess);
      } catch (e) {
        logRequestError('favorites.add', e);
        return ErrorHandler.handle(e);
      }
    }
    return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
  }

  @override
  Future<Either<Failure, void>> removeFromFavorites({
    required String propertyId,
    required String userId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        const requestName = 'favorites.remove';
        logRequestStart(requestName, details: {
          'propertyId': propertyId,
          'userId': userId,
        });
        final uid = (localStorage.getData(StorageConstants.userId) ?? userId).toString();
        await apiClient.delete(
          '/api/client/favorites',
          data: {
            'userId': uid,
            'propertyId': propertyId,
          },
        );
        logRequestSuccess(requestName);
        return const Right(null);
      } catch (e) {
        logRequestError('favorites.remove', e);
        return ErrorHandler.handle(e);
      }
    }
    return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
  }

  @override
  Future<Either<Failure, bool>> checkFavoriteStatus({
    required String propertyId,
    required String userId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        const requestName = 'favorites.checkStatus';
        logRequestStart(requestName, details: {
          'propertyId': propertyId,
          'userId': userId,
        });
        final uid = (localStorage.getData(StorageConstants.userId) ?? userId).toString();
        final response = await apiClient.get(
          '/api/client/properties/$propertyId',
          queryParameters: {
            'userId': uid,
          },
        );
        logRequestSuccess(requestName, statusCode: response.statusCode);
        final data = response.data;
        final payload = (data is Map) ? data['data'] : null;
        if (payload is Map && payload['isFavorite'] is bool) {
          return Right(payload['isFavorite'] as bool);
        }
        return const Right(false);
      } catch (e) {
        logRequestError('favorites.checkStatus', e);
        return ErrorHandler.handle(e);
      }
    }
    return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
  }

  Favorite _mapFavorite(Map<String, dynamic> json) {
    // Provide safe defaults for missing fields
    DateTime parseDate(dynamic v) {
      if (v is String) {
        final d = DateTime.tryParse(v);
        if (d != null) return d;
      }
      return DateTime.now();
    }

    List<PropertyImage> images = [];
    final imagesRaw = json['images'];
    if (imagesRaw is List) {
      images = imagesRaw.map((i) {
        final m = i as Map<String, dynamic>? ?? {};
        return PropertyImage(
          id: (m['id'] ?? '').toString(),
          propertyId: (m['propertyId'])?.toString(),
          unitId: (m['unitId'])?.toString(),
          name: (m['name'] ?? 'image').toString(),
          url: (m['url'] ?? '').toString(),
          sizeBytes: (m['sizeBytes'] ?? 0) is int
              ? (m['sizeBytes'] ?? 0) as int
              : int.tryParse((m['sizeBytes'] ?? '0').toString()) ?? 0,
          type: (m['type'] ?? '').toString(),
          category: (m['category'] ?? '').toString(),
          caption: (m['caption'] ?? '').toString(),
          altText: (m['altText'] ?? '').toString(),
          tags: (m['tags'] ?? '').toString(),
          sizes: (m['sizes'] ?? '').toString(),
          isMain: (m['isMain'] ?? false) as bool,
          displayOrder: (m['displayOrder'] ?? 0) is int
              ? (m['displayOrder'] ?? 0) as int
              : int.tryParse((m['displayOrder'] ?? '0').toString()) ?? 0,
          uploadedAt: parseDate(m['uploadedAt']),
          status: (m['status'] ?? '').toString(),
          associationType: (m['associationType'] ?? '').toString(),
        );
      }).toList();
    }

    List<Amenity> amenities = [];
    final amenitiesRaw = json['amenities'];
    if (amenitiesRaw is List) {
      amenities = amenitiesRaw.map((a) {
        final m = a as Map<String, dynamic>? ?? {};
        return Amenity(
          id: (m['id'] ?? '').toString(),
          name: (m['name'] ?? '').toString(),
          description: (m['description'] ?? '').toString(),
          iconUrl: (m['iconUrl'] ?? '').toString(),
          category: (m['category'] ?? '').toString(),
          isActive: (m['isActive'] ?? true) as bool,
          displayOrder: (m['displayOrder'] ?? 0) is int
              ? (m['displayOrder'] ?? 0) as int
              : int.tryParse((m['displayOrder'] ?? '0').toString()) ?? 0,
          createdAt: parseDate(m['createdAt']),
        );
      }).toList();
    }

    double toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0.0;
    }

    int toInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    return Favorite(
      id: (json['favoriteId'] ?? json['id'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      propertyId: (json['propertyId'] ?? '').toString(),
      propertyName: (json['propertyName'] ?? 'عقار').toString(),
      propertyImage: (json['propertyImage'] ?? '').toString(),
      propertyLocation: (json['propertyLocation'] ?? '').toString(),
      typeId: (json['typeId'] ?? '').toString(),
      typeName: (json['typeName'] ?? 'نوع').toString(),
      ownerName: (json['ownerName'] ?? 'المالك').toString(),
      address: (json['address'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      latitude: toDouble(json['latitude']),
      longitude: toDouble(json['longitude']),
      starRating: toInt(json['starRating']),
      averageRating: toDouble(json['averageRating']),
      reviewsCount: toInt(json['reviewsCount']),
      minPrice: toDouble(json['minPrice']),
      currency: (json['currency'] ?? 'YER').toString(),
      images: images,
      amenities: amenities,
      createdAt: parseDate(json['createdAt']),
    );
  }
}

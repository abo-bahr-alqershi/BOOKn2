// lib/features/admin_sections/data/datasources/unit_in_section_images_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:bookn_cp_app/core/network/api_client.dart';
import 'package:bookn_cp_app/core/error/exceptions.dart';
import 'package:bookn_cp_app/core/constants/app_constants.dart';
import 'package:bookn_cp_app/core/utils/video_utils.dart';
import '../models/section_image_model.dart';

abstract class UnitInSectionImagesRemoteDataSource {
  Future<SectionImageModel> uploadImage({
    String? unitInSectionId,
    String? tempKey,
    required String filePath,
    String? category,
    String? alt,
    bool isPrimary = false,
    int? order,
    List<String>? tags,
    ProgressCallback? onSendProgress,
  });

  Future<List<SectionImageModel>> getUnitInSectionImages(
    String? unitInSectionId, {
    String? tempKey,
  });

  Future<bool> updateImage(String imageId, Map<String, dynamic> data);
  Future<bool> deleteImage(String imageId);
  Future<bool> reorderImages(
    String? unitInSectionId,
    String? tempKey,
    List<String> imageIds,
  );
  Future<bool> setAsPrimaryImage(
    String? unitInSectionId,
    String? tempKey,
    String imageId,
  );
}

class UnitInSectionImagesRemoteDataSourceImpl
    implements UnitInSectionImagesRemoteDataSource {
  final ApiClient apiClient;
  static const String _baseEndpoint = '/api/admin/unit-in-section-images';

  UnitInSectionImagesRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<SectionImageModel> uploadImage({
    String? unitInSectionId,
    String? tempKey,
    required String filePath,
    String? category,
    String? alt,
    bool isPrimary = false,
    int? order,
    List<String>? tags,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      String? posterPath;
      if (AppConstants.isVideoFile(filePath)) {
        posterPath = await VideoUtils.generateVideoThumbnail(filePath);
      }

      // Only send UnitInSectionId if it is a valid GUID to avoid ASP.NET Core model binding 400
      final bool unitIdIsGuid = unitInSectionId != null &&
          RegExp(r'^[{]?[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}[}]?$')
              .hasMatch(unitInSectionId.trim());
      final normalizedUnitInSectionId =
          (unitInSectionId != null && unitIdIsGuid) ? unitInSectionId.trim() : null;
      // IMPORTANT: Only use tempKey if unitInSectionId is not provided
      final normalizedTempKey = normalizedUnitInSectionId != null 
          ? null 
          : ((tempKey != null && tempKey.trim().isNotEmpty) ? tempKey.trim() : null);
      if (const bool.fromEnvironment('DEBUG') || true) {
        try {
          print('🧾 [UnitUpload] unitInSectionId=$normalizedUnitInSectionId tempKey=$normalizedTempKey file=${filePath.split('/').last}');
          print('🎞️ [UnitUpload] isVideo=${posterPath != null}');
        } catch (_) {}
      }
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        if (normalizedUnitInSectionId != null) 
          'unitInSectionId': normalizedUnitInSectionId
        else if (normalizedTempKey != null) 
          'tempKey': normalizedTempKey,
        if (category != null && category.trim().isNotEmpty) 'category': category,
        if (alt != null && alt.trim().isNotEmpty) 'alt': alt,
        'isPrimary': isPrimary,
        if (order != null) 'order': order,
        if (tags != null && tags.isNotEmpty) 'tags': tags.join(','),
        if (posterPath != null)
          'videoThumbnail': await MultipartFile.fromFile(posterPath),
      });

      final response = await apiClient.post(
        '$_baseEndpoint/upload',
        data: formData,
        options: Options(
          extra: {
            'suppressErrorToast': true,
          },
        ),
        onSendProgress: onSendProgress,
      );
      if (const bool.fromEnvironment('DEBUG') || true) {
        try {
          final dt = response.data;
          print('⬅️ [UnitUpload] response type: ${dt.runtimeType}');
          if (dt is Map<String, dynamic>) {
            print('⬅️ [UnitUpload] response keys: ${dt.keys.toList()}');
            print('⬅️ [UnitUpload] success=${dt['success']} hasData=${dt.containsKey('data')}');
          }
        } catch (_) {}
      }

      // Accept different response shapes similar to section_images_remote_datasource
      if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        final dynamic data =
            map['data'] ?? map['item'] ?? map['image'] ?? map['payload'];

        // Standard payloads
        if (map['success'] == true && data != null) {
          if (const bool.fromEnvironment('DEBUG') || true) {
            print('✅ [UnitUpload] Parsed image from data block');
          }
          return SectionImageModel.fromJson(data);
        }
        // Image directly on root
        if (map['success'] == true && data == null && map.containsKey('id')) {
          if (const bool.fromEnvironment('DEBUG') || true) {
            print('✅ [UnitUpload] Using root image object');
          }
          return SectionImageModel.fromJson(map);
        }

        // Some APIs return a collection block on upload
        if (map['success'] == true) {
          final dynamic imagesBlock = map['images'] ?? map['items'] ?? map['data'];
          if (imagesBlock is Map && imagesBlock['items'] is List && (imagesBlock['items'] as List).isNotEmpty) {
            final List items = imagesBlock['items'] as List;
            if (const bool.fromEnvironment('DEBUG') || true) {
              print('🧩 [UnitUpload] imagesBlock map with items length: ${items.length}');
            }
            final dynamic last = items.last;
            if (last is Map<String, dynamic>) {
              return SectionImageModel.fromJson(last);
            }
          } else if (imagesBlock is List && imagesBlock.isNotEmpty) {
            if (const bool.fromEnvironment('DEBUG') || true) {
              print('🧩 [UnitUpload] imagesBlock list length: ${imagesBlock.length}');
            }
            final dynamic last = imagesBlock.last;
            if (last is Map<String, dynamic>) {
              return SectionImageModel.fromJson(last);
            }
          }

          // Last resort: short polling to fetch the latest if backend processes asynchronously
          for (var attempt = 0; attempt < 10; attempt++) {
            if (const bool.fromEnvironment('DEBUG') || true) {
              print('🔁 [UnitUpload] Poll attempt ${attempt + 1}/10');
            }
            final latest = await getUnitInSectionImages(
              normalizedUnitInSectionId,
              tempKey: normalizedTempKey,
            );
            if (const bool.fromEnvironment('DEBUG') || true) {
              print('🔎 [UnitUpload] Poll fetched ${latest.length} items');
            }
            if (latest.isNotEmpty) {
              latest.sort((a, b) => a.uploadedAt.compareTo(b.uploadedAt));
              if (const bool.fromEnvironment('DEBUG') || true) {
                print('✅ [UnitUpload] Returning latest polled image');
              }
              return latest.last as SectionImageModel;
            }
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }
      }

      // If we reached here but the HTTP status is 2xx, treat as async success and poll
      final sc = response.statusCode ?? 0;
      if (sc >= 200 && sc < 300) {
        for (var attempt = 0; attempt < 10; attempt++) {
          if (const bool.fromEnvironment('DEBUG') || true) {
            print('🔁 [UnitUpload] Fallback poll attempt ${attempt + 1}/10');
          }
          final latest = await getUnitInSectionImages(
            normalizedUnitInSectionId,
            tempKey: normalizedTempKey,
          );
          if (const bool.fromEnvironment('DEBUG') || true) {
            print('🔎 [UnitUpload] Fallback poll fetched ${latest.length} items');
          }
          if (latest.isNotEmpty) {
            latest.sort((a, b) => a.uploadedAt.compareTo(b.uploadedAt));
            if (const bool.fromEnvironment('DEBUG') || true) {
              print('✅ [UnitUpload] Returning latest fallback polled image');
            }
            return latest.last as SectionImageModel;
          }
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      throw const ServerException('Failed to upload image');
    } on DioException catch (e) {
      // Better error messages and connectivity handling
      String? msg;
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        // Prefer detailed errors
        final errors = data['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) {
            msg = first.first?.toString();
          } else if (first != null) {
            msg = first.toString();
          }
        } else if (errors is List && errors.isNotEmpty) {
          msg = errors.first?.toString();
        }
        // ProblemDetails support
        msg ??= (data['message'] ?? data['detail'] ?? data['title'])?.toString();
      }
      msg ??= e.message;
      if (e.type == DioExceptionType.unknown &&
          (e.error?.toString().contains('SocketException') ?? false)) {
        if (const bool.fromEnvironment('DEBUG') || true) {
          print('❌ [UnitUpload] Network error (SocketException)');
        }
        throw const ServerException(
            'لا يمكن الاتصال بالخادم. تحقق من الاتصال بالإنترنت أو إعدادات الخادم');
      }
      if (const bool.fromEnvironment('DEBUG') || true) {
        print('❌ [UnitUpload] DioException type=${e.type} msg=${msg ?? e.message}');
      }
      throw ServerException(msg ?? 'Failed to upload image');
    }
  }

  @override
  Future<List<SectionImageModel>> getUnitInSectionImages(
    String? unitInSectionId, {
    String? tempKey,
  }) async {
    try {
      final bool unitIdIsGuid = unitInSectionId != null &&
          RegExp(r'^[{]?[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}[}]?$')
              .hasMatch(unitInSectionId.trim());
      final normalizedUnitInSectionId =
          (unitInSectionId != null && unitIdIsGuid) ? unitInSectionId.trim() : null;
      // IMPORTANT: Only use tempKey if unitInSectionId is not provided
      final normalizedTempKey = normalizedUnitInSectionId != null
          ? null
          : ((tempKey != null && tempKey.trim().isNotEmpty) ? tempKey.trim() : null);
      final qp = <String, dynamic>{
        if (normalizedUnitInSectionId != null) 'unitInSectionId': normalizedUnitInSectionId
        else if (normalizedTempKey != null) 'tempKey': normalizedTempKey,
        'sortBy': 'uploadedAt',
        'sortOrder': 'desc',
      };

      if (const bool.fromEnvironment('DEBUG') || true) {
        print('🔎 [UnitGet] Query unitInSectionId=$normalizedUnitInSectionId tempKey=$normalizedTempKey sortBy=uploadedAt desc');
      }
      final response = await apiClient.get(
        _baseEndpoint,
        queryParameters: qp,
        options: Options(
          extra: {
            'suppressErrorToast': true,
          },
        ),
      );

      // Handle different response formats like section images
      if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        if (map['success'] == true) {
          final dynamic imagesData =
              map['images'] ?? map['items'] ?? map['data'];
          if (imagesData is List) {
            if (const bool.fromEnvironment('DEBUG') || true) {
              print('⬅️ [UnitGet] images list length: ${imagesData.length}');
            }
            return imagesData
                .map((json) => SectionImageModel.fromJson(json))
                .toList();
          } else if (imagesData is Map && imagesData['items'] is List) {
            final List<dynamic> items = imagesData['items'];
            if (const bool.fromEnvironment('DEBUG') || true) {
              print('⬅️ [UnitGet] images paged items length: ${items.length}');
            }
            return items
                .map((json) => SectionImageModel.fromJson(json))
                .toList();
          }
        }
        if (map['items'] is List) {
          final List<dynamic> items = map['items'];
          if (const bool.fromEnvironment('DEBUG') || true) {
            print('⬅️ [UnitGet] items length: ${items.length}');
          }
          return items.map((json) => SectionImageModel.fromJson(json)).toList();
        }
      } else if (response.data is List) {
        if (const bool.fromEnvironment('DEBUG') || true) {
          print('⬅️ [UnitGet] raw list length: ${(response.data as List).length}');
        }
        return (response.data as List)
            .map((json) => SectionImageModel.fromJson(json))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      if (e.type == DioExceptionType.unknown &&
          e.error.toString().contains('SocketException')) {
        throw const ServerException(
            'لا يمكن الاتصال بالخادم. تحقق من الاتصال بالإنترنت أو إعدادات الخادم');
      }
      final msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message'] as String?)
          : e.message;
      throw ServerException(msg ?? 'Failed to fetch images');
    }
  }

  @override
  Future<bool> updateImage(String imageId, Map<String, dynamic> data) async {
    try {
      final response = await apiClient.put(
        '$_baseEndpoint/$imageId',
        data: data,
      );

      if (response.statusCode == 204) return true;
      if (response.data is Map<String, dynamic>) {
        return (response.data as Map<String, dynamic>)['success'] == true;
      }
      return response.statusCode == 200;
    } on DioException catch (e) {
      final msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message'] as String?)
          : e.message;
      throw ServerException(msg ?? 'Failed to update image');
    }
  }

  @override
  Future<bool> deleteImage(String imageId) async {
    try {
      final response = await apiClient.delete('$_baseEndpoint/$imageId');
      if (response.statusCode == 204) return true;
      if (response.data is Map<String, dynamic>) {
        return (response.data as Map<String, dynamic>)['success'] == true;
      }
      return response.statusCode == 200;
    } on DioException catch (e) {
      final msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message'] as String?)
          : e.message;
      throw ServerException(msg ?? 'Failed to delete image');
    }
  }

  @override
  Future<bool> reorderImages(
    String? unitInSectionId,
    String? tempKey,
    List<String> imageIds,
  ) async {
    try {
      final payload = {
        'imageIds': imageIds,
        if (unitInSectionId != null && unitInSectionId.trim().isNotEmpty) 'unitInSectionId': unitInSectionId
        else if (tempKey != null && tempKey.trim().isNotEmpty) 'tempKey': tempKey,
      };
      final response =
          await apiClient.post('$_baseEndpoint/reorder', data: payload);
      return response.statusCode == 204 ||
          (response.data is Map && response.data['success'] == true);
    } on DioException catch (e) {
      throw ServerException(
          e.response?.data['message'] ?? 'Failed to reorder images');
    }
  }

  @override
  Future<bool> setAsPrimaryImage(
    String? unitInSectionId,
    String? tempKey,
    String imageId,
  ) async {
    try {
      final body = {
        if (unitInSectionId != null && unitInSectionId.trim().isNotEmpty) 'unitInSectionId': unitInSectionId
        else if (tempKey != null && tempKey.trim().isNotEmpty) 'tempKey': tempKey,
      };
      final response = await apiClient
          .post('$_baseEndpoint/$imageId/set-primary', data: body);
      return response.statusCode == 204 ||
          (response.data is Map && response.data['success'] == true);
    } on DioException catch (e) {
      throw ServerException(
          e.response?.data['message'] ?? 'Failed to set primary image');
    }
  }
}

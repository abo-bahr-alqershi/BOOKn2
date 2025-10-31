// lib/features/admin_sections/data/datasources/section_images_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:bookn_cp_app/core/network/api_client.dart';
import 'package:bookn_cp_app/core/error/exceptions.dart';
import 'package:bookn_cp_app/core/constants/app_constants.dart';
import 'package:bookn_cp_app/core/utils/video_utils.dart';
import '../models/section_image_model.dart';

abstract class SectionImagesRemoteDataSource {
  Future<SectionImageModel> uploadImage({
    String? sectionId,
    String? tempKey,
    required String filePath,
    String? category,
    String? alt,
    bool isPrimary = false,
    int? order,
    List<String>? tags,
    ProgressCallback? onSendProgress,
  });

  Future<List<SectionImageModel>> getSectionImages(
    String? sectionId, {
    String? tempKey,
  });

  Future<bool> updateImage(String imageId, Map<String, dynamic> data);
  Future<bool> deleteImage(String imageId);
  Future<bool> reorderImages(
    String? sectionId,
    String? tempKey,
    List<String> imageIds,
  );
  Future<bool> setAsPrimaryImage(
    String? sectionId,
    String? tempKey,
    String imageId,
  );
}

class SectionImagesRemoteDataSourceImpl
    implements SectionImagesRemoteDataSource {
  final ApiClient apiClient;
  static const String _baseEndpoint = '/api/admin/section-images';

  SectionImagesRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<SectionImageModel> uploadImage({
    String? sectionId,
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
      print('📤 Uploading image: $filePath');
      print('  - SectionId: $sectionId');
      print('  - TempKey: $tempKey');

      String? posterPath;
      if (AppConstants.isVideoFile(filePath)) {
        posterPath = await VideoUtils.generateVideoThumbnail(filePath);
      }

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        if (sectionId != null) 'sectionId': sectionId,
        if (tempKey != null) 'tempKey': tempKey,
        if (category != null) 'category': category,
        if (alt != null) 'alt': alt,
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
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
        onSendProgress: onSendProgress,
      );

      print('📥 Upload response: ${response.data}');

      if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        if (map['success'] == true && map['data'] != null) {
          return SectionImageModel.fromJson(map['data']);
        }
      }
      throw ServerException(
          response.data['message'] ?? 'Failed to upload image');
    } on DioException catch (e) {
      print('❌ Upload error: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      throw ServerException(e.response?.data['message'] ??
          'Failed to upload image: ${e.message}');
    }
  }

  @override
  Future<List<SectionImageModel>> getSectionImages(
    String? sectionId, {
    String? tempKey,
  }) async {
    try {
      print('🔍 Getting section images');
      print('  - SectionId: $sectionId');
      print('  - TempKey: $tempKey');

      final qp = <String, dynamic>{
        if (sectionId != null) 'sectionId': sectionId,
        if (tempKey != null) 'tempKey': tempKey,
        'sortBy': 'order',
        'sortOrder': 'asc',
      };

      final response = await apiClient.get(_baseEndpoint, queryParameters: qp);

      print('📥 Response type: ${response.data.runtimeType}');
      print('📥 Response data: ${response.data}');

      // Handle different response formats
      if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;

        // Check for success field
        if (map['success'] == true) {
          // Try different field names for the images array
          final dynamic imagesData =
              map['images'] ?? map['items'] ?? map['data'];

          if (imagesData is List) {
            return imagesData
                .map((json) => SectionImageModel.fromJson(json))
                .toList();
          } else if (imagesData is Map && imagesData['items'] is List) {
            // Handle paginated response
            final List<dynamic> items = imagesData['items'];
            return items
                .map((json) => SectionImageModel.fromJson(json))
                .toList();
          }
        }

        // If success field doesn't exist, check if data is directly in the map
        if (map['items'] is List) {
          final List<dynamic> items = map['items'];
          return items.map((json) => SectionImageModel.fromJson(json)).toList();
        }
      } else if (response.data is List) {
        // If response is directly a list
        return (response.data as List)
            .map((json) => SectionImageModel.fromJson(json))
            .toList();
      }

      // Return empty list if no images found
      print('⚠️ No images found or unexpected response format');
      return [];
    } on DioException catch (e) {
      print('❌ Get images error: ${e.message}');
      print('❌ Response: ${e.response?.data}');

      // Check if it's a connection error
      if (e.type == DioExceptionType.unknown &&
          e.error.toString().contains('SocketException')) {
        throw const ServerException(
            'لا يمكن الاتصال بالخادم. تحقق من الاتصال بالإنترنت أو إعدادات الخادم');
      }

      throw ServerException(e.response?.data['message'] ??
          'Failed to fetch section images: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error: $e');
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<bool> updateImage(String imageId, Map<String, dynamic> data) async {
    try {
      final response = await apiClient.put(
        '$_baseEndpoint/$imageId',
        data: data,
      );

      return response.data['success'] == true;
    } on DioException catch (e) {
      throw ServerException(
          e.response?.data['message'] ?? 'Failed to update image');
    }
  }

  @override
  Future<bool> deleteImage(String imageId) async {
    try {
      final response = await apiClient.delete('$_baseEndpoint/$imageId');
      return response.data['success'] == true;
    } on DioException catch (e) {
      throw ServerException(
          e.response?.data['message'] ?? 'Failed to delete image');
    }
  }

  @override
  Future<bool> reorderImages(
    String? sectionId,
    String? tempKey,
    List<String> imageIds,
  ) async {
    try {
      final payload = {
        'imageIds': imageIds,
        if (sectionId != null) 'sectionId': sectionId,
        if (tempKey != null) 'tempKey': tempKey,
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
    String? sectionId,
    String? tempKey,
    String imageId,
  ) async {
    try {
      final body = {
        if (sectionId != null) 'sectionId': sectionId,
        if (tempKey != null) 'tempKey': tempKey,
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

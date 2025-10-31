// lib/features/admin_units/data/datasources/unit_images_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:bookn_cp_app/core/network/api_client.dart';
import 'package:bookn_cp_app/core/error/exceptions.dart';
import 'package:bookn_cp_app/core/constants/app_constants.dart';
import 'package:bookn_cp_app/core/utils/video_utils.dart';
import '../models/unit_image_model.dart';

abstract class UnitImagesRemoteDataSource {
  Future<UnitImageModel> uploadImage({
    String? unitId,
    String? sectionId,
    String? unitInSectionId,
    String? tempKey,
    required String filePath,
    String? videoThumbnailPath,
    String? category,
    String? alt,
    bool isPrimary = false,
    int? order,
    List<String>? tags,
    ProgressCallback? onSendProgress,
  });

  Future<List<UnitImageModel>> getUnitImages(String? unitId, {String? tempKey});
  Future<bool> updateImage(String imageId, Map<String, dynamic> data);
  Future<bool> deleteImage(String imageId);
  Future<bool> reorderImages(
      String? unitId, String? tempKey, List<String> imageIds);
  Future<bool> setAsPrimaryImage(
      String? unitId, String? tempKey, String imageId);
}

class UnitImagesRemoteDataSourceImpl implements UnitImagesRemoteDataSource {
  final ApiClient apiClient;
  static const String _imagesEndpoint = '/api/images';

  UnitImagesRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<UnitImageModel> uploadImage({
    String? unitId,
    String? sectionId,
    String? unitInSectionId,
    String? tempKey,
    required String filePath,
    String? videoThumbnailPath,
    String? category,
    String? alt,
    bool isPrimary = false,
    int? order,
    List<String>? tags,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      // Auto-generate a poster if not provided and it's a video file
      String? posterPath = videoThumbnailPath;
      if (posterPath == null && AppConstants.isVideoFile(filePath)) {
        posterPath = await VideoUtils.generateVideoThumbnail(filePath);
      }
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        'unitId': unitId,
        if (sectionId != null) 'sectionId': sectionId,
        if (unitInSectionId != null) 'unitInSectionId': unitInSectionId,
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
        '$_imagesEndpoint/upload',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
        onSendProgress: onSendProgress,
      );

      if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        if (map['success'] == true && map['image'] != null) {
          return UnitImageModel.fromJson(map['image']);
        }
        // بعض البيئات قد ترجع تحت data
        if (map['success'] == true && map['data'] != null) {
          final data = map['data'];
          if (data is Map<String, dynamic> && data.containsKey('url')) {
            return UnitImageModel.fromJson(data);
          }
        }
      }
      throw ServerException(
          response.data['message'] ?? 'Failed to upload image');
    } on DioException catch (e) {
      throw ServerException(
          e.response?.data['message'] ?? 'Failed to upload image');
    }
  }

  @override
  Future<List<UnitImageModel>> getUnitImages(String? unitId,
      {String? tempKey}) async {
    try {
      final qp = <String, dynamic>{
        'unitId': unitId,
        'sortBy': 'order',
        'sortOrder': 'asc',
      };
      if (tempKey != null) qp['tempKey'] = tempKey;
      final response =
          await apiClient.get(_imagesEndpoint, queryParameters: qp);

      if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        final List<dynamic> list =
            (map['images'] as List?) ?? (map['items'] as List?) ?? const [];
        return list.map((json) => UnitImageModel.fromJson(json)).toList();
      }
      throw const ServerException('Invalid response when fetching images');
    } on DioException catch (e) {
      throw ServerException(
          e.response?.data['message'] ?? 'Failed to fetch unit images');
    }
  }

  @override
  Future<bool> updateImage(String imageId, Map<String, dynamic> data) async {
    try {
      final response = await apiClient.put(
        '$_imagesEndpoint/$imageId',
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
      final response = await apiClient.delete('$_imagesEndpoint/$imageId');
      return response.data['success'] == true;
    } on DioException catch (e) {
      throw ServerException(
          e.response?.data['message'] ?? 'Failed to delete image');
    }
  }

  @override
  Future<bool> reorderImages(
      String? unitId, String? tempKey, List<String> imageIds) async {
    try {
      final payload = {
        'imageIds': imageIds,
        if (unitId != null) 'unitId': unitId,
        if (tempKey != null) 'tempKey': tempKey,
      };
      final response =
          await apiClient.post('$_imagesEndpoint/reorder', data: payload);
      return response.statusCode == 204 ||
          (response.data is Map && response.data['success'] == true);
    } on DioException catch (e) {
      throw ServerException(
          e.response?.data['message'] ?? 'Failed to reorder images');
    }
  }

  @override
  Future<bool> setAsPrimaryImage(
      String? unitId, String? tempKey, String imageId) async {
    try {
      final body = {
        if (unitId != null) 'unitId': unitId,
        if (tempKey != null) 'tempKey': tempKey,
      };
      final response = await apiClient
          .post('$_imagesEndpoint/$imageId/set-primary', data: body);
      return response.statusCode == 204 ||
          (response.data is Map && response.data['success'] == true);
    } on DioException catch (e) {
      throw ServerException(
          e.response?.data['message'] ?? 'Failed to set primary image');
    }
  }
}

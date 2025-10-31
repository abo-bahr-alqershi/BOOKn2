// lib/features/admin_reviews/data/datasources/reviews_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:bookn_cp_app/core/network/api_client.dart';
import 'package:bookn_cp_app/core/error/exceptions.dart';
import 'package:bookn_cp_app/services/local_storage_service.dart';
import 'package:bookn_cp_app/core/constants/storage_constants.dart';
import 'package:bookn_cp_app/core/models/paginated_result.dart';
import '../models/review_model.dart';
import '../models/review_response_model.dart';

abstract class ReviewsRemoteDataSource {
  Future<PaginatedResult<ReviewModel>> getAllReviews({
    String? status,
    double? minRating,
    double? maxRating,
    bool? hasImages,
    String? propertyId,
    String? unitId,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int? pageNumber,
    int? pageSize,
    bool? includeStats,
  });
  
  // Not available in backend; kept for interface compatibility but unused
  Future<ReviewModel> getReviewDetails(String reviewId);
  Future<ReviewModel?> getReviewByBooking(String bookingId);
  Future<bool> approveReview(String reviewId);
  // Currently not supported by backend (no endpoint). Keep for future.
  Future<bool> rejectReview(String reviewId);
  Future<bool> deleteReview(String reviewId);
  Future<ReviewResponseModel> respondToReview({
    required String reviewId,
    required String responseText,
    required String respondedBy,
  });
  Future<List<ReviewResponseModel>> getReviewResponses(String reviewId);
  Future<bool> deleteReviewResponse(String responseId);
}

class ReviewsRemoteDataSourceImpl implements ReviewsRemoteDataSource {
  final ApiClient apiClient;
  final LocalStorageService localStorage;
  
  ReviewsRemoteDataSourceImpl({required this.apiClient, required this.localStorage});
  
  @override
  Future<PaginatedResult<ReviewModel>> getAllReviews({
    String? status,
    double? minRating,
    double? maxRating,
    bool? hasImages,
    String? propertyId,
    String? unitId,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int? pageNumber,
    int? pageSize,
    bool? includeStats,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (status != null) queryParams['status'] = status;
      if (minRating != null) queryParams['minRating'] = minRating;
      if (maxRating != null) queryParams['maxRating'] = maxRating;
      if (hasImages != null) queryParams['hasImages'] = hasImages;
      if (propertyId != null) queryParams['propertyId'] = propertyId;
      if (unitId != null) queryParams['unitId'] = unitId;
      if (userId != null) queryParams['userId'] = userId;
      // Align with backend query contract: ReviewedAfter/ReviewedBefore
      if (startDate != null) queryParams['reviewedAfter'] = startDate.toIso8601String();
      if (endDate != null) queryParams['reviewedBefore'] = endDate.toIso8601String();
      if (pageNumber != null) queryParams['pageNumber'] = pageNumber;
      if (pageSize != null) queryParams['pageSize'] = pageSize;
      if (includeStats != null) queryParams['includeStats'] = includeStats;
      
      final response = await apiClient.get(
        '/api/admin/reviews',
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200) {
        final body = response.data;
        // Backend now returns PaginatedResult<ReviewDto>
        return PaginatedResult<ReviewModel>.fromJson(
          body is Map<String, dynamic> ? body : {},
          (json) => ReviewModel.fromJson(json),
        );
      }
      throw ServerException('Failed to load reviews');
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Network error occurred');
    }
  }
  
  @override
  Future<ReviewModel> getReviewDetails(String reviewId) async {
    try {
      final response = await apiClient.get('/api/admin/reviews/$reviewId');
      if (response.statusCode == 200) {
        final body = response.data;
        final success = (body is Map<String, dynamic>) && (body['success'] == true || body['isSuccess'] == true);
        if (success) {
          final data = body['data'] as Map<String, dynamic>;
          return ReviewModel.fromJson(data);
        }
        throw ServerException((body is Map && body['message'] is String) ? body['message'] as String : 'Failed to load review details');
      }
      throw ServerException('Failed to load review details');
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Failed to load review details');
    }
  }

  @override
  Future<ReviewModel?> getReviewByBooking(String bookingId) async {
    try {
      final response = await apiClient.get('/api/admin/reviews/by-booking/$bookingId');
      if (response.statusCode == 200) {
        final body = response.data;
        final success = (body is Map<String, dynamic>) && (body['success'] == true || body['isSuccess'] == true);
        if (success) {
          final data = body['data'];
          if (data == null) return null;
          return ReviewModel.fromJson(data as Map<String, dynamic>);
        }
        throw ServerException((body is Map && body['message'] is String) ? body['message'] as String : 'Failed to load review by booking');
      }
      throw ServerException('Failed to load review by booking');
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Failed to load review by booking');
    }
  }
  
  @override
  Future<bool> approveReview(String reviewId) async {
    try {
      final String? adminId = localStorage.getData(StorageConstants.userId)?.toString();
      if (adminId == null || adminId.isEmpty) {
        throw ServerException('AdminId is missing');
      }
      final response = await apiClient.post(
        '/api/admin/reviews/$reviewId/approve',
        data: {
          // Matches ApproveReviewCommand AdminId
          'adminId': adminId,
        },
      );
      
      if (response.statusCode == 200) {
        final body = response.data;
        final success = (body is Map<String, dynamic>) && (body['success'] == true || body['isSuccess'] == true);
        if (success) {
          // Prefer returned data if present, else true
          if (body is Map<String, dynamic> && body['data'] is bool) {
            return body['data'] as bool;
          }
          return true;
        }
        throw ServerException((body is Map && body['message'] is String) ? body['message'] as String : 'Failed to approve review');
      }
      throw ServerException('Failed to approve review');
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Failed to approve review');
    }
  }
  
  @override
  Future<bool> rejectReview(String reviewId) async {
    // Not supported by backend as of now
    throw ServerException('Reject review is not supported by backend');
  }
  
  @override
  Future<bool> deleteReview(String reviewId) async {
    try {
      final response = await apiClient.delete('/api/admin/reviews/$reviewId');
      
      if (response.statusCode == 200) {
        final body = response.data;
        final success = (body is Map<String, dynamic>) && (body['success'] == true || body['isSuccess'] == true);
        if (success) {
          if (body is Map<String, dynamic> && body['data'] is bool) {
            return body['data'] as bool;
          }
          return true;
        }
        throw ServerException((body is Map && body['message'] is String) ? body['message'] as String : 'Failed to delete review');
      }
      throw ServerException('Failed to delete review');
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Failed to delete review');
    }
  }
  
  @override
  Future<ReviewResponseModel> respondToReview({
    required String reviewId,
    required String responseText,
    required String respondedBy,
  }) async {
    try {
      // Backend expects OwnerId as GUID. If client passes a non-GUID placeholder, omit it to let backend use current user.
      String? ownerIdToSend;
      final trimmed = respondedBy.trim();
      final guidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12} ?$');
      if (trimmed.isNotEmpty && guidRegex.hasMatch(trimmed)) {
        ownerIdToSend = trimmed;
      } else {
        // Try to read from local storage if present
        final stored = localStorage.getData(StorageConstants.userId)?.toString();
        if (stored != null && stored.isNotEmpty && RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(stored)) {
          ownerIdToSend = stored;
        }
      }

      final Map<String, dynamic> payload = {
        'responseText': responseText,
      };
      if (ownerIdToSend != null && ownerIdToSend.isNotEmpty) {
        payload['ownerId'] = ownerIdToSend;
      }

      final response = await apiClient.post(
        '/api/admin/reviews/$reviewId/respond',
        data: payload,
      );
      
      if (response.statusCode == 200) {
        final body = response.data;
        final success = (body is Map<String, dynamic>) && (body['success'] == true || body['isSuccess'] == true);
        if (success) {
          return ReviewResponseModel.fromJson(body['data'] as Map<String, dynamic>);
        }
        throw ServerException((body is Map && body['message'] is String) ? body['message'] as String : 'Failed to add response');
      }
      throw ServerException('Failed to add response');
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Failed to respond to review');
    }
  }
  
  @override
  Future<List<ReviewResponseModel>> getReviewResponses(String reviewId) async {
    try {
      final response = await apiClient.get(
        '/api/admin/reviews/$reviewId/responses',
      );
      
      if (response.statusCode == 200) {
        final body = response.data;
        final success = (body is Map<String, dynamic>) && (body['success'] == true || body['isSuccess'] == true);
        if (success) {
          final data = (body['data'] as List?) ?? const [];
          return data.map((json) => ReviewResponseModel.fromJson(json)).toList();
        }
        throw ServerException((body is Map && body['message'] is String) ? body['message'] as String : 'Failed to load responses');
      }
      throw ServerException('Failed to load responses');
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Network error occurred');
    }
  }
  
  @override
  Future<bool> deleteReviewResponse(String responseId) async {
    try {
      final response = await apiClient.delete(
        '/api/admin/reviews/responses/$responseId',
      );
      
      if (response.statusCode == 200) {
        final body = response.data;
        final success = (body is Map<String, dynamic>) && (body['success'] == true || body['isSuccess'] == true);
        if (success) {
          if (body is Map<String, dynamic> && body['data'] is bool) {
            return body['data'] as bool;
          }
          return true;
        }
        throw ServerException((body is Map && body['message'] is String) ? body['message'] as String : 'Failed to delete response');
      }
      throw ServerException('Failed to delete response');
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Failed to delete response');
    }
  }
}
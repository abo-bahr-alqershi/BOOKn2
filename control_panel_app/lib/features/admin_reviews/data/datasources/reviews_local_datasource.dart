// lib/features/admin_reviews/data/datasources/reviews_local_datasource.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/review_model.dart';

abstract class ReviewsLocalDataSource {
  Future<List<ReviewModel>> getCachedReviews();
  Future<void> cacheReviews(List<ReviewModel> reviews);
  Future<void> deleteReview(String reviewId);
  Future<void> clearCache();
  Future<void> upsertReview(ReviewModel review);
}

class ReviewsLocalDataSourceImpl implements ReviewsLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String CACHED_REVIEWS_KEY = 'CACHED_REVIEWS';
  
  ReviewsLocalDataSourceImpl({required this.sharedPreferences});
  
  @override
  Future<List<ReviewModel>> getCachedReviews() async {
    final jsonString = sharedPreferences.getString(CACHED_REVIEWS_KEY);
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => ReviewModel.fromJson(json)).toList();
    }
    return [];
  }
  
  @override
  Future<void> cacheReviews(List<ReviewModel> reviews) async {
    final jsonList = reviews.map((review) => review.toJson()).toList();
    await sharedPreferences.setString(
      CACHED_REVIEWS_KEY,
      json.encode(jsonList),
    );
  }
  
  @override
  Future<void> deleteReview(String reviewId) async {
    final reviews = await getCachedReviews();
    final updatedReviews = reviews.where((r) => r.id != reviewId).toList();
    await cacheReviews(updatedReviews);
  }
  
  @override
  Future<void> clearCache() async {
    await sharedPreferences.remove(CACHED_REVIEWS_KEY);
  }

  @override
  Future<void> upsertReview(ReviewModel review) async {
    final reviews = await getCachedReviews();
    final index = reviews.indexWhere((r) => r.id == review.id);
    if (index >= 0) {
      reviews[index] = review;
    } else {
      reviews.add(review);
    }
    await cacheReviews(reviews);
  }
}
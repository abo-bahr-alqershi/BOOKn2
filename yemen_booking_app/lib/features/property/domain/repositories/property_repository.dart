import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../entities/property_detail.dart';
import '../entities/unit.dart' as entity;

abstract class PropertyRepository {
  Future<Either<Failure, PropertyDetail>> getPropertyDetails({
    required String propertyId,
    String? userId,
  });

  Future<Either<Failure, List<entity.Unit>>> getPropertyUnits({
    required String propertyId,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    required int guestsCount,
  });

  Future<Either<Failure, List<PropertyReview>>> getPropertyReviews({
    required String propertyId,
    int pageNumber = 1,
    int pageSize = 20,
    String? sortBy,
    String? sortDirection,
    bool withImagesOnly = false,
    String? userId,
  });

  Future<Either<Failure, bool>> addToFavorites({
    required String propertyId,
    required String userId,
    String? notes,
    DateTime? desiredVisitDate,
    double? expectedBudget,
    String currency = 'YER',
  });

  Future<Either<Failure, bool>> removeFromFavorites({
    required String propertyId,
    required String userId,
  });

  Future<Either<Failure, bool>> updateViewCount({
    required String propertyId,
  });
}

class PropertyReview extends Equatable {
  final String id;
  final String bookingId;
  final String propertyName;
  final String userName;
  final int cleanliness;
  final int service;
  final int location;
  final int value;
  final double averageRating;
  final String comment;
  final String? responseText;
  final DateTime? responseDate;
  final DateTime createdAt;
  final List<ReviewImage> images;

  const PropertyReview({
    required this.id,
    required this.bookingId,
    required this.propertyName,
    required this.userName,
    required this.cleanliness,
    required this.service,
    required this.location,
    required this.value,
    required this.averageRating,
    required this.comment,
    this.responseText,
    this.responseDate,
    required this.createdAt,
    required this.images,
  });

  @override
  List<Object?> get props => [
        id,
        bookingId,
        propertyName,
        userName,
        cleanliness,
        service,
        location,
        value,
        averageRating,
        comment,
        responseText,
        responseDate,
        createdAt,
        images,
      ];
}

class ReviewImage extends Equatable {
  final String id;
  final String reviewId;
  final String name;
  final String url;
  final int sizeBytes;
  final String type;
  final String category;
  final String caption;
  final String altText;
  final DateTime uploadedAt;

  const ReviewImage({
    required this.id,
    required this.reviewId,
    required this.name,
    required this.url,
    required this.sizeBytes,
    required this.type,
    required this.category,
    required this.caption,
    required this.altText,
    required this.uploadedAt,
  });

  @override
  List<Object?> get props => [
        id,
        reviewId,
        name,
        url,
        sizeBytes,
        type,
        category,
        caption,
        altText,
        uploadedAt,
      ];
}
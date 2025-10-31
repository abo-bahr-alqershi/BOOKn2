import 'package:equatable/equatable.dart';

abstract class ReviewEvent extends Equatable {
  const ReviewEvent();

  @override
  List<Object?> get props => [];
}

/// حدث إنشاء مراجعة جديدة
class CreateReviewEvent extends ReviewEvent {
  final String bookingId;
  final String propertyId;
  final int cleanliness;
  final int service;
  final int location;
  final int value;
  final String comment;
  final List<String>? imagesBase64;

  const CreateReviewEvent({
    required this.bookingId,
    required this.propertyId,
    required this.cleanliness,
    required this.service,
    required this.location,
    required this.value,
    required this.comment,
    this.imagesBase64,
  });

  @override
  List<Object?> get props => [
        bookingId,
        propertyId,
        cleanliness,
        service,
        location,
        value,
        comment,
        imagesBase64,
      ];
}

/// حدث جلب مراجعات العقار
class GetPropertyReviewsEvent extends ReviewEvent {
  final String propertyId;
  final int pageNumber;
  final int pageSize;
  final int? rating;
  final String? sortBy;
  final String? sortDirection;
  final bool? withImagesOnly;
  final String? userId;

  const GetPropertyReviewsEvent({
    required this.propertyId,
    this.pageNumber = 1,
    this.pageSize = 10,
    this.rating,
    this.sortBy,
    this.sortDirection,
    this.withImagesOnly,
    this.userId,
  });

  @override
  List<Object?> get props => [
        propertyId,
        pageNumber,
        pageSize,
        rating,
        sortBy,
        sortDirection,
        withImagesOnly,
        userId,
      ];
}

/// حدث جلب المزيد من المراجعات
class LoadMoreReviewsEvent extends ReviewEvent {
  const LoadMoreReviewsEvent();
}

/// حدث جلب ملخص المراجعات
class GetPropertyReviewsSummaryEvent extends ReviewEvent {
  final String propertyId;

  const GetPropertyReviewsSummaryEvent({required this.propertyId});

  @override
  List<Object?> get props => [propertyId];
}

/// حدث رفع صور المراجعة
class UploadReviewImagesEvent extends ReviewEvent {
  final String reviewId;
  final List<String> imagesBase64;

  const UploadReviewImagesEvent({
    required this.reviewId,
    required this.imagesBase64,
  });

  @override
  List<Object?> get props => [reviewId, imagesBase64];
}

/// حدث تصفية المراجعات
class FilterReviewsEvent extends ReviewEvent {
  final int? rating;
  final bool? withImagesOnly;
  final String? sortBy;
  final String? sortDirection;

  const FilterReviewsEvent({
    this.rating,
    this.withImagesOnly,
    this.sortBy,
    this.sortDirection,
  });

  @override
  List<Object?> get props => [rating, withImagesOnly, sortBy, sortDirection];
}

/// حدث تحديث المراجعات
class RefreshReviewsEvent extends ReviewEvent {
  final String propertyId;

  const RefreshReviewsEvent({required this.propertyId});

  @override
  List<Object?> get props => [propertyId];
}

/// حدث الإعجاب بمراجعة
class LikeReviewEvent extends ReviewEvent {
  final String reviewId;

  const LikeReviewEvent({required this.reviewId});

  @override
  List<Object?> get props => [reviewId];
}

/// حدث إلغاء الإعجاب بمراجعة
class UnlikeReviewEvent extends ReviewEvent {
  final String reviewId;

  const UnlikeReviewEvent({required this.reviewId});

  @override
  List<Object?> get props => [reviewId];
}
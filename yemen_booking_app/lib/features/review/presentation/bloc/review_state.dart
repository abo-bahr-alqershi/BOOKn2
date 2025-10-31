import 'package:equatable/equatable.dart';
import '../../../../core/models/paginated_result.dart';
import '../../domain/entities/review.dart';
import '../../domain/entities/review_image.dart';

abstract class ReviewState extends Equatable {
  const ReviewState();

  @override
  List<Object?> get props => [];
}

/// الحالة الأولية
class ReviewInitial extends ReviewState {}

/// حالة التحميل
class ReviewLoading extends ReviewState {}

/// حالة تحميل المزيد
class ReviewLoadingMore extends ReviewState {
  final List<Review> currentReviews;

  const ReviewLoadingMore({required this.currentReviews});

  @override
  List<Object?> get props => [currentReviews];
}

/// حالة النجاح في جلب المراجعات
class ReviewsLoaded extends ReviewState {
  final PaginatedResult<Review> reviews;
  final bool hasReachedMax;

  const ReviewsLoaded({
    required this.reviews,
    this.hasReachedMax = false,
  });

  ReviewsLoaded copyWith({
    PaginatedResult<Review>? reviews,
    bool? hasReachedMax,
  }) {
    return ReviewsLoaded(
      reviews: reviews ?? this.reviews,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object?> get props => [reviews, hasReachedMax];
}

/// حالة النجاح في جلب ملخص المراجعات
class ReviewsSummaryLoaded extends ReviewState {
  final ReviewsSummary summary;

  const ReviewsSummaryLoaded({required this.summary});

  @override
  List<Object?> get props => [summary];
}

/// حالة النجاح في إنشاء مراجعة
class ReviewCreated extends ReviewState {
  final Review review;

  const ReviewCreated({required this.review});

  @override
  List<Object?> get props => [review];
}

/// حالة إنشاء المراجعة
class ReviewCreating extends ReviewState {}

/// حالة النجاح في رفع الصور
class ReviewImagesUploaded extends ReviewState {
  final List<ReviewImage> images;

  const ReviewImagesUploaded({required this.images});

  @override
  List<Object?> get props => [images];
}

/// حالة رفع الصور
class ReviewImagesUploading extends ReviewState {
  final double progress;

  const ReviewImagesUploading({this.progress = 0.0});

  @override
  List<Object?> get props => [progress];
}

/// حالة الخطأ
class ReviewError extends ReviewState {
  final String message;

  const ReviewError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// حالة الخطأ في إنشاء المراجعة
class ReviewCreateError extends ReviewState {
  final String message;
  final Map<String, List<String>>? errors;

  const ReviewCreateError({
    required this.message,
    this.errors,
  });

  @override
  List<Object?> get props => [message, errors];
}

/// حالة تحديث المراجعة
class ReviewUpdating extends ReviewState {
  final String reviewId;

  const ReviewUpdating({required this.reviewId});

  @override
  List<Object?> get props => [reviewId];
}

/// حالة تم تحديث المراجعة
class ReviewUpdated extends ReviewState {
  final Review review;

  const ReviewUpdated({required this.review});

  @override
  List<Object?> get props => [review];
}
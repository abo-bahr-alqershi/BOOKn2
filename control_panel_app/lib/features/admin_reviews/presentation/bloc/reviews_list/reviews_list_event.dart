// lib/features/admin_reviews/presentation/bloc/reviews_list/reviews_list_event.dart

part of 'reviews_list_bloc.dart';

abstract class ReviewsListEvent extends Equatable {
  const ReviewsListEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadReviewsEvent extends ReviewsListEvent {
  final String? status;
  final double? minRating;
  final double? maxRating;
  final bool? hasImages;
  final String? propertyId;
  final String? userId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? pageNumber;
  final int? pageSize;
  
  const LoadReviewsEvent({
    this.status,
    this.minRating,
    this.maxRating,
    this.hasImages,
    this.propertyId,
    this.userId,
    this.startDate,
    this.endDate,
    this.pageNumber,
    this.pageSize,
  });
  
  @override
  List<Object?> get props => [
    status, minRating, maxRating, hasImages,
    propertyId, userId, startDate, endDate,
    pageNumber, pageSize,
  ];
}

class FilterReviewsEvent extends ReviewsListEvent {
  final String searchQuery;
  final double? minRating;
  final bool? isPending;
  final bool? hasResponse;
  final String? propertyId;
  
  const FilterReviewsEvent({
    this.searchQuery = '',
    this.minRating,
    this.isPending,
    this.hasResponse,
    this.propertyId,
  });
  
  @override
  List<Object?> get props => [searchQuery, minRating, isPending, hasResponse, propertyId];
}

class ApproveReviewEvent extends ReviewsListEvent {
  final String reviewId;
  
  const ApproveReviewEvent(this.reviewId);
  
  @override
  List<Object> get props => [reviewId];
}

class DeleteReviewEvent extends ReviewsListEvent {
  final String reviewId;
  
  const DeleteReviewEvent(this.reviewId);
  
  @override
  List<Object> get props => [reviewId];
}

class RefreshReviewsEvent extends ReviewsListEvent {}
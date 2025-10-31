// lib/features/admin_reviews/presentation/bloc/reviews_list/reviews_list_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/review.dart';
import '../../../domain/usecases/get_all_reviews_usecase.dart';
import '../../../domain/usecases/approve_review_usecase.dart';
import '../../../domain/usecases/delete_review_usecase.dart';

part 'reviews_list_event.dart';
part 'reviews_list_state.dart';

class ReviewsListBloc extends Bloc<ReviewsListEvent, ReviewsListState> {
  final GetAllReviewsUseCase getAllReviews;
  final ApproveReviewUseCase approveReview;
  final DeleteReviewUseCase deleteReview;
  
  List<Review> _allReviews = [];
  int _currentPageNumber = 1;
  int _currentPageSize = 20;
  bool _isLoadingMore = false;
  
  ReviewsListBloc({
    required this.getAllReviews,
    required this.approveReview,
    required this.deleteReview,
  }) : super(ReviewsListInitial()) {
    on<LoadReviewsEvent>(_onLoadReviews);
    on<FilterReviewsEvent>(_onFilterReviews);
    on<ApproveReviewEvent>(_onApproveReview);
    on<DeleteReviewEvent>(_onDeleteReview);
    on<RefreshReviewsEvent>(_onRefreshReviews);
  }
  
  Future<void> _onLoadReviews(
    LoadReviewsEvent event,
    Emitter<ReviewsListState> emit,
  ) async {
    final isLoadMore = state is ReviewsListLoaded && (event.pageNumber ?? 1) > 1;
    if (!isLoadMore) {
      emit(ReviewsListLoading());
    } else {
      if (_isLoadingMore) return; // guard against duplicate triggers
      _isLoadingMore = true;
      
      // 🎯 عرض حالة LoadingMore بدلاً من إخفاء المحتوى
      final current = state as ReviewsListLoaded;
      emit(ReviewsListLoadingMore(
        reviews: current.reviews,
        filteredReviews: current.filteredReviews,
        pendingCount: current.pendingCount,
        averageRating: current.averageRating,
        approvingReviewIds: current.approvingReviewIds,
        stats: current.stats,
      ));
    }
    
    final nextPageNumber = event.pageNumber ?? (isLoadMore ? _currentPageNumber + 1 : 1);
    final nextPageSize = event.pageSize ?? _currentPageSize;

    final result = await getAllReviews(GetAllReviewsParams(
      status: event.status,
      minRating: event.minRating,
      maxRating: event.maxRating,
      hasImages: event.hasImages,
      propertyId: event.propertyId,
      userId: event.userId,
      startDate: event.startDate,
      endDate: event.endDate,
      pageNumber: nextPageNumber,
      pageSize: nextPageSize,
      includeStats: true, // Always include stats so UI is consistent across pages
    ));
    
    result.fold(
      (failure) {
        _isLoadingMore = false;
        emit(ReviewsListError(failure.message));
      },
      (page) {
        final stats = _extractStats(page.metadata);
        if (isLoadMore && state is ReviewsListLoaded) {
          final current = state as ReviewsListLoaded;
          final combined = <Review>[...current.reviews];
          for (final r in page.items) {
            if (!combined.any((c) => c.id == r.id)) combined.add(r);
          }
          _allReviews = combined;
          _currentPageNumber = nextPageNumber;
          _currentPageSize = nextPageSize;
          emit(ReviewsListLoaded(
            reviews: combined,
            filteredReviews: combined,
            pendingCount: _computePendingCount(combined, stats ?? current.stats),
            averageRating: _computeAverageRating(combined, stats ?? current.stats),
            stats: stats ?? current.stats,
            approvingReviewIds: current.approvingReviewIds,
          ));
        } else {
          _allReviews = page.items;
          _currentPageNumber = nextPageNumber;
          _currentPageSize = nextPageSize;
          emit(ReviewsListLoaded(
            reviews: page.items,
            filteredReviews: page.items,
            pendingCount: _computePendingCount(page.items, stats),
            averageRating: _computeAverageRating(page.items, stats),
            stats: stats,
            approvingReviewIds: const <String>{},
          ));
        }
        _isLoadingMore = false;
      },
    );
  }
  
  Future<void> _onFilterReviews(
    FilterReviewsEvent event,
    Emitter<ReviewsListState> emit,
  ) async {
    if (state is ReviewsListLoaded) {
      final currentState = state as ReviewsListLoaded;

      // If high-level filters that impact backend stats are provided (minRating or isPending),
      // refetch from server to update metadata. Keep search locally.
      final bool requiresServerRefetch = event.minRating != null || event.isPending != null;
      if (requiresServerRefetch) {
        emit(ReviewsListLoading());
        final result = await getAllReviews(GetAllReviewsParams(
          status: event.isPending == null
              ? null
              : (event.isPending! ? 'pending' : 'approved'),
          minRating: event.minRating,
          propertyId: event.propertyId,
          pageNumber: 1,
          pageSize: currentState.reviews.length.clamp(10, 100),
          includeStats: true,
        ));
        result.fold(
          (failure) => emit(ReviewsListError(failure.message)),
          (page) {
            _allReviews = page.items;
            // Apply only the text/response filters locally after refetch
            var filtered = _allReviews;
            if (event.searchQuery.isNotEmpty) {
              filtered = filtered.where((review) =>
                review.userName.toLowerCase().contains(event.searchQuery.toLowerCase()) ||
                review.propertyName.toLowerCase().contains(event.searchQuery.toLowerCase()) ||
                review.comment.toLowerCase().contains(event.searchQuery.toLowerCase())
              ).toList();
            }
            if (event.hasResponse != null) {
              filtered = filtered.where((r) => r.hasResponse == event.hasResponse).toList();
            }
            final stats = _extractStats(page.metadata);
            emit(ReviewsListLoaded(
              reviews: page.items,
              filteredReviews: filtered,
              pendingCount: _computePendingCount(page.items, stats),
              averageRating: _computeAverageRating(page.items, stats),
              stats: stats,
              approvingReviewIds: const <String>{},
            ));
          },
        );
        return;
      }

      // Only local search/hasResponse filters; keep backend stats unchanged
      var filtered = _allReviews;
      if (event.searchQuery.isNotEmpty) {
        filtered = filtered.where((review) =>
          review.userName.toLowerCase().contains(event.searchQuery.toLowerCase()) ||
          review.propertyName.toLowerCase().contains(event.searchQuery.toLowerCase()) ||
          review.comment.toLowerCase().contains(event.searchQuery.toLowerCase())
        ).toList();
      }
      if (event.hasResponse != null) {
        filtered = filtered.where((r) => r.hasResponse == event.hasResponse).toList();
      }
      emit(currentState.copyWith(
        filteredReviews: filtered,
      ));
    }
  }
  
  Future<void> _onApproveReview(
    ApproveReviewEvent event,
    Emitter<ReviewsListState> emit,
  ) async {
    if (state is ReviewsListLoaded) {
      final currentState = state as ReviewsListLoaded;
      // Mark this review as approving
      final Set<String> newApproving = Set<String>.from(currentState.approvingReviewIds)
        ..add(event.reviewId);
      emit(currentState.copyWith(approvingReviewIds: newApproving));

      final result = await approveReview(event.reviewId);
      
      result.fold(
        (failure) {
          // Remove from approving on failure and surface error
          final Set<String> cleaned = Set<String>.from(newApproving)..remove(event.reviewId);
          emit(currentState.copyWith(approvingReviewIds: cleaned));
          emit(ReviewsListError(failure.message));
        },
        (_) {
          final updatedReviews = currentState.reviews.map((review) {
            if (review.id == event.reviewId) {
              return Review(
                id: review.id,
                bookingId: review.bookingId,
                propertyName: review.propertyName,
                userName: review.userName,
                cleanliness: review.cleanliness,
                service: review.service,
                location: review.location,
                value: review.value,
                comment: review.comment,
                createdAt: review.createdAt,
                images: review.images,
                isApproved: true,
                isPending: false,
                responseText: review.responseText,
                responseDate: review.responseDate,
                respondedBy: review.respondedBy,
              );
            }
            return review;
          }).toList();
          
          _allReviews = updatedReviews;
          final Set<String> cleaned = Set<String>.from(newApproving)..remove(event.reviewId);
          emit(currentState.copyWith(
            reviews: updatedReviews,
            filteredReviews: updatedReviews,
            pendingCount: updatedReviews.where((r) => r.isPending).length,
            approvingReviewIds: cleaned,
          ));
        },
      );
    }
  }
  
  Future<void> _onDeleteReview(
    DeleteReviewEvent event,
    Emitter<ReviewsListState> emit,
  ) async {
    if (state is ReviewsListLoaded) {
      final currentState = state as ReviewsListLoaded;
      
      final result = await deleteReview(event.reviewId);
      
      result.fold(
        (failure) => emit(ReviewsListError(failure.message)),
        (_) {
          final updatedReviews = currentState.reviews
              .where((r) => r.id != event.reviewId)
              .toList();
          
          _allReviews = updatedReviews;
          emit(currentState.copyWith(
            reviews: updatedReviews,
            filteredReviews: updatedReviews,
            pendingCount: updatedReviews.where((r) => r.isPending).length,
            averageRating: _calculateAverageRating(updatedReviews),
          ));
        },
      );
    }
  }
  
  Future<void> _onRefreshReviews(
    RefreshReviewsEvent event,
    Emitter<ReviewsListState> emit,
  ) async {
    add(LoadReviewsEvent());
  }
  
  double _calculateAverageRating(List<Review> reviews) {
    if (reviews.isEmpty) return 0;
    final total = reviews.fold<double>(
      0,
      (sum, review) => sum + review.averageRating,
    );
    return total / reviews.length;
  }

  Map<String, dynamic>? _extractStats(Object? metadata) {
    if (metadata == null) return null;
    if (metadata is Map<String, dynamic>) return metadata;
    if (metadata is Map) {
      return metadata.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  int _computePendingCount(List<Review> reviews, Map<String, dynamic>? stats) {
    final backendPending = stats != null ? stats['pendingReviews'] : null;
    if (backendPending is int) return backendPending;
    if (backendPending is String) {
      final v = int.tryParse(backendPending);
      if (v != null) return v;
    }
    return reviews.where((r) => r.isPending).length;
  }

  double _computeAverageRating(List<Review> reviews, Map<String, dynamic>? stats) {
    final backendAvg = stats != null ? stats['averageRating'] : null;
    if (backendAvg is num) return backendAvg.toDouble();
    if (backendAvg is String) {
      final v = double.tryParse(backendAvg);
      if (v != null) return v;
    }
    return _calculateAverageRating(reviews);
  }
}
import 'package:equatable/equatable.dart';
import '../../domain/entities/property_detail.dart';
import '../../domain/entities/unit.dart';
import '../../domain/repositories/property_repository.dart';

abstract class PropertyState extends Equatable {
  const PropertyState();

  @override
  List<Object?> get props => [];
}

/// الحالة الأولية
class PropertyInitial extends PropertyState {}

/// حالة التحميل
class PropertyLoading extends PropertyState {}

/// حالة تحميل الوحدات
class PropertyUnitsLoading extends PropertyState {}

/// حالة تحميل المراجعات
class PropertyReviewsLoading extends PropertyState {}

/// حالة النجاح في جلب تفاصيل العقار
class PropertyDetailsLoaded extends PropertyState {
  final PropertyDetail property;
  final bool isFavorite;
  final int selectedImageIndex;
  final bool isFavoritePending;
  final bool? queuedFavoriteTarget;

  const PropertyDetailsLoaded({
    required this.property,
    required this.isFavorite,
    this.selectedImageIndex = 0,
    this.isFavoritePending = false,
    this.queuedFavoriteTarget,
  });

  PropertyDetailsLoaded copyWith({
    PropertyDetail? property,
    bool? isFavorite,
    int? selectedImageIndex,
    bool? isFavoritePending,
    bool? queuedFavoriteTarget,
  }) {
    return PropertyDetailsLoaded(
      property: property ?? this.property,
      isFavorite: isFavorite ?? this.isFavorite,
      selectedImageIndex: selectedImageIndex ?? this.selectedImageIndex,
      isFavoritePending: isFavoritePending ?? this.isFavoritePending,
      queuedFavoriteTarget: queuedFavoriteTarget ?? this.queuedFavoriteTarget,
    );
  }

  @override
  List<Object?> get props => [property, isFavorite, selectedImageIndex, isFavoritePending, queuedFavoriteTarget];
}

/// حالة النجاح في جلب الوحدات
class PropertyUnitsLoaded extends PropertyState {
  final List<Unit> units;
  final String? selectedUnitId;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final int guestsCount;

  const PropertyUnitsLoaded({
    required this.units,
    this.selectedUnitId,
    this.checkInDate,
    this.checkOutDate,
    required this.guestsCount,
  });

  PropertyUnitsLoaded copyWith({
    List<Unit>? units,
    String? selectedUnitId,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    int? guestsCount,
  }) {
    return PropertyUnitsLoaded(
      units: units ?? this.units,
      selectedUnitId: selectedUnitId ?? this.selectedUnitId,
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      guestsCount: guestsCount ?? this.guestsCount,
    );
  }

  @override
  List<Object?> get props => [
        units,
        selectedUnitId,
        checkInDate,
        checkOutDate,
        guestsCount,
      ];
}

/// حالة النجاح في جلب المراجعات
class PropertyReviewsLoaded extends PropertyState {
  final List<PropertyReview> reviews;
  final bool hasReachedMax;
  final int currentPage;

  const PropertyReviewsLoaded({
    required this.reviews,
    this.hasReachedMax = false,
    this.currentPage = 1,
  });

  PropertyReviewsLoaded copyWith({
    List<PropertyReview>? reviews,
    bool? hasReachedMax,
    int? currentPage,
  }) {
    return PropertyReviewsLoaded(
      reviews: reviews ?? this.reviews,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [reviews, hasReachedMax, currentPage];
}

/// حالة النجاح في إضافة/إزالة المفضلة
class PropertyFavoriteUpdated extends PropertyState {
  final bool isFavorite;
  final String message;

  const PropertyFavoriteUpdated({
    required this.isFavorite,
    required this.message,
  });

  @override
  List<Object?> get props => [isFavorite, message];
}

/// حالة الخطأ
class PropertyError extends PropertyState {
  final String message;

  const PropertyError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// حالة مشتركة مع تفاصيل العقار
class PropertyWithDetails extends PropertyState {
  final PropertyDetail property;
  final List<Unit> units;
  final List<PropertyReview> reviews;
  final bool isFavorite;
  final int selectedImageIndex;
  final String? selectedUnitId;
  final bool isFavoritePending;
  final bool? queuedFavoriteTarget;

  const PropertyWithDetails({
    required this.property,
    required this.units,
    required this.reviews,
    required this.isFavorite,
    this.selectedImageIndex = 0,
    this.selectedUnitId,
    this.isFavoritePending = false,
    this.queuedFavoriteTarget,
  });

  PropertyWithDetails copyWith({
    PropertyDetail? property,
    List<Unit>? units,
    List<PropertyReview>? reviews,
    bool? isFavorite,
    int? selectedImageIndex,
    String? selectedUnitId,
    bool? isFavoritePending,
    bool? queuedFavoriteTarget,
  }) {
    return PropertyWithDetails(
      property: property ?? this.property,
      units: units ?? this.units,
      reviews: reviews ?? this.reviews,
      isFavorite: isFavorite ?? this.isFavorite,
      selectedImageIndex: selectedImageIndex ?? this.selectedImageIndex,
      selectedUnitId: selectedUnitId ?? this.selectedUnitId,
      isFavoritePending: isFavoritePending ?? this.isFavoritePending,
      queuedFavoriteTarget: queuedFavoriteTarget ?? this.queuedFavoriteTarget,
    );
  }

  @override
  List<Object?> get props => [
        property,
        units,
        reviews,
        isFavorite,
        selectedImageIndex,
        selectedUnitId,
        isFavoritePending,
        queuedFavoriteTarget,
      ];
}
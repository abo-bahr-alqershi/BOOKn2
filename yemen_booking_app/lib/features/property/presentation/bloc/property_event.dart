import 'package:equatable/equatable.dart';

abstract class PropertyEvent extends Equatable {
  const PropertyEvent();

  @override
  List<Object?> get props => [];
}

/// حدث جلب تفاصيل العقار
class GetPropertyDetailsEvent extends PropertyEvent {
  final String propertyId;
  final String? userId;

  const GetPropertyDetailsEvent({
    required this.propertyId,
    this.userId,
  });

  @override
  List<Object?> get props => [propertyId, userId];
}

/// حدث جلب وحدات العقار
class GetPropertyUnitsEvent extends PropertyEvent {
  final String propertyId;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final int guestsCount;

  const GetPropertyUnitsEvent({
    required this.propertyId,
    this.checkInDate,
    this.checkOutDate,
    required this.guestsCount,
  });

  @override
  List<Object?> get props => [propertyId, checkInDate, checkOutDate, guestsCount];
}

/// حدث جلب مراجعات العقار
class GetPropertyReviewsEvent extends PropertyEvent {
  final String propertyId;
  final int pageNumber;
  final int pageSize;
  final String? sortBy;
  final String? sortDirection;
  final bool withImagesOnly;
  final String? userId;

  const GetPropertyReviewsEvent({
    required this.propertyId,
    this.pageNumber = 1,
    this.pageSize = 20,
    this.sortBy,
    this.sortDirection,
    this.withImagesOnly = false,
    this.userId,
  });

  @override
  List<Object?> get props => [
        propertyId,
        pageNumber,
        pageSize,
        sortBy,
        sortDirection,
        withImagesOnly,
        userId,
      ];
}

/// حدث إضافة للمفضلة
class AddToFavoritesEvent extends PropertyEvent {
  final String propertyId;
  final String userId;
  final String? notes;
  final DateTime? desiredVisitDate;
  final double? expectedBudget;
  final String currency;

  const AddToFavoritesEvent({
    required this.propertyId,
    required this.userId,
    this.notes,
    this.desiredVisitDate,
    this.expectedBudget,
    this.currency = 'YER',
  });

  @override
  List<Object?> get props => [
        propertyId,
        userId,
        notes,
        desiredVisitDate,
        expectedBudget,
        currency,
      ];
}

/// حدث إزالة من المفضلة
class RemoveFromFavoritesEvent extends PropertyEvent {
  final String propertyId;
  final String userId;

  const RemoveFromFavoritesEvent({
    required this.propertyId,
    required this.userId,
  });

  @override
  List<Object?> get props => [propertyId, userId];
}

/// حدث تحديث عدد المشاهدات
class UpdateViewCountEvent extends PropertyEvent {
  final String propertyId;

  const UpdateViewCountEvent({required this.propertyId});

  @override
  List<Object?> get props => [propertyId];
}

/// حدث تحديث المفضلة
class ToggleFavoriteEvent extends PropertyEvent {
  final String propertyId;
  final String userId;
  final bool isFavorite;

  const ToggleFavoriteEvent({
    required this.propertyId,
    required this.userId,
    required this.isFavorite,
  });

  @override
  List<Object?> get props => [propertyId, userId, isFavorite];
}

/// حدث تحديد وحدة
class SelectUnitEvent extends PropertyEvent {
  final String unitId;

  const SelectUnitEvent({required this.unitId});

  @override
  List<Object?> get props => [unitId];
}

/// حدث تحديد صورة
class SelectImageEvent extends PropertyEvent {
  final int imageIndex;

  const SelectImageEvent({required this.imageIndex});

  @override
  List<Object?> get props => [imageIndex];
}
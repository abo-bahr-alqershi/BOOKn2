import 'package:equatable/equatable.dart';
import '../../../../core/models/paginated_result.dart';
import '../../domain/entities/amenity.dart';

abstract class AmenitiesState extends Equatable {
  const AmenitiesState();

  @override
  List<Object?> get props => [];
}

/// 🎬 الحالة الابتدائية
class AmenitiesInitial extends AmenitiesState {}

/// ⏳ حالة التحميل
class AmenitiesLoading extends AmenitiesState {
  final String? message;

  const AmenitiesLoading({this.message});

  @override
  List<Object?> get props => [message];
}

/// ✅ حالة النجاح
class AmenitiesLoaded extends AmenitiesState {
  final PaginatedResult<Amenity> amenities;
  final Amenity? selectedAmenity;
  final String? searchTerm;
  final bool? isAssigned;
  final bool? isFree;
  final String? propertyTypeId;
  final List<Amenity> popularAmenities;
  final AmenityStats? stats;

  const AmenitiesLoaded({
    required this.amenities,
    this.selectedAmenity,
    this.searchTerm,
    this.isAssigned,
    this.isFree,
    this.propertyTypeId,
    this.popularAmenities = const [],
    this.stats,
  });

  AmenitiesLoaded copyWith({
    PaginatedResult<Amenity>? amenities,
    Amenity? selectedAmenity,
    bool clearSelectedAmenity = false,
    String? searchTerm,
    bool? isAssigned,
    bool? isFree,
    String? propertyTypeId,
    List<Amenity>? popularAmenities,
    AmenityStats? stats,
  }) {
    return AmenitiesLoaded(
      amenities: amenities ?? this.amenities,
      selectedAmenity:
          clearSelectedAmenity ? null : selectedAmenity ?? this.selectedAmenity,
      searchTerm: searchTerm ?? this.searchTerm,
      isAssigned: isAssigned ?? this.isAssigned,
      isFree: isFree ?? this.isFree,
      propertyTypeId: propertyTypeId ?? this.propertyTypeId,
      popularAmenities: popularAmenities ?? this.popularAmenities,
      stats: stats ?? this.stats,
    );
  }

  @override
  List<Object?> get props => [
        amenities,
        selectedAmenity,
        searchTerm,
        isAssigned,
        isFree,
        propertyTypeId,
        popularAmenities,
        stats,
      ];
}

/// ❌ حالة الخطأ
class AmenitiesError extends AmenitiesState {
  final String message;

  const AmenitiesError({required this.message});

  @override
  List<Object> get props => [message];
}

/// 🔄 حالة العملية الجارية
class AmenityOperationInProgress extends AmenitiesState {
  final String operation;
  final String? amenityId;

  const AmenityOperationInProgress({
    required this.operation,
    this.amenityId,
  });

  @override
  List<Object?> get props => [operation, amenityId];
}

/// ✅ حالة نجاح العملية
class AmenityOperationSuccess extends AmenitiesState {
  final String message;
  final String? amenityId;

  const AmenityOperationSuccess({
    required this.message,
    this.amenityId,
  });

  @override
  List<Object?> get props => [message, amenityId];
}

/// ❌ حالة فشل العملية
class AmenityOperationFailure extends AmenitiesState {
  final String message;
  final String? amenityId;

  const AmenityOperationFailure({
    required this.message,
    this.amenityId,
  });

  @override
  List<Object?> get props => [message, amenityId];
}
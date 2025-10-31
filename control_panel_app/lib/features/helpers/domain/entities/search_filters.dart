// Shared filter DTOs used by helpers facades. No UI here.

class UserSearchFilters {
  final int? pageNumber;
  final int? pageSize;
  final String? searchTerm;
  final String? sortBy;
  final bool? isAscending;
  final String? roleId;
  final bool? isActive;
  final DateTime? createdAfter;
  final DateTime? createdBefore;
  final DateTime? lastLoginAfter;
  final String? loyaltyTier;
  final double? minTotalSpent;

  const UserSearchFilters({
    this.pageNumber,
    this.pageSize,
    this.searchTerm,
    this.sortBy,
    this.isAscending,
    this.roleId,
    this.isActive,
    this.createdAfter,
    this.createdBefore,
    this.lastLoginAfter,
    this.loyaltyTier,
    this.minTotalSpent,
  });
}

class PropertySearchFilters {
  final int? pageNumber;
  final int? pageSize;
  final String? searchTerm;
  final String? propertyTypeId;
  final String? sortBy;
  final bool? isAscending;
  final double? minPrice;
  final double? maxPrice;
  final List<String>? amenityIds;
  final List<int>? starRatings;
  final double? minAverageRating;
  final bool? isApproved;
  final bool? hasActiveBookings;

  const PropertySearchFilters({
    this.pageNumber,
    this.pageSize,
    this.searchTerm,
    this.propertyTypeId,
    this.sortBy,
    this.isAscending,
    this.minPrice,
    this.maxPrice,
    this.amenityIds,
    this.starRatings,
    this.minAverageRating,
    this.isApproved,
    this.hasActiveBookings,
  });
}

class UnitSearchFilters {
  final int? pageNumber;
  final int? pageSize;
  final String? propertyId;
  final String? unitTypeId;
  final bool? isAvailable;
  final double? minPrice;
  final double? maxPrice;
  final String? searchQuery;

  const UnitSearchFilters({
    this.pageNumber,
    this.pageSize,
    this.propertyId,
    this.unitTypeId,
    this.isAvailable,
    this.minPrice,
    this.maxPrice,
    this.searchQuery,
  });
}


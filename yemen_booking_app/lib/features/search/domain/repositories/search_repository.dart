import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../entities/search_result.dart';

abstract class SearchRepository {
  Future<Either<Failure, PaginatedResult<SearchResult>>> searchProperties({
    String? searchTerm,
    String? city,
    String? propertyTypeId,
    double? minPrice,
    double? maxPrice,
    int? minStarRating,
    List<String>? requiredAmenities,
    String? unitTypeId,
    List<String>? serviceIds,
    Map<String, dynamic>? dynamicFieldFilters,
    DateTime? checkIn,
    DateTime? checkOut,
    int? guestsCount,
    double? latitude,
    double? longitude,
    double? radiusKm,
    String? preferredCurrency,
    String? sortBy,
    int pageNumber = 1,
    int pageSize = 20,
  });

  Future<Either<Failure, SearchFilters>> getSearchFilters();

  Future<Either<Failure, List<String>>> getSearchSuggestions({
    required String query,
    int limit = 10,
  });

  Future<Either<Failure, List<SearchResult>>> getRecommendedProperties({
    String? userId,
    int limit = 10,
  });

  Future<Either<Failure, List<String>>> getPopularDestinations({
    int limit = 10,
  });
}
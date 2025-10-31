import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../entities/search_result.dart';

abstract class HelpersRepository {
  Future<Either<Failure, PaginatedResult<SearchResult>>> searchUsers({
    String? searchTerm,
    String? role,
    bool? isActive,
    int pageNumber = 1,
    int pageSize = 20,
  });

  Future<Either<Failure, PaginatedResult<SearchResult>>> searchProperties({
    String? searchTerm,
    String? typeId,
    String? city,
    bool? isApproved,
    int pageNumber = 1,
    int pageSize = 20,
  });

  Future<Either<Failure, PaginatedResult<SearchResult>>> searchUnits({
    String? searchTerm,
    String? propertyId,
    String? unitTypeId,
    bool? isAvailable,
    int pageNumber = 1,
    int pageSize = 20,
  });

  Future<Either<Failure, PaginatedResult<SearchResult>>> searchCities({
    String? searchTerm,
    String? country,
    int pageNumber = 1,
    int pageSize = 20,
  });

  Future<Either<Failure, PaginatedResult<SearchResult>>> searchBookings({
    String? searchTerm,
    String? userId,
    String? unitId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int pageNumber = 1,
    int pageSize = 20,
  });
}
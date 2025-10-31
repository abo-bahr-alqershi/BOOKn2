import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../entities/search_result.dart';
import '../repositories/helpers_repository.dart';

class SearchBookingsUseCase {
  final HelpersRepository repository;

  SearchBookingsUseCase(this.repository);

  Future<Either<Failure, PaginatedResult<SearchResult>>> call({
    String? searchTerm,
    String? userId,
    String? unitId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    return await repository.searchBookings(
      searchTerm: searchTerm,
      userId: userId,
      unitId: unitId,
      status: status,
      startDate: startDate,
      endDate: endDate,
      pageNumber: pageNumber,
      pageSize: pageSize,
    );
  }
}
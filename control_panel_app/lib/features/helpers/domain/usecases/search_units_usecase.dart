import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../entities/search_result.dart';
import '../repositories/helpers_repository.dart';

class SearchUnitsUseCase {
  final HelpersRepository repository;

  SearchUnitsUseCase(this.repository);

  Future<Either<Failure, PaginatedResult<SearchResult>>> call({
    String? searchTerm,
    String? propertyId,
    String? unitTypeId,
    bool? isAvailable,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    return await repository.searchUnits(
      searchTerm: searchTerm,
      propertyId: propertyId,
      unitTypeId: unitTypeId,
      isAvailable: isAvailable,
      pageNumber: pageNumber,
      pageSize: pageSize,
    );
  }
}
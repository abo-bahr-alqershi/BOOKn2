import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../entities/search_result.dart';
import '../repositories/helpers_repository.dart';

class SearchCitiesUseCase {
  final HelpersRepository repository;

  SearchCitiesUseCase(this.repository);

  Future<Either<Failure, PaginatedResult<SearchResult>>> call({
    String? searchTerm,
    String? country,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    return await repository.searchCities(
      searchTerm: searchTerm,
      country: country,
      pageNumber: pageNumber,
      pageSize: pageSize,
    );
  }
}
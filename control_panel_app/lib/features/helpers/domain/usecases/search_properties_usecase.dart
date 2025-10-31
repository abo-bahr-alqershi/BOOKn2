import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../entities/search_result.dart';
import '../repositories/helpers_repository.dart';

class SearchPropertiesUseCase {
  final HelpersRepository repository;

  SearchPropertiesUseCase(this.repository);

  Future<Either<Failure, PaginatedResult<SearchResult>>> call({
    String? searchTerm,
    String? typeId,
    String? city,
    bool? isApproved,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    return await repository.searchProperties(
      searchTerm: searchTerm,
      typeId: typeId,
      city: city,
      isApproved: isApproved,
      pageNumber: pageNumber,
      pageSize: pageSize,
    );
  }
}
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../entities/search_result.dart';
import '../repositories/helpers_repository.dart';

class SearchUsersUseCase {
  final HelpersRepository repository;

  SearchUsersUseCase(this.repository);

  Future<Either<Failure, PaginatedResult<SearchResult>>> call({
    String? searchTerm,
    String? role,
    bool? isActive,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    return await repository.searchUsers(
      searchTerm: searchTerm,
      role: role,
      isActive: isActive,
      pageNumber: pageNumber,
      pageSize: pageSize,
    );
  }
}
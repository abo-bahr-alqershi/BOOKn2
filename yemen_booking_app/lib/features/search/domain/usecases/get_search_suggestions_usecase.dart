import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:yemen_booking_app/core/usecases/usecase.dart';
import '../../../../core/error/failures.dart';
import '../repositories/search_repository.dart';

class GetSearchSuggestionsUseCase implements UseCase<List<String>, SearchSuggestionsParams> {
  final SearchRepository repository;

  GetSearchSuggestionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<String>>> call(SearchSuggestionsParams params) async {
    return await repository.getSearchSuggestions(
      query: params.query,
      limit: params.limit,
    );
  }
}

class SearchSuggestionsParams extends Equatable {
  final String query;
  final int limit;

  const SearchSuggestionsParams({
    required this.query,
    this.limit = 10,
  });

  @override
  List<Object> get props => [query, limit];
}
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/city.dart';
import '../repositories/cities_repository.dart';

class GetCitiesUseCase implements UseCase<List<City>, GetCitiesParams> {
  final CitiesRepository repository;

  GetCitiesUseCase(this.repository);

  @override
  Future<Either<Failure, List<City>>> call(GetCitiesParams params) async {
    return await repository.getCities(
      page: params.page,
      limit: params.limit,
      search: params.search,
      country: params.country,
      isActive: params.isActive,
    );
  }
}

class GetCitiesParams extends Equatable {
  final int? page;
  final int? limit;
  final String? search;
  final String? country;
  final bool? isActive;

  const GetCitiesParams({
    this.page,
    this.limit,
    this.search,
    this.country,
    this.isActive,
  });

  @override
  List<Object?> get props => [page, limit, search, country, isActive];
}
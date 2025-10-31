import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/cities_repository.dart';

class GetCitiesStatisticsUseCase implements UseCase<Map<String, dynamic>, GetCitiesStatsParams> {
  final CitiesRepository repository;

  GetCitiesStatisticsUseCase(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(GetCitiesStatsParams params) async {
    return await repository.getCitiesStatistics(startDate: params.startDate, endDate: params.endDate);
  }
}

class GetCitiesStatsParams {
  final DateTime? startDate;
  final DateTime? endDate;
  GetCitiesStatsParams({this.startDate, this.endDate});
}
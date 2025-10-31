import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_lifetime_stats.dart';
import '../repositories/users_repository.dart';

class GetUserLifetimeStatsUseCase implements UseCase<UserLifetimeStats, GetUserLifetimeStatsParams> {
  final UsersRepository repository;

  GetUserLifetimeStatsUseCase(this.repository);

  @override
  Future<Either<Failure, UserLifetimeStats>> call(GetUserLifetimeStatsParams params) {
    return repository.getUserLifetimeStats(params.userId);
  }
}

class GetUserLifetimeStatsParams extends Equatable {
  final String userId;

  const GetUserLifetimeStatsParams({required this.userId});

  @override
  List<Object> get props => [userId];
}
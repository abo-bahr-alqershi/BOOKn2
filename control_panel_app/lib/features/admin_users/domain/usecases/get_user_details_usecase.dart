import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_details.dart';
import '../repositories/users_repository.dart';

class GetUserDetailsUseCase implements UseCase<UserDetails, GetUserDetailsParams> {
  final UsersRepository repository;

  GetUserDetailsUseCase(this.repository);

  @override
  Future<Either<Failure, UserDetails>> call(GetUserDetailsParams params) {
    return repository.getUserDetails(params.userId);
  }
}

class GetUserDetailsParams extends Equatable {
  final String userId;

  const GetUserDetailsParams({required this.userId});

  @override
  List<Object> get props => [userId];
}
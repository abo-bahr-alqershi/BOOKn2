import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/users_repository.dart';

class UpdateUserUseCase implements UseCase<bool, UpdateUserParams> {
  final UsersRepository repository;

  UpdateUserUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(UpdateUserParams params) {
    return repository.updateUser(
      userId: params.userId,
      name: params.name,
      email: params.email,
      phone: params.phone,
      profileImage: params.profileImage,
    );
  }
}

class UpdateUserParams extends Equatable {
  final String userId;
  final String? name;
  final String? email;
  final String? phone;
  final String? profileImage;

  const UpdateUserParams({
    required this.userId,
    this.name,
    this.email,
    this.phone,
    this.profileImage,
  });

  @override
  List<Object?> get props => [userId, name, email, phone, profileImage];
}
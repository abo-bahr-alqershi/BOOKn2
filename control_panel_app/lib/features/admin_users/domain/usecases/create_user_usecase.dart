import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/users_repository.dart';

class CreateUserUseCase implements UseCase<String, CreateUserParams> {
  final UsersRepository repository;

  CreateUserUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(CreateUserParams params) {
    return repository.createUser(
      name: params.name,
      email: params.email,
      password: params.password,
      phone: params.phone,
      profileImage: params.profileImage,
    );
  }
}

class CreateUserParams extends Equatable {
  final String name;
  final String email;
  final String password;
  final String phone;
  final String? profileImage;

  const CreateUserParams({
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    this.profileImage,
  });

  @override
  List<Object?> get props => [name, email, password, phone, profileImage];
}
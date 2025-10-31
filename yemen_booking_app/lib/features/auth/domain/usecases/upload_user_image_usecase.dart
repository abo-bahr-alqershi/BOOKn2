import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class UploadUserImageUseCase implements UseCase<User, UploadUserImageParams> {
  final AuthRepository repository;

  UploadUserImageUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(UploadUserImageParams params) async {
    return await repository.uploadProfileImage(
      imagePath: params.imagePath,
    );
  }
}

class UploadUserImageParams extends Equatable {
  final String imagePath;

  const UploadUserImageParams({
    required this.imagePath,
  });

  @override
  List<Object?> get props => [imagePath];
}
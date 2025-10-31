import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/favorites_repository.dart';

class CheckFavoriteStatusParams {
  final String propertyId;
  final String userId;

  CheckFavoriteStatusParams({
    required this.propertyId,
    required this.userId,
  });
}

class CheckFavoriteStatusUseCase implements UseCase<bool, CheckFavoriteStatusParams> {
  final FavoritesRepository repository;

  CheckFavoriteStatusUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(CheckFavoriteStatusParams params) async {
    return await repository.checkFavoriteStatus(
      propertyId: params.propertyId,
      userId: params.userId,
    );
  }
}
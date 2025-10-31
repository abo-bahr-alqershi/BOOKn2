import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/favorites_repository.dart';

class RemoveFromFavoritesParams {
  final String propertyId;
  final String userId;

  RemoveFromFavoritesParams({
    required this.propertyId,
    required this.userId,
  });
}

class RemoveFromFavoritesUseCase implements UseCase<void, RemoveFromFavoritesParams> {
  final FavoritesRepository repository;

  RemoveFromFavoritesUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(RemoveFromFavoritesParams params) async {
    return await repository.removeFromFavorites(
      propertyId: params.propertyId,
      userId: params.userId,
    );
  }
}
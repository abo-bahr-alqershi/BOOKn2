import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/favorites_repository.dart';

class AddToFavoritesParams {
  final String propertyId;
  final String userId;

  AddToFavoritesParams({
    required this.propertyId,
    required this.userId,
  });
}

class AddToFavoritesUseCase implements UseCase<bool, AddToFavoritesParams> {
  final FavoritesRepository repository;

  AddToFavoritesUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(AddToFavoritesParams params) async {
    return await repository.addToFavorites(
      propertyId: params.propertyId,
      userId: params.userId,
    );
  }
}
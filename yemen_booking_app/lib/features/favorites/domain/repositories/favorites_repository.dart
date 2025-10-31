import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/favorite.dart';

abstract class FavoritesRepository {
  Future<Either<Failure, List<Favorite>>> getFavorites();
  
  Future<Either<Failure, bool>> addToFavorites({
    required String propertyId,
    required String userId,
  });
  
  Future<Either<Failure, void>> removeFromFavorites({
    required String propertyId,
    required String userId,
  });
  
  Future<Either<Failure, bool>> checkFavoriteStatus({
    required String propertyId,
    required String userId,
  });
}
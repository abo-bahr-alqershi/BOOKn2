import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/property_repository.dart';

class RemoveFromFavoritesUseCase implements UseCase<bool, RemoveFromFavoritesParams> {
  final PropertyRepository repository;

  RemoveFromFavoritesUseCase({required this.repository});

  @override
  Future<Either<Failure, bool>> call(RemoveFromFavoritesParams params) async {
    return await repository.removeFromFavorites(
      propertyId: params.propertyId,
      userId: params.userId,
    );
  }
}

class RemoveFromFavoritesParams extends Equatable {
  final String propertyId;
  final String userId;

  const RemoveFromFavoritesParams({
    required this.propertyId,
    required this.userId,
  });

  @override
  List<Object?> get props => [propertyId, userId];
}

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/property_repository.dart';

class AddToFavoritesUseCase implements UseCase<bool, AddToFavoritesParams> {
  final PropertyRepository repository;

  AddToFavoritesUseCase({required this.repository});

  @override
  Future<Either<Failure, bool>> call(AddToFavoritesParams params) async {
    return await repository.addToFavorites(
      propertyId: params.propertyId,
      userId: params.userId,
      notes: params.notes,
      desiredVisitDate: params.desiredVisitDate,
      expectedBudget: params.expectedBudget,
      currency: params.currency,
    );
  }
}

class AddToFavoritesParams extends Equatable {
  final String propertyId;
  final String userId;
  final String? notes;
  final DateTime? desiredVisitDate;
  final double? expectedBudget;
  final String currency;

  const AddToFavoritesParams({
    required this.propertyId,
    required this.userId,
    this.notes,
    this.desiredVisitDate,
    this.expectedBudget,
    this.currency = 'YER',
  });

  @override
  List<Object?> get props => [
        propertyId,
        userId,
        notes,
        desiredVisitDate,
        expectedBudget,
        currency,
      ];
}
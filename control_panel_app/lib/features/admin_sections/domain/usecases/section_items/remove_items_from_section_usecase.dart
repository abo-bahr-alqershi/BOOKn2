import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/models/section_item_dto.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../domain/repositories/sections_repository.dart';

class RemoveItemsFromSectionUseCase implements UseCase<void, RemoveItemsFromSectionParams> {
  final SectionsRepository repository;
  RemoveItemsFromSectionUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(RemoveItemsFromSectionParams params) {
    return repository.removeItems(params.sectionId, params.payload);
  }
}

class RemoveItemsFromSectionParams extends Equatable {
  final String sectionId;
  final RemoveItemsFromSectionDto payload;

  const RemoveItemsFromSectionParams({required this.sectionId, required this.payload});

  @override
  List<Object?> get props => [sectionId, payload];
}


import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/models/section_item_dto.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../domain/repositories/sections_repository.dart';

class AddItemsToSectionUseCase implements UseCase<void, AddItemsToSectionParams> {
  final SectionsRepository repository;
  AddItemsToSectionUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AddItemsToSectionParams params) {
    return repository.addItems(params.sectionId, params.payload);
  }
}

class AddItemsToSectionParams extends Equatable {
  final String sectionId;
  final AddItemsToSectionDto payload;

  const AddItemsToSectionParams({required this.sectionId, required this.payload});

  @override
  List<Object?> get props => [sectionId, payload];
}


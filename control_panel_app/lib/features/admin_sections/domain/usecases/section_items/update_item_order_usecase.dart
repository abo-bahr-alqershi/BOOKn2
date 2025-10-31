import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/models/section_item_dto.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../domain/repositories/sections_repository.dart';

class UpdateItemOrderUseCase implements UseCase<void, UpdateItemOrderParams> {
  final SectionsRepository repository;
  UpdateItemOrderUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateItemOrderParams params) {
    return repository.reorderItems(params.sectionId, params.payload);
  }
}

class UpdateItemOrderParams extends Equatable {
  final String sectionId;
  final UpdateItemOrderDto payload;

  const UpdateItemOrderParams({required this.sectionId, required this.payload});

  @override
  List<Object?> get props => [sectionId, payload];
}


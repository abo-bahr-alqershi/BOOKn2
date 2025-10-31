import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../repositories/unit_type_fields_repository.dart';

class DeleteFieldUseCase implements UseCase<bool, String> {
  final UnitTypeFieldsRepository repository;

  DeleteFieldUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(String fieldId) async {
    return await repository.deleteField(fieldId);
  }
}
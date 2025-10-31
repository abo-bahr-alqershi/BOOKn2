import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/amenities_repository.dart';

class DeleteAmenityUseCase implements UseCase<bool, String> {
  final AmenitiesRepository repository;

  DeleteAmenityUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(String amenityId) async {
    return await repository.deleteAmenity(amenityId);
  }
}
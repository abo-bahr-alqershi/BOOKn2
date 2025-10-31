import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/service.dart';
import '../repositories/services_repository.dart';

/// 🏢 Use Case لجلب خدمات عقار معين
class GetServicesByPropertyUseCase implements UseCase<List<Service>, String> {
  final ServicesRepository repository;

  GetServicesByPropertyUseCase(this.repository);

  @override
  Future<Either<Failure, List<Service>>> call(String propertyId) async {
    return await repository.getServicesByProperty(propertyId);
  }
}
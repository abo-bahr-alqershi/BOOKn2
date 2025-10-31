import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/money.dart';
import '../entities/pricing_model.dart';
import '../repositories/services_repository.dart';

/// ➕ Use Case لإنشاء خدمة جديدة
class CreateServiceUseCase implements UseCase<String, CreateServiceParams> {
  final ServicesRepository repository;

  CreateServiceUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(CreateServiceParams params) async {
    return await repository.createService(
      propertyId: params.propertyId,
      name: params.name,
      price: params.price,
      pricingModel: params.pricingModel,
      icon: params.icon,
      description: params.description,
    );
  }
}

class CreateServiceParams extends Equatable {
  final String propertyId;
  final String name;
  final Money price;
  final PricingModel pricingModel;
  final String icon;
  final String? description;

  const CreateServiceParams({
    required this.propertyId,
    required this.name,
    required this.price,
    required this.pricingModel,
    required this.icon,
    this.description,
  });

  @override
  List<Object?> get props => [propertyId, name, price, pricingModel, icon, description];
}
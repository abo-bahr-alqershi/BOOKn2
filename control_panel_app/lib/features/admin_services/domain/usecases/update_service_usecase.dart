import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/money.dart';
import '../entities/pricing_model.dart';
import '../repositories/services_repository.dart';

/// ✏️ Use Case لتحديث خدمة
class UpdateServiceUseCase implements UseCase<bool, UpdateServiceParams> {
  final ServicesRepository repository;

  UpdateServiceUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(UpdateServiceParams params) async {
    return await repository.updateService(
      serviceId: params.serviceId,
      name: params.name,
      price: params.price,
      pricingModel: params.pricingModel,
      icon: params.icon,
      description: params.description,
    );
  }
}

class UpdateServiceParams extends Equatable {
  final String serviceId;
  final String? name;
  final Money? price;
  final PricingModel? pricingModel;
  final String? icon;
  final String? description;

  const UpdateServiceParams({
    required this.serviceId,
    this.name,
    this.price,
    this.pricingModel,
    this.icon,
    this.description,
  });

  @override
  List<Object?> get props => [serviceId, name, price, pricingModel, icon, description];
}
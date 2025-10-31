import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class UpdateProfileUseCase implements UseCase<void, UpdateProfileParams> {
  final AuthRepository repository;

  UpdateProfileUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateProfileParams params) async {
    return await repository.updateProfile(
      name: params.name,
      email: params.email,
      phone: params.phone,
      propertyId: params.propertyId,
      propertyName: params.propertyName,
      propertyAddress: params.propertyAddress,
      propertyCity: params.propertyCity,
      propertyShortDescription: params.propertyShortDescription,
      propertyDescription: params.propertyDescription,
      propertyCurrency: params.propertyCurrency,
      propertyStarRating: params.propertyStarRating,
      propertyLatitude: params.propertyLatitude,
      propertyLongitude: params.propertyLongitude,
    );
  }
}

class UpdateProfileParams extends Equatable {
  final String name;
  final String? email;
  final String? phone;
  // Owner property fields (optional)
  final String? propertyId;
  final String? propertyName;
  final String? propertyAddress;
  final String? propertyCity;
  final String? propertyShortDescription;
  final String? propertyDescription;
  final String? propertyCurrency;
  final int? propertyStarRating;
  final double? propertyLatitude;
  final double? propertyLongitude;

  const UpdateProfileParams({
    required this.name,
    this.email,
    this.phone,
    this.propertyId,
    this.propertyName,
    this.propertyAddress,
    this.propertyCity,
    this.propertyShortDescription,
    this.propertyDescription,
    this.propertyCurrency,
    this.propertyStarRating,
    this.propertyLatitude,
    this.propertyLongitude,
  });

  @override
  List<Object?> get props => [
        name,
        email,
        phone,
        propertyId,
        propertyName,
        propertyAddress,
        propertyCity,
        propertyShortDescription,
        propertyDescription,
        propertyCurrency,
        propertyStarRating,
        propertyLatitude,
        propertyLongitude,
      ];
}
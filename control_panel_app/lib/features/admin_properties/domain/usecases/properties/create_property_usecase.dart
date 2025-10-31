// lib/features/admin_properties/domain/usecases/properties/create_property_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../../repositories/properties_repository.dart';

class CreatePropertyParams {
  final String name;
  final String address;
  final String propertyTypeId;
  final String ownerId;
  final String description;
  final double latitude;
  final double longitude;
  final String city;
  final int starRating;
  final List<String>? images;
  final List<String>? amenityIds; // أضف هذا السطر
  final String? tempKey;
  final String shortDescription;
  final String currency;
  final bool isFeatured;

  CreatePropertyParams({
    required this.name,
    required this.address,
    required this.propertyTypeId,
    required this.ownerId,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.starRating,
    this.images,
    this.amenityIds, // أضف هذا السطر
    this.tempKey,
    required this.shortDescription,
    required this.currency,
    required this.isFeatured,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'propertyTypeId': propertyTypeId,
      'ownerId': ownerId,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'starRating': starRating,
      'shortDescription': shortDescription,
      'currency': currency,
      'isFeatured': isFeatured,
      if (images != null && images!.isNotEmpty) 'images': images,
      if (amenityIds != null && amenityIds!.isNotEmpty)
        'amenityIds': amenityIds,
      if (tempKey != null && tempKey!.isNotEmpty) 'tempKey': tempKey,
    };
  }
}

class CreatePropertyUseCase implements UseCase<String, CreatePropertyParams> {
  final PropertiesRepository repository;

  CreatePropertyUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(CreatePropertyParams params) async {
    // تحقق من صحة البيانات قبل الإرسال
    if (params.starRating < 1 || params.starRating > 5) {
      return const Left(
          ValidationFailure('تقييم النجوم يجب أن يكون بين 1 و 5'));
    }

    if (params.latitude < -90 || params.latitude > 90) {
      return const Left(ValidationFailure('خط العرض غير صحيح'));
    }

    if (params.longitude < -180 || params.longitude > 180) {
      return const Left(ValidationFailure('خط الطول غير صحيح'));
    }

    return await repository.createProperty(params.toJson());
  }
}

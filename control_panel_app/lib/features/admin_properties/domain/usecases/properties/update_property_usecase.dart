// lib/features/admin_properties/domain/usecases/properties/update_property_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import '../../repositories/properties_repository.dart';

class UpdatePropertyParams {
  final String propertyId;
  final String? name;
  final String? address;
  final String? description;
  final double? latitude;
  final double? longitude;
  final String? city;
  final int? starRating;
  final List<String>? images;
  final String? shortDescription;
  final String? currency;
  final bool? isFeatured;
  final String? ownerId;
  final List<String>? amenityIds;

  UpdatePropertyParams({
    required this.propertyId,
    this.name,
    this.address,
    this.description,
    this.latitude,
    this.longitude,
    this.city,
    this.starRating,
    this.images,
    this.shortDescription,
    this.currency,
    this.isFeatured,
    this.ownerId,
    this.amenityIds,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (address != null) data['address'] = address;
    if (description != null) data['description'] = description;
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    if (city != null) data['city'] = city;
    if (starRating != null) data['starRating'] = starRating;
    if (images != null) data['images'] = images;
    if (shortDescription != null) data['shortDescription'] = shortDescription;
    if (currency != null) data['currency'] = currency;
    if (isFeatured != null) data['isFeatured'] = isFeatured;
    if (ownerId != null) data['ownerId'] = ownerId;
    if (amenityIds != null) data['amenityIds'] = amenityIds;
    return data;
  }
}

class UpdatePropertyUseCase implements UseCase<bool, UpdatePropertyParams> {
  final PropertiesRepository repository;

  UpdatePropertyUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(UpdatePropertyParams params) async {
    return await repository.updateProperty(params.propertyId, params.toJson());
  }
}

// lib/features/admin_reviews/data/models/review_model.dart
import 'package:bookn_cp_app/features/admin_reviews/domain/entities/review.dart';

import 'review_image_model.dart';

class ReviewModel extends Review {
  const ReviewModel({
    required super.id,
    required super.bookingId,
    required super.propertyName,
    super.unitName,
    required super.userName,
    required super.cleanliness,
    required super.service,
    required super.location,
    required super.value,
    required super.comment,
    required super.createdAt,
    required super.images,
    super.isApproved,
    super.isPending,
    super.responseText,
    super.responseDate,
    super.respondedBy,
    super.propertyCity,
    super.propertyAddress,
    super.userEmail,
    super.userPhone,
    super.bookingCheckIn,
    super.bookingCheckOut,
    super.guestsCount,
    super.bookingStatus,
    super.bookingSource,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      bookingId: json['bookingId'] as String,
      propertyName: json['propertyName'] as String,
      unitName: json['unitName'] as String?,
      userName: json['userName'] as String,
      cleanliness: (json['cleanliness'] as num).toDouble(),
      service: (json['service'] as num).toDouble(),
      location: (json['location'] as num).toDouble(),
      value: (json['value'] as num).toDouble(),
      comment: json['comment'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => ReviewImageModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isApproved: json['isApproved'] as bool? ?? false,
      isPending: json['isPending'] as bool? ?? true,
      responseText: json['responseText'] as String?,
      responseDate: json['responseDate'] != null
          ? DateTime.parse(json['responseDate'] as String)
          : null,
      respondedBy: json['respondedBy'] as String?,
      propertyCity: json['propertyCity'] as String?,
      propertyAddress: json['propertyAddress'] as String?,
      userEmail: json['userEmail'] as String?,
      userPhone: json['userPhone'] as String?,
      bookingCheckIn: json['bookingCheckIn'] != null
          ? DateTime.parse(json['bookingCheckIn'] as String)
          : null,
      bookingCheckOut: json['bookingCheckOut'] != null
          ? DateTime.parse(json['bookingCheckOut'] as String)
          : null,
      guestsCount: json['guestsCount'] as int?,
      bookingStatus: json['bookingStatus'] as String?,
      bookingSource: json['bookingSource'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'propertyName': propertyName,
      'unitName': unitName,
      'userName': userName,
      'cleanliness': cleanliness,
      'service': service,
      'location': location,
      'value': value,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'images': images.map((e) => (e as ReviewImageModel).toJson()).toList(),
      'isApproved': isApproved,
      'isPending': isPending,
      'responseText': responseText,
      'responseDate': responseDate?.toIso8601String(),
      'respondedBy': respondedBy,
      'propertyCity': propertyCity,
      'propertyAddress': propertyAddress,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'bookingCheckIn': bookingCheckIn?.toIso8601String(),
      'bookingCheckOut': bookingCheckOut?.toIso8601String(),
      'guestsCount': guestsCount,
      'bookingStatus': bookingStatus,
      'bookingSource': bookingSource,
    };
  }
}

import '../../domain/repositories/property_repository.dart';

class ReviewModel extends PropertyReview {
  const ReviewModel({
    required super.id,
    required super.bookingId,
    required super.propertyName,
    required super.userName,
    required super.cleanliness,
    required super.service,
    required super.location,
    required super.value,
    required super.averageRating,
    required super.comment,
    super.responseText,
    super.responseDate,
    required super.createdAt,
    required super.images,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] ?? '',
      bookingId: json['bookingId'] ?? '',
      propertyName: json['propertyName'] ?? '',
      userName: json['userName'] ?? '',
      cleanliness: json['cleanliness'] ?? 0,
      service: json['service'] ?? 0,
      location: json['location'] ?? 0,
      value: json['value'] ?? 0,
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      comment: json['comment'] ?? '',
      responseText: json['responseText'],
      responseDate: json['responseDate'] != null 
          ? DateTime.parse(json['responseDate']) 
          : null,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      images: (json['images'] as List?)
              ?.map((e) => ReviewImageModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'propertyName': propertyName,
      'userName': userName,
      'cleanliness': cleanliness,
      'service': service,
      'location': location,
      'value': value,
      'averageRating': averageRating,
      'comment': comment,
      'responseText': responseText,
      'responseDate': responseDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'images': images.map((e) => (e as ReviewImageModel).toJson()).toList(),
    };
  }
}

class ReviewImageModel extends ReviewImage {
  const ReviewImageModel({
    required super.id,
    required super.reviewId,
    required super.name,
    required super.url,
    required super.sizeBytes,
    required super.type,
    required super.category,
    required super.caption,
    required super.altText,
    required super.uploadedAt,
  });

  factory ReviewImageModel.fromJson(Map<String, dynamic> json) {
    return ReviewImageModel(
      id: json['id'] ?? '',
      reviewId: json['reviewId'] ?? '',
      name: json['name'] ?? '',
      url: json['url'] ?? '',
      sizeBytes: json['sizeBytes'] ?? 0,
      type: json['type'] ?? '',
      category: json['category'] ?? '',
      caption: json['caption'] ?? '',
      altText: json['altText'] ?? '',
      uploadedAt: DateTime.parse(json['uploadedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reviewId': reviewId,
      'name': name,
      'url': url,
      'sizeBytes': sizeBytes,
      'type': type,
      'category': category,
      'caption': caption,
      'altText': altText,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }
}
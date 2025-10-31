import '../../domain/entities/review_image.dart';

class ReviewImageModel extends ReviewImage {
  const ReviewImageModel({
    required super.id,
    required super.url,
    required super.thumbnailUrl,
    super.caption,
    required super.displayOrder,
    super.sizeBytes,
    super.type,
    super.uploadedAt,
  });

  factory ReviewImageModel.fromJson(Map<String, dynamic> json) {
    return ReviewImageModel(
      id: json['id'] ?? '',
      url: json['url'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      caption: json['caption'],
      displayOrder: json['displayOrder'] ?? 0,
      sizeBytes: json['sizeBytes'],
      type: json['type'],
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.parse(json['uploadedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'caption': caption,
      'displayOrder': displayOrder,
      'sizeBytes': sizeBytes,
      'type': type,
      'uploadedAt': uploadedAt?.toIso8601String(),
    };
  }

  ReviewImage toEntity() {
    return ReviewImage(
      id: id,
      url: url,
      thumbnailUrl: thumbnailUrl,
      caption: caption,
      displayOrder: displayOrder,
      sizeBytes: sizeBytes,
      type: type,
      uploadedAt: uploadedAt,
    );
  }
}
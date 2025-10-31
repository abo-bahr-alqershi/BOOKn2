import 'package:equatable/equatable.dart';

/// <summary>
/// كيان صورة المراجعة
/// Review image entity
/// </summary>
class ReviewImage extends Equatable {
  /// <summary>
  /// معرف الصورة
  /// Image ID
  /// </summary>
  final String id;

  /// <summary>
  /// رابط الصورة
  /// Image URL
  /// </summary>
  final String url;

  /// <summary>
  /// رابط الصورة المصغرة
  /// Thumbnail URL
  /// </summary>
  final String thumbnailUrl;

  /// <summary>
  /// التسمية التوضيحية
  /// Caption
  /// </summary>
  final String? caption;

  /// <summary>
  /// ترتيب العرض
  /// Display order
  /// </summary>
  final int displayOrder;

  /// <summary>
  /// حجم الصورة بالبايت
  /// Image size in bytes
  /// </summary>
  final int? sizeBytes;

  /// <summary>
  /// نوع الصورة
  /// Image type
  /// </summary>
  final String? type;

  /// <summary>
  /// تاريخ الرفع
  /// Upload date
  /// </summary>
  final DateTime? uploadedAt;

  const ReviewImage({
    required this.id,
    required this.url,
    required this.thumbnailUrl,
    this.caption,
    required this.displayOrder,
    this.sizeBytes,
    this.type,
    this.uploadedAt,
  });

  @override
  List<Object?> get props => [
        id,
        url,
        thumbnailUrl,
        caption,
        displayOrder,
        sizeBytes,
        type,
        uploadedAt,
      ];
}
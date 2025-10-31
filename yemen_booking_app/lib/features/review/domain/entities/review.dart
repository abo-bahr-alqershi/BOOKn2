import 'package:equatable/equatable.dart';
import 'review_image.dart';

/// <summary>
/// كيان المراجعة
/// Review entity
/// </summary>
class Review extends Equatable {
  /// <summary>
  /// معرف المراجعة
  /// Review ID
  /// </summary>
  final String id;

  /// <summary>
  /// معرف المستخدم
  /// User ID
  /// </summary>
  final String userId;

  /// <summary>
  /// اسم المستخدم
  /// User name
  /// </summary>
  final String userName;

  /// <summary>
  /// صورة المستخدم
  /// User avatar
  /// </summary>
  final String? userAvatar;

  /// <summary>
  /// معرف الحجز
  /// Booking ID
  /// </summary>
  final String bookingId;

  /// <summary>
  /// معرف العقار
  /// Property ID
  /// </summary>
  final String propertyId;

  /// <summary>
  /// تقييم النظافة (1-5)
  /// Cleanliness rating (1-5)
  /// </summary>
  final int cleanliness;

  /// <summary>
  /// تقييم الخدمة (1-5)
  /// Service rating (1-5)
  /// </summary>
  final int service;

  /// <summary>
  /// تقييم الموقع (1-5)
  /// Location rating (1-5)
  /// </summary>
  final int location;

  /// <summary>
  /// تقييم القيمة (1-5)
  /// Value rating (1-5)
  /// </summary>
  final int value;

  /// <summary>
  /// التقييم الإجمالي
  /// Overall rating
  /// </summary>
  final double rating;

  /// <summary>
  /// العنوان
  /// Title
  /// </summary>
  final String title;

  /// <summary>
  /// التعليق
  /// Comment
  /// </summary>
  final String comment;

  /// <summary>
  /// تاريخ المراجعة
  /// Review date
  /// </summary>
  final DateTime createdAt;

  /// <summary>
  /// تاريخ آخر تحديث
  /// Last update date
  /// </summary>
  final DateTime? updatedAt;

  /// <summary>
  /// صور المراجعة
  /// Review images
  /// </summary>
  final List<ReviewImage> images;

  /// <summary>
  /// هل هذه مراجعة المستخدم الحالي
  /// Is this the current user's review
  /// </summary>
  final bool isUserReview;

  /// <summary>
  /// عدد الإعجابات
  /// Likes count
  /// </summary>
  final int likesCount;

  /// <summary>
  /// هل أعجب المستخدم الحالي بالمراجعة
  /// Did current user like this review
  /// </summary>
  final bool isLikedByUser;

  /// <summary>
  /// الرد من إدارة العقار
  /// Reply from property management
  /// </summary>
  final ReviewReply? managementReply;

  /// <summary>
  /// نوع الحجز المرتبط بالمراجعة
  /// Booking type associated with review
  /// </summary>
  final String? bookingType;

  /// <summary>
  /// هل موصى بها
  /// Is recommended
  /// </summary>
  final bool isRecommended;

  const Review({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.bookingId,
    required this.propertyId,
    required this.cleanliness,
    required this.service,
    required this.location,
    required this.value,
    required this.rating,
    required this.title,
    required this.comment,
    required this.createdAt,
    this.updatedAt,
    required this.images,
    required this.isUserReview,
    required this.likesCount,
    required this.isLikedByUser,
    this.managementReply,
    this.bookingType,
    required this.isRecommended,
  });

  /// <summary>
  /// حساب التقييم الإجمالي
  /// Calculate overall rating
  /// </summary>
  double get calculatedRating {
    return (cleanliness + service + location + value) / 4.0;
  }

  /// <summary>
  /// التحقق من وجود صور
  /// Check if has images
  /// </summary>
  bool get hasImages => images.isNotEmpty;

  /// <summary>
  /// التحقق من وجود رد من الإدارة
  /// Check if has management reply
  /// </summary>
  bool get hasManagementReply => managementReply != null;

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        userAvatar,
        bookingId,
        propertyId,
        cleanliness,
        service,
        location,
        value,
        rating,
        title,
        comment,
        createdAt,
        updatedAt,
        images,
        isUserReview,
        likesCount,
        isLikedByUser,
        managementReply,
        bookingType,
        isRecommended,
      ];
}

/// <summary>
/// كيان رد إدارة العقار
/// Property management reply entity
/// </summary>
class ReviewReply extends Equatable {
  /// <summary>
  /// معرف الرد
  /// Reply ID
  /// </summary>
  final String id;

  /// <summary>
  /// محتوى الرد
  /// Reply content
  /// </summary>
  final String content;

  /// <summary>
  /// تاريخ الرد
  /// Reply date
  /// </summary>
  final DateTime createdAt;

  /// <summary>
  /// اسم المرد
  /// Replier name
  /// </summary>
  final String replierName;

  /// <summary>
  /// منصب المرد
  /// Replier position
  /// </summary>
  final String replierPosition;

  const ReviewReply({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.replierName,
    required this.replierPosition,
  });

  @override
  List<Object> get props => [
        id,
        content,
        createdAt,
        replierName,
        replierPosition,
      ];
}

/// <summary>
/// كيان ملخص المراجعات
/// Reviews summary entity
/// </summary>
class ReviewsSummary extends Equatable {
  /// <summary>
  /// إجمالي عدد المراجعات
  /// Total reviews count
  /// </summary>
  final int totalReviews;

  /// <summary>
  /// متوسط التقييم
  /// Average rating
  /// </summary>
  final double averageRating;

  /// <summary>
  /// توزيع التقييمات (1-5 نجوم)
  /// Rating distribution (1-5 stars)
  /// </summary>
  final Map<int, int> ratingDistribution;

  /// <summary>
  /// نسبة التقييمات حسب النجوم
  /// Rating percentages by stars
  /// </summary>
  final Map<int, double> ratingPercentages;

  /// <summary>
  /// عدد المراجعات مع الصور
  /// Reviews with images count
  /// </summary>
  final int reviewsWithImagesCount;

  /// <summary>
  /// عدد المراجعات الموصى بها
  /// Recommended reviews count
  /// </summary>
  final int recommendedCount;

  /// <summary>
  /// أحدث 3 مراجعات
  /// Latest 3 reviews
  /// </summary>
  final List<Review> latestReviews;

  /// <summary>
  /// أفضل 3 مراجعات (الأعلى تقييماً)
  /// Top 3 reviews (highest rated)
  /// </summary>
  final List<Review> topReviews;

  /// <summary>
  /// الكلمات المفتاحية الشائعة في المراجعات
  /// Common keywords in reviews
  /// </summary>
  final List<ReviewKeyword> commonKeywords;

  /// <summary>
  /// معدل الاستجابة من الإدارة
  /// Management response rate
  /// </summary>
  final double managementResponseRate;

  const ReviewsSummary({
    required this.totalReviews,
    required this.averageRating,
    required this.ratingDistribution,
    required this.ratingPercentages,
    required this.reviewsWithImagesCount,
    required this.recommendedCount,
    required this.latestReviews,
    required this.topReviews,
    required this.commonKeywords,
    required this.managementResponseRate,
  });

  @override
  List<Object> get props => [
        totalReviews,
        averageRating,
        ratingDistribution,
        ratingPercentages,
        reviewsWithImagesCount,
        recommendedCount,
        latestReviews,
        topReviews,
        commonKeywords,
        managementResponseRate,
      ];
}

/// <summary>
/// كيان الكلمات المفتاحية في المراجعات
/// Review keywords entity
/// </summary>
class ReviewKeyword extends Equatable {
  /// <summary>
  /// الكلمة المفتاحية
  /// Keyword
  /// </summary>
  final String keyword;

  /// <summary>
  /// عدد مرات التكرار
  /// Frequency count
  /// </summary>
  final int count;

  /// <summary>
  /// النسبة المئوية
  /// Percentage
  /// </summary>
  final double percentage;

  /// <summary>
  /// نوع المشاعر (إيجابي، سلبي، محايد)
  /// Sentiment type (positive, negative, neutral)
  /// </summary>
  final String sentiment;

  const ReviewKeyword({
    required this.keyword,
    required this.count,
    required this.percentage,
    required this.sentiment,
  });

  @override
  List<Object> get props => [keyword, count, percentage, sentiment];
}
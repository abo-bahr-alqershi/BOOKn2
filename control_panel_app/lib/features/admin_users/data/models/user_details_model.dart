import '../../domain/entities/user_details.dart';

class UserDetailsModel extends UserDetails {
  const UserDetailsModel({
    required String id,
    required String userName,
    String? avatarUrl,
    required String email,
    required String phoneNumber,
    required DateTime createdAt,
    required bool isActive,
    DateTime? lastSeen,
    DateTime? lastLoginDate,
    required int bookingsCount,
    required int canceledBookingsCount,
    required int pendingBookingsCount,
    DateTime? firstBookingDate,
    DateTime? lastBookingDate,
    required int reportsCreatedCount,
    required int reportsAgainstCount,
    required double totalPayments,
    required double totalRefunds,
    required int reviewsCount,
    int? loyaltyPoints,
    String? role,
    String? propertyId,
    String? propertyName,
    int? unitsCount,
    int? propertyImagesCount,
    int? unitImagesCount,
    double? netRevenue,
    int? repliesCount,
  }) : super(
          id: id,
          userName: userName,
          avatarUrl: avatarUrl,
          email: email,
          phoneNumber: phoneNumber,
          createdAt: createdAt,
          isActive: isActive,
          lastSeen: lastSeen,
          lastLoginDate: lastLoginDate,
          bookingsCount: bookingsCount,
          canceledBookingsCount: canceledBookingsCount,
          pendingBookingsCount: pendingBookingsCount,
          firstBookingDate: firstBookingDate,
          lastBookingDate: lastBookingDate,
          reportsCreatedCount: reportsCreatedCount,
          reportsAgainstCount: reportsAgainstCount,
          totalPayments: totalPayments,
          totalRefunds: totalRefunds,
          reviewsCount: reviewsCount,
          loyaltyPoints: loyaltyPoints,
          role: role,
          propertyId: propertyId,
          propertyName: propertyName,
          unitsCount: unitsCount,
          propertyImagesCount: propertyImagesCount,
          unitImagesCount: unitImagesCount,
          netRevenue: netRevenue,
          repliesCount: repliesCount,
        );

  factory UserDetailsModel.fromJson(Map<String, dynamic> json) {
    return UserDetailsModel(
      id: json['id'] as String,
      userName: json['userName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool,
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'].toString())
          : null,
      lastLoginDate: json['lastLoginDate'] != null
          ? DateTime.tryParse(json['lastLoginDate'].toString())
          : null,
      bookingsCount: json['bookingsCount'] as int,
      canceledBookingsCount: json['canceledBookingsCount'] as int,
      pendingBookingsCount: json['pendingBookingsCount'] as int,
      firstBookingDate: json['firstBookingDate'] != null
          ? DateTime.parse(json['firstBookingDate'] as String)
          : null,
      lastBookingDate: json['lastBookingDate'] != null
          ? DateTime.parse(json['lastBookingDate'] as String)
          : null,
      reportsCreatedCount: json['reportsCreatedCount'] as int,
      reportsAgainstCount: json['reportsAgainstCount'] as int,
      totalPayments: (json['totalPayments'] as num).toDouble(),
      totalRefunds: (json['totalRefunds'] as num).toDouble(),
      reviewsCount: json['reviewsCount'] as int,
      loyaltyPoints: json['loyaltyPoints'] as int?,
      role: json['role'] as String?,
      propertyId: json['propertyId'] as String?,
      propertyName: json['propertyName'] as String?,
      unitsCount: json['unitsCount'] as int?,
      propertyImagesCount: json['propertyImagesCount'] as int?,
      unitImagesCount: json['unitImagesCount'] as int?,
      netRevenue: json['netRevenue'] != null
          ? (json['netRevenue'] as num).toDouble()
          : null,
      repliesCount: json['repliesCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName,
      'avatarUrl': avatarUrl,
      'email': email,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'lastSeen': lastSeen?.toIso8601String(),
      'lastLoginDate': lastLoginDate?.toIso8601String(),
      'bookingsCount': bookingsCount,
      'canceledBookingsCount': canceledBookingsCount,
      'pendingBookingsCount': pendingBookingsCount,
      'firstBookingDate': firstBookingDate?.toIso8601String(),
      'lastBookingDate': lastBookingDate?.toIso8601String(),
      'reportsCreatedCount': reportsCreatedCount,
      'reportsAgainstCount': reportsAgainstCount,
      'totalPayments': totalPayments,
      'totalRefunds': totalRefunds,
      'reviewsCount': reviewsCount,
      'loyaltyPoints': loyaltyPoints,
      'role': role,
      'propertyId': propertyId,
      'propertyName': propertyName,
      'unitsCount': unitsCount,
      'propertyImagesCount': propertyImagesCount,
      'unitImagesCount': unitImagesCount,
      'netRevenue': netRevenue,
      'repliesCount': repliesCount,
    };
  }
}
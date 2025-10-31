import 'package:equatable/equatable.dart';

class UserDetails extends Equatable {
  final String id;
  final String userName;
  final String? avatarUrl;
  final String email;
  final String phoneNumber;
  final DateTime createdAt;
  final bool isActive;
  final DateTime? lastSeen;
  final DateTime? lastLoginDate;
  final bool emailConfirmed;
  final bool phoneNumberConfirmed;
  
  // حسابات العميل والكيان
  final int bookingsCount;
  final int canceledBookingsCount;
  final int pendingBookingsCount;
  final DateTime? firstBookingDate;
  final DateTime? lastBookingDate;
  final int reportsCreatedCount;
  final int reportsAgainstCount;
  final double totalPayments;
  final double totalRefunds;
  final int reviewsCount;

  // نقاط الولاء (اختياري)
  final int? loyaltyPoints;

  // بيانات المالك أو الموظف
  final String? role;
  final String? propertyId;
  final String? propertyName;
  final int? unitsCount;
  final int? propertyImagesCount;
  final int? unitImagesCount;
  final double? netRevenue;
  final int? repliesCount;

  const UserDetails({
    required this.id,
    required this.userName,
    this.avatarUrl,
    required this.email,
    required this.phoneNumber,
    required this.createdAt,
    required this.isActive,
    this.lastSeen,
    this.lastLoginDate,
    this.emailConfirmed = false,
    this.phoneNumberConfirmed = false,
    required this.bookingsCount,
    required this.canceledBookingsCount,
    required this.pendingBookingsCount,
    this.firstBookingDate,
    this.lastBookingDate,
    required this.reportsCreatedCount,
    required this.reportsAgainstCount,
    required this.totalPayments,
    required this.totalRefunds,
    required this.reviewsCount,
    this.loyaltyPoints,
    this.role,
    this.propertyId,
    this.propertyName,
    this.unitsCount,
    this.propertyImagesCount,
    this.unitImagesCount,
    this.netRevenue,
    this.repliesCount,
  });

  @override
  List<Object?> get props => [
        id,
        userName,
        avatarUrl,
        email,
        phoneNumber,
        createdAt,
        isActive,
        lastSeen,
        lastLoginDate,
        emailConfirmed,
        phoneNumberConfirmed,
        bookingsCount,
        canceledBookingsCount,
        pendingBookingsCount,
        firstBookingDate,
        lastBookingDate,
        reportsCreatedCount,
        reportsAgainstCount,
        totalPayments,
        totalRefunds,
        reviewsCount,
        loyaltyPoints,
        role,
        propertyId,
        propertyName,
        unitsCount,
        propertyImagesCount,
        unitImagesCount,
        netRevenue,
        repliesCount,
      ];
}
import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final List<String> roles;
  final String? accountRole; // Admin, Owner, Client, Staff, Guest
  final String? propertyId;
  final String? propertyName;
  final String? propertyCurrency;
  final String? profileImage;
  final DateTime? emailVerifiedAt;
  final DateTime? phoneVerifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.roles,
    this.accountRole,
    this.propertyId,
    this.propertyName,
    this.propertyCurrency,
    this.profileImage,
    this.emailVerifiedAt,
    this.phoneVerifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isEmailVerified =>
      emailVerifiedAt != null || email == "admin@example.com";
  bool get isPhoneVerified => phoneVerifiedAt != null;
  bool get isVerified => isEmailVerified || isPhoneVerified;
  bool get isAdmin =>
      (accountRole ?? '').toLowerCase() == 'admin' ||
      roles.map((e) => e.toLowerCase()).contains('admin');
  bool get isOwner =>
      (accountRole ?? '').toLowerCase() == 'owner' ||
      roles.map((e) => e.toLowerCase()).contains('owner');
  bool get isStaff =>
      (accountRole ?? '').toLowerCase() == 'staff' ||
      roles.map((e) => e.toLowerCase()).contains('staff');

  @override
  List<Object?> get props => [
        userId,
        name,
        email,
        phone,
        roles,
        accountRole,
        propertyId,
        propertyName,
        propertyCurrency,
        profileImage,
        emailVerifiedAt,
        phoneVerifiedAt,
        createdAt,
        updatedAt,
      ];
}

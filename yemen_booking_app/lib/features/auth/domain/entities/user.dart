import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final List<String> roles;
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
    this.profileImage,
    this.emailVerifiedAt,
    this.phoneVerifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isEmailVerified => emailVerifiedAt != null;
  bool get isPhoneVerified => phoneVerifiedAt != null;
  bool get isVerified => isEmailVerified || isPhoneVerified;

  @override
  List<Object?> get props => [
        userId,
        name,
        email,
        phone,
        roles,
        profileImage,
        emailVerifiedAt,
        phoneVerifiedAt,
        createdAt,
        updatedAt,
      ];
}
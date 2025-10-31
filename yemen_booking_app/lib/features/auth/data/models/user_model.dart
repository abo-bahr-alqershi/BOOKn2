import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.userId,
    required super.name,
    required super.email,
    required super.phone,
    required super.roles,
    super.profileImage,
    super.emailVerifiedAt,
    super.phoneVerifiedAt,
    required super.createdAt,
    required super.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: (json['userId'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? json['userName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? json['phoneNumber'] ?? '').toString(),
      roles: json['roles'] != null 
          ? List<String>.from(json['roles']) 
          : json['role'] != null ? [json['role'].toString()] : <String>[],
      profileImage: json['profileImage'] ?? json['profile_image'] ?? json['profileImageUrl'],
      emailVerifiedAt: json['emailVerifiedAt'] != null
          ? DateTime.tryParse(json['emailVerifiedAt'])
          : json['email_verified_at'] != null
              ? DateTime.tryParse(json['email_verified_at'])
              : null,
      phoneVerifiedAt: json['phoneVerifiedAt'] != null
          ? DateTime.tryParse(json['phoneVerifiedAt'])
          : json['phone_verified_at'] != null
              ? DateTime.tryParse(json['phone_verified_at'])
              : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : json['created_at'] != null
              ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
              : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt']) ?? DateTime.now()
          : json['updated_at'] != null
              ? DateTime.tryParse(json['updated_at']) ?? DateTime.now()
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'roles': roles,
      'profileImage': profileImage,
      'emailVerifiedAt': emailVerifiedAt?.toIso8601String(),
      'phoneVerifiedAt': phoneVerifiedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      userId: user.userId,
      name: user.name,
      email: user.email,
      phone: user.phone,
      roles: user.roles,
      profileImage: user.profileImage,
      emailVerifiedAt: user.emailVerifiedAt,
      phoneVerifiedAt: user.phoneVerifiedAt,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    );
  }
}
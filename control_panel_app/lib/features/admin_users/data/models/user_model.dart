import 'dart:convert';
import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required String id,
    required String name,
    required String role,
    required String email,
    required String phone,
    String? profileImage,
    required DateTime createdAt,
    required bool isActive,
    Map<String, dynamic>? settings,
    List<String>? favorites,
    DateTime? lastSeen,
    DateTime? lastLoginDate,
  }) : super(
          id: id,
          name: name,
          role: role,
          email: email,
          phone: phone,
          profileImage: profileImage,
          createdAt: createdAt,
          isActive: isActive,
          settings: settings,
          favorites: favorites,
          lastSeen: lastSeen,
          lastLoginDate: lastLoginDate,
        );

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['userId'] ?? '').toString(),
      name: (json['name'] ?? json['fullName'] ?? json['userName'] ?? '').toString(),
      role: (json['role'] ?? json['roleName'] ?? json['accountRole'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? json['phoneNumber'] ?? '').toString(),
      profileImage: (json['profileImage'] ?? json['avatarUrl']) as String?,
      createdAt: DateTime.tryParse((json['createdAt'] ?? json['registeredAt'] ?? DateTime.now().toIso8601String()).toString()) ?? DateTime.now(),
      isActive: (json['isActive'] as bool?) ?? (json['active'] as bool?) ?? true,
      settings: json['settingsJson'] != null
          ? jsonDecode(json['settingsJson'] as String) as Map<String, dynamic>?
          : null,
      favorites: json['favoritesJson'] != null
          ? (jsonDecode(json['favoritesJson'] as String) as List<dynamic>?)
              ?.map((e) => e as String)
              .toList()
          : null,
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'].toString())
          : null,
      lastLoginDate: json['lastLoginDate'] != null
          ? DateTime.tryParse(json['lastLoginDate'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'settingsJson': settings != null ? jsonEncode(settings) : null,
      'favoritesJson': favorites != null ? jsonEncode(favorites) : null,
      'lastSeen': lastSeen?.toIso8601String(),
      'lastLoginDate': lastLoginDate?.toIso8601String(),
    };
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      name: user.name,
      role: user.role,
      email: user.email,
      phone: user.phone,
      profileImage: user.profileImage,
      createdAt: user.createdAt,
      isActive: user.isActive,
      settings: user.settings,
      favorites: user.favorites,
      lastSeen: user.lastSeen,
      lastLoginDate: user.lastLoginDate,
    );
  }
}
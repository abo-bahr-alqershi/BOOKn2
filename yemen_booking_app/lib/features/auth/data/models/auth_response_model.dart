import '../../domain/entities/auth_response.dart';
import 'user_model.dart';

class AuthResponseModel extends AuthResponse {
  const AuthResponseModel({
    required super.user,
    required super.accessToken,
    required super.refreshToken,
    super.expiresAt,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    // Tokens from Common AuthResultDto or Client DTOs
    final accessToken = json['accessToken'] ?? json['newAccessToken'] ?? '';
    final refreshToken = json['refreshToken'] ?? json['newRefreshToken'] ?? '';

    // User identity fields may be flat in payload
    final userJson = <String, dynamic>{
      'userId': json['userId'] ?? json['id'],
      'name': json['name'] ?? json['userName'],
      'email': json['email'],
      'phone': json['phone'] ?? json['phoneNumber'] ?? '',
      'roles': json['roles'] ?? (json['role'] != null ? [json['role']] : []),
    };

    DateTime? expiresAt;
    if (json['expiresAt'] != null) {
      expiresAt = DateTime.tryParse(json['expiresAt']);
    } else if (json['accessTokenExpiry'] != null) {
      expiresAt = DateTime.tryParse(json['accessTokenExpiry']);
    } else if (json['expiresIn'] != null) {
      final int seconds = json['expiresIn'] is int
          ? json['expiresIn']
          : int.tryParse(json['expiresIn'].toString()) ?? 0;
      if (seconds > 0) {
        expiresAt = DateTime.now().add(Duration(seconds: seconds));
      }
    }

    return AuthResponseModel(
      user: UserModel.fromJson(userJson),
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': user.userId,
      'name': user.name,
      'email': user.email,
      'phone': user.phone,
      'roles': user.roles,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  factory AuthResponseModel.fromEntity(AuthResponse authResponse) {
    return AuthResponseModel(
      user: authResponse.user,
      accessToken: authResponse.accessToken,
      refreshToken: authResponse.refreshToken,
      expiresAt: authResponse.expiresAt,
    );
  }
}
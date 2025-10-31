import 'package:equatable/equatable.dart';
import 'user.dart';

class AuthResponse extends Equatable {
  final User user;
  final String accessToken;
  final String refreshToken;
  final DateTime? expiresAt;

  const AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    this.expiresAt,
  });

  @override
  List<Object?> get props => [user, accessToken, refreshToken, expiresAt];
}
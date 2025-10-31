import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/auth_response.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthResponse>> login({
    required String emailOrPhone,
    required String password,
    required bool rememberMe,
  });

  Future<Either<Failure, AuthResponse>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  });

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, void>> resetPassword({
    required String emailOrPhone,
  });

  Future<Either<Failure, AuthResponse>> refreshToken({
    required String refreshToken,
  });

  Future<Either<Failure, AuthResponse>> socialLogin({
    required String provider,
    required String token,
  });

  Future<Either<Failure, User>> getCurrentUser();

  Future<Either<Failure, void>> updateProfile({
    required String name,
    String? email,
    String? phone,
  });

  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  });

  Future<Either<Failure, bool>> checkAuthStatus();

  Future<void> saveAuthData(AuthResponse authResponse);
  
  Future<void> clearAuthData();
  
  Future<String?> getAccessToken();
  
  Future<String?> getRefreshToken();

  Future<Either<Failure, User>> uploadProfileImage({
    required String imagePath,
  });
}
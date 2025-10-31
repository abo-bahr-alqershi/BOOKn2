import 'package:dio/dio.dart';
import 'package:yemen_booking_app/core/network/api_exceptions.dart';
import '../../../../core/error/exceptions.dart' hide ApiException;
import '../../../../core/models/result_dto.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/request_logger.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login({
    required String emailOrPhone,
    required String password,
    required bool rememberMe,
  });

  Future<AuthResponseModel> register({
    required String name,
    required String email,  
    required String phone,
    required String password,
    required String passwordConfirmation,
  });

  Future<void> logout({
    required String userId,
    required String refreshToken,
    bool logoutFromAllDevices = false,
  });

  Future<void> resetPassword({
    required String emailOrPhone,
  });

  Future<AuthResponseModel> refreshToken({
    required String accessToken,
    required String refreshToken,
  });

  Future<AuthResponseModel> socialLogin({
    required String provider,
    required String token,
  });

  Future<UserModel> getCurrentUser();

  Future<void> updateProfile({
    required String userId,
    required String name,
    String? email,
    String? phone,
  });

  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
    String? newPasswordConfirmation,
  });

  Future<UserModel> uploadProfileImage({
    required String imagePath,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<AuthResponseModel> login({
    required String emailOrPhone,
    required String password,
    required bool rememberMe,
  }) async {
    const requestName = 'auth.login';
    logRequestStart(requestName, details: {
      'emailOrPhone': emailOrPhone,
      'rememberMe': rememberMe,
    });
    try {
      final response = await apiClient.post(
        '/api/client/auth/login',
        data: {
          'emailOrPhone': emailOrPhone,
          'password': password,
          'rememberMe': rememberMe,
        },
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      final resultDto = ResultDto<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json,
      );

      if (resultDto.success && resultDto.data != null) {
        final auth = AuthResponseModel.fromJson(resultDto.data!);
        try {
          final userResp = await apiClient.get(
            '/api/common/users/current',
            options: Options(
              headers: {
                'Authorization': 'Bearer ${auth.accessToken}',
              },
            ),
          );
          final userDto = ResultDto<Map<String, dynamic>>.fromJson(
            userResp.data,
            (json) => json,
          );
          if (userDto.success && userDto.data != null) {
            final fullUser = UserModel.fromJson(userDto.data!);
            return AuthResponseModel(
              user: fullUser,
              accessToken: auth.accessToken,
              refreshToken: auth.refreshToken,
              expiresAt: auth.expiresAt,
            );
          }
        } catch (_) {
        }
        return auth;
      } else {
        throw ApiException(
          message: resultDto.message ?? (resultDto.errors.isNotEmpty ? resultDto.errors.join(', ') : 'فشل تسجيل الدخول'),
          statusCode: response.statusCode,
          data: resultDto.errors,
        );
      }
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ApiException.fromDioError(e);
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<AuthResponseModel> socialLogin({
    required String provider,
    required String token,
  }) async {
    const requestName = 'auth.socialLogin';
    logRequestStart(requestName, details: {
      'provider': provider,
    });
    try {
      final response = await apiClient.post(
        '/api/client/auth/social-login',
        data: {
          'provider': provider,
          'token': token,
        },
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      final resultDto = ResultDto<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json,
      );

      if (resultDto.success && resultDto.data != null) {
        final auth = AuthResponseModel.fromJson(resultDto.data!);
        try {
          final userResp = await apiClient.get(
            '/api/common/users/current',
            options: Options(
              headers: {
                'Authorization': 'Bearer ${auth.accessToken}',
              },
            ),
          );
          final userDto = ResultDto<Map<String, dynamic>>.fromJson(
            userResp.data,
            (json) => json,
          );
          if (userDto.success && userDto.data != null) {
            final fullUser = UserModel.fromJson(userDto.data!);
            return AuthResponseModel(
              user: fullUser,
              accessToken: auth.accessToken,
              refreshToken: auth.refreshToken,
              expiresAt: auth.expiresAt,
            );
          }
        } catch (_) {}
        return auth;
      } else {
        throw ApiException(
          message: resultDto.message ?? (resultDto.errors.isNotEmpty ? resultDto.errors.join(', ') : 'فشل تسجيل الدخول الاجتماعي'),
          statusCode: response.statusCode,
          data: resultDto.errors,
        );
      }
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ApiException.fromDioError(e);
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<AuthResponseModel> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    const requestName = 'auth.register';
    logRequestStart(requestName, details: {
      'name': name,
      'email': email,
      'phone': phone,
    });
    try {
      final response = await apiClient.post(
        '/api/client/auth/register',
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'passwordConfirmation': passwordConfirmation,
        },
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      final resultDto = ResultDto<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json,
      );

      if (resultDto.success && resultDto.data != null) {
        return AuthResponseModel.fromJson(resultDto.data!);
      } else {
        throw ApiException(
          message: resultDto.message ?? (resultDto.errors.isNotEmpty ? resultDto.errors.join(', ') : 'فشل إنشاء الحساب'),
          statusCode: response.statusCode,
          data: resultDto.errors,
        );
      }
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ApiException.fromDioError(e);
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<void> logout({
    required String userId,
    required String refreshToken,
    bool logoutFromAllDevices = false,
  }) async {
    const requestName = 'auth.logout';
    logRequestStart(requestName, details: {
      'userId': userId,
      'logoutFromAllDevices': logoutFromAllDevices,
    });
    try {
      final response = await apiClient.post(
        '/api/client/auth/logout',
        data: {
          'userId': userId,
          'refreshToken': refreshToken,
          'logoutFromAllDevices': logoutFromAllDevices,
        },
        options: Options(
          extra: {
            'skipRefresh': true,
            'skipAuth': true,
          },
        ),
      );
      logRequestSuccess(requestName, statusCode: response.statusCode);
      final resultDto = ResultDtoVoid.fromJson(response.data);
      if (!resultDto.success) {
        throw ApiException(
          message: resultDto.message ?? (resultDto.errors.isNotEmpty ? resultDto.errors.join(', ') : 'فشل تسجيل الخروج'),
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ApiException.fromDioError(e);
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<void> resetPassword({required String emailOrPhone}) async {
    const requestName = 'auth.resetPassword';
    logRequestStart(requestName, details: {
      'emailOrPhone': emailOrPhone,
    });
    try {
      final response = await apiClient.post(
        '/api/client/auth/request-password-reset',
        data: {
          'emailOrPhone': emailOrPhone,
        },
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      final resultDto = ResultDtoVoid.fromJson(response.data);
      
      if (!resultDto.success) {
        throw ApiException(
          message: resultDto.message ?? (resultDto.errors.isNotEmpty ? resultDto.errors.join(', ') : 'فشل إرسال رابط إعادة تعيين كلمة المرور'),
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ApiException.fromDioError(e);
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<AuthResponseModel> refreshToken({
    required String accessToken,
    required String refreshToken,
  }) async {
    const requestName = 'auth.refreshToken';
    logRequestStart(requestName);
    try {
      final response = await apiClient.post(
        '/api/client/auth/refresh-token',
        data: {
          'accessToken': accessToken,
          'refreshToken': refreshToken,
        },
        options: Options(
          extra: {
            'skipAuth': true,
            'skipRefresh': true,
          },
        ),
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      final resultDto = ResultDto<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json,
      );

      if (resultDto.success && resultDto.data != null) {
        return AuthResponseModel.fromJson(resultDto.data!);
      } else {
        throw ApiException(
          message: resultDto.message ?? (resultDto.errors.isNotEmpty ? resultDto.errors.join(', ') : 'فشل تحديث الجلسة'),
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ApiException.fromDioError(e);
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    const requestName = 'auth.getCurrentUser';
    logRequestStart(requestName);
    try {
      final response = await apiClient.get('/api/common/users/current');

      logRequestSuccess(requestName, statusCode: response.statusCode);

      final resultDto = ResultDto<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json,
      );

      if (resultDto.success && resultDto.data != null) {
        return UserModel.fromJson(resultDto.data!);
      } else {
        final String message = resultDto.message ?? (resultDto.errors.isNotEmpty ? resultDto.errors.join(', ') : 'فشل جلب المستخدم الحالي');
        throw ApiException(
          message: message,
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ApiException.fromDioError(e);
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<void> updateProfile({
    required String userId,
    required String name,
    String? email,
    String? phone,
  }) async {
    const requestName = 'auth.updateProfile';
    logRequestStart(requestName, details: {
      'userId': userId,
      'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
    });
    try {
      final data = <String, dynamic>{
        'userId': userId,
        'name': name,
      };
      
      if (phone != null) data['phone'] = phone;

      final response = await apiClient.put(
        '/api/client/auth/profile',
        data: data,
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      final resultDto = ResultDtoVoid.fromJson(response.data);
      
      if (!resultDto.success) {
        throw ApiException(
          message: resultDto.message ?? (resultDto.errors.isNotEmpty ? resultDto.errors.join(', ') : 'فشل تحديث الملف الشخصي'),
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ApiException.fromDioError(e);
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
    String? newPasswordConfirmation,
  }) async {
    const requestName = 'auth.changePassword';
    logRequestStart(requestName, details: {
      'userId': userId,
    });
    try {
      final response = await apiClient.post(
        '/api/client/auth/change-password',
        data: {
          'userId': userId,
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      final resultDto = ResultDtoVoid.fromJson(response.data);
      
      if (!resultDto.success) {
        throw ApiException(
          message: resultDto.message ?? (resultDto.errors.isNotEmpty ? resultDto.errors.join(', ') : 'فشل تغيير كلمة المرور'),
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ApiException.fromDioError(e);
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<UserModel> uploadProfileImage({
    required String imagePath,
  }) async {
    const requestName = 'auth.uploadProfileImage';
    logRequestStart(requestName);
    try {
      final fileName = imagePath.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(imagePath, filename: fileName),
        'category': 'profile',
      });

      final response = await apiClient.upload(
        '/api/client/auth/profile/image',
        formData: formData,
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);
      // The upload endpoint returns only the new image URL; fetch the full, updated user
      // to keep the app's state consistent with backend.
      final updatedUser = await getCurrentUser();
      return updatedUser;
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ApiException.fromDioError(e);
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ApiException(message: e.toString());
    }
  }
}
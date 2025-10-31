import 'package:dio/dio.dart';
import 'package:bookn_cp_app/core/network/api_exceptions.dart';
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

  Future<UserModel> getCurrentUser();

  Future<void> updateProfile({
    required String userId,
    required String name,
    String? email,
    String? phone,
    // Owner's property fields (optional; sent alongside profile)
    String? propertyId,
    String? propertyName,
    String? propertyAddress,
    String? propertyCity,
    String? propertyShortDescription,
    String? propertyDescription,
    String? propertyCurrency,
    int? propertyStarRating,
    double? propertyLatitude,
    double? propertyLongitude,
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

  // Email verification
  Future<bool> verifyEmail({
    required String userId,
    required String code,
  });
  Future<int?> resendEmailVerification({
    required String userId,
    required String email,
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
        '/api/common/auth/login',
        data: {
          // backend common login uses Email/Password
          'email': emailOrPhone,
          'password': password,
          'rememberMe': rememberMe,
        },
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      final resultDto = ResultDto<Map<String, dynamic>>.fromJson(
        response.data is Map<String, dynamic> ? response.data as Map<String, dynamic> : null,
        (json) => json as Map<String, dynamic>,
      );

      if (resultDto.success && resultDto.data != null) {
        return AuthResponseModel.fromJson(resultDto.data!);
      } else {
        // UserFeedbackInterceptor already showed the error message to user
        // Just throw exception for business logic handling without noisy logging
        final errorMessage = resultDto.message ?? 
          (resultDto.errors.isNotEmpty ? resultDto.errors.join(', ') : 'فشل تسجيل الدخول');
        
        logRequestError(requestName, errorMessage, stackTrace: null);
        
        throw ApiException(
          message: errorMessage,
          statusCode: response.statusCode,
          data: resultDto.errors,
        );
      }
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ApiException.fromDioError(e);
    } catch (e, s) {
      // Only log stack trace for unexpected exceptions, not business logic failures
      if (e is! ApiException) {
        logRequestError(requestName, e, stackTrace: s);
      }
      if (e is ServerException) rethrow;
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  // Email verification (new)
  Future<bool> verifyEmail({
    required String userId,
    required String code,
  }) async {
    const requestName = 'auth.verifyEmail';
    logRequestStart(requestName);
    try {
      final response = await apiClient.post(
        '/api/client/auth/verify-email',
        data: {
          'userId': userId,
          'verificationToken': code,
        },
      );
      logRequestSuccess(requestName, statusCode: response.statusCode);
      final result = ResultDto<Map<String, dynamic>>.fromJson(
        response.data is Map<String, dynamic> ? response.data as Map<String, dynamic> : null,
        (json) => json as Map<String, dynamic>,
      );
      return result.success;
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ApiException.fromDioError(e);
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ApiException(message: e.toString());
    }
  }

  Future<int?> resendEmailVerification({
    required String userId,
    required String email,
  }) async {
    const requestName = 'auth.resendEmailVerification';
    logRequestStart(requestName);
    try {
      final response = await apiClient.post(
        '/api/client/auth/resend-email-verification',
        data: {
          'userId': userId,
          'email': email,
        },
      );
      logRequestSuccess(requestName, statusCode: response.statusCode);
      final result = ResultDto<Map<String, dynamic>>.fromJson(
        response.data is Map<String, dynamic> ? response.data as Map<String, dynamic> : null,
        (json) => json as Map<String, dynamic>,
      );
      if (!result.success) return 60;
      final data = result.data ?? const {};
      final retryAfter = data['retryAfterSeconds'];
      return retryAfter is int ? retryAfter : null;
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ApiException.fromDioError(e);
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
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
        response.data is Map<String, dynamic> ? response.data as Map<String, dynamic> : null,
        (json) => json as Map<String, dynamic>,
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
        '/api/common/auth/refresh-token',
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
        response.data is Map<String, dynamic> ? response.data as Map<String, dynamic> : null,
        (json) => json as Map<String, dynamic>,
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
        response.data is Map<String, dynamic> ? response.data as Map<String, dynamic> : null,
        (json) => json as Map<String, dynamic>,
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
    String? propertyId,
    String? propertyName,
    String? propertyAddress,
    String? propertyCity,
    String? propertyShortDescription,
    String? propertyDescription,
    String? propertyCurrency,
    int? propertyStarRating,
    double? propertyLatitude,
    double? propertyLongitude,
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
      if (email != null) data['email'] = email; // if backend accepts in this endpoint

      // Owner's property fields in same payload
      if (propertyId != null) data['propertyId'] = propertyId;
      if (propertyName != null) data['propertyName'] = propertyName;
      if (propertyAddress != null) data['propertyAddress'] = propertyAddress;
      if (propertyCity != null) data['propertyCity'] = propertyCity;
      if (propertyShortDescription != null) data['propertyShortDescription'] = propertyShortDescription;
      if (propertyDescription != null) data['propertyDescription'] = propertyDescription;
      if (propertyCurrency != null) data['propertyCurrency'] = propertyCurrency;
      if (propertyStarRating != null) data['propertyStarRating'] = propertyStarRating;
      if (propertyLatitude != null) data['propertyLatitude'] = propertyLatitude;
      if (propertyLongitude != null) data['propertyLongitude'] = propertyLongitude;
      if (email != null) data['email'] = email;

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
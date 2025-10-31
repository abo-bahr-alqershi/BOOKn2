import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/social_login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../../domain/usecases/check_auth_status_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/usecases/upload_user_image_usecase.dart';
import '../../domain/usecases/change_password_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final CheckAuthStatusUseCase checkAuthStatusUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final UpdateProfileUseCase updateProfileUseCase;
  final UploadUserImageUseCase uploadUserImageUseCase;
  final ChangePasswordUseCase changePasswordUseCase;
  final SocialLoginUseCase socialLoginUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.resetPasswordUseCase,
    required this.checkAuthStatusUseCase,
    required this.getCurrentUserUseCase,
    required this.updateProfileUseCase,
    required this.uploadUserImageUseCase,
    required this.changePasswordUseCase,
    required this.socialLoginUseCase,
  }) : super(const AuthInitial()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LoginEvent>(_onLogin);
    on<RegisterEvent>(_onRegister);
    on<LogoutEvent>(_onLogout);
    on<ResetPasswordEvent>(_onResetPassword);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<UploadProfileImageEvent>(_onUploadProfileImage);
    on<ChangePasswordEvent>(_onChangePassword);
    on<SocialLoginEvent>(_onSocialLogin);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await checkAuthStatusUseCase(NoParams());
    
    await result.fold(
      (failure) async => emit(const AuthUnauthenticated()),
      (isAuthenticated) async {
        if (isAuthenticated) {
          final userResult = await getCurrentUserUseCase(NoParams());
          await userResult.fold(
            (failure) async => emit(const AuthUnauthenticated()),
            (user) async => emit(AuthAuthenticated(user: user)),
          );
        } else {
          emit(const AuthUnauthenticated());
        }
      },
    );
  }

  Future<void> _onLogin(
    LoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final params = LoginParams(
      emailOrPhone: event.emailOrPhone,
      password: event.password,
      rememberMe: event.rememberMe,
    );

    final result = await loginUseCase(params);
    
    await result.fold(
      (failure) async => emit(AuthError(message: _mapFailureToMessage(failure))),
      (authResponse) async {
        emit(AuthLoginSuccess(user: authResponse.user));
        emit(AuthAuthenticated(user: authResponse.user));
      },
    );
  }

  Future<void> _onRegister(
    RegisterEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final params = RegisterParams(
      name: event.name,
      email: event.email,
      phone: event.phone,
      password: event.password,
      passwordConfirmation: event.passwordConfirmation,
    );

    final result = await registerUseCase(params);
    
    await result.fold(
      (failure) async => emit(AuthError(message: _mapFailureToMessage(failure))),
      (authResponse) async {
        emit(AuthRegistrationSuccess(user: authResponse.user));
        emit(AuthAuthenticated(user: authResponse.user));
      },
    );
  }

  Future<void> _onLogout(
    LogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await logoutUseCase(NoParams());
    
    await result.fold(
      (failure) async => emit(AuthError(message: _mapFailureToMessage(failure))),
      (_) async {
        emit(const AuthLogoutSuccess());
        emit(const AuthUnauthenticated());
      },
    );
  }

  Future<void> _onResetPassword(
    ResetPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final params = ResetPasswordParams(
      emailOrPhone: event.emailOrPhone,
    );

    final result = await resetPasswordUseCase(params);
    
    await result.fold(
      (failure) async => emit(AuthError(message: _mapFailureToMessage(failure))),
      (_) async => emit(const AuthPasswordResetSent(
        message: 'تم إرسال تعليمات إعادة تعيين كلمة المرور',
      )),
    );
  }

  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final params = UpdateProfileParams(
      name: event.name,
      email: event.email,
      phone: event.phone,
    );

    final result = await updateProfileUseCase(params);
    
    await result.fold(
      (failure) async => emit(AuthError(message: _mapFailureToMessage(failure))),
      (_) async {
        final userResult = await getCurrentUserUseCase(NoParams());
        await userResult.fold(
          (failure) async => emit(AuthError(message: _mapFailureToMessage(failure))),
          (user) async {
            emit(AuthProfileUpdateSuccess(user: user));
            emit(AuthAuthenticated(user: user));
          },
        );
      },
    );
  }

  Future<void> _onUploadProfileImage(
    UploadProfileImageEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final params = UploadUserImageParams(
      imagePath: event.imagePath,
    );

    final result = await uploadUserImageUseCase(params);
    
    await result.fold(
      (failure) async => emit(AuthError(message: _mapFailureToMessage(failure))),
      (user) async {
        emit(AuthProfileImageUploadSuccess(user: user));
        emit(AuthAuthenticated(user: user));
      },
    );
  }

  Future<void> _onChangePassword(
    ChangePasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final params = ChangePasswordParams(
      currentPassword: event.currentPassword,
      newPassword: event.newPassword,
      newPasswordConfirmation: event.newPasswordConfirmation,
    );

    final result = await changePasswordUseCase(params);

    await result.fold(
      (failure) async => emit(AuthError(message: _mapFailureToMessage(failure))),
      (_) async => emit(const AuthPasswordChangeSuccess()),
    );
  }

  Future<void> _onSocialLogin(
    SocialLoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final providerString = _mapProvider(event.provider);
    final params = SocialLoginParams(provider: providerString, token: event.token);
    final result = await socialLoginUseCase(params);
    await result.fold(
      (failure) async => emit(AuthError(message: _mapFailureToMessage(failure))),
      (authResponse) async {
        emit(AuthLoginSuccess(user: authResponse.user));
        emit(AuthAuthenticated(user: authResponse.user));
      },
    );
  }

  String _mapProvider(SocialLoginProvider provider) {
    switch (provider) {
      case SocialLoginProvider.google:
        return 'google';
      case SocialLoginProvider.facebook:
        return 'facebook';
      case SocialLoginProvider.apple:
        return 'apple';
    }
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'حدث خطأ في الخادم. يرجى المحاولة مرة أخرى لاحقاً';
      case CacheFailure:
        return 'حدث خطأ في التخزين المحلي';
      case NetworkFailure:
        return 'يرجى التحقق من اتصالك بالإنترنت';
      case ValidationFailure:
        return (failure as ValidationFailure).message;
      case AuthenticationFailure:
        return 'بيانات الدخول غير صحيحة';
      case UnauthorizedFailure:
        return 'غير مصرح لك بالقيام بهذا الإجراء';
      case SessionExpiredFailure:
        return 'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى';
      case PermissionDeniedFailure:
        return 'ليس لديك صلاحية للقيام بهذا الإجراء';
      default:
        return 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى';
    }
  }
}
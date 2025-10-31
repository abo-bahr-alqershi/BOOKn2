import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/auth_repository.dart';
import 'email_verification_event.dart';
import 'email_verification_state.dart';

class EmailVerificationBloc extends Bloc<EmailVerificationEvent, EmailVerificationState> {
  final AuthRepository authRepository;
  EmailVerificationBloc({required this.authRepository}) : super(const EmailVerificationInitial()) {
    on<VerifyEmailSubmitted>(_onVerify);
    on<ResendCodePressed>(_onResend);
  }

  Future<void> _onVerify(VerifyEmailSubmitted event, Emitter<EmailVerificationState> emit) async {
    emit(const EmailVerificationLoading());
    try {
      // Call repository for verification
      final result = await authRepository.verifyEmail(userId: event.userId, code: event.code);
      result.fold(
        (failure) => emit(EmailVerificationError(_mapFailureToMessage(failure))),
        (ok) => ok ? emit(const EmailVerificationSuccess()) : emit(const EmailVerificationError('رمز التحقق غير صحيح')),
      );
    } catch (e) {
      emit(EmailVerificationError(e.toString()));
    }
  }

  Future<void> _onResend(ResendCodePressed event, Emitter<EmailVerificationState> emit) async {
    emit(const EmailVerificationLoading());
    try {
      final result = await authRepository.resendEmailVerification(userId: event.userId, email: event.email);
      result.fold(
        (failure) => emit(EmailVerificationError(_mapFailureToMessage(failure))),
        (retryAfter) => emit(EmailVerificationCodeResent(retryAfterSeconds: retryAfter)),
      );
    } catch (e) {
      emit(EmailVerificationError(e.toString()));
    }
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case NetworkFailure:
        return 'يرجى التحقق من اتصالك بالإنترنت';
      case ServerFailure:
        return 'حدث خطأ في الخادم. يرجى المحاولة لاحقاً';
      case ValidationFailure:
        return (failure as ValidationFailure).message;
      default:
        return 'حدث خطأ غير متوقع';
    }
  }
}


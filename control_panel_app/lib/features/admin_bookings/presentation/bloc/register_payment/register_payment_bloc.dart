import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/enums/payment_method_enum.dart';
import '../../../domain/entities/booking_details.dart';
import '../../../domain/usecases/register_booking_payment.dart';

part 'register_payment_event.dart';
part 'register_payment_state.dart';

/// 💳 BLoC for managing payment registration
class RegisterPaymentBloc extends Bloc<RegisterPaymentEvent, RegisterPaymentState> {
  final RegisterBookingPaymentUseCase registerBookingPaymentUseCase;

  RegisterPaymentBloc({
    required this.registerBookingPaymentUseCase,
  }) : super(RegisterPaymentInitial()) {
    on<RegisterNewPaymentEvent>(_onRegisterNewPayment);
    on<ResetRegisterPaymentEvent>(_onResetRegisterPayment);
  }

  /// 💳 Handle register new payment event
  Future<void> _onRegisterNewPayment(
    RegisterNewPaymentEvent event,
    Emitter<RegisterPaymentState> emit,
  ) async {
    emit(RegisterPaymentLoading());

    final params = RegisterPaymentParams(
      bookingId: event.bookingId,
      amount: event.amount,
      currency: event.currency,
      paymentMethod: event.paymentMethod,
      transactionId: event.transactionId,
      notes: event.notes,
      paymentDate: event.paymentDate,
    );

    final result = await registerBookingPaymentUseCase(params);

    result.fold(
      (failure) => emit(RegisterPaymentError(failure.message)),
      (payment) => emit(
        RegisterPaymentSuccess(
          payment: payment,
          successMessage: 'تم تسجيل الدفعة بنجاح',
        ),
      ),
    );
  }

  /// 🔄 Handle reset registration form
  void _onResetRegisterPayment(
    ResetRegisterPaymentEvent event,
    Emitter<RegisterPaymentState> emit,
  ) {
    emit(RegisterPaymentInitial());
  }
}

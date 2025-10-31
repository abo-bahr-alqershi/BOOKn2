// lib/features/admin_bookings/presentation/widgets/booking_payment_summary.dart

import 'dart:ui';
import 'package:bookn_cp_app/features/admin_bookings/presentation/bloc/booking_details/booking_details_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/booking.dart' show Booking, Money;
import '../../domain/entities/booking_details.dart'
    show BookingDetails, Payment;
import '../../../../core/enums/payment_method_enum.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../pages/register_payment_page.dart';
import '../bloc/booking_details/booking_details_bloc.dart';
import '../bloc/booking_details/booking_details_event.dart';
import '../bloc/register_payment/register_payment_bloc.dart';
import '../../../../injection_container.dart';

class BookingPaymentSummary extends StatelessWidget {
  final Booking booking;
  final BookingDetails? bookingDetails;
  final List<Payment> payments;
  final VoidCallback? onShowInvoice;
  final BookingDetailsBloc? bookingDetailsBloc;
  final bool isRefreshing;

  const BookingPaymentSummary({
    super.key,
    required this.booking,
    this.bookingDetails,
    List<Payment>? payments,
    this.onShowInvoice,
    this.bookingDetailsBloc,
    this.isRefreshing = false,
  }) : payments = payments ?? const [];

  @override
  Widget build(BuildContext context) {
    final effectivePayments = bookingDetails?.payments ?? payments;
    final totalPriceMoney =
        bookingDetails?.booking.totalPrice ?? booking.totalPrice;
    final totalPaidMoney = bookingDetails?.totalPaid ??
        _calculateTotalPaidMoney(effectivePayments, totalPriceMoney.currency);
    final remainingMoney = bookingDetails?.remainingAmount ??
        _createMoney(totalPriceMoney.amount - totalPaidMoney.amount,
            totalPriceMoney.currency);
    final isFullyPaid = remainingMoney.amount <= 0;
    final isCancelled = booking.status.name == 'cancelled';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowDark.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.darkCard.withOpacity(0.8),
                  AppTheme.darkCard.withOpacity(0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isFullyPaid
                    ? AppTheme.success.withOpacity(0.3)
                    : AppTheme.warning.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                _buildHeader(isFullyPaid),
                _buildSummary(totalPriceMoney, totalPaidMoney, remainingMoney),
                if (effectivePayments.isNotEmpty)
                  _buildPaymentsList(effectivePayments),
                _buildFooter(context, isFullyPaid, isCancelled),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isFullyPaid) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isFullyPaid
              ? [
                  AppTheme.success.withOpacity(0.15),
                  AppTheme.success.withOpacity(0.05),
                ]
              : [
                  AppTheme.warning.withOpacity(0.15),
                  AppTheme.warning.withOpacity(0.05),
                ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isFullyPaid
                    ? [AppTheme.success, AppTheme.success.withOpacity(0.7)]
                    : [AppTheme.warning, AppTheme.warning.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isFullyPaid
                  ? CupertinoIcons.checkmark_seal_fill
                  : CupertinoIcons.clock_fill,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ملخص المدفوعات',
                style: AppTextStyles.heading3.copyWith(
                  color: AppTheme.textWhite,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isFullyPaid
                      ? AppTheme.success.withOpacity(0.1)
                      : AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isFullyPaid ? 'مدفوع بالكامل' : 'دفعة جزئية',
                  style: AppTextStyles.caption.copyWith(
                    color: isFullyPaid ? AppTheme.success : AppTheme.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(
    Money totalPrice,
    Money totalPaid,
    Money remainingMoney,
  ) {
    final hasRemaining = remainingMoney.amount > 0;
    final remainingDisplay = hasRemaining
        ? _formatMoney(remainingMoney)
        : _formatMoney(_createMoney(0, remainingMoney.currency));

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSummaryRow(
            label: 'المبلغ الإجمالي',
            value: _formatMoney(totalPrice),
            icon: CupertinoIcons.tag_fill,
            color: AppTheme.textWhite,
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            label: 'المبلغ المدفوع',
            value: _formatMoney(totalPaid),
            icon: CupertinoIcons.checkmark_circle_fill,
            color: AppTheme.success,
            isLoading: isRefreshing,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: hasRemaining
                    ? [
                        AppTheme.warning.withOpacity(0.15),
                        AppTheme.warning.withOpacity(0.05),
                      ]
                    : [
                        AppTheme.success.withOpacity(0.15),
                        AppTheme.success.withOpacity(0.05),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasRemaining
                    ? AppTheme.warning.withOpacity(0.3)
                    : AppTheme.success.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasRemaining
                      ? CupertinoIcons.exclamationmark_triangle_fill
                      : CupertinoIcons.checkmark_seal_fill,
                  color: hasRemaining ? AppTheme.warning : AppTheme.success,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'المبلغ المتبقي',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: isRefreshing
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              hasRemaining
                                  ? AppTheme.warning
                                  : AppTheme.success,
                            ),
                          ),
                        )
                      : Text(
                          remainingDisplay,
                          style: AppTextStyles.heading2.copyWith(
                            color: hasRemaining
                                ? AppTheme.warning
                                : AppTheme.success,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool isLoading = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: color.withOpacity(0.7),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
        const Spacer(),
        isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
            : Text(
                value,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ],
    );
  }

  Widget _buildPaymentsList(List<Payment> payments) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'سجل المدفوعات',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...payments.map((payment) => _buildPaymentItem(payment)),
        ],
      ),
    );
  }

  Widget _buildPaymentItem(Payment payment) {
    final isSuccessful = payment.status == PaymentStatus.successful;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSuccessful
              ? AppTheme.success.withOpacity(0.2)
              : AppTheme.error.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSuccessful
                  ? AppTheme.success.withOpacity(0.1)
                  : AppTheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getPaymentMethodIcon(payment.method),
              size: 18,
              color: isSuccessful ? AppTheme.success : AppTheme.error,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.method.displayNameAr,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textWhite,
                  ),
                ),
                Text(
                  Formatters.formatDateTime(payment.paymentDate),
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                payment.amount.formattedAmount,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isSuccessful ? AppTheme.success : AppTheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSuccessful
                      ? AppTheme.success.withOpacity(0.1)
                      : AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  payment.status.displayNameAr,
                  style: AppTextStyles.caption.copyWith(
                    color: isSuccessful ? AppTheme.success : AppTheme.error,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isFullyPaid, bool isCancelled) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withOpacity(0.3),
        border: Border(
          top: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.1),
          ),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          if (!isFullyPaid && !isCancelled) ...[
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.warning.withOpacity(0.8),
                      AppTheme.warning,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.warning.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      debugPrint('🔵 Register Payment button tapped');
                      debugPrint('🔵 bookingDetailsBloc: $bookingDetailsBloc');
                      debugPrint(
                          '🔵 bookingDetailsBloc != null: ${bookingDetailsBloc != null}');

                      if (bookingDetailsBloc != null) {
                        debugPrint(
                            '🔵 Bloc state: ${bookingDetailsBloc!.state.runtimeType}');
                        if (bookingDetailsBloc!.state is BookingDetailsLoaded) {
                          final state =
                              bookingDetailsBloc!.state as BookingDetailsLoaded;
                          debugPrint('🔵 Booking ID: ${state.booking.id}');
                          debugPrint(
                              '🔵 Total Amount: ${state.booking.totalPrice.amount}');
                          debugPrint(
                              '🔵 Payments: ${state.bookingDetails?.payments.length ?? 0}');
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MultiBlocProvider(
                              providers: [
                                BlocProvider.value(
                                  value: bookingDetailsBloc!,
                                ),
                                BlocProvider(
                                  create: (context) =>
                                      sl<RegisterPaymentBloc>(),
                                ),
                              ],
                              child: RegisterPaymentPage(
                                bookingId: booking.id,
                              ),
                            ),
                          ),
                        ).then((result) {
                          if (result == true) {
                            bookingDetailsBloc!.add(const RefreshBookingDetailsEvent());
                          }
                        });
                      } else {
                        debugPrint('❌ bookingDetailsBloc is null!');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                const Text('حدث خطأ في تحميل بيانات الحجز'),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            CupertinoIcons.money_dollar_circle,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'تسجيل دفعة',
                            style: AppTextStyles.buttonMedium.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.darkCard.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.darkBorder.withOpacity(0.3),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onShowInvoice,
                  borderRadius: BorderRadius.circular(12),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.doc_text,
                          color: AppTheme.textMuted,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'عرض الفاتورة',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Money _calculateTotalPaidMoney(List<Payment> payments, String currency) {
    final paidAmount = payments
        .where((p) => p.status == PaymentStatus.successful)
        .fold(0.0, (sum, payment) => sum + payment.amount.amount);

    return _createMoney(paidAmount, currency);
  }

  IconData _getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return CupertinoIcons.money_dollar;
      case PaymentMethod.creditCard:
        return CupertinoIcons.creditcard;
      case PaymentMethod.paypal:
        return CupertinoIcons.globe;
      default:
        return CupertinoIcons.device_phone_portrait;
    }
  }

  Money _createMoney(double amount, String currency) {
    return Money(
      amount: amount,
      currency: currency,
      formattedAmount: Formatters.formatCurrency(amount, currency),
    );
  }

  String _formatMoney(Money money) {
    if (money.formattedAmount.trim().isNotEmpty) {
      return money.formattedAmount;
    }
    return Formatters.formatCurrency(money.amount, money.currency);
  }
}

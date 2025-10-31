// lib/features/admin_payments/presentation/pages/payment_details_page.dart

import 'dart:ui';

import 'package:bookn_cp_app/core/enums/payment_method_enum.dart';
import 'package:bookn_cp_app/features/admin_payments/domain/entities/payment_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/utils/formatters.dart';
import '../bloc/payment_details/payment_details_bloc.dart';
import '../bloc/payment_details/payment_details_event.dart';
import '../bloc/payment_details/payment_details_state.dart';
import '../widgets/refund_dialog.dart';
import '../widgets/void_payment_dialog.dart';

class PaymentDetailsPage extends StatefulWidget {
  final String paymentId;

  const PaymentDetailsPage({
    super.key,
    required this.paymentId,
  });

  @override
  State<PaymentDetailsPage> createState() => _PaymentDetailsPageState();
}

class _PaymentDetailsPageState extends State<PaymentDetailsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late ScrollController _scrollController;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scrollController = ScrollController()
      ..addListener(() {
        setState(() {
          _scrollOffset = _scrollController.offset;
        });
      });

    _loadPaymentDetails();
    _animationController.forward();
  }

  void _loadPaymentDetails() {
    context.read<PaymentDetailsBloc>().add(
          LoadPaymentDetailsEvent(paymentId: widget.paymentId),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wrap with WillPopScope for Android back button handling
    // Note: Use PopScope if Flutter version >= 3.16, WillPopScope for older versions
    return WillPopScope(
      onWillPop: () async {
        _handleBackNavigation(context);
        return false; // Prevent default pop
      },
      child: Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: BlocBuilder<PaymentDetailsBloc, PaymentDetailsState>(
          builder: (context, state) {
            if (state is PaymentDetailsLoading) {
              return const LoadingWidget(
                type: LoadingType.futuristic,
                message: 'جاري تحميل تفاصيل الدفعة...',
              );
            }

            if (state is PaymentDetailsError) {
              return CustomErrorWidget(
                message: state.message,
                onRetry: _loadPaymentDetails,
              );
            }

            if (state is PaymentDetailsLoaded) {
              return _buildContent(state);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  void _handleBackNavigation(BuildContext context) {
    HapticFeedback.lightImpact();

    try {
      // Try to pop first (this will work if we came from another page)
      context.pop();
    } catch (e) {
      // If pop fails, navigate to payments list
      // This handles the case when the app is opened directly to this page
      context.go('/admin/payments');
    }
  }

  Widget _buildContent(PaymentDetailsLoaded state) {
    final payment = state.payment;
    final details = state.paymentDetails;

    return Stack(
      children: [
        CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(state),
            SliverToBoxAdapter(
              child: AnimationLimiter(
                child: Column(
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 375),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(child: widget),
                    ),
                    children: [
                      _buildPaymentSummaryCard(state),
                      _buildPaymentInfoCard(state),
                      if (details?.bookingInfo != null)
                        _buildBookingInfoCard(state),
                      if (payment.userName != null || payment.userEmail != null)
                        _buildCustomerInfoCard(state),
                      if (details?.gatewayInfo != null)
                        _buildGatewayInfoCard(state),
                      if (state.refunds.isNotEmpty) _buildRefundsCard(state),
                      if (state.activities.isNotEmpty)
                        _buildActivityTimeline(state),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(PaymentDetailsLoaded state) {
    final payment = state.payment;
    final parallaxOffset = _scrollOffset * 0.5;

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppTheme.darkBackground,
      leading: _buildBackButton(),
      actions: const [], // Actions removed - no share or print buttons
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient background with parallax
            Transform.translate(
              offset: Offset(0, parallaxOffset),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getStatusColor(payment.status).withOpacity(0.3),
                      AppTheme.darkBackground.withOpacity(0.7),
                      AppTheme.darkBackground,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            // Content
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                payment.transactionId.isNotEmpty
                                    ? 'دفعة #${payment.transactionId}'
                                    : payment.id.length >= 8
                                        ? 'دفعة #${payment.id.substring(0, 8).toUpperCase()}'
                                        : 'دفعة #${payment.id.toUpperCase()}',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${payment.amount.amount.toStringAsFixed(payment.amount.currency == "USD" ? 2 : 0)} ${payment.amount.currency}',
                                style: AppTextStyles.heading1.copyWith(
                                  color: AppTheme.textWhite,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildStatusBadge(payment.status),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      icon: CupertinoIcons.calendar,
                      label: 'تاريخ الدفع',
                      value: Formatters.formatDateTime(payment.paymentDate),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _handleBackNavigation(context);
          },
          borderRadius: BorderRadius.circular(12),
          child: Icon(
            CupertinoIcons.arrow_right,
            color: AppTheme.textWhite,
            size: 20,
          ),
        ),
      ),
    );
  }

  // 🏨 Booking Info Card
  Widget _buildBookingInfoCard(PaymentDetailsLoaded state) {
    final bookingInfo = state.paymentDetails!.bookingInfo!;

    return _buildGlassCard(
      title: 'معلومات الحجز',
      icon: CupertinoIcons.building_2_fill,
      child: Column(
        children: [
          _buildDetailRow(
            label: 'رقم الحجز',
            value: bookingInfo.bookingReference,
            icon: CupertinoIcons.number,
          ),
          _buildDetailRow(
            label: 'العقار',
            value: bookingInfo.propertyName,
            icon: CupertinoIcons.home,
          ),
          _buildDetailRow(
            label: 'الوحدة',
            value: bookingInfo.unitName,
            icon: CupertinoIcons.bed_double,
          ),
          _buildDetailRow(
            label: 'عدد الضيوف',
            value: '${bookingInfo.guestsCount} ضيف',
            icon: CupertinoIcons.person_2_fill,
          ),
          _buildDetailRow(
            label: 'تاريخ الوصول',
            value: Formatters.formatDate(bookingInfo.checkIn),
            icon: CupertinoIcons.arrow_down_circle,
          ),
          _buildDetailRow(
            label: 'تاريخ المغادرة',
            value: Formatters.formatDate(bookingInfo.checkOut),
            icon: CupertinoIcons.arrow_up_circle,
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.08),
                    blurRadius: 25,
                    offset: const Offset(0, 12),
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: AppTheme.shadowDark.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.darkCard.withOpacity(0.7),
                          AppTheme.darkCard.withOpacity(0.5),
                          AppTheme.primaryBlue.withOpacity(0.02),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppTheme.primaryBlue.withOpacity(0.15),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                AppTheme.primaryBlue.withOpacity(0.1),
                                Colors.transparent,
                              ],
                            ),
                            border: Border(
                              bottom: BorderSide(
                                color: AppTheme.primaryBlue.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.primaryBlue,
                                      AppTheme.primaryBlue.withOpacity(0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          AppTheme.primaryBlue.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  icon,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                title,
                                style: AppTextStyles.heading3.copyWith(
                                  color: AppTheme.textWhite,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: child,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required IconData icon,
    bool isMultiline = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppTheme.primaryBlue.withOpacity(0.03),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryBlue.withOpacity(0.7),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
              maxLines: isMultiline ? null : 1,
              overflow:
                  isMultiline ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // 🔧 Helper Methods
  Widget _buildStatusBadge(dynamic status) {
    final color = _getStatusColor(status);
    final text = _getStatusText(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textMuted),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: AppTextStyles.bodySmall.copyWith(color: AppTheme.textMuted),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(color: AppTheme.textWhite),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(dynamic status) {
    final statusStr = status.toString().toLowerCase();
    if (statusStr.contains('success')) return AppTheme.success;
    if (statusStr.contains('pending')) return AppTheme.warning;
    if (statusStr.contains('failed')) return AppTheme.error;
    if (statusStr.contains('refund')) return AppTheme.warning;
    if (statusStr.contains('void')) return AppTheme.textMuted;
    return AppTheme.primaryBlue;
  }

  String _getStatusText(dynamic status) {
    final statusStr = status.toString().toLowerCase();
    if (statusStr.contains('success')) return 'مكتمل';
    if (statusStr.contains('pending')) return 'قيد الانتظار';
    if (statusStr.contains('failed')) return 'فشل';
    if (statusStr.contains('refund')) return 'مسترد';
    if (statusStr.contains('void')) return 'ملغي';
    return 'غير معروف';
  }

  // 💰 Payment Summary Card - نفس أسلوب فاتورة الحجز
  Widget _buildPaymentSummaryCard(PaymentDetailsLoaded state) {
    final payment = state.payment;
    final isSuccessful =
        payment.status.toString().toLowerCase().contains('success');

    return TweenAnimationBuilder<double>(
      key: ValueKey('payment_summary_${payment.id}'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: isSuccessful
                        ? AppTheme.success.withOpacity(0.15)
                        : AppTheme.warning.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: AppTheme.shadowDark.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.darkCard.withOpacity(0.9),
                          AppTheme.darkCard.withOpacity(0.7),
                          isSuccessful
                              ? AppTheme.success.withOpacity(0.05)
                              : AppTheme.warning.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: isSuccessful
                            ? AppTheme.success.withOpacity(0.4)
                            : AppTheme.warning.withOpacity(0.4),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryHeader(isSuccessful),
                        _buildSummaryContent(state),
                        _buildSummaryFooter(state),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryHeader(bool isSuccessful) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSuccessful
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
                colors: isSuccessful
                    ? [AppTheme.success, AppTheme.success.withOpacity(0.7)]
                    : [AppTheme.warning, AppTheme.warning.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isSuccessful
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
                'ملخص الدفعة',
                style:
                    AppTextStyles.heading3.copyWith(color: AppTheme.textWhite),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSuccessful
                      ? AppTheme.success.withOpacity(0.1)
                      : AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isSuccessful ? 'دفعة ناجحة' : 'قيد المعالجة',
                  style: AppTextStyles.caption.copyWith(
                    color: isSuccessful ? AppTheme.success : AppTheme.warning,
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

  Widget _buildSummaryContent(PaymentDetailsLoaded state) {
    final payment = state.payment;
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSummaryRow(
            label: 'المبلغ الإجمالي',
            value:
                '${payment.amount.amount.toStringAsFixed(payment.amount.currency == "USD" ? 2 : 0)} ${payment.amount.currency}',
            icon: CupertinoIcons.money_dollar_circle_fill,
            color: AppTheme.textWhite,
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            label: 'طريقة الدفع',
            value: payment.method.displayNameAr ??
                payment.method.displayNameEn ??
                payment.method.name ??
                '',
            icon: CupertinoIcons.creditcard_fill,
            color: AppTheme.primaryBlue,
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            label: 'معرف المعاملة',
            value: payment.transactionId.isNotEmpty
                ? payment.transactionId
                : 'غير متوفر',
            icon: CupertinoIcons.barcode,
            color: AppTheme.textMuted,
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
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color.withOpacity(0.7)),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textMuted),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryFooter(PaymentDetailsLoaded state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withOpacity(0.3),
        border: Border(
          top: BorderSide(color: AppTheme.darkBorder.withOpacity(0.1)),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.calendar, size: 16, color: AppTheme.textMuted),
          const SizedBox(width: 8),
          Text(
            'تاريخ الدفع: ${Formatters.formatDateTime(state.payment.paymentDate)}',
            style: AppTextStyles.caption.copyWith(color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  // 📝 Payment Info Card
  Widget _buildPaymentInfoCard(PaymentDetailsLoaded state) {
    final payment = state.payment;
    return _buildGlassCard(
      title: 'تفاصيل الدفع',
      icon: CupertinoIcons.doc_text_fill,
      child: Column(
        children: [
          _buildDetailRow(
            label: 'معرف الحجز',
            value: payment.bookingId,
            icon: CupertinoIcons.doc,
          ),
          _buildDetailRow(
            label: 'تاريخ الدفع',
            value: Formatters.formatDateTime(payment.paymentDate),
            icon: CupertinoIcons.time,
          ),
          if (payment.description != null)
            _buildDetailRow(
              label: 'الوصف',
              value: payment.description!,
              icon: CupertinoIcons.text_alignleft,
              isMultiline: true,
            ),
          if (payment.notes != null)
            _buildDetailRow(
              label: 'ملاحظات',
              value: payment.notes!,
              icon: CupertinoIcons.text_bubble,
              isMultiline: true,
            ),
        ],
      ),
    );
  }

  // 👤 Customer Info Card
  Widget _buildCustomerInfoCard(PaymentDetailsLoaded state) {
    final payment = state.payment;
    return _buildGlassCard(
      title: 'معلومات العميل',
      icon: CupertinoIcons.person_circle_fill,
      child: Column(
        children: [
          if (payment.userName != null)
            _buildDetailRow(
              label: 'الاسم',
              value: payment.userName!,
              icon: CupertinoIcons.person,
            ),
          if (payment.userEmail != null)
            _buildDetailRow(
              label: 'البريد الإلكتروني',
              value: payment.userEmail!,
              icon: CupertinoIcons.mail,
            ),
          if (payment.userId != null)
            _buildDetailRow(
              label: 'معرف العميل',
              value: payment.userId!,
              icon: CupertinoIcons.person_badge_plus,
            ),
        ],
      ),
    );
  }

  // 💳 Gateway Info Card
  Widget _buildGatewayInfoCard(PaymentDetailsLoaded state) {
    final gatewayInfo = state.paymentDetails!.gatewayInfo!;
    return _buildGlassCard(
      title: 'معلومات بوابة الدفع',
      icon: CupertinoIcons.creditcard_fill,
      child: Column(
        children: [
          _buildDetailRow(
            label: 'اسم البوابة',
            value: gatewayInfo.gatewayName,
            icon: CupertinoIcons.building_2_fill,
          ),
          _buildDetailRow(
            label: 'معرف المعاملة',
            value: gatewayInfo.gatewayTransactionId,
            icon: CupertinoIcons.barcode,
          ),
          if (gatewayInfo.responseCode != null)
            _buildDetailRow(
              label: 'كود الاستجابة',
              value: gatewayInfo.responseCode!,
              icon: CupertinoIcons.checkmark_circle,
            ),
        ],
      ),
    );
  }

  // 💸 Refunds Card
  Widget _buildRefundsCard(PaymentDetailsLoaded state) {
    return _buildGlassCard(
      title: 'الاستردادات',
      icon: CupertinoIcons.arrow_counterclockwise,
      child: Column(
        children: state.refunds.map((refund) {
          final isCompleted = refund.status.name.toLowerCase() == 'completed';
          final color = isCompleted ? AppTheme.success : AppTheme.warning;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.darkBackground.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(CupertinoIcons.money_dollar, size: 18, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${refund.amount.amount.toStringAsFixed(2)} ${refund.amount.currency}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getRefundStatusText(refund.status),
                        style: AppTextStyles.caption.copyWith(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (refund.reason.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    refund.reason,
                    style: AppTextStyles.caption
                        .copyWith(color: AppTheme.textMuted),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ⏱️ Activity Timeline - Beautiful Timeline Design
  Widget _buildActivityTimeline(PaymentDetailsLoaded state) {
    final activities = state.activities.take(10).toList();
    if (activities.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowDark.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.darkCard.withOpacity(0.6),
                  AppTheme.darkCard.withOpacity(0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryBlue.withOpacity(0.15),
                        AppTheme.primaryBlue.withOpacity(0.05),
                      ],
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryBlue,
                              AppTheme.primaryBlue.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryBlue.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          CupertinoIcons.time,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'الخط الزمني للأنشطة',
                        style: AppTextStyles.heading3.copyWith(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryBlue.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.arrow_up_arrow_down_circle_fill,
                              size: 14,
                              color: AppTheme.primaryBlue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${activities.length} نشاط',
                              style: AppTextStyles.caption.copyWith(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Timeline Items
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: activities.asMap().entries.map((entry) {
                      final index = entry.key;
                      final activity = entry.value;
                      final isFirst = index == 0;
                      final isLast = index == activities.length - 1;

                      return _buildTimelineItem(
                        activity: activity,
                        isFirst: isFirst,
                        isLast: isLast,
                        index: index,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required PaymentActivity activity,
    required bool isFirst,
    required bool isLast,
    required int index,
  }) {
    final color = _getActivityColor(activity.action);
    final icon = _getActivityIcon(activity.action);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline Line and Dot
        SizedBox(
          width: 40,
          child: Column(
            children: [
              // Top Line
              if (!isFirst)
                Container(
                  width: 2,
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.primaryBlue.withOpacity(0.3),
                        AppTheme.primaryBlue.withOpacity(0.5),
                      ],
                    ),
                  ),
                ),
              // Dot with animation
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: Duration(milliseconds: 500 + (index * 100)),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            color,
                            color.withOpacity(0.7),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Bottom Line
              if (!isLast)
                Container(
                  width: 2,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.primaryBlue.withOpacity(0.5),
                        AppTheme.primaryBlue.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Content Card
        Expanded(
          child: TweenAnimationBuilder<double>(
            key: ValueKey('activity_$index'),
            tween: Tween<double>(begin: 0, end: 1),
            duration: Duration(milliseconds: 600 + (index * 100)),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(20 * (1 - value), 0),
                child: Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withOpacity(0.1),
                          color.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: color.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                activity.description,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppTheme.textWhite,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _getActivityLabel(activity.action),
                                style: AppTextStyles.caption.copyWith(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.clock,
                                  size: 14,
                                  color: AppTheme.textMuted.withOpacity(0.7),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  Formatters.formatDateTime(activity.timestamp),
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppTheme.textMuted.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                            if (activity.userName != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    CupertinoIcons.person_circle,
                                    size: 14,
                                    color: AppTheme.textMuted.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      activity.userName!,
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppTheme.textMuted.withOpacity(0.7),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getActivityColor(String action) {
    switch (action.toLowerCase()) {
      case 'created':
        return AppTheme.primaryBlue;
      case 'processed':
        return AppTheme.success;
      case 'refunded':
        return AppTheme.warning;
      case 'voided':
        return AppTheme.error;
      case 'updated':
        return AppTheme.info;
      default:
        return AppTheme.textMuted;
    }
  }

  IconData _getActivityIcon(String action) {
    switch (action.toLowerCase()) {
      case 'created':
        return CupertinoIcons.add_circled_solid;
      case 'processed':
        return CupertinoIcons.checkmark_seal_fill;
      case 'refunded':
        return CupertinoIcons.arrow_counterclockwise_circle_fill;
      case 'voided':
        return CupertinoIcons.xmark_seal_fill;
      case 'updated':
        return CupertinoIcons.pencil_circle_fill;
      default:
        return CupertinoIcons.circle_fill;
    }
  }

  String _getActivityLabel(String action) {
    switch (action.toLowerCase()) {
      case 'created':
        return 'إنشاء';
      case 'processed':
        return 'معالجة';
      case 'refunded':
        return 'استرداد';
      case 'voided':
        return 'إلغاء';
      case 'updated':
        return 'تحديث';
      default:
        return action;
    }
  }

  String _getRefundStatusText(dynamic status) {
    final statusStr = status.toString().toLowerCase();
    if (statusStr.contains('completed')) return 'مكتمل';
    if (statusStr.contains('pending')) return 'قيد الانتظار';
    if (statusStr.contains('processing')) return 'جاري المعالجة';
    if (statusStr.contains('failed')) return 'فشل';
    if (statusStr.contains('cancelled')) return 'ملغي';
    return 'غير معروف';
  }
}

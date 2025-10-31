import 'package:bookn_cp_app/features/admin_payments/domain/entities/refund.dart';
import 'package:bookn_cp_app/features/admin_payments/presentation/bloc/payment_refund/payment_refund_bloc.dart';
import 'package:bookn_cp_app/features/admin_payments/presentation/bloc/payment_refund/payment_refund_event.dart';
import 'package:bookn_cp_app/features/admin_payments/presentation/bloc/payment_refund/payment_refund_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/theme/app_dimensions.dart';
import '../../../../../../core/widgets/loading_widget.dart';
import '../../../../../../core/widgets/error_widget.dart';
import '../../../../../../core/widgets/price_widget.dart';

class RefundsManagementPage extends StatefulWidget {
  final String? paymentId;

  const RefundsManagementPage({
    super.key,
    this.paymentId,
  });

  @override
  State<RefundsManagementPage> createState() => _RefundsManagementPageState();
}

class _RefundsManagementPageState extends State<RefundsManagementPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  RefundType _selectedType = RefundType.full;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    if (widget.paymentId != null) {
      context.read<PaymentRefundBloc>().add(
            InitializeRefundEvent(paymentId: widget.paymentId!),
          );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.darkGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: BlocConsumer<PaymentRefundBloc, PaymentRefundState>(
                  listener: (context, state) {
                    if (state is PaymentRefundSuccess) {
                      _showSuccessDialog(state);
                    } else if (state is PaymentRefundFailure) {
                      _showErrorDialog(state);
                    }
                  },
                  builder: (context, state) {
                    if (state is PaymentRefundLoading) {
                      return const LoadingWidget(
                        type: LoadingType.pulse,
                        message: 'جاري التحضير...',
                      );
                    }

                    if (state is PaymentRefundError) {
                      return CustomErrorWidget(
                        message: state.message,
                        type: ErrorType.general,
                        onRetry: widget.paymentId != null
                            ? () {
                                context.read<PaymentRefundBloc>().add(
                                      InitializeRefundEvent(
                                        paymentId: widget.paymentId!,
                                      ),
                                    );
                              }
                            : null,
                      );
                    }

                    if (state is PaymentRefundReady) {
                      return _buildRefundForm(state);
                    }

                    if (state is PaymentRefundProcessing) {
                      return _buildProcessingView(state);
                    }

                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.darkBorder,
                  width: 1,
                ),
              ),
              child: Icon(
                CupertinoIcons.arrow_left,
                color: AppTheme.textWhite,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppTheme.primaryGradient.createShader(bounds),
                  child: Text(
                    'إدارة المستردات',
                    style: AppTextStyles.heading1.copyWith(
                      color: AppTheme.textWhite,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'معالجة طلبات الاسترداد',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundForm(PaymentRefundReady state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment Info Card
          _buildPaymentInfoCard(state),
          const SizedBox(height: 24),

          // Refund Type Selection
          _buildRefundTypeSelection(state),
          const SizedBox(height: 24),

          // Amount Input
          if (_selectedType == RefundType.partial) _buildAmountInput(state),

          // Reason Input
          _buildReasonInput(),
          const SizedBox(height: 24),

          // Refund History
          if (state.refundHistory.isNotEmpty) _buildRefundHistory(state),

          const SizedBox(height: 24),

          // Actions
          _buildActions(state),
        ],
      ),
    );
  }

  Widget _buildPaymentInfoCard(PaymentRefundReady state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.darkBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  CupertinoIcons.creditcard,
                  color: AppTheme.primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'معاملة #${state.payment.transactionId}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppTheme.textWhite,
                      ),
                    ),
                    const SizedBox(height: 4),
                    PriceWidget(
                      price: state.payment.amount.amount,
                      currency: state.payment.amount.currency,
                      displayType: PriceDisplayType.compact,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.darkBackground.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  'المبلغ المتاح للاسترداد',
                  state.availableAmount.formattedAmount,
                  AppTheme.success,
                ),
                if (state.refundHistory.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'المبلغ المسترد سابقاً',
                    '${state.payment.refundedAmount ?? 0} ${state.payment.amount.currency}',
                    AppTheme.warning,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRefundTypeSelection(PaymentRefundReady state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نوع الاسترداد',
          style: AppTextStyles.heading3.copyWith(
            color: AppTheme.textWhite,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTypeOption(
                RefundType.full,
                'استرداد كامل',
                CupertinoIcons.arrow_counterclockwise_circle_fill,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeOption(
                RefundType.partial,
                'استرداد جزئي',
                CupertinoIcons.arrow_counterclockwise_circle,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeOption(RefundType type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
        context.read<PaymentRefundBloc>().add(
              ChangeRefundTypeEvent(refundType: type),
            );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: isSelected ? null : AppTheme.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppTheme.darkBorder,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppTheme.textWhite,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textWhite,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInput(PaymentRefundReady state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'مبلغ الاسترداد',
          style: AppTextStyles.heading3.copyWith(
            color: AppTheme.textWhite,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.darkBorder,
              width: 1,
            ),
          ),
          child: TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppTheme.textWhite,
            ),
            decoration: InputDecoration(
              hintText: 'أدخل المبلغ',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted,
              ),
              prefixIcon: Icon(
                CupertinoIcons.money_dollar,
                color: AppTheme.textMuted,
              ),
              suffixText: state.payment.amount.currency,
              suffixStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildReasonInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'سبب الاسترداد',
          style: AppTextStyles.heading3.copyWith(
            color: AppTheme.textWhite,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.darkBorder,
              width: 1,
            ),
          ),
          child: TextField(
            controller: _reasonController,
            maxLines: 3,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppTheme.textWhite,
            ),
            decoration: InputDecoration(
              hintText: 'اشرح سبب الاسترداد...',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            onChanged: (value) {
              context.read<PaymentRefundBloc>().add(
                    UpdateRefundReasonEvent(reason: value),
                  );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRefundHistory(PaymentRefundReady state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'سجل الاستردادات',
          style: AppTextStyles.heading3.copyWith(
            color: AppTheme.textWhite,
          ),
        ),
        const SizedBox(height: 12),
        ...state.refundHistory.map((refund) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.darkBorder,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      CupertinoIcons.arrow_counterclockwise,
                      color: AppTheme.warning,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          refund.reason,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppTheme.textWhite,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${refund.amount.formattedAmount} • ${refund.requestedAt}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildActions(PaymentRefundReady state) {
    return Row(
      children: [
        Expanded(
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(16),
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppTheme.textWhite,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              onPressed: state.canRefund ? _processRefund : null,
              child: Text(
                'تنفيذ الاسترداد',
                style: AppTextStyles.buttonMedium.copyWith(
                  color: AppTheme.textWhite,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingView(PaymentRefundProcessing state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const LoadingWidget(
              type: LoadingType.circular,
              size: 60,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'جاري معالجة الاسترداد...',
            style: AppTextStyles.heading2.copyWith(
              color: AppTheme.textWhite,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            state.refundAmount.formattedAmount,
            style: AppTextStyles.heading1.copyWith(
              color: AppTheme.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  void _processRefund() {
    // Implement refund processing
    context.read<PaymentRefundBloc>().add(
          const ValidateRefundEvent(),
        );
  }

  void _showSuccessDialog(PaymentRefundSuccess state) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('نجح الاسترداد'),
        content: Text(
          'تم استرداد ${state.refundAmount.formattedAmount} بنجاح',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(PaymentRefundFailure state) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('فشل الاسترداد'),
        content: Text(state.message),
        actions: [
          if (state.canRetry)
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
                context.read<PaymentRefundBloc>().add(
                      const RetryRefundEvent(),
                    );
              },
              child: const Text('إعادة المحاولة'),
            ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }
}

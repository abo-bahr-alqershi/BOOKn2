import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/enums/payment_method_enum.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/booking_details.dart';
import '../bloc/register_payment/register_payment_bloc.dart';
import '../bloc/booking_details/booking_details_bloc.dart';
import '../bloc/booking_details/booking_details_state.dart';
import '../bloc/booking_details/booking_details_event.dart';
import '../widgets/booking_status_badge.dart';

class RegisterPaymentPage extends StatefulWidget {
  final String bookingId;

  const RegisterPaymentPage({
    super.key,
    required this.bookingId,
  });

  @override
  State<RegisterPaymentPage> createState() => _RegisterPaymentPageState();
}

class _RegisterPaymentPageState extends State<RegisterPaymentPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _transactionIdController = TextEditingController();
  final _notesController = TextEditingController();

  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  DateTime _selectedDate = DateTime.now();
  String _currency = 'YER';

  Booking? _booking;
  double _totalAmount = 0;
  double _paidAmount = 0;
  double _remainingAmount = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animationController.forward();
    // تأخير تحميل البيانات حتى يكتمل بناء الـ widget tree
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBookingData();
    });
  }

  void _loadBookingData() {
    if (!mounted) return;

    try {
      final bookingDetailsBloc = context.read<BookingDetailsBloc>();
      // إذا لم تكن البيانات محملة، قم بتحميلها أولاً
      if (bookingDetailsBloc.state is! BookingDetailsLoaded) {
        bookingDetailsBloc
            .add(LoadBookingDetailsEvent(bookingId: widget.bookingId));
        // انتظر قليلاً ثم حاول مرة أخرى
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _loadBookingData();
        });
        return;
      }

      final state = bookingDetailsBloc.state as BookingDetailsLoaded;

      // حساب المبلغ المدفوع - نستخدم كل من bookingDetails.payments و bookingDetails.totalPaid
      final payments = state.bookingDetails?.payments ?? [];
      final paidAmount = state.bookingDetails?.totalPaid.amount ??
          payments
              .where((p) => p.status == PaymentStatus.successful)
              .fold<double>(0.0, (sum, payment) => sum + payment.amount.amount);

      setState(() {
        _booking = state.booking;
        _totalAmount = state.booking.totalPrice.amount;
        _currency = state.booking.totalPrice.currency;
        _paidAmount = paidAmount;
        _remainingAmount = _totalAmount - _paidAmount;

        _amountController.text =
            _remainingAmount > 0 ? _remainingAmount.toStringAsFixed(2) : '0.00';
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading booking data: $e');
      debugPrint('Stack trace: $stackTrace');
      // إذا فشل تحميل البيانات، قم بإغلاق الصفحة
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ في تحميل بيانات الحجز: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _amountController.dispose();
    _transactionIdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitPayment() {
    if (_formKey.currentState?.validate() ?? false) {
      final amount = double.tryParse(_amountController.text) ?? 0;

      context.read<RegisterPaymentBloc>().add(
            RegisterNewPaymentEvent(
              bookingId: widget.bookingId,
              amount: amount,
              currency: _currency,
              paymentMethod: _selectedPaymentMethod,
              transactionId: _transactionIdController.text.isNotEmpty
                  ? _transactionIdController.text
                  : null,
              notes: _notesController.text.isNotEmpty
                  ? _notesController.text
                  : null,
              paymentDate: _selectedDate,
            ),
          );
    }
  }

  void _showSuccessDialog(Payment payment) {
    final navigator = Navigator.of(context);
    BookingDetailsBloc? detailsBloc;
    try {
      detailsBloc = context.read<BookingDetailsBloc>();
    } catch (_) {}

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.success.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.checkmark_circle_fill,
                  color: AppTheme.success,
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'تم تسجيل الدفعة بنجاح',
                style: AppTextStyles.heading2.copyWith(
                  color: AppTheme.textWhite,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'المبلغ: ${Formatters.formatCurrency(payment.amount.amount, payment.amount.currency)}',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        try {
                          detailsBloc?.add(const RefreshBookingDetailsEvent());
                        } catch (e) {
                          debugPrint('Error reloading booking details: $e');
                        }
                        navigator.pop();
                        navigator.pop(true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'حسناً',
                        style: AppTextStyles.buttonMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              CupertinoIcons.xmark_circle_fill,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryBlue,
              onPrimary: Colors.white,
              surface: AppTheme.darkCard,
              onSurface: AppTheme.textWhite,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
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

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkBackground,
            AppTheme.darkCard.withOpacity(0.5),
            AppTheme.darkBackground,
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: Container(
          color: Colors.black54,
          child: const Center(
            child: LoadingWidget(
              type: LoadingType.futuristic,
              message: 'جاري تسجيل الدفعة...',
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkCard,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.arrow_right, color: AppTheme.textWhite),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'تسجيل دفعة جديدة',
          style: AppTextStyles.heading2.copyWith(color: AppTheme.textWhite),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<RegisterPaymentBloc, RegisterPaymentState>(
        listener: (context, state) {
          if (state is RegisterPaymentSuccess) {
            _showSuccessDialog(state.payment);
          } else if (state is RegisterPaymentError) {
            _showErrorSnackBar(state.message);
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              _buildBackground(),
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_booking != null) _buildBookingInfoCard(),
                      const SizedBox(height: 16),
                      _buildPaymentSummaryCard(),
                      const SizedBox(height: 16),
                      _buildPaymentForm(),
                      const SizedBox(height: 24),
                      _buildActionButtons(state is RegisterPaymentLoading),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
              if (state is RegisterPaymentLoading) _buildLoadingOverlay(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookingInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.doc_text_fill, color: AppTheme.primaryBlue),
              const SizedBox(width: 12),
              Text(
                'معلومات الحجز',
                style:
                    AppTextStyles.heading3.copyWith(color: AppTheme.textWhite),
              ),
              const Spacer(),
              BookingStatusBadge(status: _booking!.status),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('الضيف', _booking!.userName),
          _buildInfoRow('الوحدة', _booking!.unitName),
          _buildInfoRow('الوصول', Formatters.formatDate(_booking!.checkIn)),
          _buildInfoRow('المغادرة', Formatters.formatDate(_booking!.checkOut)),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.warning.withOpacity(0.15),
            AppTheme.warning.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          _buildAmountRow('المبلغ الإجمالي', _totalAmount, AppTheme.textWhite),
          const SizedBox(height: 8),
          _buildAmountRow('المبلغ المدفوع', _paidAmount, AppTheme.success),
          const Divider(height: 24),
          _buildAmountRow('المبلغ المتبقي', _remainingAmount, AppTheme.warning),
        ],
      ),
    );
  }

  Widget _buildPaymentForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amount Field
          Text(
            'المبلغ المدفوع',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: AppTheme.textWhite),
            decoration: InputDecoration(
              prefixIcon:
                  Icon(CupertinoIcons.money_dollar, color: AppTheme.warning),
              suffix:
                  Text(_currency, style: TextStyle(color: AppTheme.warning)),
              filled: true,
              fillColor: AppTheme.darkBackground.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'المبلغ مطلوب';
              final amount = double.tryParse(value);
              if (amount == null || amount <= 0) return 'المبلغ غير صحيح';
              if (amount > _remainingAmount) return 'المبلغ يتجاوز المتبقي';
              return null;
            },
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
          ),
          const SizedBox(height: 20),

          // Payment Method
          Text(
            'طريقة الدفع',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.darkBackground.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonFormField<PaymentMethod>(
              initialValue: _selectedPaymentMethod,
              dropdownColor: AppTheme.darkCard,
              style: TextStyle(color: AppTheme.textWhite),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: PaymentMethod.values.map((method) {
                return DropdownMenuItem(
                  value: method,
                  child: Row(
                    children: [
                      Icon(_getPaymentMethodIcon(method),
                          color: AppTheme.primaryBlue, size: 20),
                      const SizedBox(width: 8),
                      Text(method.displayNameAr),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null)
                  setState(() => _selectedPaymentMethod = value);
              },
            ),
          ),
          const SizedBox(height: 20),

          // Transaction ID
          Text(
            'رقم المعاملة (اختياري)',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _transactionIdController,
            style: TextStyle(color: AppTheme.textWhite),
            decoration: InputDecoration(
              prefixIcon:
                  Icon(CupertinoIcons.number, color: AppTheme.primaryBlue),
              filled: true,
              fillColor: AppTheme.darkBackground.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Date Picker
          Text(
            'تاريخ الدفع',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _selectDate(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.darkBackground.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(CupertinoIcons.calendar, color: AppTheme.primaryBlue),
                  const SizedBox(width: 12),
                  Text(
                    Formatters.formatDate(_selectedDate),
                    style: TextStyle(color: AppTheme.textWhite),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isLoading) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : _submitPayment,
            icon: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: Colors.white,
                  ),
            label: Text(
              isLoading ? 'جاري التسجيل...' : 'تسجيل الدفعة',
              style: AppTextStyles.buttonMedium.copyWith(
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warning,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'إلغاء',
            style: TextStyle(color: AppTheme.textMuted),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: AppTheme.textMuted)),
          const Spacer(),
          Text(value, style: TextStyle(color: AppTheme.textWhite)),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, double amount, Color color) {
    return Row(
      children: [
        Text(label, style: TextStyle(color: AppTheme.textMuted)),
        const Spacer(),
        Text(
          Formatters.formatCurrency(amount, _currency),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../utils/formatters.dart';

/// Payment Identity Card Tooltip - بطاقة المدفوعة المنبثقة
class PaymentIdentityCardTooltip {
  static OverlayEntry? _overlayEntry;
  static final GlobalKey<_PaymentCardContentState> _contentKey = GlobalKey();

  static void show({
    required BuildContext context,
    required GlobalKey targetKey,
    required String paymentId,
    required String transactionId,
    required double amount,
    required String currency,
    required String paymentMethod,
    required String status,
    required DateTime paymentDate,
    String? userName,
    String? userEmail,
    String? bookingId,
    String? propertyName,
    String? unitName,
    String? gatewayTransactionId,
    String? processedBy,
    DateTime? processedAt,
    double? refundedAmount,
    DateTime? refundedAt,
    String? refundReason,
    String? refundTransactionId,
    bool? isVoided,
    DateTime? voidedAt,
    String? voidReason,
    String? notes,
  }) {
    hide();

    _overlayEntry = OverlayEntry(
      builder: (context) => _PaymentCardOverlay(
        targetKey: targetKey,
        paymentId: paymentId,
        transactionId: transactionId,
        amount: amount,
        currency: currency,
        paymentMethod: paymentMethod,
        status: status,
        paymentDate: paymentDate,
        userName: userName,
        userEmail: userEmail,
        bookingId: bookingId,
        propertyName: propertyName,
        unitName: unitName,
        gatewayTransactionId: gatewayTransactionId,
        processedBy: processedBy,
        processedAt: processedAt,
        refundedAmount: refundedAmount,
        refundedAt: refundedAt,
        refundReason: refundReason,
        refundTransactionId: refundTransactionId,
        isVoided: isVoided,
        voidedAt: voidedAt,
        voidReason: voidReason,
        notes: notes,
        contentKey: _contentKey,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static void hide() {
    _contentKey.currentState?.animateOut(() {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }
}

class _PaymentCardOverlay extends StatelessWidget {
  final GlobalKey targetKey;
  final String paymentId;
  final String transactionId;
  final double amount;
  final String currency;
  final String paymentMethod;
  final String status;
  final DateTime paymentDate;
  final String? userName;
  final String? userEmail;
  final String? bookingId;
  final String? propertyName;
  final String? unitName;
  final String? gatewayTransactionId;
  final String? processedBy;
  final DateTime? processedAt;
  final double? refundedAmount;
  final DateTime? refundedAt;
  final String? refundReason;
  final String? refundTransactionId;
  final bool? isVoided;
  final DateTime? voidedAt;
  final String? voidReason;
  final String? notes;
  final GlobalKey<_PaymentCardContentState> contentKey;

  const _PaymentCardOverlay({
    required this.targetKey,
    required this.paymentId,
    required this.transactionId,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.status,
    required this.paymentDate,
    this.userName,
    this.userEmail,
    this.bookingId,
    this.propertyName,
    this.unitName,
    this.gatewayTransactionId,
    this.processedBy,
    this.processedAt,
    this.refundedAmount,
    this.refundedAt,
    this.refundReason,
    this.refundTransactionId,
    this.isVoided,
    this.voidedAt,
    this.voidReason,
    this.notes,
    required this.contentKey,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => PaymentIdentityCardTooltip.hide(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black54,
        child: Stack(
          children: [
            _PaymentCardContent(
              key: contentKey,
              targetKey: targetKey,
              paymentId: paymentId,
              transactionId: transactionId,
              amount: amount,
              currency: currency,
              paymentMethod: paymentMethod,
              status: status,
              paymentDate: paymentDate,
              userName: userName,
              userEmail: userEmail,
              bookingId: bookingId,
              propertyName: propertyName,
              unitName: unitName,
              gatewayTransactionId: gatewayTransactionId,
              processedBy: processedBy,
              processedAt: processedAt,
              refundedAmount: refundedAmount,
              refundedAt: refundedAt,
              refundReason: refundReason,
              refundTransactionId: refundTransactionId,
              isVoided: isVoided,
              voidedAt: voidedAt,
              voidReason: voidReason,
              notes: notes,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentCardContent extends StatefulWidget {
  final GlobalKey targetKey;
  final String paymentId;
  final String transactionId;
  final double amount;
  final String currency;
  final String paymentMethod;
  final String status;
  final DateTime paymentDate;
  final String? userName;
  final String? userEmail;
  final String? bookingId;
  final String? propertyName;
  final String? unitName;
  final String? gatewayTransactionId;
  final String? processedBy;
  final DateTime? processedAt;
  final double? refundedAmount;
  final DateTime? refundedAt;
  final String? refundReason;
  final String? refundTransactionId;
  final bool? isVoided;
  final DateTime? voidedAt;
  final String? voidReason;
  final String? notes;

  const _PaymentCardContent({
    super.key,
    required this.targetKey,
    required this.paymentId,
    required this.transactionId,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.status,
    required this.paymentDate,
    this.userName,
    this.userEmail,
    this.bookingId,
    this.propertyName,
    this.unitName,
    this.gatewayTransactionId,
    this.processedBy,
    this.processedAt,
    this.refundedAmount,
    this.refundedAt,
    this.refundReason,
    this.refundTransactionId,
    this.isVoided,
    this.voidedAt,
    this.voidReason,
    this.notes,
  });

  @override
  State<_PaymentCardContent> createState() => _PaymentCardContentState();
}

class _PaymentCardContentState extends State<_PaymentCardContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void animateOut(VoidCallback onComplete) {
    _controller.reverse().then((_) => onComplete());
  }

  Color _getStatusColor() {
    switch (widget.status.toLowerCase()) {
      case 'successful':
      case 'completed':
        return AppTheme.success;
      case 'pending':
        return AppTheme.warning;
      case 'failed':
      case 'voided':
        return AppTheme.error;
      case 'refunded':
      case 'partiallyrefunded':
        return AppTheme.primaryCyan;
      default:
        return AppTheme.textMuted;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.status.toLowerCase()) {
      case 'successful':
      case 'completed':
        return CupertinoIcons.checkmark_seal_fill;
      case 'pending':
        return CupertinoIcons.time_solid;
      case 'failed':
        return CupertinoIcons.xmark_circle_fill;
      case 'voided':
        return CupertinoIcons.slash_circle_fill;
      case 'refunded':
        return CupertinoIcons.arrow_counterclockwise_circle_fill;
      case 'partiallyrefunded':
        return CupertinoIcons.arrow_2_circlepath_circle_fill;
      default:
        return CupertinoIcons.creditcard_fill;
    }
  }

  String _getStatusText() {
    switch (widget.status.toLowerCase()) {
      case 'successful':
        return 'ناجح';
      case 'completed':
        return 'مكتمل';
      case 'pending':
        return 'قيد الانتظار';
      case 'failed':
        return 'فاشل';
      case 'voided':
        return 'ملغى';
      case 'refunded':
        return 'مسترد';
      case 'partiallyrefunded':
        return 'مسترد جزئياً';
      default:
        return widget.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final statusColor = _getStatusColor();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Center(
              child: Container(
                width: isMobile ? size.width * 0.9 : 400,
                constraints: BoxConstraints(maxHeight: size.height * 0.85),
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildHeader(statusColor),
                            _buildContent(),
                          ],
                        ),
                      ),
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

  Widget _buildHeader(Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(16), // 🎯 تقليل padding
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withOpacity(0.15), // 🎯 شفافية أقل
            statusColor.withOpacity(0.03),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: statusColor.withOpacity(0.15), // 🎯 حدود أخف
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [statusColor, statusColor.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getStatusIcon(),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'معاملة مالية',
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textMuted,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '#${widget.transactionId}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor.withOpacity(0.5),
                  ),
                ),
                child: Text(
                  _getStatusText(),
                  style: AppTextStyles.caption.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.darkBackground.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المبلغ',
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textMuted,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.formatCurrency(widget.amount, widget.currency),
                      style: AppTextStyles.heading2.copyWith(
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
                Icon(
                  CupertinoIcons.money_dollar_circle_fill,
                  color: statusColor,
                  size: 40,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16), // 🎯 تقليل padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            'معلومات الدفع',
            CupertinoIcons.creditcard_fill,
            [
              _buildInfoRow('طريقة الدفع', widget.paymentMethod),
              _buildInfoRow(
                'تاريخ المعاملة',
                Formatters.formatDateTime(widget.paymentDate),
              ),
              if (widget.gatewayTransactionId != null)
                _buildInfoRow('رقم بوابة الدفع', widget.gatewayTransactionId!),
            ],
          ),
          if (widget.userName != null || widget.bookingId != null) ...[
            const SizedBox(height: 12), // 🎯 تقليل المسافة
            _buildSection(
              'معلومات العميل والحجز',
              CupertinoIcons.person_2_fill,
              [
                if (widget.userName != null)
                  _buildInfoRow('اسم العميل', widget.userName!),
                if (widget.userEmail != null)
                  _buildInfoRow('البريد الإلكتروني', widget.userEmail!),
                if (widget.bookingId != null)
                  _buildInfoRow('رقم الحجز', widget.bookingId!),
                if (widget.propertyName != null)
                  _buildInfoRow('العقار', widget.propertyName!),
                if (widget.unitName != null)
                  _buildInfoRow('الوحدة', widget.unitName!),
              ],
            ),
          ],
          if (widget.processedBy != null || widget.processedAt != null) ... [
            const SizedBox(height: 12),
            _buildSection(
              'معلومات المعالجة',
              CupertinoIcons.checkmark_shield_fill,
              [
                if (widget.processedBy != null)
                  _buildInfoRow('تمت المعالجة بواسطة', widget.processedBy!),
                if (widget.processedAt != null)
                  _buildInfoRow(
                    'وقت المعالجة',
                    Formatters.formatDateTime(widget.processedAt!),
                  ),
              ],
            ),
          ],
          if (widget.refundedAmount != null && widget.refundedAmount! > 0) ... [
            const SizedBox(height: 12),
            _buildSection(
              'معلومات الاسترداد',
              CupertinoIcons.arrow_counterclockwise_circle_fill,
              [
                _buildInfoRow(
                  'المبلغ المسترد',
                  Formatters.formatCurrency(
                      widget.refundedAmount!, widget.currency),
                ),
                if (widget.refundedAt != null)
                  _buildInfoRow(
                    'تاريخ الاسترداد',
                    Formatters.formatDateTime(widget.refundedAt!),
                  ),
                if (widget.refundReason != null)
                  _buildInfoRow('سبب الاسترداد', widget.refundReason!),
                if (widget.refundTransactionId != null)
                  _buildInfoRow(
                    'رقم معاملة الاسترداد',
                    widget.refundTransactionId!,
                  ),
              ],
            ),
          ],
          if (widget.isVoided == true) ... [
            const SizedBox(height: 12),
            _buildSection(
              'معلومات الإلغاء',
              CupertinoIcons.slash_circle_fill,
              [
                if (widget.voidedAt != null)
                  _buildInfoRow(
                    'تاريخ الإلغاء',
                    Formatters.formatDateTime(widget.voidedAt!),
                  ),
                if (widget.voidReason != null)
                  _buildInfoRow('سبب الإلغاء', widget.voidReason!),
              ],
            ),
          ],
          if (widget.notes != null && widget.notes!.isNotEmpty) ... [
            const SizedBox(height: 12),
            _buildSection(
              'ملاحظات',
              CupertinoIcons.doc_text_fill,
              [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.darkBackground.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.notes!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.textWhite,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.primaryBlue, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textMuted,
                decoration: TextDecoration.none, // 🎯 إزالة الخط الأصفر
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textWhite,
                decoration: TextDecoration.none, // 🎯 إزالة الخط الأصفر
              ),
              textAlign: TextAlign.end,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

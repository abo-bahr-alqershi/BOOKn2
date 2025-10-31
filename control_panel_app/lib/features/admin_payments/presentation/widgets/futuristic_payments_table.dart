import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../../domain/entities/payment.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/theme/app_dimensions.dart';
import '../../../../../../core/widgets/price_widget.dart';
import 'payment_status_indicator.dart';
import 'payment_method_icon.dart';
import 'futuristic_payment_card.dart';

class FuturisticPaymentsTable extends StatefulWidget {
  final List<Payment> payments;
  final Function(Payment) onPaymentTap;
  final Function(Payment)? onRefundTap;
  final Function(Payment)? onVoidTap;
  final bool showActions;
  final bool isLoading;
  final double? height;
  final bool forceCardView; // خيار لفرض عرض الكروت

  const FuturisticPaymentsTable({
    super.key,
    required this.payments,
    required this.onPaymentTap,
    this.onRefundTap,
    this.onVoidTap,
    this.showActions = true,
    this.isLoading = false,
    this.height,
    this.forceCardView = false,
  });

  @override
  State<FuturisticPaymentsTable> createState() =>
      _FuturisticPaymentsTableState();
}

class _FuturisticPaymentsTableState extends State<FuturisticPaymentsTable>
    with TickerProviderStateMixin {
  final ScrollController _horizontalScrollController = ScrollController();
  // ❌ _verticalScrollController محذوف - الـ scroll من الخارج
  late List<AnimationController> _rowAnimationControllers;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;
  int? _hoveredRowIndex;
  int? _selectedPaymentIndex;
  bool _isGridView = false;
  final Set<String> _selectedPayments = {};

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _rowAnimationControllers = List.generate(
      widget.payments.length,
      (index) => AnimationController(
        duration: Duration(milliseconds: 300 + (index * 50)),
        vsync: this,
      ),
    );

    _fadeAnimations = _rowAnimationControllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeIn,
      ));
    }).toList();

    _slideAnimations = _rowAnimationControllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(0.2, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutCubic,
      ));
    }).toList();

    // Start animations
    Future.forEach(_rowAnimationControllers, (controller) async {
      await Future.delayed(const Duration(milliseconds: 50));
      if (mounted) controller.forward();
    });
  }

  @override
  void didUpdateWidget(FuturisticPaymentsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.payments.length == oldWidget.payments.length) {
      return;
    }

    final grew = widget.payments.length > oldWidget.payments.length;
    final bool samePrefix = _hasSamePrefix(oldWidget.payments, widget.payments);

    if (grew && samePrefix) {
      final startIndex = oldWidget.payments.length;
      final addCount = widget.payments.length - oldWidget.payments.length;
      _appendAnimations(startIndex, addCount);
      for (var i = startIndex; i < _rowAnimationControllers.length; i++) {
        final controller = _rowAnimationControllers[i];
        if (mounted && controller.status == AnimationStatus.dismissed) {
          controller.forward();
        }
      }
    } else {
      for (var controller in _rowAnimationControllers) {
        controller.dispose();
      }
      _initializeAnimations();
    }
  }

  @override
  void dispose() {
    for (var controller in _rowAnimationControllers) {
      controller.dispose();
    }
    _horizontalScrollController.dispose();
    // ❌ _verticalScrollController محذوف
    super.dispose();
  }

  bool _hasSamePrefix(List<Payment> oldList, List<Payment> newList) {
    if (newList.length < oldList.length) return false;
    for (var i = 0; i < oldList.length; i++) {
      if (oldList[i].id != newList[i].id) return false;
    }
    return true;
    }

  void _appendAnimations(int startIndex, int count) {
    for (var i = 0; i < count; i++) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 300 + ((startIndex + i) * 50)),
        vsync: this,
      );
      _rowAnimationControllers.add(controller);
      _fadeAnimations.add(Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeIn),
      ));
      _slideAnimations.add(Tween<Offset>(begin: const Offset(0.2, 0), end: Offset.zero).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    // التحقق من حجم الشاشة للريسبونسيف
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isMediumScreen = screenSize.width >= 600 && screenSize.width < 1200;
    final isLargeScreen = screenSize.width >= 1200;

    // تحديد عدد الأعمدة للـ Grid
    int crossAxisCount = 1;
    if (isMediumScreen) crossAxisCount = 2;
    if (isLargeScreen) crossAxisCount = 3;

    return LayoutBuilder(
      builder: (context, constraints) {
        // استخدام الكروت للشاشات الصغيرة أو إذا تم فرض عرض الكروت
        if (isSmallScreen || widget.forceCardView || _isGridView) {
          return _buildResponsiveCardView(
            constraints: constraints,
            crossAxisCount: crossAxisCount,
            isSmallScreen: isSmallScreen,
          );
        }

        // للشاشات الكبيرة، عرض الجدول مع خيار التبديل
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildViewToggle(),
            const SizedBox(height: 16),
            Expanded(
              child: _buildTableView(constraints),
            ),
          ],
        );
      },
    );
  }

  // زر التبديل بين العرض الجدولي والكروت
  Widget _buildViewToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.darkCard.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.darkBorder.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _buildToggleButton(
                  icon: CupertinoIcons.list_bullet,
                  isActive: !_isGridView,
                  onTap: () => setState(() => _isGridView = false),
                ),
                const SizedBox(width: 4),
                _buildToggleButton(
                  icon: CupertinoIcons.square_grid_2x2,
                  isActive: _isGridView,
                  onTap: () => setState(() => _isGridView = true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: isActive ? AppTheme.primaryGradient : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isActive ? Colors.white : AppTheme.textMuted,
        ),
      ),
    );
  }

  // عرض الكروت الريسبونسيف
  Widget _buildResponsiveCardView({
    required BoxConstraints constraints,
    required int crossAxisCount,
    required bool isSmallScreen,
  }) {
    if (widget.isLoading) {
      return _buildLoadingState();
    }

    if (widget.payments.isEmpty) {
      return _buildEmptyState();
    }

    // حساب الـ aspect ratio المناسب
    double aspectRatio = isSmallScreen ? 1.4 : 1.6;

    return Container(
      // ❌ لا height محدد - يجعل الجدول جزء من scroll الرئيسي
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min, // 🎯 مهم!
            children: [
              // Header مع إحصائيات
              if (!isSmallScreen) _buildCardsHeader(),

              // قائمة الكروت - 🎯 بدون Expanded + shrinkWrap
              GridView.builder(
                // ❌ لا controller - الـ scroll من الخارج
                shrinkWrap: true, // 🎯 مثل الحجوزات
                physics: const NeverScrollableScrollPhysics(), // 🎯 مثل الحجوزات
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: aspectRatio,
                ),
                itemCount: widget.payments.length,
                itemBuilder: (context, index) {
                    final payment = widget.payments[index];
                    final isSelected = _selectedPayments.contains(payment.id);

                    return AnimatedBuilder(
                      animation: _fadeAnimations[index],
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _fadeAnimations[index],
                          child: SlideTransition(
                            position: _slideAnimations[index],
                            child: ResponsivePaymentCard(
                              payment: payment,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() {
                                  _selectedPaymentIndex = index;
                                });
                                widget.onPaymentTap(payment);
                              },
                              onLongPress: () {
                                setState(() {
                                  if (_selectedPayments.contains(payment.id)) {
                                    _selectedPayments.remove(payment.id);
                                  } else {
                                    _selectedPayments.add(payment.id);
                                  }
                                });
                              },
                              onRefundTap: widget.onRefundTap != null
                                  ? () => widget.onRefundTap!(payment)
                                  : null,
                              onVoidTap: widget.onVoidTap != null
                                  ? () => widget.onVoidTap!(payment)
                                  : null,
                              showActions: widget.showActions,
                              isCompact: isSmallScreen,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

              // Footer مع عدد المحدد
              if (_selectedPayments.isNotEmpty) _buildSelectionFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // Header للكروت
  Widget _buildCardsHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withValues(alpha: 0.1),
            AppTheme.primaryPurple.withValues(alpha: 0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.creditcard,
            color: AppTheme.primaryBlue,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'إجمالي المدفوعات: ${widget.payments.length}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (_selectedPayments.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_selectedPayments.length} محدد',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Footer للعناصر المحددة
  Widget _buildSelectionFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.8),
        border: Border(
          top: BorderSide(
            color: AppTheme.darkBorder.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${_selectedPayments.length} عنصر محدد',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedPayments.clear();
              });
            },
            child: Text(
              'إلغاء التحديد',
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // عرض الجدول (الكود الأصلي محسّن)
  Widget _buildTableView(BoxConstraints constraints) {
    final containerHeight = widget.height ?? constraints.maxHeight * 0.8;

    return Container(
      height: containerHeight,
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Flexible(
                child: _buildTableContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withValues(alpha: 0.1),
            AppTheme.primaryPurple.withValues(alpha: 0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildHeaderCell('المعاملة', flex: 2),
          _buildHeaderCell('العميل', flex: 2),
          _buildHeaderCell('المبلغ', flex: 2),
          _buildHeaderCell('الطريقة', flex: 1),
          _buildHeaderCell('الحالة', flex: 1),
          _buildHeaderCell('التاريخ', flex: 2),
          if (widget.showActions) _buildHeaderCell('الإجراءات', flex: 2),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: AppTheme.textMuted,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTableContent() {
    if (widget.isLoading) {
      return _buildLoadingState();
    }

    if (widget.payments.isEmpty) {
      return _buildEmptyState();
    }

    // 🎯 بدون Scrollbar ولا controller - الـ scroll من الخارج
    return ListView.builder(
        shrinkWrap: true, // 🎯 مثل الحجوزات
        physics: const NeverScrollableScrollPhysics(), // 🎯 مثل الحجوزات
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: widget.payments.length,
        itemBuilder: (context, index) {
          return FadeTransition(
            opacity: _fadeAnimations[index],
            child: SlideTransition(
              position: _slideAnimations[index],
              child: _buildTableRow(widget.payments[index], index),
            ),
          );
        },
      );
  }

  Widget _buildTableRow(Payment payment, int index) {
    final isHovered = _hoveredRowIndex == index;
    final isSelected = _selectedPaymentIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRowIndex = index),
      onExit: (_) => setState(() => _hoveredRowIndex = null),
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedPaymentIndex = index);
          widget.onPaymentTap(payment);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            gradient: isSelected
                ? AppTheme.primaryGradient.scale(0.2)
                : isHovered
                    ? LinearGradient(
                        colors: [
                          AppTheme.darkCard.withValues(alpha: 0.8),
                          AppTheme.darkCard.withValues(alpha: 0.6),
                        ],
                      )
                    : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryBlue.withValues(alpha: 0.3)
                  : isHovered
                      ? AppTheme.darkBorder.withValues(alpha: 0.5)
                      : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Transaction ID
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${payment.transactionId}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppTheme.textWhite,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (payment.invoiceNumber != null)
                            Text(
                              'فاتورة: ${payment.invoiceNumber}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppTheme.textMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Customer
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.userName ?? 'غير محدد',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppTheme.textWhite,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (payment.userEmail != null)
                      Text(
                        payment.userEmail!,
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Amount
              Expanded(
                flex: 2,
                child: PriceWidget(
                  price: payment.amount.amount,
                  currency: payment.amount.currency,
                  displayType: PriceDisplayType.normal,
                  priceStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Method
              Expanded(
                flex: 1,
                child: PaymentMethodIcon(
                  method: payment.method,
                  size: 24,
                  showLabel: false,
                ),
              ),

              // Status
              Expanded(
                flex: 1,
                child: PaymentStatusIndicator(
                  status: payment.status,
                  size: PaymentStatusSize.small,
                ),
              ),

              // Date
              Expanded(
                flex: 2,
                child: Text(
                  _formatDate(payment.paymentDate),
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ),

              // Actions
              if (widget.showActions)
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (payment.canRefund && widget.onRefundTap != null)
                        _buildActionButton(
                          icon: CupertinoIcons.arrow_counterclockwise,
                          color: AppTheme.warning,
                          onTap: () => widget.onRefundTap!(payment),
                        ),
                      const SizedBox(width: 8),
                      if (payment.canVoid && widget.onVoidTap != null)
                        _buildActionButton(
                          icon: CupertinoIcons.xmark_circle,
                          color: AppTheme.error,
                          onTap: () => widget.onVoidTap!(payment),
                        ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: CupertinoIcons.eye,
                        color: AppTheme.primaryBlue,
                        onTap: () => widget.onPaymentTap(payment),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                shape: BoxShape.circle,
              ),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'جاري تحميل المدفوعات...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.darkCard.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.creditcard,
                color: AppTheme.textMuted,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد مدفوعات',
              style: AppTextStyles.heading3.copyWith(
                color: AppTheme.textWhite,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'لم يتم العثور على أي مدفوعات',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// كارت المدفوعات الريسبونسيف المحسّن
class ResponsivePaymentCard extends StatelessWidget {
  final Payment payment;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onRefundTap;
  final VoidCallback? onVoidTap;
  final bool showActions;
  final bool isCompact;

  const ResponsivePaymentCard({
    super.key,
    required this.payment,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
    this.onRefundTap,
    this.onVoidTap,
    this.showActions = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return FuturisticPaymentCard(
      payment: payment,
      isSelected: isSelected,
      onTap: onTap,
      onLongPress: onLongPress,
      onRefundTap: onRefundTap,
      onVoidTap: onVoidTap,
      showActions: showActions,
    );
  }
}

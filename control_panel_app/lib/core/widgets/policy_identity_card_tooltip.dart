import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../utils/formatters.dart';
import '../../features/admin_properties/domain/entities/policy.dart';

/// Policy Identity Card Tooltip - بطاقة السياسة المنبثقة
class PolicyIdentityCardTooltip {
  static OverlayEntry? _overlayEntry;
  static final GlobalKey<_PolicyCardContentState> _contentKey = GlobalKey();

  static void show({
    required BuildContext context,
    required GlobalKey targetKey,
    required String policyId,
    required PolicyType policyType,
    required String description,
    required String rules,
    required bool isActive,
    String? propertyName,
    DateTime? effectiveDate,
  }) {
    hide();

    _overlayEntry = OverlayEntry(
      builder: (context) => _PolicyCardOverlay(
        targetKey: targetKey,
        policyId: policyId,
        policyType: policyType,
        description: description,
        rules: rules,
        isActive: isActive,
        propertyName: propertyName,
        effectiveDate: effectiveDate,
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

class _PolicyCardOverlay extends StatelessWidget {
  final GlobalKey targetKey;
  final String policyId;
  final PolicyType policyType;
  final String description;
  final String rules;
  final bool isActive;
  final String? propertyName;
  final DateTime? effectiveDate;
  final GlobalKey<_PolicyCardContentState> contentKey;

  const _PolicyCardOverlay({
    required this.targetKey,
    required this.policyId,
    required this.policyType,
    required this.description,
    required this.rules,
    required this.isActive,
    this.propertyName,
    this.effectiveDate,
    required this.contentKey,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: PolicyIdentityCardTooltip.hide,
          child: Container(
            color: Colors.black.withOpacity(0.3),
          ),
        ),
        _PolicyCardContent(
          key: contentKey,
          targetKey: targetKey,
          policyId: policyId,
          policyType: policyType,
          description: description,
          rules: rules,
          isActive: isActive,
          propertyName: propertyName,
          effectiveDate: effectiveDate,
        ),
      ],
    );
  }
}

class _PolicyCardContent extends StatefulWidget {
  final GlobalKey targetKey;
  final String policyId;
  final PolicyType policyType;
  final String description;
  final String rules;
  final bool isActive;
  final String? propertyName;
  final DateTime? effectiveDate;

  const _PolicyCardContent({
    super.key,
    required this.targetKey,
    required this.policyId,
    required this.policyType,
    required this.description,
    required this.rules,
    required this.isActive,
    this.propertyName,
    this.effectiveDate,
  });

  @override
  State<_PolicyCardContent> createState() => _PolicyCardContentState();
}

class _PolicyCardContentState extends State<_PolicyCardContent>
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

  Color get statusColor {
    if (!widget.isActive) return AppTheme.error;
    return _getPolicyColor();
  }

  Color _getPolicyColor() {
    switch (widget.policyType) {
      case PolicyType.cancellation:
        return AppTheme.error;
      case PolicyType.checkIn:
        return AppTheme.success;
      case PolicyType.checkOut:
        return AppTheme.warning;
      case PolicyType.payment:
        return AppTheme.primaryBlue;
      case PolicyType.smoking:
        return AppTheme.primaryPurple;
      case PolicyType.pets:
        return AppTheme.primaryCyan;
      case PolicyType.damage:
        return AppTheme.error;
      case PolicyType.other:
        return AppTheme.textMuted;
    }
  }

  IconData _getPolicyIcon() {
    switch (widget.policyType) {
      case PolicyType.cancellation:
        return CupertinoIcons.xmark_circle_fill;
      case PolicyType.checkIn:
        return CupertinoIcons.arrow_down_circle_fill;
      case PolicyType.checkOut:
        return CupertinoIcons.arrow_up_circle_fill;
      case PolicyType.payment:
        return CupertinoIcons.money_dollar_circle_fill;
      case PolicyType.smoking:
        return CupertinoIcons.smoke_fill;
      case PolicyType.pets:
        return CupertinoIcons.paw_solid;
      case PolicyType.damage:
        return CupertinoIcons.exclamationmark_triangle_fill;
      case PolicyType.other:
        return CupertinoIcons.doc_text_fill;
    }
  }

  String _getPolicyLabel() {
    switch (widget.policyType) {
      case PolicyType.cancellation:
        return 'سياسة الإلغاء';
      case PolicyType.checkIn:
        return 'تسجيل الدخول';
      case PolicyType.checkOut:
        return 'تسجيل الخروج';
      case PolicyType.payment:
        return 'الدفع';
      case PolicyType.smoking:
        return 'التدخين';
      case PolicyType.pets:
        return 'الحيوانات الأليفة';
      case PolicyType.damage:
        return 'الأضرار';
      case PolicyType.other:
        return 'أخرى';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Center(
              child: Container(
                width: isMobile ? size.width * 0.9 : 380,
                constraints: BoxConstraints(maxHeight: size.height * 0.8),
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
                          color: statusColor.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: DefaultTextStyle(
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppTheme.textWhite,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildHeader(),
                            Flexible(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    _buildIconSection(),
                                    const SizedBox(height: 16),
                                    if (widget.propertyName != null)
                                      _buildInfoCard(
                                        CupertinoIcons.building_2_fill,
                                        'العقار',
                                        widget.propertyName!,
                                        AppTheme.primaryBlue,
                                      ),
                                    if (widget.propertyName != null)
                                      const SizedBox(height: 12),
                                    _buildInfoCard(
                                      CupertinoIcons.doc_text,
                                      'الوصف',
                                      widget.description,
                                      AppTheme.primaryPurple,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildRulesCard(),
                                    if (widget.effectiveDate != null) ...[
                                      const SizedBox(height: 12),
                                      _buildInfoCard(
                                        CupertinoIcons.calendar,
                                        'تاريخ السريان',
                                        Formatters.formatDate(
                                            widget.effectiveDate!),
                                        AppTheme.primaryCyan,
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    _buildPolicyId(),
                                  ],
                                ),
                              ),
                            ),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: statusColor.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              CupertinoIcons.doc_text_search,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'بطاقة السياسة',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: PolicyIdentityCardTooltip.hide,
            icon: Icon(
              CupertinoIcons.xmark_circle_fill,
              color: AppTheme.textMuted,
              size: 22,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildIconSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Large Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [statusColor, statusColor.withOpacity(0.6)],
              ),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              _getPolicyIcon(),
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          // Policy Type
          Text(
            _getPolicyLabel(),
            style: AppTextStyles.heading2.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: statusColor.withOpacity(0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.isActive ? 'نشطة' : 'غير نشطة',
                  style: AppTextStyles.caption.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.warning.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.list_bullet,
                size: 16,
                color: AppTheme.warning,
              ),
              const SizedBox(width: 8),
              Text(
                'القواعد والشروط',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.rules,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textLight,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyId() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.number,
            size: 12,
            color: AppTheme.textMuted,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'ID: ${widget.policyId}',
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted,
                fontFamily: 'monospace',
                fontSize: 9,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

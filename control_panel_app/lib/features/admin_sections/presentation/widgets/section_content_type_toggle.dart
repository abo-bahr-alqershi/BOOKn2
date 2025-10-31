import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/enums/section_content_type.dart';

class SectionContentTypeToggle extends StatefulWidget {
  final SectionContentType? selectedType;
  final Function(SectionContentType) onTypeSelected;
  final bool isCompact;
  final bool showDescriptions;

  const SectionContentTypeToggle({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
    this.isCompact = false,
    this.showDescriptions = true,
  });

  @override
  State<SectionContentTypeToggle> createState() =>
      _SectionContentTypeToggleState();
}

class _SectionContentTypeToggleState extends State<SectionContentTypeToggle>
    with TickerProviderStateMixin {
  late AnimationController _selectionController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  int _hoveredIndex = -1;

  final List<_ContentTypeInfo> _types = [
    _ContentTypeInfo(
      type: SectionContentType.properties,
      label: 'عقارات',
      description: 'عرض العقارات فقط',
      icon: CupertinoIcons.building_2_fill,
      gradient: [AppTheme.primaryBlue, AppTheme.primaryCyan],
    ),
    _ContentTypeInfo(
      type: SectionContentType.units,
      label: 'وحدات',
      description: 'عرض الوحدات فقط',
      icon: CupertinoIcons.house_fill,
      gradient: [AppTheme.primaryPurple, AppTheme.primaryViolet],
    ),
    _ContentTypeInfo(
      type: SectionContentType.mixed,
      label: 'مختلط',
      description: 'عرض العقارات والوحدات',
      icon: CupertinoIcons.square_stack_3d_up_fill,
      gradient: [AppTheme.warning, AppTheme.neonPurple],
    ),
    _ContentTypeInfo(
      type: SectionContentType.none,
      label: 'بدون عناصر',
      description: 'لن يتم عرض عقارات أو وحدات لهذا القسم',
      icon: CupertinoIcons.eye_slash_fill,
      gradient: [AppTheme.textMuted, AppTheme.darkBorder],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _selectionController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _selectionController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppTheme.primaryGradient.createShader(bounds),
              child: Text(
                'نوع المحتوى',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'مطلوب',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        widget.isCompact ? _buildCompactToggle() : _buildFullToggle(),
      ],
    );
  }

  Widget _buildFullToggle() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withValues(alpha: 0.3),
            AppTheme.darkCard.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: _types.asMap().entries.map((entry) {
                    final index = entry.key;
                    final info = entry.value;
                    final isSelected = widget.selectedType == info.type;
                    final isFirst = index == 0;
                    final isLast = index == _types.length - 1;

                    return Expanded(
                      child: MouseRegion(
                        onEnter: (_) => setState(() => _hoveredIndex = index),
                        onExit: (_) => setState(() => _hoveredIndex = -1),
                        child: GestureDetector(
                          onTap: () {
                            widget.onTypeSelected(info.type);
                            _selectionController.forward().then((_) {
                              _selectionController.reverse();
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            transform: Matrix4.identity()
                              ..scale(_hoveredIndex == index ? 1.02 : 1.0),
                            child: _buildOption(
                              info: info,
                              isSelected: isSelected,
                              isFirst: isFirst,
                              isLast: isLast,
                              showDescription: widget.showDescriptions,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (widget.showDescriptions) _buildDescriptionBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactToggle() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withValues(alpha: 0.3),
            AppTheme.darkCard.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            children: _types.asMap().entries.map((entry) {
              final index = entry.key;
              final info = entry.value;
              final isSelected = widget.selectedType == info.type;
              final isFirst = index == 0;
              final isLast = index == _types.length - 1;

              return Expanded(
                child: GestureDetector(
                  onTap: () => widget.onTypeSelected(info.type),
                  child: _buildCompactOption(
                    info: info,
                    isSelected: isSelected,
                    isFirst: isFirst,
                    isLast: isLast,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildOption({
    required _ContentTypeInfo info,
    required bool isSelected,
    required bool isFirst,
    required bool isLast,
    required bool showDescription,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: isSelected ? LinearGradient(colors: info.gradient) : null,
        borderRadius: BorderRadius.horizontal(
          left: isLast ? const Radius.circular(11) : Radius.zero,
          right: isFirst ? const Radius.circular(11) : Radius.zero,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: info.gradient.first.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          // Animated background effect for selected
          if (isSelected)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _PulseEffectPainter(
                      color: Colors.white,
                      animationValue: _pulseController.value,
                    ),
                  );
                },
              ),
            ),
          // Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.2)
                        : info.gradient.first.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.3)
                          : info.gradient.first.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    info.icon,
                    color: isSelected
                        ? Colors.white
                        : _hoveredIndex == _types.indexOf(info)
                            ? info.gradient.first
                            : AppTheme.textMuted,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                info.label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isSelected ? Colors.white : AppTheme.textWhite,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
              if (showDescription) ...[
                const SizedBox(height: 2),
                Text(
                  info.description,
                  style: AppTextStyles.caption.copyWith(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.9)
                        : AppTheme.textMuted.withValues(alpha: 0.7),
                    fontSize: 9,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactOption({
    required _ContentTypeInfo info,
    required bool isSelected,
    required bool isFirst,
    required bool isLast,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: isSelected ? LinearGradient(colors: info.gradient) : null,
        borderRadius: BorderRadius.horizontal(
          left: isLast ? const Radius.circular(11) : Radius.zero,
          right: isFirst ? const Radius.circular(11) : Radius.zero,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            info.icon,
            color: isSelected ? Colors.white : AppTheme.textMuted,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            info.label,
            style: AppTextStyles.caption.copyWith(
              color: isSelected ? Colors.white : AppTheme.textMuted,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionBar() {
    final selectedInfo = _types.firstWhere(
      (info) => info.type == widget.selectedType,
      orElse: () => _types.first,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            selectedInfo.gradient.first.withValues(alpha: 0.05),
            selectedInfo.gradient.last.withValues(alpha: 0.02),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: selectedInfo.gradient.first.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.info_circle_fill,
            size: 16,
            color: selectedInfo.gradient.first,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getDetailedDescription(widget.selectedType),
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDetailedDescription(SectionContentType? type) {
    switch (type) {
      case SectionContentType.properties:
        return 'سيتم عرض العقارات فقط في هذا القسم، مع إمكانية التصفية حسب النوع والموقع والسعر';
      case SectionContentType.units:
        return 'سيتم عرض الوحدات السكنية فقط، مع إمكانية التصفية حسب السعة والمرافق والتوفر';
      case SectionContentType.mixed:
        return 'سيتم عرض مزيج من العقارات والوحدات في نفس القسم، مما يوفر تنوعاً أكبر للمستخدمين';
      case SectionContentType.none:
        return 'هذا القسم لن يعرض عناصر عقارات أو وحدات، مناسب للأقسام المعلوماتية أو الإعلانية المخصصة';
      default:
        return 'اختر نوع المحتوى المناسب لهذا القسم';
    }
  }
}

// Helper class for content type info
class _ContentTypeInfo {
  final SectionContentType type;
  final String label;
  final String description;
  final IconData icon;
  final List<Color> gradient;

  _ContentTypeInfo({
    required this.type,
    required this.label,
    required this.description,
    required this.icon,
    required this.gradient,
  });
}

// Custom painter for pulse effect
class _PulseEffectPainter extends CustomPainter {
  final Color color;
  final double animationValue;

  _PulseEffectPainter({
    required this.color,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    // Draw multiple pulse layers
    for (int i = 0; i < 2; i++) {
      paint.color = color.withValues(
        alpha: (0.05 - (i * 0.02)) * (1 - animationValue),
      );

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          -5.0 - (i * 10 * animationValue),
          -5.0 - (i * 10 * animationValue),
          size.width + 10 + (i * 20 * animationValue),
          size.height + 10 + (i * 20 * animationValue),
        ),
        const Radius.circular(11),
      );

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

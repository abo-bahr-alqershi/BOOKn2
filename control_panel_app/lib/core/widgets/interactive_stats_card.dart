import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import 'glassmorphic_tooltip.dart';

/// Interactive Stats Card with Glassmorphic Tooltip
/// بطاقة إحصائيات تفاعلية مع tooltip زجاجي
class InteractiveStatsCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;
  final bool isPositive;
  final String? detailedDescription;
  final Map<String, dynamic>? additionalStats;

  const InteractiveStatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.isPositive = true,
    this.detailedDescription,
    this.additionalStats,
  });

  @override
  State<InteractiveStatsCard> createState() => _InteractiveStatsCardState();
}

class _InteractiveStatsCardState extends State<InteractiveStatsCard>
    with SingleTickerProviderStateMixin {
  final GlobalKey _cardKey = GlobalKey();
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleLongPress() {
    setState(() => _isPressed = true);
    _scaleController.forward();

    // Build detailed message with stats
    final String message = _buildDetailedMessage();

    // Show tooltip
    GlasmorphicTooltip.show(
      context: context,
      targetKey: _cardKey,
      title: widget.title,
      message: message,
      accentColor: widget.color,
      icon: widget.icon,
      duration: const Duration(seconds: 5),
    );

    // Reset scale after tooltip appears
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _scaleController.reverse();
        setState(() => _isPressed = false);
      }
    });
  }

  String _buildDetailedMessage() {
    String description = widget.detailedDescription ?? 'اضغط للمزيد من التفاصيل';
    
    // Add value prominently
    String message = '📊 القيمة الحالية: ${widget.value}\n\n';
    message += description;
    
    // Add additional stats if available
    if (widget.additionalStats != null && widget.additionalStats!.isNotEmpty) {
      message += '\n\n📈 تفاصيل إضافية:';
      widget.additionalStats!.forEach((key, value) {
        message += '\n• $key: $value';
      });
    }
    
    return message;
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        key: _cardKey,
        onLongPress: _handleLongPress,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.color.withValues(alpha: 0.1),
                widget.color.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isPressed
                  ? widget.color.withValues(alpha: 0.6)
                  : widget.color.withValues(alpha: 0.3),
              width: _isPressed ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _isPressed ? 0.3 : 0.1),
                blurRadius: _isPressed ? 15 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.color,
                      size: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.value,
                      style: AppTextStyles.heading2.copyWith(
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  // Long press indicator
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppTheme.textMuted.withValues(alpha: 0.5),
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

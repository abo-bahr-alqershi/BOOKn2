import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../../domain/entities/payment_details.dart';
import '../../domain/entities/refund.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/theme/app_dimensions.dart';

class PaymentTimelineWidget extends StatefulWidget {
  final List<PaymentActivity> activities;
  final List<Refund> refunds;

  const PaymentTimelineWidget({
    super.key,
    required this.activities,
    required this.refunds,
  });

  @override
  State<PaymentTimelineWidget> createState() => _PaymentTimelineWidgetState();
}

class _PaymentTimelineWidgetState extends State<PaymentTimelineWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _itemControllers;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    final itemCount = widget.activities.length + widget.refunds.length;
    _itemControllers = List.generate(
      itemCount,
      (index) => AnimationController(
        duration: Duration(milliseconds: 300 + (index * 50)),
        vsync: this,
      ),
    );

    _fadeAnimations = _itemControllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeIn,
      ));
    }).toList();

    _slideAnimations = _itemControllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(-0.2, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutCubic,
      ));
    }).toList();

    // Start animations
    Future.forEach(_itemControllers, (controller) async {
      await Future.delayed(const Duration(milliseconds: 50));
      if (mounted) controller.forward();
    });
  }

  @override
  void dispose() {
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Combine and sort timeline items
    final timelineItems = _buildTimelineItems();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkCard.withValues(alpha: 0.8),
            AppTheme.darkCard.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              _buildHeader(),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _isExpanded ? null : 0,
                child: _isExpanded
                    ? ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        itemCount: timelineItems.length,
                        itemBuilder: (context, index) {
                          if (index < _fadeAnimations.length) {
                            return FadeTransition(
                              opacity: _fadeAnimations[index],
                              child: SlideTransition(
                                position: _slideAnimations[index],
                                child: _buildTimelineItem(
                                  timelineItems[index],
                                  index == 0,
                                  index == timelineItems.length - 1,
                                ),
                              ),
                            );
                          }
                          return _buildTimelineItem(
                            timelineItems[index],
                            index == 0,
                            index == timelineItems.length - 1,
                          );
                        },
                      )
                    : const SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                CupertinoIcons.time,
                color: AppTheme.textWhite,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'السجل الزمني',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppTheme.textWhite,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.activities.length + widget.refunds.length} عملية',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                CupertinoIcons.chevron_down,
                color: AppTheme.textWhite,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<TimelineItem> _buildTimelineItems() {
    final items = <TimelineItem>[];

    // Add activities
    for (var activity in widget.activities) {
      items.add(TimelineItem(
        type: TimelineItemType.activity,
        title: activity.action,
        description: activity.description,
        timestamp: activity.timestamp,
        userName: activity.userName,
        data: activity,
      ));
    }

    // Add refunds
    for (var refund in widget.refunds) {
      items.add(TimelineItem(
        type: TimelineItemType.refund,
        title: 'استرداد ${refund.type == RefundType.full ? "كامل" : "جزئي"}',
        description: refund.reason,
        timestamp: refund.requestedAt,
        userName: refund.processedBy,
        data: refund,
      ));
    }

    // Sort by timestamp
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return items;
  }

  Widget _buildTimelineItem(TimelineItem item, bool isFirst, bool isLast) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Line & Dot
          Column(
            children: [
              if (!isFirst)
                Container(
                  width: 2,
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.primaryBlue.withValues(alpha: 0.3),
                        AppTheme.primaryBlue.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: _getItemGradient(item.type),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getItemColor(item.type).withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    _getItemIcon(item.type),
                    color: AppTheme.textWhite,
                    size: 20,
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.primaryBlue.withValues(alpha: 0.1),
                        AppTheme.primaryBlue.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.darkBackground.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getItemColor(item.type).withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppTheme.textWhite,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _getItemColor(item.type).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _formatTime(item.timestamp),
                          style: AppTextStyles.caption.copyWith(
                            color: _getItemColor(item.type),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                  if (item.userName != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.person_fill,
                          color: AppTheme.textMuted,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.userName!,
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (item.type == TimelineItemType.refund) ...[
                    const SizedBox(height: 8),
                    _buildRefundDetails(item.data as Refund),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundDetails(Refund refund) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.warning.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'المبلغ المسترد',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
              Text(
                refund.amount.formattedAmount,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.warning,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (refund.transactionId != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'رقم المعاملة',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
                Text(
                  refund.transactionId!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textWhite,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  LinearGradient _getItemGradient(TimelineItemType type) {
    switch (type) {
      case TimelineItemType.activity:
        return AppTheme.primaryGradient;
      case TimelineItemType.refund:
        return LinearGradient(
          colors: [
            AppTheme.warning,
            AppTheme.warning.withValues(alpha: 0.7),
          ],
        );
    }
  }

  Color _getItemColor(TimelineItemType type) {
    switch (type) {
      case TimelineItemType.activity:
        return AppTheme.primaryBlue;
      case TimelineItemType.refund:
        return AppTheme.warning;
    }
  }

  IconData _getItemIcon(TimelineItemType type) {
    switch (type) {
      case TimelineItemType.activity:
        return CupertinoIcons.doc_text_fill;
      case TimelineItemType.refund:
        return CupertinoIcons.arrow_counterclockwise_circle_fill;
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inHours < 1) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inDays < 1) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

class TimelineItem {
  final TimelineItemType type;
  final String title;
  final String description;
  final DateTime timestamp;
  final String? userName;
  final dynamic data;

  TimelineItem({
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    this.userName,
    this.data,
  });
}

enum TimelineItemType {
  activity,
  refund,
}

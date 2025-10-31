// lib/features/home/presentation/widgets/common/refresh_indicator_widget.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class FuturisticRefreshIndicator extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const FuturisticRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  State<FuturisticRefreshIndicator> createState() =>
      _FuturisticRefreshIndicatorState();
}

class _FuturisticRefreshIndicatorState extends State<FuturisticRefreshIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        _rotationController.repeat();
        await widget.onRefresh();
        _rotationController.stop();
        _rotationController.reset();
      },
      color: AppTheme.primaryBlue,
      backgroundColor: AppTheme.darkCard,
      strokeWidth: 3,
      displacement: 80,
      child: widget.child,
    );
  }
}

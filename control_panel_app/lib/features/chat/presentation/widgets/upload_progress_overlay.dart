import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

class UploadProgressOverlay extends StatefulWidget {
  final List<UploadTask> tasks;
  final VoidCallback? onCancel;

  const UploadProgressOverlay({
    super.key,
    required this.tasks,
    this.onCancel,
  });

  @override
  State<UploadProgressOverlay> createState() => _UploadProgressOverlayState();
}

class _UploadProgressOverlayState extends State<UploadProgressOverlay>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completedTasks = widget.tasks.where((t) => t.isCompleted).length;
    final failedTasks = widget.tasks.where((t) => t.isFailed).length;
    final totalProgress = widget.tasks.fold<double>(
          0,
          (sum, task) => sum + task.progress,
        ) /
        widget.tasks.length;

    return SlideTransition(
      position: _slideAnimation,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.darkCard.withValues(alpha: 0.9),
                      AppTheme.darkCard.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      children: [
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.primaryBlue
                                          .withValues(alpha: 0.2),
                                      AppTheme.primaryPurple
                                          .withValues(alpha: 0.1),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.cloud_upload_rounded,
                                  color: AppTheme.primaryBlue
                                      .withValues(alpha: 0.8),
                                  size: 18,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'جاري رفع الصور',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '$completedTasks من ${widget.tasks.length} مكتمل',
                                style: AppTextStyles.caption.copyWith(
                                  color:
                                      AppTheme.textMuted.withValues(alpha: 0.6),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.onCancel != null)
                          GestureDetector(
                            onTap: widget.onCancel,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppTheme.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.close,
                                color: AppTheme.error.withValues(alpha: 0.7),
                                size: 16,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Overall progress
                    _buildOverallProgress(totalProgress),

                    const SizedBox(height: 12),

                    // Individual tasks
                    ...widget.tasks.map((task) => _buildTaskProgress(task)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverallProgress(double progress) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(
            AppTheme.primaryBlue.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskProgress(UploadTask task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: task.isFailed
                    ? AppTheme.error.withValues(alpha: 0.3)
                    : task.isCompleted
                        ? AppTheme.success.withValues(alpha: 0.3)
                        : AppTheme.primaryBlue.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: task.thumbnail != null
                  ? Image.file(
                      task.thumbnail!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: AppTheme.darkCard,
                      child: Icon(
                        Icons.image,
                        color: AppTheme.textMuted.withValues(alpha: 0.3),
                        size: 20,
                      ),
                    ),
            ),
          ),

          const SizedBox(width: 12),

          // Progress info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.fileName,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (task.isFailed)
                      Icon(
                        Icons.error_outline,
                        color: AppTheme.error.withValues(alpha: 0.7),
                        size: 14,
                      )
                    else if (task.isCompleted)
                      Icon(
                        Icons.check_circle,
                        color: AppTheme.success.withValues(alpha: 0.7),
                        size: 14,
                      )
                    else
                      Text(
                        '${(task.progress * 100).toInt()}%',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(1),
                    child: LinearProgressIndicator(
                      value: task.progress,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        task.isFailed
                            ? AppTheme.error.withValues(alpha: 0.6)
                            : task.isCompleted
                                ? AppTheme.success.withValues(alpha: 0.6)
                                : AppTheme.primaryBlue.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class UploadTask {
  final String id;
  final String fileName;
  final File? thumbnail;
  double progress;
  bool isCompleted;
  bool isFailed;
  String? error;

  UploadTask({
    required this.id,
    required this.fileName,
    this.thumbnail,
    this.progress = 0.0,
    this.isCompleted = false,
    this.isFailed = false,
    this.error,
  });
}

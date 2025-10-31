import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yemen_booking_app/features/chat/presentation/widgets/online_status_indicator.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../domain/entities/conversation.dart';

class ParticipantItemWidget extends StatelessWidget {
  final ChatUser participant;
  final bool isAdmin;
  final bool isCurrentUser;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const ParticipantItemWidget({
    super.key,
    required this.participant,
    this.isAdmin = false,
    this.isCurrentUser = false,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap != null ? () {
          HapticFeedback.selectionClick();
          onTap!();
        } : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          child: Row(
            children: [
              _buildCompactAvatar(),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNameRow(),
                    if (participant.isOnline || participant.lastSeen != null)
                      _buildStatusText(),
                  ],
                ),
              ),
              if (onRemove != null)
                _buildRemoveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactAvatar() {
    return Stack(
      children: [
        Container(
          width: 42, // Reduced from 48
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryBlue.withOpacity(0.08),
                AppTheme.primaryPurple.withOpacity(0.04),
              ],
            ),
            border: Border.all(
              color: participant.isOnline
                  ? AppTheme.success.withOpacity(0.3)
                  : AppTheme.darkBorder.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          child: participant.profileImage != null
              ? ClipOval(
                  child: CachedImageWidget(
                    imageUrl: participant.profileImage!,
                    width: 42,
                    height: 42,
                    fit: BoxFit.cover,
                  ),
                )
              : Center(
                  child: Text(
                    _getInitials(participant.name),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppTheme.primaryBlue.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
        ),
        if (participant.isOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: OnlineStatusIndicator(
              isOnline: true,
              size: 10,
              showBorder: true,
            ),
          ),
      ],
    );
  }

  Widget _buildNameRow() {
    return Row(
      children: [
        Expanded(
          child: Text(
            participant.name,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        if (isCurrentUser)
          _buildMinimalBadge(
            label: 'أنت',
            gradient: [
              AppTheme.primaryBlue.withOpacity(0.1),
              AppTheme.primaryPurple.withOpacity(0.05),
            ],
            textColor: AppTheme.primaryBlue,
          ),
        if (isAdmin)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: _buildMinimalBadge(
              label: 'مشرف',
              gradient: [
                AppTheme.warning.withOpacity(0.1),
                const Color(0xFFF97316).withOpacity(0.05),
              ],
              textColor: AppTheme.warning,
            ),
          ),
      ],
    );
  }

  Widget _buildMinimalBadge({
    required String label,
    required List<Color> gradient,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: textColor.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildStatusText() {
    String statusText;
    Color statusColor;
    
    if (participant.isOnline) {
      statusText = 'متصل الآن';
      statusColor = AppTheme.success;
    } else if (participant.lastSeen != null) {
      statusText = 'آخر ظهور ${_formatLastSeen(participant.lastSeen!)}';
      statusColor = AppTheme.textMuted.withOpacity(0.6);
    } else {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        statusText,
        style: AppTextStyles.caption.copyWith(
          color: statusColor,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildRemoveButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onRemove!();
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.error.withOpacity(0.1),
              AppTheme.error.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.remove_circle_outline_rounded,
          color: AppTheme.error.withOpacity(0.8),
          size: 18,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes}د';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours}س';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else {
      return 'منذ ${difference.inDays}ي';
    }
  }
}
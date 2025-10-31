// lib/features/chat/presentation/widgets/conversation_item_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../domain/entities/conversation.dart';

class ConversationItemWidget extends StatelessWidget {
  final Conversation conversation;
  final String currentUserId;
  final List<String> typingUserIds;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ConversationItemWidget({
    super.key,
    required this.conversation,
    required this.currentUserId,
    this.typingUserIds = const [],
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final otherParticipant = conversation.isDirectChat
        ? conversation.getOtherParticipant(currentUserId)
        : null;

    final displayName = conversation.title ??
        otherParticipant?.name ??
        'محادثة';

    final displayImage = conversation.avatar ??
        otherParticipant?.profileImage;

    final isTyping = typingUserIds.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        onLongPress: onLongPress != null ? () {
          HapticFeedback.lightImpact();
          onLongPress!();
        } : null,
        borderRadius: BorderRadius.circular(0),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppTheme.darkBorder.withOpacity(0.03),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              _buildUltraMinimalAvatar(displayImage, displayName),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: conversation.hasUnreadMessages
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              fontSize: 13,
                              color: AppTheme.textWhite.withOpacity(
                                conversation.hasUnreadMessages ? 0.95 : 0.8
                              ),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conversation.isMuted)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Icon(
                              Icons.notifications_off,
                              size: 10,
                              color: AppTheme.textMuted.withOpacity(0.3),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(conversation.lastMessage?.createdAt ??
                              conversation.updatedAt),
                          style: AppTextStyles.caption.copyWith(
                            color: conversation.hasUnreadMessages
                                ? AppTheme.primaryBlue.withOpacity(0.7)
                                : AppTheme.textMuted.withOpacity(0.4),
                            fontSize: 10,
                            fontWeight: conversation.hasUnreadMessages
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (conversation.lastMessage != null &&
                            conversation.lastMessage!.senderId == currentUserId)
                          _buildUltraMinimalStatus(conversation.lastMessage!.status),
                        Expanded(
                          child: isTyping
                              ? _buildUltraMinimalTyping()
                              : _buildUltraMinimalLastMessage(),
                        ),
                        if (conversation.hasUnreadMessages)
                          _buildUltraMinimalBadge(),
                      ],
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

  Widget _buildUltraMinimalAvatar(String? imageUrl, String name) {
    return Stack(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: conversation.hasUnreadMessages
                ? LinearGradient(
                    colors: [
                      AppTheme.primaryBlue.withOpacity(0.1),
                      AppTheme.primaryPurple.withOpacity(0.05),
                    ],
                  )
                : null,
            color: !conversation.hasUnreadMessages
                ? AppTheme.darkCard.withOpacity(0.05)
                : null,
            border: Border.all(
              color: conversation.hasUnreadMessages
                  ? AppTheme.primaryBlue.withOpacity(0.2)
                  : AppTheme.darkBorder.withOpacity(0.05),
              width: 0.5,
            ),
          ),
          child: ClipOval(
            child: imageUrl != null
                ? CachedImageWidget(
                    imageUrl: imageUrl,
                    width: 42,
                    height: 42,
                    fit: BoxFit.cover,
                  )
                : Center(
                    child: Text(
                      _getInitials(name),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: conversation.hasUnreadMessages
                            ? AppTheme.primaryBlue.withOpacity(0.7)
                            : AppTheme.textMuted.withOpacity(0.5),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
          ),
        ),
        if (conversation.isDirectChat && conversation.getOtherParticipant(currentUserId)?.isOnline == true)
          Positioned(
            bottom: 1,
            right: 1,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.9),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.darkBackground,
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUltraMinimalStatus(String status) {
    IconData icon;
    Color color;
    double size = 12;

    switch (status) {
      case 'sent':
        icon = Icons.check;
        color = AppTheme.textMuted.withOpacity(0.3);
        break;
      case 'delivered':
        icon = Icons.done_all;
        color = AppTheme.textMuted.withOpacity(0.3);
        break;
      case 'read':
        icon = Icons.done_all;
        color = AppTheme.primaryBlue.withOpacity(0.6);
        break;
      case 'failed':
        icon = Icons.error_outline;
        color = AppTheme.error.withOpacity(0.6);
        size = 11;
        break;
      default:
        icon = Icons.schedule;
        color = AppTheme.textMuted.withOpacity(0.2);
        size = 11;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Icon(
        icon,
        size: size,
        color: color,
      ),
    );
  }

  Widget _buildUltraMinimalLastMessage() {
    if (conversation.lastMessage == null) {
      return Text(
        'ابدأ المحادثة',
        style: AppTextStyles.caption.copyWith(
          color: AppTheme.textMuted.withOpacity(0.3),
          fontStyle: FontStyle.italic,
          fontSize: 11,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    String messageText = '';
    Widget? prefix;

    switch (conversation.lastMessage!.messageType) {
      case 'text':
        messageText = conversation.lastMessage!.content ?? '';
        break;
      case 'image':
        prefix = Icon(Icons.image, size: 12, 
            color: AppTheme.textMuted.withOpacity(0.3));
        messageText = 'صورة';
        break;
      case 'video':
        prefix = Icon(Icons.videocam, size: 12,
            color: AppTheme.textMuted.withOpacity(0.3));
        messageText = 'فيديو';
        break;
      case 'audio':
        prefix = Icon(Icons.mic, size: 12,
            color: AppTheme.textMuted.withOpacity(0.3));
        messageText = 'رسالة صوتية';
        break;
      case 'document':
        prefix = Icon(Icons.attach_file, size: 12,
            color: AppTheme.textMuted.withOpacity(0.3));
        messageText = 'مستند';
        break;
      case 'location':
        prefix = Icon(Icons.location_on, size: 12,
            color: AppTheme.textMuted.withOpacity(0.3));
        messageText = 'موقع';
        break;
    }

    return Row(
      children: [
        if (prefix != null) ...[
          prefix,
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Text(
            messageText,
            style: AppTextStyles.caption.copyWith(
              color: conversation.hasUnreadMessages
                  ? AppTheme.textWhite.withOpacity(0.7)
                  : AppTheme.textMuted.withOpacity(0.4),
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildUltraMinimalTyping() {
    return Row(
      children: [
        Text(
          'يكتب',
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.primaryBlue.withOpacity(0.6),
            fontStyle: FontStyle.italic,
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 12,
          height: 6,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (index) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.3, end: 1),
                duration: Duration(milliseconds: 300 + (index * 100)),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Container(
                    width: 2,
                    height: 2,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(value * 0.6),
                      shape: BoxShape.circle,
                    ),
                  );
                },
                onEnd: () {},
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildUltraMinimalBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withOpacity(0.8),
            AppTheme.primaryPurple.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      constraints: const BoxConstraints(
        minWidth: 14,
        minHeight: 14,
      ),
      child: Center(
        child: Text(
          conversation.unreadCount > 99
              ? '99+'
              : conversation.unreadCount.toString(),
          style: AppTextStyles.caption.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 8,
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
    );

    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'أمس';
    } else if (now.difference(dateTime).inDays < 7) {
      final days = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
      return days[dateTime.weekday % 7];
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '؟';
    if (parts.length == 1) {
      return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '؟';
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../domain/entities/conversation.dart';

class ChatAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Conversation conversation;
  final String currentUserId;
  final VoidCallback onBackPressed;
  final VoidCallback onInfoPressed;
  final VoidCallback? onCallPressed;
  final VoidCallback? onVideoCallPressed;

  const ChatAppBar({
    super.key,
    required this.conversation,
    required this.currentUserId,
    required this.onBackPressed,
    required this.onInfoPressed,
    this.onCallPressed,
    this.onVideoCallPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(52); // Reduced from 56

  @override
  State<ChatAppBar> createState() => _ChatAppBarState();
}

class _ChatAppBarState extends State<ChatAppBar> 
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final otherParticipant = widget.conversation.isDirectChat
        ? widget.conversation.getOtherParticipant(widget.currentUserId)
        : null;

    final displayName = widget.conversation.title ??
        otherParticipant?.name ??
        'محادثة';

    final displayImage = widget.conversation.avatar ??
        otherParticipant?.profileImage;

    final statusText = _getStatusText();

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.darkCard.withOpacity(0.85),
                AppTheme.darkCard.withOpacity(0.8),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: AppTheme.darkBorder.withOpacity(0.05),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  // Back button - Premium minimal style
                  _buildMinimalIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: widget.onBackPressed,
                    size: 16,
                  ),
                  
                  const SizedBox(width: 6),
                  
                  // User info - Compact and elegant
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onInfoPressed();
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          _buildPremiumAvatar(displayImage, displayName),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: AppTheme.textWhite.withOpacity(0.9),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (statusText != null)
                                  AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 200),
                                    style: AppTextStyles.caption.copyWith(
                                      color: _getStatusColor(),
                                      fontSize: 9,
                                    ),
                                    child: Text(
                                      statusText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Action buttons - Minimal style
                  if (widget.onCallPressed != null)
                    _buildMinimalIconButton(
                      icon: Icons.call_rounded,
                      onPressed: widget.onCallPressed!,
                      size: 18,
                    ),
                  if (widget.onVideoCallPressed != null)
                    _buildMinimalIconButton(
                      icon: Icons.videocam_rounded,
                      onPressed: widget.onVideoCallPressed!,
                      size: 18,
                    ),
                  _buildMinimalIconButton(
                    icon: Icons.more_vert_rounded,
                    onPressed: widget.onInfoPressed,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required double size,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: Container(
        width: 32, // Reduced from 36
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.03),
              Colors.white.withOpacity(0.01),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
            width: 0.5,
          ),
        ),
        child: Icon(
          icon,
          size: size,
          color: AppTheme.textWhite.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildPremiumAvatar(String? imageUrl, String name) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            Container(
              width: 34, // Reduced from 36
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.08),
                    AppTheme.primaryPurple.withOpacity(0.04),
                  ],
                ),
                border: Border.all(
                  color: AppTheme.primaryBlue.withOpacity(0.15),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(
                      0.05 * _glowAnimation.value,
                    ),
                    blurRadius: 8,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
              child: imageUrl != null
                  ? ClipOval(
                      child: CachedImageWidget(
                        imageUrl: imageUrl,
                        width: 34,
                        height: 34,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Text(
                        _getInitials(name),
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.primaryBlue.withOpacity(0.8),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
            ),
            if (widget.conversation.isDirectChat)
              Positioned(
                bottom: 0,
                right: 0,
                child: _buildMinimalOnlineIndicator(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMinimalOnlineIndicator() {
    final otherParticipant = widget.conversation.getOtherParticipant(widget.currentUserId);
    if (otherParticipant == null || !otherParticipant.isOnline) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: 7, // Reduced from 8
          height: 7,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.success.withOpacity(0.9),
                AppTheme.neonGreen.withOpacity(0.7),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.darkCard,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.success.withOpacity(
                  0.3 + 0.1 * _glowAnimation.value,
                ),
                blurRadius: 3 + 2 * _glowAnimation.value,
                spreadRadius: 0.3,
              ),
            ],
          ),
        );
      },
    );
  }

  String? _getStatusText() {
    if (widget.conversation.isDirectChat) {
      final otherParticipant = widget.conversation.getOtherParticipant(widget.currentUserId);
      if (otherParticipant == null) return null;
      
      if (otherParticipant.isOnline) {
        return 'متصل';
      } else if (otherParticipant.lastSeen != null) {
        return _formatLastSeen(otherParticipant.lastSeen!);
      }
    } else {
      final onlineCount = widget.conversation.participants
          .where((p) => p.isOnline && p.id != widget.currentUserId)
          .length;
      if (onlineCount > 0) {
        return '$onlineCount متصل';
      }
    }
    return null;
  }

  Color _getStatusColor() {
    final otherParticipant = widget.conversation.isDirectChat
        ? widget.conversation.getOtherParticipant(widget.currentUserId)
        : null;
    
    if (otherParticipant?.isOnline == true) {
      return AppTheme.success.withOpacity(0.8);
    }
    return AppTheme.textMuted.withOpacity(0.6);
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

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
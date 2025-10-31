import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/conversation.dart';

// في ملف pinned_admins_widget.dart، حدث callback onUserTap:

class PinnedAdminsWidget extends StatelessWidget {
  final List<ChatUser> adminUsers;
  final Set<ChatUser> selectedUsers;
  final Function(ChatUser) onUserTap;
  final ScrollController? scrollController;

  const PinnedAdminsWidget({
    super.key,
    required this.adminUsers,
    required this.selectedUsers,
    required this.onUserTap,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (adminUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryBlue.withValues(alpha: 0.03),
            AppTheme.primaryPurple.withValues(alpha: 0.02),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withValues(alpha: 0.08),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber.withValues(alpha: 0.2),
                        Colors.orange.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    size: 14,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'إدارة التطبيق',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${adminUsers.length}',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Admins horizontal list
          SizedBox(
            height: 100,
            child: ListView.builder(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: adminUsers.length,
              itemBuilder: (context, index) {
                final admin = adminUsers[index];
                final isSelected = selectedUsers.contains(admin);
                
                return _AdminItemWidget(
                  admin: admin,
                  isSelected: isSelected,
                  onTap: () => onUserTap(admin), // استخدام callback مباشرة
                  index: index,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminItemWidget extends StatefulWidget {
  final ChatUser admin;
  final bool isSelected;
  final VoidCallback onTap;
  final int index;

  const _AdminItemWidget({
    required this.admin,
    required this.isSelected,
    required this.onTap,
    required this.index,
  });

  @override
  State<_AdminItemWidget> createState() => _AdminItemWidgetState();
}

class _AdminItemWidgetState extends State<_AdminItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 400 + (widget.index * 50)),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onTap();
              },
              child: Container(
                width: 72,
                margin: const EdgeInsets.only(right: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Avatar with premium effect
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow effect
                        if (widget.isSelected)
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryBlue.withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        
                        // Avatar container
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: widget.isSelected
                                ? LinearGradient(
                                    colors: [
                                      AppTheme.primaryBlue,
                                      AppTheme.primaryPurple,
                                    ],
                                  )
                                : LinearGradient(
                                    colors: [
                                      Colors.amber.withValues(alpha: 0.2),
                                      Colors.orange.withValues(alpha: 0.15),
                                    ],
                                  ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: widget.isSelected
                                  ? Colors.white.withValues(alpha: 0.3)
                                  : Colors.amber.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _getInitials(widget.admin.name),
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: widget.isSelected
                                    ? Colors.white
                                    : Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        
                        // Crown badge
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.amber, Colors.orange],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.darkCard,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.star_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        
                        // Selection checkmark
                        if (widget.isSelected)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: AppTheme.success,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.darkCard,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // Name
                    Text(
                      widget.admin.name.split(' ').first,
                      style: AppTextStyles.caption.copyWith(
                        color: widget.isSelected
                            ? AppTheme.primaryBlue
                            : AppTheme.textWhite,
                        fontSize: 11,
                        fontWeight: widget.isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    
                    // Status
                    if (widget.admin.isOnline)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'متصل',
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.success,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length.clamp(0, 2)).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}
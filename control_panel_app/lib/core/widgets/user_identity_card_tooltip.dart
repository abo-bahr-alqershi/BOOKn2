import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../utils/formatters.dart';

/// User Identity Card Tooltip - بطاقة المستخدم المنبثقة
class UserIdentityCardTooltip {
  static OverlayEntry? _overlayEntry;
  static final GlobalKey<_UserCardContentState> _contentKey = GlobalKey();

  static void show({
    required BuildContext context,
    required GlobalKey targetKey,
    required String userId,
    required String name,
    required String role,
    required String email,
    required String phone,
    String? profileImage,
    required DateTime createdAt,
    required bool isActive,
    DateTime? lastSeen,
    DateTime? lastLoginDate,
    Map<String, dynamic>? additionalInfo,
  }) {
    hide();

    _overlayEntry = OverlayEntry(
      builder: (context) => _UserCardOverlay(
        targetKey: targetKey,
        userId: userId,
        name: name,
        role: role,
        email: email,
        phone: phone,
        profileImage: profileImage,
        createdAt: createdAt,
        isActive: isActive,
        lastSeen: lastSeen,
        lastLoginDate: lastLoginDate,
        additionalInfo: additionalInfo,
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

class _UserCardOverlay extends StatelessWidget {
  final GlobalKey targetKey;
  final String userId;
  final String name;
  final String role;
  final String email;
  final String phone;
  final String? profileImage;
  final DateTime createdAt;
  final bool isActive;
  final DateTime? lastSeen;
  final DateTime? lastLoginDate;
  final Map<String, dynamic>? additionalInfo;
  final GlobalKey<_UserCardContentState> contentKey;

  const _UserCardOverlay({
    required this.targetKey,
    required this.userId,
    required this.name,
    required this.role,
    required this.email,
    required this.phone,
    this.profileImage,
    required this.createdAt,
    required this.isActive,
    this.lastSeen,
    this.lastLoginDate,
    this.additionalInfo,
    required this.contentKey,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: UserIdentityCardTooltip.hide,
          child: Container(
            color: Colors.black.withOpacity(0.3),
          ),
        ),
        _UserCardContent(
          key: contentKey,
          targetKey: targetKey,
          userId: userId,
          name: name,
          role: role,
          email: email,
          phone: phone,
          profileImage: profileImage,
          createdAt: createdAt,
          isActive: isActive,
          lastSeen: lastSeen,
          lastLoginDate: lastLoginDate,
          additionalInfo: additionalInfo,
        ),
      ],
    );
  }
}

class _UserCardContent extends StatefulWidget {
  final GlobalKey targetKey;
  final String userId;
  final String name;
  final String role;
  final String email;
  final String phone;
  final String? profileImage;
  final DateTime createdAt;
  final bool isActive;
  final DateTime? lastSeen;
  final DateTime? lastLoginDate;
  final Map<String, dynamic>? additionalInfo;

  const _UserCardContent({
    super.key,
    required this.targetKey,
    required this.userId,
    required this.name,
    required this.role,
    required this.email,
    required this.phone,
    this.profileImage,
    required this.createdAt,
    required this.isActive,
    this.lastSeen,
    this.lastLoginDate,
    this.additionalInfo,
  });

  @override
  State<_UserCardContent> createState() => _UserCardContentState();
}

class _UserCardContentState extends State<_UserCardContent>
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

  Color _getRoleColor() {
    switch (widget.role.toLowerCase()) {
      case 'admin':
        return AppTheme.error;
      case 'owner':
        return AppTheme.primaryBlue;
      case 'client':
        return AppTheme.primaryCyan;
      case 'staff':
        return AppTheme.warning;
      case 'guest':
        return AppTheme.primaryPurple;
      default:
        return AppTheme.textMuted;
    }
  }

  IconData _getRoleIcon() {
    switch (widget.role.toLowerCase()) {
      case 'admin':
        return CupertinoIcons.shield_fill;
      case 'owner':
        return CupertinoIcons.building_2_fill;
      case 'client':
        return CupertinoIcons.person_fill;
      case 'staff':
        return CupertinoIcons.person_badge_plus_fill;
      case 'guest':
        return CupertinoIcons.person_crop_circle;
      default:
        return CupertinoIcons.person;
    }
  }

  String _getRoleArabic() {
    switch (widget.role.toLowerCase()) {
      case 'admin':
        return 'مدير النظام';
      case 'owner':
        return 'مالك';
      case 'client':
        return 'عميل';
      case 'staff':
        return 'موظف';
      case 'guest':
        return 'ضيف';
      default:
        return widget.role; // عرض القيمة الأصلية
    }
  }

  String _getLastSeenText(DateTime lastSeen) {
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inMinutes < 5) return 'متصل الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return Formatters.formatDateTime(lastSeen);
  }

  Color _getLastSeenColor(DateTime? lastSeen) {
    if (lastSeen == null) return AppTheme.textMuted;
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inMinutes < 5) return AppTheme.success;
    if (diff.inHours < 24) return AppTheme.primaryBlue;
    if (diff.inDays < 7) return AppTheme.warning;
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final roleColor = _getRoleColor();

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
                      color: roleColor.withOpacity(0.3),
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
                          color: roleColor.withOpacity(0.4),
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
                            _buildHeader(roleColor),
                            Flexible(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    _buildProfile(roleColor),
                                    const SizedBox(height: 16),
                                    _buildInfoRow(
                                      CupertinoIcons.mail_solid,
                                      'البريد',
                                      widget.email,
                                      AppTheme.primaryBlue,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildInfoRow(
                                      CupertinoIcons.phone_fill,
                                      'الهاتف',
                                      widget.phone.isNotEmpty
                                          ? widget.phone
                                          : 'غير محدد',
                                      AppTheme.primaryPurple,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildInfoRow(
                                      CupertinoIcons.time,
                                      'آخر ظهور',
                                      widget.lastSeen != null
                                          ? _getLastSeenText(widget.lastSeen!)
                                          : 'لم يسجل الدخول',
                                      _getLastSeenColor(widget.lastSeen),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildUserId(),
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

  Widget _buildHeader(Color roleColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: roleColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: roleColor.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              CupertinoIcons.person_crop_square_fill,
              color: roleColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'بطاقة المستخدم',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: UserIdentityCardTooltip.hide,
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

  Widget _buildProfile(Color roleColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: roleColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: roleColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: roleColor,
                width: 3.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: roleColor.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: widget.profileImage != null
                  ? Image.network(
                      widget.profileImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _buildDefaultAvatar(roleColor),
                    )
                  : _buildDefaultAvatar(roleColor),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.name,
            style: AppTextStyles.heading2.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: roleColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getRoleIcon(),
                      color: roleColor,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _getRoleArabic(),
                      style: AppTextStyles.caption.copyWith(
                        color: roleColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isActive ? AppTheme.success : AppTheme.error,
                  boxShadow: [
                    BoxShadow(
                      color:
                          (widget.isActive ? AppTheme.success : AppTheme.error)
                              .withOpacity(0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(Color color) {
    return Container(
      color: color.withOpacity(0.1),
      child: Icon(
        CupertinoIcons.person_fill,
        size: 70,
        color: color,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
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
                const SizedBox(height: 2),
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

  Widget _buildUserId() {
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
              'ID: ${widget.userId}',
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

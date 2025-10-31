// lib/features/admin_users/presentation/widgets/futuristic_users_table.dart

import 'package:bookn_cp_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:bookn_cp_app/core/theme/app_text_styles.dart';
import 'package:bookn_cp_app/core/theme/app_dimensions.dart';
import '../../domain/entities/user.dart';
import 'last_seen_widget.dart';
import '../../../../core/widgets/user_identity_card_tooltip.dart';

class FuturisticUsersTable extends StatefulWidget {
  final List<User> users;
  final Function(String) onUserTap;
  final Function(String, bool) onStatusToggle;
  final Function(String) onDelete;
  
  const FuturisticUsersTable({
    super.key,
    required this.users,
    required this.onUserTap,
    required this.onStatusToggle,
    required this.onDelete,
  });
  
  @override
  State<FuturisticUsersTable> createState() => _FuturisticUsersTableState();
}

class _FuturisticUsersTableState extends State<FuturisticUsersTable>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  String? _hoveredUserId;
  String? _pressedUserId;
  String _sortColumn = 'name';
  bool _isAscending = true;
  final Map<String, GlobalKey> _cardKeys = {};
  
  // Breakpoints
  static const double _mobileBreakpoint = 600;
  static const double _tabletBreakpoint = 1024;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  List<User> get _sortedUsers {
    final sorted = List<User>.from(widget.users);
    
    sorted.sort((a, b) {
      int comparison = 0;
      
      switch (_sortColumn) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'email':
          comparison = a.email.compareTo(b.email);
          break;
        case 'role':
          comparison = a.role.compareTo(b.role);
          break;
        case 'createdAt':
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case 'lastSeen':
          if (a.lastSeen == null && b.lastSeen == null) comparison = 0;
          else if (a.lastSeen == null) comparison = 1;
          else if (b.lastSeen == null) comparison = -1;
          else comparison = a.lastSeen!.compareTo(b.lastSeen!);
          break;
        case 'status':
          comparison = a.isActive.toString().compareTo(b.isActive.toString());
          break;
      }
      
      return _isAscending ? comparison : -comparison;
    });
    
    return sorted;
  }
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // تحديد نوع الشاشة
        if (constraints.maxWidth < _mobileBreakpoint) {
          return _buildMobileView();
        } else if (constraints.maxWidth < _tabletBreakpoint) {
          return _buildTabletView();
        } else {
          return _buildDesktopView();
        }
      },
    );
  }
  
  // ========== عرض الموبايل - بطاقات عمودية ==========
  Widget _buildMobileView() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.all(12),
        itemCount: _sortedUsers.length,
        itemBuilder: (context, index) {
          final user = _sortedUsers[index];
          return _buildMobileCard(user, index);
        },
      ),
    );
  }
  
  Widget _buildMobileCard(User user, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        final clamped = value.clamp(0.0, 1.0);
        return Transform.scale(
          scale: clamped,
          child: Opacity(
            opacity: clamped,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.darkCard.withValues(alpha: 0.9),
                    AppTheme.darkCard.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _pressedUserId == user.id
                      ? AppTheme.primaryBlue.withValues(alpha: 0.6)
                      : user.isActive
                          ? AppTheme.success.withValues(alpha: 0.3)
                          : AppTheme.darkBorder.withValues(alpha: 0.3),
                  width: _pressedUserId == user.id ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: user.isActive
                        ? AppTheme.success.withValues(alpha: 0.1)
                        : AppTheme.darkBorder.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: _getCardKey(user.id),
                      onTap: () => widget.onUserTap(user.id),
                      onLongPress: () => _showUserIdentityCard(user),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with avatar and status
                            Row(
                              children: [
                                // Avatar
                                _buildAvatar(user, size: 50),
                                const SizedBox(width: 12),
                                // User Name and Role
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.name,
                                        style: AppTextStyles.heading3.copyWith(
                                          fontSize: 16,
                                          color: AppTheme.textWhite,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      _buildRoleBadge(user.role),
                                    ],
                                  ),
                                ),
                                // Status Badge
                                _buildStatusBadge(user.isActive),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // User Details
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.darkSurface.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  _buildMobileDetailRow(
                                    icon: Icons.email_rounded,
                                    label: 'البريد',
                                    value: user.email,
                                    iconColor: AppTheme.primaryBlue,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildMobileDetailRow(
                                    icon: Icons.phone_rounded,
                                    label: 'الهاتف',
                                    value: user.phone.isNotEmpty ? user.phone : 'غير محدد',
                                    iconColor: AppTheme.primaryPurple,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildMobileDetailRow(
                                    icon: Icons.calendar_today_rounded,
                                    label: 'تاريخ الإنضمام',
                                    value: _formatDate(user.createdAt),
                                    iconColor: AppTheme.primaryCyan,
                                  ),
                                  const SizedBox(height: 12),
                                  LastSeenWidget(
                                    lastSeen: user.lastSeen,
                                    style: LastSeenStyle.detailed,
                                    showIcon: true,
                                    showAnimation: true,
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMobileActionButton(
                                    label: user.isActive ? 'إيقاف' : 'تفعيل',
                                    icon: user.isActive 
                                        ? Icons.toggle_on_rounded 
                                        : Icons.toggle_off_rounded,
                                    color: user.isActive 
                                        ? AppTheme.success 
                                        : AppTheme.textMuted,
                                    onTap: () => widget.onStatusToggle(
                                      user.id, 
                                      !user.isActive
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildMobileActionButton(
                                    label: 'عرض',
                                    icon: Icons.visibility_rounded,
                                    color: AppTheme.primaryBlue,
                                    onTap: () => widget.onUserTap(user.id),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildMobileActionButton(
                                    label: 'حذف',
                                    icon: Icons.delete_rounded,
                                    color: AppTheme.error,
                                    onTap: () => widget.onDelete(user.id),
                                  ),
                                ),
                              ],
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
  
  Widget _buildMobileDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: iconColor.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textLight,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
  
  Widget _buildMobileActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // ========== عرض التابلت - جدول مبسط ==========
  Widget _buildTabletView() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkCard.withValues(alpha: 0.7),
              AppTheme.darkCard.withValues(alpha: 0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryBlue.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              children: [
                _buildTabletHeader(),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 900, // عرض ثابت للتابلت
                    child: ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _sortedUsers.length,
                      itemBuilder: (context, index) {
                        final user = _sortedUsers[index];
                        return _buildTabletRow(user);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTabletHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withValues(alpha: 0.1),
            AppTheme.primaryPurple.withValues(alpha: 0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildTabletHeaderCell('المستخدم', flex: 3, sortKey: 'name'),
          _buildTabletHeaderCell('البريد الإلكتروني', flex: 3, sortKey: 'email'),
          _buildTabletHeaderCell('الدور', flex: 2, sortKey: 'role'),
          _buildTabletHeaderCell('الحالة', flex: 1, sortKey: 'status'),
          _buildTabletHeaderCell('الإجراءات', flex: 2),
        ],
      ),
    );
  }
  
  Widget _buildTabletHeaderCell(String title, {
    required int flex,
    String? sortKey,
  }) {
    final isActive = _sortColumn == sortKey;
    
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: sortKey != null
            ? () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (_sortColumn == sortKey) {
                    _isAscending = !_isAscending;
                  } else {
                    _sortColumn = sortKey;
                    _isAscending = true;
                  }
                });
              }
            : null,
        child: Row(
          mainAxisAlignment: sortKey == null 
              ? MainAxisAlignment.center 
              : MainAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.bodySmall.copyWith(
                color: isActive ? AppTheme.primaryBlue : AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (sortKey != null) ...[
              const SizedBox(width: 4),
              Icon(
                isActive
                    ? (_isAscending
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded)
                    : Icons.unfold_more_rounded,
                size: 14,
                color: isActive
                    ? AppTheme.primaryBlue
                    : AppTheme.textMuted.withValues(alpha: 0.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildTabletRow(User user) {
    final isHovered = _hoveredUserId == user.id;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredUserId = user.id),
      onExit: (_) => setState(() => _hoveredUserId = null),
      child: GestureDetector(
        onTap: () => widget.onUserTap(user.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: isHovered
                ? LinearGradient(
                    colors: [
                      AppTheme.primaryBlue.withValues(alpha: 0.08),
                      AppTheme.primaryPurple.withValues(alpha: 0.04),
                    ],
                  )
                : null,
            color: !isHovered
                ? AppTheme.darkSurface.withValues(alpha: 0.3)
                : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHovered
                  ? AppTheme.primaryBlue.withValues(alpha: 0.3)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // User Info
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    _buildAvatar(user, size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppTheme.textWhite,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (user.phone.isNotEmpty)
                            Text(
                              user.phone,
                              style: AppTextStyles.caption.copyWith(
                                color: AppTheme.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Email
              Expanded(
                flex: 3,
                child: Text(
                  user.email,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // Role
              Expanded(
                flex: 2,
                child: _buildRoleBadge(user.role),
              ),
              
              // Status
              Expanded(
                flex: 1,
                child: Center(
                  child: _buildStatusBadge(user.isActive),
                ),
              ),
              
              // Actions
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildActionButton(
                      icon: user.isActive
                          ? Icons.toggle_on_rounded
                          : Icons.toggle_off_rounded,
                      color: user.isActive ? AppTheme.success : AppTheme.textMuted,
                      onTap: () => widget.onStatusToggle(user.id, !user.isActive),
                    ),
                    const SizedBox(width: 4),
                    _buildActionButton(
                      icon: Icons.visibility_rounded,
                      color: AppTheme.primaryBlue,
                      onTap: () => widget.onUserTap(user.id),
                    ),
                    const SizedBox(width: 4),
                    _buildActionButton(
                      icon: Icons.delete_rounded,
                      color: AppTheme.error,
                      onTap: () => widget.onDelete(user.id),
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
  
  // ========== عرض سطح المكتب - الجدول الكامل ==========
  Widget _buildDesktopView() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkCard.withValues(alpha: 0.7),
              AppTheme.darkCard.withValues(alpha: 0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryBlue.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              children: [
                _buildDesktopHeader(),
                _buildDesktopBody(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildDesktopHeader() {
    final headers = [
      {'label': 'المستخدم', 'key': 'name', 'flex': 3},
      {'label': 'البريد الإلكتروني', 'key': 'email', 'flex': 3},
      {'label': 'الدور', 'key': 'role', 'flex': 2},
      {'label': 'آخر ظهور', 'key': 'lastSeen', 'flex': 2},
      {'label': 'الحالة', 'key': 'status', 'flex': 1},
      {'label': 'الإجراءات', 'key': 'actions', 'flex': 2},
    ];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withValues(alpha: 0.1),
            AppTheme.primaryPurple.withValues(alpha: 0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: headers.map((header) {
          final isActionColumn = header['key'] == 'actions';
          final isActive = _sortColumn == header['key'];
          
          return Expanded(
            flex: header['flex'] as int,
            child: isActionColumn
                ? Center(
                    child: Text(
                      header['label'] as String,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (_sortColumn == header['key']) {
                          _isAscending = !_isAscending;
                        } else {
                          _sortColumn = header['key'] as String;
                          _isAscending = true;
                        }
                      });
                    },
                    child: Row(
                      children: [
                        Text(
                          header['label'] as String,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isActive ? AppTheme.primaryBlue : AppTheme.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (isActive)
                          Icon(
                            _isAscending
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 14,
                            color: AppTheme.primaryBlue,
                          )
                        else
                          Icon(
                            Icons.unfold_more_rounded,
                            size: 14,
                            color: AppTheme.textMuted.withValues(alpha: 0.3),
                          ),
                      ],
                    ),
                  ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildDesktopBody() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _sortedUsers.length,
      itemBuilder: (context, index) {
        final user = _sortedUsers[index];
        return _buildDesktopRow(user, index);
      },
    );
  }
  
  Widget _buildDesktopRow(User user, int index) {
    final isHovered = _hoveredUserId == user.id;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredUserId = user.id),
      onExit: (_) => setState(() => _hoveredUserId = null),
      child: GestureDetector(
        onTap: () => widget.onUserTap(user.id),
        child: TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 200 + (index * 30)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            final clamped = value.clamp(0.0, 1.0);
            return Transform.translate(
              offset: Offset((1 - clamped) * -50, 0),
              child: Opacity(
                opacity: clamped,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isHovered
                        ? LinearGradient(
                            colors: [
                              AppTheme.primaryBlue.withValues(alpha: 0.08),
                              AppTheme.primaryPurple.withValues(alpha: 0.04),
                            ],
                          )
                        : null,
                    color: !isHovered
                        ? AppTheme.darkSurface.withValues(alpha: 0.3)
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isHovered
                          ? AppTheme.primaryBlue.withValues(alpha: 0.3)
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // User Info
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            _buildAvatar(user, size: 40),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppTheme.textWhite,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (user.phone.isNotEmpty)
                                    Text(
                                      user.phone,
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppTheme.textMuted,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Email
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 14,
                              color: AppTheme.textMuted.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                user.email,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppTheme.textLight,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Role
                      Expanded(
                        flex: 2,
                        child: _buildRoleBadge(user.role),
                      ),
                      
                      // Last Seen
                      Expanded(
                        flex: 2,
                        child: LastSeenWidget(
                          lastSeen: user.lastSeen,
                          style: LastSeenStyle.compact,
                          showIcon: true,
                          showAnimation: true,
                        ),
                      ),
                      
                      // Status
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: _buildStatusBadge(user.isActive),
                        ),
                      ),
                      
                      // Actions
                      Expanded(
                        flex: 2,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildActionButton(
                              icon: user.isActive
                                  ? Icons.toggle_on_rounded
                                  : Icons.toggle_off_rounded,
                              color: user.isActive ? AppTheme.success : AppTheme.textMuted,
                              tooltip: user.isActive ? 'إلغاء التفعيل' : 'تفعيل',
                              onTap: () => widget.onStatusToggle(user.id, !user.isActive),
                            ),
                            const SizedBox(width: 8),
                            _buildActionButton(
                              icon: Icons.visibility_rounded,
                              color: AppTheme.primaryBlue,
                              tooltip: 'عرض التفاصيل',
                              onTap: () => widget.onUserTap(user.id),
                            ),
                            const SizedBox(width: 8),
                            _buildActionButton(
                              icon: Icons.delete_rounded,
                              color: AppTheme.error,
                              tooltip: 'حذف',
                              onTap: () => widget.onDelete(user.id),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  // ========== مكونات مشتركة ==========
  Widget _buildAvatar(User user, {required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: user.profileImage != null
            ? null
            : AppTheme.primaryGradient,
        border: Border.all(
          color: user.isActive
              ? AppTheme.success.withValues(alpha: 0.5)
              : AppTheme.darkBorder,
          width: 1.5,
        ),
        boxShadow: [
          if (user.isActive)
            BoxShadow(
              color: AppTheme.success.withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
        ],
      ),
      child: user.profileImage != null && user.profileImage!.trim().isNotEmpty
          ? ClipOval(
              child: Image.network(
                user.profileImage!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultAvatar(user.name);
                },
              ),
            )
          : _buildDefaultAvatar(user.name),
    );
  }
  
  Widget _buildDefaultAvatar(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    
    return Center(
      child: Text(
        initial,
        style: AppTextStyles.bodyMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildRoleBadge(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getRoleGradient(role),
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getRoleGradient(role)[0].withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        _getRoleText(role),
        style: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [
                  AppTheme.success.withValues(alpha: 0.2),
                  AppTheme.success.withValues(alpha: 0.1),
                ]
              : [
                  AppTheme.textMuted.withValues(alpha: 0.2),
                  AppTheme.textMuted.withValues(alpha: 0.1),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? AppTheme.success.withValues(alpha: 0.5)
              : AppTheme.textMuted.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppTheme.success : AppTheme.textMuted,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'نشط' : 'غير نشط',
            style: AppTextStyles.caption.copyWith(
              color: isActive ? AppTheme.success : AppTheme.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    String? tooltip,
    required VoidCallback onTap,
  }) {
    final button = GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: color,
        ),
      ),
    );
    
    return tooltip != null
        ? Tooltip(message: tooltip, child: button)
        : button;
  }
  
  List<Color> _getRoleGradient(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return [AppTheme.error, AppTheme.primaryViolet];
      case 'owner':
        return [AppTheme.primaryBlue, AppTheme.primaryPurple];
      case 'staff':
        return [AppTheme.warning, AppTheme.neonBlue];
      default:
        return [AppTheme.primaryCyan, AppTheme.neonGreen];
    }
  }
  
  String _getRoleText(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'مدير';
      case 'owner':
        return 'مالك';
      case 'staff':
        return 'موظف';
      case 'customer':
        return 'عميل';
      default:
        return role;
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  // ========== User Identity Card Methods ==========
  
  GlobalKey _getCardKey(String userId) {
    if (!_cardKeys.containsKey(userId)) {
      _cardKeys[userId] = GlobalKey();
    }
    return _cardKeys[userId]!;
  }
  
  void _showUserIdentityCard(User user) {
    setState(() => _pressedUserId = user.id);
    
    HapticFeedback.mediumImpact();
    
    // Additional info
    final additionalInfo = <String, dynamic>{};
    
    if (user.favorites != null && user.favorites!.isNotEmpty) {
      additionalInfo['المفضلات'] = '${user.favorites!.length} عنصر';
    }
    
    if (user.settings != null && user.settings!.isNotEmpty) {
      final notificationsEnabled = user.settings!['notifications_enabled'] ?? true;
      additionalInfo['الإشعارات'] = notificationsEnabled ? 'مفعلة' : 'معطلة';
      
      final language = user.settings!['language'] ?? 'ar';
      additionalInfo['اللغة'] = language == 'ar' ? 'العربية' : 'English';
    }
    
    // Show tooltip
    UserIdentityCardTooltip.show(
      context: context,
      targetKey: _getCardKey(user.id),
      userId: user.id,
      name: user.name,
      role: user.role,
      email: user.email,
      phone: user.phone,
      profileImage: user.profileImage,
      createdAt: user.createdAt,
      isActive: user.isActive,
      lastSeen: user.lastSeen,
      lastLoginDate: user.lastLoginDate,
      additionalInfo: additionalInfo.isNotEmpty ? additionalInfo : null,
    );
    
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _pressedUserId = null);
    });
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bookn_cp_app/features/chat/presentation/pages/chat_page.dart';
import 'package:bookn_cp_app/features/chat/presentation/widgets/pinned_admins_widget.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/empty_widget.dart';
import '../../domain/entities/conversation.dart';
import '../bloc/chat_bloc.dart';
import '../widgets/participant_item_widget.dart';
import 'package:characters/characters.dart';

class NewConversationPage extends StatefulWidget {
  const NewConversationPage({super.key});

  @override
  State<NewConversationPage> createState() => _NewConversationPageState();
}

class _NewConversationPageState extends State<NewConversationPage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();
  final Set<ChatUser> _selectedUsers = {};

  bool _isCreatingGroup = false; // المجموعات معطلة
  List<ChatUser> _availableUsers = [];
  List<ChatUser> _filteredUsers = [];

  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAvailableUsers();
    _searchController.addListener(_filterUsers);
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutQuart,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _groupNameController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _loadAvailableUsers() {
    final bloc = context.read<ChatBloc>();
    bloc.add(const LoadAdminUsersEvent());
    bloc.add(const LoadAvailableUsersEvent());
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _availableUsers;
      } else {
        _filteredUsers = _availableUsers
            .where((user) => user.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state is ConversationCreated) {
          // نجح إنشاء المحادثة
          HapticFeedback.mediumImpact();

          // إغلاق أي dialog مفتوح
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }

          // الانتقال للمحادثة الجديدة
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  ChatPage(conversation: state.conversation),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutQuart,
                    )),
                    child: child,
                  ),
                );
              },
            ),
          );
        } else if (state is ConversationCreating) {
          // إظهار loading dialog
          showDialog(
            fullscreenDialog: true,
            context: context,
            barrierDismissible: false,
            barrierColor: Colors.black54,
            builder: (dialogContext) => _buildCreatingDialog(),
          );
        } else if (state is ChatError && state.message.isNotEmpty) {
          // إغلاق أي dialog مفتوح
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }

          // إظهار رسالة الخطأ
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.message,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        } else if (state is ChatLoaded) {
          // إغلاق dialog التحميل عند الرجوع للحالة العادية
          // التحقق من وجود dialog مفتوح
          final route = ModalRoute.of(context);
          if (route != null &&
              !route.isCurrent &&
              Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Stack(
          children: [
            // Premium gradient background
            _buildPremiumBackground(),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  _buildPremiumAppBar(),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildUserSelectionView(),
                    ),
                  ),
                ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: null,
      ),
    );
  }

// أضف دالة بناء dialog التحميل الاحترافي
  Widget _buildCreatingDialog() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.darkCard.withValues(alpha: 0.9),
                          AppTheme.darkCard.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Custom loading animation
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer ring
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration: const Duration(seconds: 2),
                                builder: (context, value, child) {
                                  return CircularProgressIndicator(
                                    value: value,
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.primaryBlue
                                          .withValues(alpha: 0.3),
                                    ),
                                  );
                                },
                              ),
                              // Inner animated ring
                              CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryBlue,
                                ),
                              ),
                              // Center icon
                              Icon(
                                Icons.chat_bubble_rounded,
                                color: AppTheme.primaryBlue,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              AppTheme.primaryBlue,
                              AppTheme.primaryPurple
                            ],
                          ).createShader(bounds),
                          child: Text(
                            _isCreatingGroup
                                ? 'إنشاء المجموعة...'
                                : 'بدء المحادثة...',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'الرجاء الانتظار لحظات',
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.textMuted.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

// تحديث دالة _startDirectChat - إزالة Navigator.pop
  void _startDirectChat(ChatUser user) {
    HapticFeedback.lightImpact();

    // فقط أرسل الحدث، BlocListener سيتولى التنقل
    context.read<ChatBloc>().add(
          CreateConversationEvent(
            participantIds: [user.id],
            conversationType: 'direct',
          ),
        );
    // لا Navigator.pop هنا!
  }

  void _handleExistingConversation(Conversation conversation) {
    // إذا كانت المحادثة موجودة بالفعل، انتقل إليها مباشرة
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ChatPage(conversation: conversation),
      ),
    );
  }

// أضف validation محسّن
  bool _validateGroupCreation() {
    if (_groupNameController.text.trim().isEmpty) {
      _showValidationError('الرجاء إدخال اسم المجموعة');
      return false;
    }

    if (_groupNameController.text.trim().length < 3) {
      _showValidationError('اسم المجموعة يجب أن يكون 3 أحرف على الأقل');
      return false;
    }

    if (_selectedUsers.length < 2) {
      _showValidationError('يجب اختيار شخصين على الأقل للمجموعة');
      return false;
    }

    if (_selectedUsers.length > 100) {
      _showValidationError('الحد الأقصى للمجموعة هو 100 عضو');
      return false;
    }

    return true;
  }

  void _showValidationError(String message) {
    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.warning,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'حسناً',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _createGroup() {
    if (!_validateGroupCreation()) {
      return;
    }

    HapticFeedback.lightImpact();

    // تنظيف اسم المجموعة
    final cleanGroupName = _groupNameController.text.trim();

    context.read<ChatBloc>().add(
          CreateConversationEvent(
            participantIds: _selectedUsers.map((u) => u.id).toList(),
            conversationType: 'group',
            title: cleanGroupName,
            description: 'مجموعة تضم ${_selectedUsers.length} أعضاء',
          ),
        );
  }

// دالة مساعدة لإظهار رسائل الخطأ
  void _showErrorSnackBar(String message) {
    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.warning,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildPremiumBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkBackground,
            AppTheme.darkBackground2,
            AppTheme.darkBackground3,
          ],
        ),
      ),
      child: CustomPaint(
        painter: _SubtlePatternPainter(),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildPremiumAppBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkCard.withValues(alpha: 0.9),
                AppTheme.darkCard.withValues(alpha: 0.85),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: AppTheme.darkBorder.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              // Back button
              _buildAppBarButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  if (_isCreatingGroup && _selectedUsers.isNotEmpty) {
                    setState(() {
                      _isCreatingGroup = false;
                    });
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),

              const SizedBox(width: 12),

              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isCreatingGroup ? 'إنشاء مجموعة' : 'محادثة جديدة',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (_selectedUsers.isNotEmpty && !_isCreatingGroup)
                      Text(
                        '${_selectedUsers.length} محدد',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.8),
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),

              // زر إنشاء مجموعة مُعطّل
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkSurface.withValues(alpha: 0.5),
              AppTheme.darkSurface.withValues(alpha: 0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppTheme.darkBorder.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        child: Icon(
          icon,
          color: AppTheme.textWhite.withValues(alpha: 0.8),
          size: 18,
        ),
      ),
    );
  }

  Widget _buildUserSelectionView() {
    return Column(
      children: [
        _buildPremiumSearchBar(),

        // إضافة widget الأدمن المثبتين
        BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            if (state is ChatLoaded && state.adminUsers.isNotEmpty) {
              return PinnedAdminsWidget(
                adminUsers: state.adminUsers,
                selectedUsers: _selectedUsers,
                onUserTap: (admin) {
                  HapticFeedback.selectionClick();

                  setState(() {
                    if (_selectedUsers.contains(admin)) {
                      _selectedUsers.remove(admin);
                    } else {
                      _selectedUsers.add(admin);
                    }
                  });

                  // إذا تم اختيار مستخدم واحد فقط، ابدأ محادثة مباشرة
                  if (_selectedUsers.length == 1) {
                    // لا تستخدم Navigator.pop هنا!
                    context.read<ChatBloc>().add(
                          CreateConversationEvent(
                            participantIds: [_selectedUsers.first.id],
                            conversationType: 'direct',
                          ),
                        );
                    // BlocListener سيتولى التنقل
                  }
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),

        if (_selectedUsers.isNotEmpty) _buildSelectedUsersChips(),

        Expanded(
          child: BlocConsumer<ChatBloc, ChatState>(
            listenWhen: (prev, curr) => curr is ChatLoaded,
            listener: (context, state) {
              if (state is ChatLoaded) {
                setState(() {
                  _availableUsers = state.availableUsers
                      .where((user) => !state.adminUsers.contains(user))
                      .toList(); // استثناء الأدمن من القائمة العادية
                  _filterUsers();
                });
              }
            },
            builder: (context, state) {
              if (state is ChatLoading) {
                return _buildPremiumLoadingState();
              }

              if (_filteredUsers.isEmpty) {
                return _buildPremiumEmptyState();
              }

              return _buildRegularUsersList();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRegularUsersList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return _buildUserListTile(user, listIndex: index);
      },
    );
  }

  // تم تعطيل واجهة إنشاء المجموعات
  Widget _buildGroupCreationView() => _buildUserSelectionView();

  Widget _buildPremiumSearchBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkSurface.withValues(alpha: 0.6),
              AppTheme.darkSurface.withValues(alpha: 0.4),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.darkBorder.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        child: TextField(
          controller: _searchController,
          style: AppTextStyles.bodySmall.copyWith(
            fontSize: 13,
          ),
          decoration: InputDecoration(
            hintText: 'البحث عن جهات الاتصال...',
            hintStyle: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textMuted.withValues(alpha: 0.4),
              fontSize: 13,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppTheme.textMuted.withValues(alpha: 0.5),
              size: 18,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedUsersChips() {
    return Container(
      height: 90, // زيادة الارتفاع من 80 إلى 90 لحل مشكلة overflow
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _selectedUsers.length,
        itemBuilder: (context, index) {
          final user = _selectedUsers.elementAt(index);
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 300 + (index * 50)),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 64, // زيادة العرض قليلاً
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // مهم جداً
                    children: [
                      Stack(
                        clipBehavior: Clip.none, // السماح بالعناصر خارج الحدود
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryBlue.withValues(alpha: 0.1),
                                  AppTheme.primaryPurple
                                      .withValues(alpha: 0.05),
                                ],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    AppTheme.primaryBlue.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _getInitials(user.name),
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: -2,
                            right: -2,
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _selectedUsers.remove(user);
                                });
                              },
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.error.withValues(alpha: 0.8),
                                      AppTheme.error.withValues(alpha: 0.6),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.darkCard,
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 10,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Flexible(
                        // استخدام Flexible بدلاً من SizedBox ثابت
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Text(
                            user.name.split(' ').first,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildUsersList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return _buildUserListTile(user, listIndex: index);
      },
    );
  }

  Widget _buildUserListTile(ChatUser user, {required int listIndex}) {
    final isSelected = _selectedUsers.contains(user);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (listIndex * 30)),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(20 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          AppTheme.primaryBlue.withValues(alpha: 0.08),
                          AppTheme.primaryPurple.withValues(alpha: 0.04),
                        ],
                      )
                    : null,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                        width: 0.5,
                      )
                    : null,
              ),
              child: ListTile(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (isSelected) {
                      _selectedUsers.remove(user);
                    } else {
                      _selectedUsers.add(user);
                    }
                  });

                  if (_selectedUsers.length == 1) {
                    _startDirectChat(_selectedUsers.first);
                  }
                },
                leading: _buildUserAvatar(user, isSelected),
                title: Text(
                  user.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                subtitle: _buildUserSubtitle(user),
                trailing: AnimatedScale(
                  scale: isSelected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryBlue, AppTheme.primaryPurple],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 12,
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

  Widget _buildUserAvatar(ChatUser user, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.primaryPurple],
              )
            : LinearGradient(
                colors: [
                  AppTheme.darkCard.withValues(alpha: 0.6),
                  AppTheme.darkCard.withValues(alpha: 0.4),
                ],
              ),
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.2)
              : AppTheme.darkBorder.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      child: Center(
        child: Text(
          _getInitials(user.name),
          style: AppTextStyles.bodySmall.copyWith(
            color: isSelected
                ? Colors.white
                : AppTheme.textWhite.withValues(alpha: 0.8),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget? _buildUserSubtitle(ChatUser user) {
    if (user.isOnline) {
      return Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.success, AppTheme.neonGreen],
              ),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'متصل الآن',
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.success.withValues(alpha: 0.8),
              fontSize: 11,
            ),
          ),
        ],
      );
    }
    if (user.lastSeen != null) {
      return Text(
        'آخر ظهور ${_formatLastSeen(user.lastSeen!)}',
        style: AppTextStyles.caption.copyWith(
          color: AppTheme.textMuted.withValues(alpha: 0.5),
          fontSize: 11,
        ),
      );
    }
    return null;
  }

  Widget _buildPremiumLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.primaryBlue.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'جاري تحميل جهات الاتصال...',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textMuted.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkCard.withValues(alpha: 0.5),
              AppTheme.darkCard.withValues(alpha: 0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.darkBorder.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withValues(alpha: 0.1),
                    AppTheme.primaryPurple.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_search_rounded,
                size: 32,
                color: AppTheme.primaryBlue.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد جهات اتصال',
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'لم يتم العثور على جهات اتصال متاحة',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textMuted.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildPremiumFAB() => null;

  String _formatLastSeen(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return '${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return '${diff.inHours} ساعة';
    return '${diff.inDays} يوم';
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts[0].characters.first + parts[1].characters.first)
        .toUpperCase();
  }
}

// Subtle Pattern Painter
class _SubtlePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryBlue.withValues(alpha: 0.02)
      ..style = PaintingStyle.fill;

    const radius = 100.0;
    const spacing = 150.0;

    for (double x = 0; x < size.width + radius; x += spacing) {
      for (double y = 0; y < size.height + radius; y += spacing) {
        canvas.drawCircle(
          Offset(x, y),
          radius,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

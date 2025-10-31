import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../bloc/chat_bloc.dart';
import '../widgets/message_bubble_widget.dart';
import '../widgets/message_input_widget.dart';
import '../widgets/typing_indicator_widget.dart';
import '../widgets/chat_app_bar.dart';
import 'chat_settings_page.dart';
import 'package:provider/provider.dart';
import '../providers/typing_indicator_provider.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class ChatPage extends StatefulWidget {
  final Conversation conversation;

  const ChatPage({
    super.key,
    required this.conversation,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> 
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  
  // Message keys for scrolling to reply
  final Map<String, GlobalKey> _messageKeys = {};
  
  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _backgroundController;
  late AnimationController _particleController;
  late AnimationController _glowController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  
  // Particles for background
  final List<_ChatParticle> _particles = [];
  
  Timer? _typingTimer;
  bool _isTyping = false;
  bool _showScrollToBottom = false;
  String? _replyToMessageId;
  Message? _editingMessage;
  
  String? _currentUserId; // سيتم ملؤه من AuthBloc
  StreamSubscription<AuthState>? _authSubscription; // للاشتراك في تغييرات حالة المصادقة

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();
    _generateParticles();
    _syncCurrentUser();
    _loadMessages();
    _scrollController.addListener(_onScroll);
    _messageController.addListener(_onTypingChanged);
    _initializeTypingIndicator();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutQuart,
    );
    
    _backgroundAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_backgroundController);
    
    _scaleAnimation = Tween<double>(
      begin: 0.98,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutBack,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    _fadeController.forward();
  }

  void _generateParticles() {
    for (int i = 0; i < 8; i++) {
      _particles.add(_ChatParticle());
    }
  }

  void _initializeTypingIndicator() {
    final typingProvider = context.read<TypingIndicatorProvider>();
    
    context.read<ChatBloc>().webSocketService.typingEvents.listen((event) {
      for (final userId in event.typingUserIds) {
        typingProvider.setUserTyping(
          conversationId: event.conversationId,
          userId: userId,
          isTyping: true,
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _messageController.dispose();
    _messageFocusNode.dispose();
    _fadeController.dispose();
    _backgroundController.dispose();
    _particleController.dispose();
    _glowController.dispose();
    _typingTimer?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _markMessagesAsRead();
    }
  }

  void _loadMessages() {
    context.read<ChatBloc>().add(
      LoadMessagesEvent(
        conversationId: widget.conversation.id,
      ),
    );
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final showButton = _scrollController.offset > 200;
      if (showButton != _showScrollToBottom) {
        setState(() {
          _showScrollToBottom = showButton;
        });
      }

      if (_scrollController.position.pixels == 
          _scrollController.position.maxScrollExtent) {
        _loadMoreMessages();
      }
    }
  }

  void _loadMoreMessages() {
    final state = context.read<ChatBloc>().state;
    if (state is ChatLoaded && !state.isLoadingMessages) {
      final messages = state.messages[widget.conversation.id] ?? [];
      if (messages.isNotEmpty) {
        context.read<ChatBloc>().add(
          LoadMessagesEvent(
            conversationId: widget.conversation.id,
            pageNumber: (messages.length ~/ 50) + 1,
            beforeMessageId: messages.last.id,
          ),
        );
      }
    }
  }

  void _onTypingChanged() {
    if (_messageController.text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      context.read<ChatBloc>().add(
        SendTypingIndicatorEvent(
          conversationId: widget.conversation.id,
          isTyping: true,
        ),
      );
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      if (_isTyping) {
        _isTyping = false;
        context.read<ChatBloc>().add(
          SendTypingIndicatorEvent(
            conversationId: widget.conversation.id,
            isTyping: false,
          ),
        );
      }
    });
  }

  void _markMessagesAsRead() {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) return;
    final state = context.read<ChatBloc>().state;
    if (state is ChatLoaded) {
      // Strong cast to Message to avoid generic runtime issues
      final List<Message> messages = (state.messages[widget.conversation.id] ?? []).cast<Message>();
      final unreadMessages = messages
          .where((m) => m.senderId != userId && !((m.deliveryReceipt?.readBy.contains(userId)) ?? false))
          .map((m) => m.id)
          .toList();
      
      if (unreadMessages.isNotEmpty) {
        context.read<ChatBloc>().add(
          MarkMessagesAsReadEvent(
            conversationId: widget.conversation.id,
            messageIds: unreadMessages,
          ),
        );
      }
    }
  }

  // FIXED: Scroll to reply message
  void _scrollToMessage(String messageId) {
    final key = _messageKeys[messageId];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutExpo,
        alignment: 0.5,
      );
      
      // Highlight animation
      HapticFeedback.lightImpact();
      // You can add a highlight animation here
    }
  }

  void _syncCurrentUser() {
    // محاولة الحصول مباشرةً من حالة AuthBloc الحالية
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _currentUserId = authState.user.userId; // استخدام userId الصحيح
    }
    // الاستماع للتغييرات المستقبلية مع إلغاء الاشتراك عند التخلص
    _authSubscription = context.read<AuthBloc>().stream.listen((state) {
      if (state is AuthAuthenticated && mounted) {
        if (_currentUserId != state.user.userId) {
          setState(() {
            _currentUserId = state.user.userId; // استخدام userId الصحيح
          });
          _markMessagesAsRead();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final effectiveUserId = _currentUserId ?? ''; // fallback مؤقت حتى يتم تحميل المستخدم
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          // Premium animated background
          _buildPremiumBackground(),
          
          // Floating particles
          _buildFloatingParticles(),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                ChatAppBar(
                  conversation: widget.conversation,
                  currentUserId: effectiveUserId,
                  onBackPressed: () => Navigator.pop(context),
                  onInfoPressed: () => _openChatSettings(),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      _buildMessagesListWithEffects(userId: effectiveUserId),
                      if (_showScrollToBottom) _buildFloatingScrollButton(),
                    ],
                  ),
                ),
                _buildPremiumBottomSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBackground() {
    return AnimatedBuilder(
      animation: Listenable.merge([_backgroundAnimation, _glowAnimation]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkBackground,
                AppTheme.darkBackground.withOpacity(0.95),
                AppTheme.darkSurface.withOpacity(0.9),
              ],
            ),
          ),
          child: CustomPaint(
            painter: _PremiumBackgroundPainter(
              animation: _backgroundAnimation.value,
              glowIntensity: _glowAnimation.value,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildFloatingParticles() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            animation: _particleController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildMessagesListWithEffects({required String userId}) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Consumer<TypingIndicatorProvider>(
          builder: (context, typingProvider, child) {
            final typingUsers = typingProvider.getTypingUsersForConversation(
              widget.conversation.id,
            );
            return BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state is! ChatLoaded) {
                  return _buildPremiumLoadingState();
                }

                // Strong cast to concrete Message list (underlying objects may be MessageModel)
                final List<Message> messages = (state.messages[widget.conversation.id] ?? []).cast<Message>();

                if (messages.isEmpty) {
                  return _buildPremiumEmptyState();
                }

                // Store message keys for scrolling
                for (final message in messages) {
                  _messageKeys[message.id] ??= GlobalKey();
                }

                return _buildMessagesList(messages, typingUsers, userId: userId);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPremiumLoadingState() {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.darkCard.withOpacity(0.5),
                        AppTheme.darkCard.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryBlue.withOpacity(0.6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'جاري تحميل الرسائل...',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppTheme.textWhite.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPremiumEmptyState() {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.darkCard.withOpacity(0.4),
                        AppTheme.darkCard.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryBlue.withOpacity(0.08),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryBlue.withOpacity(0.15),
                              AppTheme.primaryPurple.withOpacity(0.08),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.waving_hand_rounded,
                          size: 28,
                          color: AppTheme.primaryBlue.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            AppTheme.primaryBlue.withOpacity(0.8),
                            AppTheme.primaryPurple.withOpacity(0.8),
                          ],
                        ).createShader(bounds),
                        child: Text(
                          'ابدأ المحادثة',
                          style: AppTextStyles.heading3.copyWith(
                            color: AppTheme.textWhite,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'اكتب رسالتك الأولى للبدء',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppTheme.textMuted.withOpacity(0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessagesList(List<Message> messages, List<String> typingUsers, {required String userId}) {
    return ListView.builder(
      key: _listKey,
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ),
      physics: const BouncingScrollPhysics(),
      itemCount: messages.length + (typingUsers.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == 0 && typingUsers.isNotEmpty) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TypingIndicatorWidget(
              typingUserIds: typingUsers,
              conversation: widget.conversation,
            ),
          );
        }

        final messageIndex = typingUsers.isNotEmpty ? index - 1 : index;
        final message = messages[messageIndex];
        final previousMessage = messageIndex < messages.length - 1 ? messages[messageIndex + 1] : null;
        final nextMessage = messageIndex > 0 ? messages[messageIndex - 1] : null;

        final showDateSeparator = previousMessage == null || !_isSameDay(message.createdAt, previousMessage.createdAt);
        final isMe = message.senderId == userId && userId.isNotEmpty;

        // FIXED: Proper alignment for message bubbles
        return Column(
          key: _messageKeys[message.id],
          children: [
            if (showDateSeparator) _buildPremiumDateSeparator(message.createdAt),
            Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: MessageBubbleWidget(
                message: message,
                isMe: isMe,
                previousMessage: previousMessage,
                nextMessage: nextMessage,
                onReply: () => _setReplyTo(message),
                onEdit: isMe ? () => _startEditingMessage(message) : null,
                onDelete: isMe ? () => _deleteMessage(message) : null,
                onReaction: (reactionType) => _addReaction(message, reactionType, userId),
                onReplyTap: message.replyToMessageId != null ? () => _scrollToMessage(message.replyToMessageId!) : null,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPremiumDateSeparator(DateTime date) {
    final text = _getDateSeparatorText(date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 0.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppTheme.darkBorder.withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.darkCard.withOpacity(0.3),
                        AppTheme.darkCard.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppTheme.darkBorder.withOpacity(0.08),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    text,
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted.withOpacity(0.5),
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 0.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.darkBorder.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingScrollButton() {
    return Positioned(
      bottom: 8,
      right: 8,
      child: AnimatedScale(
        scale: _showScrollToBottom ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: GestureDetector(
              onTap: _scrollToBottom,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.darkCard.withOpacity(0.5),
                      AppTheme.darkCard.withOpacity(0.3),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primaryBlue.withOpacity(0.15),
                    width: 0.5,
                  ),
                ),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.textWhite.withOpacity(0.6),
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumBottomSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_replyToMessageId != null) _buildPremiumReplySection(),
        if (_editingMessage != null) _buildPremiumEditSection(),
        MessageInputWidget(
          controller: _messageController,
          focusNode: _messageFocusNode,
          conversationId: widget.conversation.id,
          replyToMessageId: _replyToMessageId,
          editingMessage: _editingMessage,
          onSend: _sendMessage,
          onAttachment: _pickAttachment,
          onLocation: _shareLocation,
          onCancelReply: () {
            setState(() {
              _replyToMessageId = null;
            });
          },
          onCancelEdit: () {
            setState(() {
              _editingMessage = null;
              _messageController.clear();
            });
          },
        ),
      ],
    );
  }

  Widget _buildPremiumReplySection() {
    final state = context.read<ChatBloc>().state;
    if (state is! ChatLoaded) return const SizedBox.shrink();
    
    final List<Message> messages = (state.messages[widget.conversation.id] ?? []).cast<Message>();

    Message? replyMessage;
    if (_replyToMessageId != null) {
      for (final m in messages) {
        if (m.id == _replyToMessageId) {
          replyMessage = m;
          break;
        }
      }
    }

    if (replyMessage == null) {
      return const SizedBox.shrink();
    }

    final currentUserId = _currentUserId;
    final displayName = currentUserId != null && replyMessage.senderId == currentUserId
        ? 'أنت'
        : 'مستخدم';

    return GestureDetector(
      onTap: () => _scrollToMessage(replyMessage!.id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.06),
                    AppTheme.primaryPurple.withOpacity(0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  left: BorderSide(
                    color: AppTheme.primaryBlue.withOpacity(0.8),
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayName,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppTheme.primaryBlue.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          (replyMessage.content ?? '').trim().isEmpty
                              ? '[محتوى غير نصي]'
                              : replyMessage.content!.trim(),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppTheme.textWhite.withOpacity(0.7),
                            fontSize: 11,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _replyToMessageId = null;
                      });
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppTheme.primaryBlue.withOpacity(0.15),
                          width: 0.5,
                        ),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: AppTheme.textWhite.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumEditSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.warning.withOpacity(0.06),
                  AppTheme.warning.withOpacity(0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border(
                left: BorderSide(
                  color: AppTheme.warning.withOpacity(0.8),
                  width: 2,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تعديل الرسالة',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.warning.withOpacity(0.7),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _editingMessage?.content ?? '',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 11,
                          color: AppTheme.textWhite.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _editingMessage = null;
                      _messageController.clear();
                    });
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 12,
                      color: AppTheme.textMuted.withOpacity(0.5),
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

  // Helper methods
  void _sendMessage(String content) {
    if (content.trim().isEmpty) return;

    HapticFeedback.lightImpact();

    if (_editingMessage != null) {
      context.read<ChatBloc>().add(
        EditMessageEvent(
          messageId: _editingMessage!.id,
          content: content,
        ),
      );
      setState(() {
        _editingMessage = null;
      });
    } else {
      context.read<ChatBloc>().add(
        SendMessageEvent(
          conversationId: widget.conversation.id,
          messageType: 'text',
          content: content,
          replyToMessageId: _replyToMessageId,
        ),
      );
      setState(() {
        _replyToMessageId = null;
      });
    }

    _messageController.clear();
    _scrollToBottom();
  }

  void _pickAttachment() {
    HapticFeedback.lightImpact();
    // Implement attachment picker
  }

  void _shareLocation() {
    HapticFeedback.lightImpact();
    // Implement location sharing
  }

  void _setReplyTo(Message message) {
    setState(() {
      _replyToMessageId = message.id;
    });
    _messageFocusNode.requestFocus();
  }

  void _startEditingMessage(Message message) {
    setState(() {
      _editingMessage = message;
      _messageController.text = message.content ?? '';
    });
    _messageFocusNode.requestFocus();
  }

  void _deleteMessage(Message message) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      barrierColor: Colors.black38,
      builder: (context) => _PremiumDeleteDialog(
        onConfirm: () {
          context.read<ChatBloc>().add(
            DeleteMessageEvent(messageId: message.id),
          );
          Navigator.pop(context);
        },
      ),
    );
  }

  void _addReaction(Message message, String reactionType, String userId) {
    HapticFeedback.lightImpact();
    
    final hasReaction = message.reactions.any(
      (r) => r.userId == userId && r.reactionType == reactionType,
    );

    if (hasReaction) {
      context.read<ChatBloc>().add(
        RemoveReactionEvent(
          messageId: message.id,
          reactionType: reactionType,
        ),
      );
    } else {
      context.read<ChatBloc>().add(
        AddReactionEvent(
          messageId: message.id,
          reactionType: reactionType,
        ),
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutExpo,
      );
    }
  }

  void _openChatSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatSettingsPage(
          conversation: widget.conversation,
        ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _getDateSeparatorText(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'اليوم';
    } else if (messageDate == yesterday) {
      return 'أمس';
    } else if (now.difference(date).inDays < 7) {
      final days = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
      return days[date.weekday % 7];
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// Premium Delete Dialog
class _PremiumDeleteDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const _PremiumDeleteDialog({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.darkCard.withOpacity(0.8),
                    AppTheme.darkCard.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.error.withOpacity(0.15),
                  width: 0.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.error.withOpacity(0.12),
                          AppTheme.error.withOpacity(0.06),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: AppTheme.error.withOpacity(0.8),
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'حذف الرسالة',
                    style: AppTextStyles.heading3.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'هل أنت متأكد من حذف هذه الرسالة؟',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.textMuted.withOpacity(0.6),
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppTheme.darkBorder.withOpacity(0.15),
                                width: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'إلغاء',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 12,
                                color: AppTheme.textWhite.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: onConfirm,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.error.withOpacity(0.7),
                                  AppTheme.error.withOpacity(0.5),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'حذف',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppTheme.textWhite,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
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
    );
  }
}

// Chat Particle
class _ChatParticle {
  double x = math.Random().nextDouble();
  double y = math.Random().nextDouble();
  double vx = (math.Random().nextDouble() - 0.5) * 0.0003;
  double vy = (math.Random().nextDouble() - 0.5) * 0.0003;
  double radius = math.Random().nextDouble() * 1.2 + 0.3;
  double opacity = math.Random().nextDouble() * 0.08 + 0.02;
  Color color = [
    AppTheme.primaryBlue,
    AppTheme.primaryPurple,
    AppTheme.primaryCyan,
  ][math.Random().nextInt(3)];

  void update() {
    x += vx;
    y += vy;
    if (x < 0 || x > 1) vx = -vx;
    if (y < 0 || y > 1) vy = -vy;
  }
}

// Painters
class _PremiumBackgroundPainter extends CustomPainter {
  final double animation;
  final double glowIntensity;

  _PremiumBackgroundPainter({
    required this.animation,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.2
      ..color = AppTheme.primaryBlue.withOpacity(0.02 * glowIntensity);

    const spacing = 30.0;
    final offset = animation * spacing;

    for (double x = -spacing + offset % spacing; x < size.width + spacing; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ParticlePainter extends CustomPainter {
  final List<_ChatParticle> particles;
  final double animation;

  _ParticlePainter({
    required this.particles,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      particle.update();
      
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      
      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
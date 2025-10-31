import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yemen_booking_app/core/theme/app_theme.dart';
import 'package:yemen_booking_app/core/theme/app_text_styles.dart';
import 'package:yemen_booking_app/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:yemen_booking_app/features/chat/presentation/pages/chat_page.dart';

class ConversationLoader extends StatefulWidget {
  final String conversationId;
  
  const ConversationLoader({required this.conversationId});
  
  @override
  State<ConversationLoader> createState() => ConversationLoaderState();
}

class ConversationLoaderState extends State<ConversationLoader> {
  @override
  void initState() {
    super.initState();
    _loadConversation();
  }
  
  void _loadConversation() {
    // حمل المحادثة من ChatBloc
    final chatBloc = context.read<ChatBloc>();
    final state = chatBloc.state;
    
    if (state is ChatLoaded) {
      final conversation = state.conversations.firstWhere(
        (c) => c.id == widget.conversationId,
        orElse: () => throw Exception('Conversation not found'),
      );
      
      // انتقل للصفحة مع المحادثة
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ChatPage(conversation: conversation),
          ),
        );
      });
    } else {
      // إذا لم تكن المحادثات محملة، حملها أولاً
      chatBloc.add(const LoadConversationsEvent());
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
            ),
            const SizedBox(height: 16),
            Text(
              'جاري تحميل المحادثة...',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
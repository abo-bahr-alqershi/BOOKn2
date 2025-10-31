import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/message.dart';
import '../bloc/chat_bloc.dart';

class MessageInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String conversationId;
  final String? replyToMessageId;
  final Message? editingMessage;
  final Function(String) onSend;
  final VoidCallback? onAttachment;
  final VoidCallback? onLocation;
  final VoidCallback? onCancelReply;
  final VoidCallback? onCancelEdit;

  const MessageInputWidget({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.conversationId,
    this.replyToMessageId,
    this.editingMessage,
    required this.onSend,
    this.onAttachment,
    this.onLocation,
    this.onCancelReply,
    this.onCancelEdit,
  });

  static MessageInputWidget createWithBloc({
    Key? key,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String conversationId,
    String? replyToMessageId,
    Message? editingMessage,
    required Function(String) onSend,
    VoidCallback? onAttachment,
    VoidCallback? onLocation,
    VoidCallback? onCancelReply,
    VoidCallback? onCancelEdit,
  }) {
    return MessageInputWidget(
      key: key,
      controller: controller,
      focusNode: focusNode,
      conversationId: conversationId,
      replyToMessageId: replyToMessageId,
      editingMessage: editingMessage,
      onSend: onSend,
      onAttachment: onAttachment,
      onLocation: onLocation,
      onCancelReply: onCancelReply,
      onCancelEdit: onCancelEdit,
    );
  }

  @override
  State<MessageInputWidget> createState() => _MessageInputWidgetState();
}

class _MessageInputWidgetState extends State<MessageInputWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _sendButtonAnimation;
  late Animation<double> _recordAnimation;

  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _showAttachmentOptions = false;
  String _recordingPath = '';
  Duration _recordingDuration = Duration.zero;

  ChatBloc? get _chatBloc => context.read<ChatBloc>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _sendButtonAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    _recordAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (widget.controller.text.isNotEmpty && _sendButtonAnimation.value == 0) {
      _animationController.forward();
    } else if (widget.controller.text.isEmpty && _sendButtonAnimation.value == 1) {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.only(
            left: 8,
            right: 8,
            top: 4,
            bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 4 : 8,
          ),
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
              top: BorderSide(
                color: AppTheme.darkBorder.withOpacity(0.03),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_showAttachmentOptions) 
                _buildMinimalAttachmentOptions(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildMinimalAttachmentButton(),
                  const SizedBox(width: 5),
                  Expanded(child: _buildMinimalInputField()),
                  const SizedBox(width: 5),
                  _buildMinimalActionButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalAttachmentOptions() {
    return Container(
      height: 64,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _MinimalAttachmentOption(
            icon: Icons.image_rounded,
            label: 'صورة',
            gradient: [
              AppTheme.primaryBlue.withOpacity(0.8),
              AppTheme.primaryBlue.withOpacity(0.6),
            ],
            onTap: () => _pickImage(ImageSource.gallery),
          ),
          _MinimalAttachmentOption(
            icon: Icons.camera_alt_rounded,
            label: 'كاميرا',
            gradient: [
              AppTheme.neonGreen.withOpacity(0.8),
              AppTheme.neonGreen.withOpacity(0.6),
            ],
            onTap: () => _pickImage(ImageSource.camera),
          ),
          _MinimalAttachmentOption(
            icon: Icons.videocam_rounded,
            label: 'فيديو',
            gradient: [
              AppTheme.error.withOpacity(0.8),
              AppTheme.error.withOpacity(0.6),
            ],
            onTap: _pickVideo,
          ),
          _MinimalAttachmentOption(
            icon: Icons.attach_file_rounded,
            label: 'ملف',
            gradient: [
              AppTheme.warning.withOpacity(0.8),
              AppTheme.warning.withOpacity(0.6),
            ],
            onTap: _pickFile,
          ),
          _MinimalAttachmentOption(
            icon: Icons.location_on_rounded,
            label: 'موقع',
            gradient: [
              AppTheme.primaryPurple.withOpacity(0.8),
              AppTheme.primaryPurple.withOpacity(0.6),
            ],
            onTap: () {
              setState(() {
                _showAttachmentOptions = false;
              });
              widget.onLocation?.call();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalAttachmentButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _showAttachmentOptions = !_showAttachmentOptions;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: _showAttachmentOptions
              ? LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.8),
                    AppTheme.primaryPurple.withOpacity(0.7),
                  ],
                )
              : null,
          color: !_showAttachmentOptions
              ? AppTheme.darkCard.withOpacity(0.4)
              : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _showAttachmentOptions
                ? Colors.white.withOpacity(0.15)
                : AppTheme.darkBorder.withOpacity(0.15),
            width: 0.5,
          ),
        ),
        child: AnimatedRotation(
          duration: const Duration(milliseconds: 200),
          turns: _showAttachmentOptions ? 0.125 : 0,
          child: Icon(
            Icons.add_rounded,
            color: _showAttachmentOptions 
                ? Colors.white 
                : AppTheme.textMuted.withOpacity(0.5),
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalInputField() {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 32,
        maxHeight: 80,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.5),
            AppTheme.darkCard.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.focusNode.hasFocus
              ? AppTheme.primaryBlue.withOpacity(0.2)
              : AppTheme.darkBorder.withOpacity(0.08),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              maxLines: null,
              textInputAction: TextInputAction.newline,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 12,
                color: AppTheme.textWhite.withOpacity(0.9),
                height: 1.3,
              ),
              decoration: InputDecoration(
                hintText: widget.editingMessage != null
                    ? 'تعديل الرسالة...'
                    : widget.replyToMessageId != null
                        ? 'اكتب ردك...'
                        : 'اكتب رسالة...',
                hintStyle: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.textMuted.withOpacity(0.35),
                  fontSize: 12,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                isDense: true,
              ),
              onSubmitted: (text) {
                if (text.trim().isNotEmpty) {
                  widget.onSend(text);
                }
              },
            ),
          ),
          GestureDetector(
            onTap: _insertEmoji,
            child: Container(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.emoji_emotions_outlined,
                color: AppTheme.textMuted.withOpacity(0.35),
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalActionButton() {
    return AnimatedBuilder(
      animation: _sendButtonAnimation,
      builder: (context, child) {
        final showSend = _sendButtonAnimation.value > 0.5;
        
        return GestureDetector(
          onTap: showSend ? _sendMessage : null,
          onLongPress: !showSend ? _startRecording : null,
          onLongPressEnd: !showSend ? (_) => _stopRecording() : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: showSend || _isRecording
                  ? LinearGradient(
                      colors: [
                        AppTheme.primaryBlue.withOpacity(0.8),
                        AppTheme.primaryPurple.withOpacity(0.7),
                      ],
                    )
                  : null,
              color: !showSend && !_isRecording
                  ? AppTheme.darkCard.withOpacity(0.4)
                  : null,
              shape: BoxShape.circle,
              border: Border.all(
                color: showSend || _isRecording
                    ? Colors.white.withOpacity(0.15)
                    : AppTheme.darkBorder.withOpacity(0.15),
                width: 0.5,
              ),
              boxShadow: showSend || _isRecording
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: _isRecording
                    ? _buildMinimalRecordingIndicator()
                    : Icon(
                        showSend
                            ? Icons.send_rounded
                            : Icons.mic_rounded,
                        color: showSend || _isRecording
                            ? Colors.white
                            : AppTheme.textMuted.withOpacity(0.5),
                        size: 16,
                        key: ValueKey(showSend),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMinimalRecordingIndicator() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _recordAnimation.value,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.error.withOpacity(0.8),
                  AppTheme.error.withOpacity(0.6),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.error.withOpacity(0.4),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _sendMessage() {
    final text = widget.controller.text.trim();
    if (text.isNotEmpty) {
      HapticFeedback.lightImpact();
      widget.onSend(text);
    }
  }

  Future<void> _startRecording() async {
    HapticFeedback.mediumImpact();
    
    final permission = await Permission.microphone.request();
    if (!permission.isGranted) return;

    if (await _audioRecorder.hasPermission()) {
      final directory = Directory.systemTemp;
      _recordingPath = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      
      await _audioRecorder.start(
        const RecordConfig(),
        path: _recordingPath,
      );
      
      setState(() {
        _isRecording = true;
      });
      
      _animationController.repeat(reverse: true);
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    
    HapticFeedback.mediumImpact();
    _animationController.stop();
    
    final path = await _audioRecorder.stop();
    
    setState(() {
      _isRecording = false;
    });
    
    if (path != null) {
      _sendAudioMessage(path);
    }
  }

  void _sendAudioMessage(String path) async {
    try {
      // Upload the audio file as part of the message sending process
      await _sendMessageWithAudioFile(path);
    } catch (e) {
      // Handle error appropriately
      print('Error sending audio message: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    
    if (image != null) {
      setState(() {
        _showAttachmentOptions = false;
      });
      // Send image
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 5),
    );
    
    if (video != null) {
      setState(() {
        _showAttachmentOptions = false;
      });
      // Send video
    }
  }

  void _pickFile() {
    setState(() {
      _showAttachmentOptions = false;
    });
    // Implement file picker
  }

  void _insertEmoji() {
    HapticFeedback.lightImpact();
    // Show emoji picker
  }

  Future<void> _sendMessageWithAudioFile(String filePath) async {
    if (_chatBloc == null) {
      print('ChatBloc not available');
      return;
    }

    try {
      // Send the audio message using the new dedicated event
      _chatBloc!.add(SendAudioMessageEvent(
        conversationId: widget.conversationId,
        filePath: filePath,
        replyToMessageId: widget.replyToMessageId,
      ));

    } catch (e) {
      print('Error sending audio message: $e');
    }
  }
}

class _MinimalAttachmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _MinimalAttachmentOption({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 56,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: gradient.first.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 9,
                color: AppTheme.textMuted.withOpacity(0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
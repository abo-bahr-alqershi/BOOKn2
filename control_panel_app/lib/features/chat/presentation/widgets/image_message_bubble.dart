import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/attachment.dart';
import '../models/image_upload_info.dart';
import 'message_status_indicator.dart';
import 'whatsapp_style_image_grid.dart';
import 'expandable_image_viewer.dart';
import '../bloc/chat_bloc.dart';
import 'reaction_picker_widget.dart';

class ImageMessageBubble extends StatefulWidget {
  final Message message;
  final bool isMe;
  final List<ImageUploadInfo>? uploadingImages;
  final void Function(Attachment)? onReply;
  final Function(String)? onReaction;
  final VoidCallback? onReplyTap; // FIX: إضافة دعم النقر على الرد

  const ImageMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.uploadingImages,
    this.onReply,
    this.onReaction,
    this.onReplyTap, // FIX: إضافة parameter
  });

  @override
  State<ImageMessageBubble> createState() => _ImageMessageBubbleState();
}

class _ImageMessageBubbleState extends State<ImageMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _showReactions = false;
  final Map<String, String> _attachmentReactions = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
    _loadExistingReactions();
  }

  void _loadExistingReactions() {
    if (widget.message.reactions.isNotEmpty &&
        widget.message.attachments.isNotEmpty) {
      for (var i = 0;
          i < widget.message.reactions.length &&
              i < widget.message.attachments.length;
          i++) {
        _attachmentReactions[widget.message.attachments[i].id] =
            widget.message.reactions[i].reactionType;
      }
    }
  }

  @override
  void didUpdateWidget(covariant ImageMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    // FIX المشكلة 2: تحديث فوري عند تغيير الـ reactions
    if (oldWidget.message.reactions.length != widget.message.reactions.length) {
      _loadExistingReactions();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Align(
          alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.only(
              left: widget.isMe ? MediaQuery.of(context).size.width * 0.2 : 8,
              right: widget.isMe ? 8 : MediaQuery.of(context).size.width * 0.2,
              top: 4,
              bottom: 2,
            ),
            child: GestureDetector(
              onLongPress: _showOptions,
              onDoubleTap: _handleDoubleTap,
              child: _buildBubbleContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBubbleContent() {
    if (widget.uploadingImages != null && widget.uploadingImages!.isNotEmpty) {
      final allCompleted =
          widget.uploadingImages!.every((img) => img.isCompleted);
      if (allCompleted) {
        return const SizedBox.shrink();
      }
      return _buildUploadingBubble();
    }

    if (widget.message.attachments.isNotEmpty) {
      return _buildCompletedBubble();
    }

    if (widget.message.messageType == 'image' &&
        (widget.message.content != null &&
            widget.message.content!.isNotEmpty)) {
      return _buildSingleContentImage(widget.message.content!);
    }

    return const SizedBox.shrink();
  }

  Widget _buildUploadingBubble() {
    final images = widget.uploadingImages!;
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth * 0.65;
    double bubbleWidth = maxWidth;

    return Container(
      width: bubbleWidth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isMe
              ? AppTheme.primaryBlue.withValues(alpha: 0.2)
              : AppTheme.darkBorder.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            _buildImageGrid(images),
            _buildProgressOverlay(images),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedBubble() {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth * 0.65;
    double bubbleWidth = maxWidth;

    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        // FIX المشكلة 2: تحديث الريآكشنات من الحالة الحالية
        if (state is ChatLoaded) {
          final List<Message> messages =
              (state.messages[widget.message.conversationId] ?? [])
                  .cast<Message>();
          final currentMessage = messages.firstWhere(
            (m) => m.id == widget.message.id,
            orElse: () => widget.message,
          );

          // مزامنة التفاعلات فوراً
          if (currentMessage.reactions.isNotEmpty) {
            for (var i = 0;
                i < currentMessage.reactions.length &&
                    i < currentMessage.attachments.length;
                i++) {
              final newReaction = currentMessage.reactions[i].reactionType;
              final attachmentId = currentMessage.attachments[i].id;
              if (_attachmentReactions[attachmentId] != newReaction) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _attachmentReactions[attachmentId] = newReaction;
                    });
                  }
                });
              }
            }
          }
        }

        final bubble = Container(
          width: bubbleWidth,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isMe
                  ? AppTheme.primaryBlue.withValues(alpha: 0.1)
                  : AppTheme.darkBorder.withValues(alpha: 0.05),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FIX: إضافة بطاقة الرد في رسائل الصور
              if (widget.message.replyToMessageId != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: _buildReplyPreviewForImage(),
                ),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: GestureDetector(
                      onLongPress: widget.message.attachments.length == 1
                          ? _showOptions
                          : null,
                      onDoubleTap: _handleDoubleTap,
                      child: WhatsAppStyleImageGrid(
                        images: widget.message.attachments,
                        isMe: widget.isMe,
                        onReaction: (reactionType) {
                          widget.onReaction?.call(reactionType);
                        },
                        onReply: (attachment) {
                          if (widget.onReply != null) {
                            widget.onReply!(attachment);
                          }
                        },
                        reactionsByAttachment: _attachmentReactions,
                        onReactForAttachment: (attachment, reaction) {
                          // FIX المشكلة 2: تحديث فوري في الحالة المحلية
                          setState(() {
                            _attachmentReactions[attachment.id] = reaction;
                          });
                          // إرسال للـ Bloc
                          widget.onReaction?.call(reaction);
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 8,
                    child: _buildMessageFooter(),
                  ),
                ],
              ),
            ],
          ),
        );

        if (widget.message.reactions.isNotEmpty || _showReactions) {
          return Column(
            crossAxisAlignment:
                widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              bubble,
              const SizedBox(height: 4),
              if (_showReactions)
                ReactionPickerWidget(
                  onReaction: (reaction) {
                    widget.onReaction?.call(reaction);
                    setState(() => _showReactions = false);
                  },
                )
              else
                _buildMinimalReactions(),
            ],
          );
        }

        return bubble;
      },
    );
  }

  Message? _findReplyMessage() {
    final replyId = widget.message.replyToMessageId;
    if (replyId == null) return null;

    final chatBloc = context.read<ChatBloc>();
    final chatState = chatBloc.state;
    if (chatState is! ChatLoaded) return null;

    final List<Message> messages =
        (chatState.messages[widget.message.conversationId] ?? [])
            .cast<Message>();

    for (final m in messages) {
      if (m.id == replyId) return m;
    }
    return null;
  }

  Widget _buildReplyPreviewForImage() {
    final replyMessage = _findReplyMessage();

    return GestureDetector(
      onTap: () {
        if (widget.onReplyTap != null) {
          HapticFeedback.selectionClick();
          widget.onReplyTap!();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.isMe
                ? [
                    Colors.white.withValues(alpha: 0.12),
                    Colors.white.withValues(alpha: 0.06),
                  ]
                : [
                    AppTheme.primaryBlue.withValues(alpha: 0.06),
                    AppTheme.primaryBlue.withValues(alpha: 0.03),
                  ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: widget.isMe
                  ? Colors.white.withValues(alpha: 0.5)
                  : AppTheme.primaryBlue.withValues(alpha: 0.8),
              width: 2,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.reply,
                  size: 12,
                  color: widget.isMe
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppTheme.primaryBlue.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  'رد على رسالة',
                  style: AppTextStyles.caption.copyWith(
                    color: widget.isMe
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppTheme.primaryBlue.withValues(alpha: 0.8),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              replyMessage?.content ?? 'رسالة محذوفة',
              style: AppTextStyles.caption.copyWith(
                color: widget.isMe
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppTheme.textMuted.withValues(alpha: 0.6),
                fontSize: 10,
                fontStyle:
                    replyMessage == null ? FontStyle.italic : FontStyle.normal,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleContentImage(String url) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth * 0.65;
    final bubbleWidth = maxWidth;

    return GestureDetector(
      onTap: () => _openViewerForSingleContentImage(url),
      onLongPress: () => _openViewerForSingleContentImage(url),
      child: Container(
        width: bubbleWidth,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isMe
                ? AppTheme.primaryBlue.withValues(alpha: 0.1)
                : AppTheme.darkBorder.withValues(alpha: 0.05),
            width: 0.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedImageWidget(
                  imageUrl: url,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  bottom: 4,
                  right: 8,
                  child: _buildMessageFooter(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openViewerForSingleContentImage(String url) {
    final attachment = Attachment(
      id: 'inline_${widget.message.id}',
      conversationId: widget.message.conversationId,
      fileName: url.split('/').isNotEmpty ? url.split('/').last : 'image.jpg',
      contentType: 'image/jpeg',
      fileSize: 0,
      filePath: '',
      fileUrl: url,
      url: url,
      uploadedBy: widget.message.senderId,
      createdAt: widget.message.createdAt,
    );

    // FIX المشكلة 2: callback فوري عند العودة
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ExpandableImageViewer(
          images: [attachment],
          initialIndex: 0,
          onReaction: widget.onReaction,
          onReply: widget.onReply,
          initialReactionsByAttachment: _attachmentReactions,
          onReactForAttachment: (att, reaction) {
            // تحديث فوري
            if (mounted) {
              setState(() {
                _attachmentReactions[att.id] = reaction;
              });
            }
            widget.onReaction?.call(reaction);
          },
        ),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ).then((_) {
      // FIX المشكلة 2: إعادة بناء عند العودة لضمان التحديث
      if (mounted) {
        setState(() {});
      }
    });
  }

  Widget _buildImageGrid(List<ImageUploadInfo> images) {
    final count = images.length;

    if (count == 1) {
      return _buildSingleImageUploading(images.first);
    } else if (count == 2) {
      return _buildTwoImagesUploading(images);
    } else if (count == 3) {
      return _buildThreeImagesUploading(images);
    } else if (count == 4) {
      return _buildFourImagesUploading(images);
    } else {
      return _buildMoreImagesUploading(images);
    }
  }

  Widget _buildSingleImageUploading(ImageUploadInfo image) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (image.file != null)
            Image.file(
              image.file!,
              fit: BoxFit.cover,
              color: Colors.black.withValues(alpha: 0.2),
              colorBlendMode: BlendMode.darken,
            ),
          if (image.progress < 1.0)
            Center(
              child: _buildCircularProgress(image.progress),
            ),
        ],
      ),
    );
  }

  Widget _buildTwoImagesUploading(List<ImageUploadInfo> images) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Row(
        children: [
          Expanded(child: _buildImageUploadTile(images[0])),
          const SizedBox(width: 2),
          Expanded(child: _buildImageUploadTile(images[1])),
        ],
      ),
    );
  }

  Widget _buildThreeImagesUploading(List<ImageUploadInfo> images) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildImageUploadTile(images[0]),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _buildImageUploadTile(images[1])),
                const SizedBox(height: 2),
                Expanded(child: _buildImageUploadTile(images[2])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFourImagesUploading(List<ImageUploadInfo> images) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildImageUploadTile(images[0])),
                const SizedBox(width: 2),
                Expanded(child: _buildImageUploadTile(images[1])),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildImageUploadTile(images[2])),
                const SizedBox(width: 2),
                Expanded(child: _buildImageUploadTile(images[3])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreImagesUploading(List<ImageUploadInfo> images) {
    final displayImages = images.take(4).toList();
    final remainingCount = images.length - 4;

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildImageUploadTile(displayImages[0])),
                const SizedBox(width: 2),
                Expanded(child: _buildImageUploadTile(displayImages[1])),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildImageUploadTile(displayImages[2])),
                const SizedBox(width: 2),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildImageUploadTile(displayImages[3]),
                      if (remainingCount > 0)
                        Container(
                          color: Colors.black.withValues(alpha: 0.6),
                          child: Center(
                            child: Text(
                              '+$remainingCount',
                              style: AppTextStyles.heading2.copyWith(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploadTile(ImageUploadInfo image) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (image.file != null)
          Image.file(
            image.file!,
            fit: BoxFit.cover,
            color: image.progress < 1.0
                ? Colors.black.withValues(alpha: 0.3)
                : null,
            colorBlendMode: image.progress < 1.0 ? BlendMode.darken : null,
          ),
        if (image.progress < 1.0)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: Center(
              child: _buildCircularProgress(image.progress),
            ),
          ),
        if (image.isFailed)
          Container(
            color: AppTheme.error.withValues(alpha: 0.3),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'فشل الرفع',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (image.isCompleted && !image.isFailed)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCircularProgress(double progress) {
    return Container(
      width: 48,
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
      child: CircularProgressIndicator(
        value: progress,
        strokeWidth: 3,
        backgroundColor: Colors.white.withValues(alpha: 0.3),
        valueColor: AlwaysStoppedAnimation<Color>(
          Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );
  }

  Widget _buildProgressOverlay(List<ImageUploadInfo> images) {
    final totalProgress = images.isEmpty
        ? 0.0
        : images.map((img) => img.progress).fold<double>(0.0, (a, b) => a + b) /
            images.length;

    final uploadingCount =
        images.where((img) => !img.isCompleted && !img.isFailed).length;
    final failedCount = images.where((img) => img.isFailed).length;

    if (uploadingCount == 0 && failedCount == 0) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(12),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.0),
                  Colors.black.withValues(alpha: 0.6),
                ],
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.cloud_upload,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            failedCount > 0
                                ? 'فشل رفع $failedCount صورة'
                                : 'جاري الرفع... ${(totalProgress * 100).toInt()}%',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: totalProgress,
                        minHeight: 2,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          failedCount > 0
                              ? AppTheme.error
                              : AppTheme.success.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (failedCount > 0) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _retryFailedUploads,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatTime(widget.message.createdAt),
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 10,
            ),
          ),
          if (widget.isMe) ...[
            const SizedBox(width: 3),
            MessageStatusIndicator(
              status: widget.message.status,
              color: Colors.white.withValues(alpha: 0.8),
              size: 12,
            ),
          ],
        ],
      ),
    );
  }

  void _showOptions() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ImageMessageOptionsSheet(
          isMe: widget.isMe,
          onReply: widget.onReply == null || widget.message.attachments.isEmpty
              ? null
              : () => widget.onReply!(widget.message.attachments.first),
        );
      },
    );
  }

  void _handleDoubleTap() {
    HapticFeedback.lightImpact();
    setState(() {
      _showReactions = !_showReactions;
    });
  }

  void _retryFailedUploads() {
    HapticFeedback.mediumImpact();
    final uploads = widget.uploadingImages ?? const <ImageUploadInfo>[];
    final failed = uploads.where((u) => u.isFailed && u.file != null).toList();
    if (failed.isEmpty) return;

    for (final item in failed) {
      final filePath = item.file!.path;
      final uploadId = item.id;
      context
          .read<ChatBloc>()
          .uploadAttachmentWithProgress(
            conversationId: widget.message.conversationId,
            filePath: filePath,
            messageType: 'image',
            onProgress: (sent, total) {
              final ratio = total > 0 ? sent / total : 0.0;
              context.read<ChatBloc>().add(
                    UpdateImageUploadProgressEvent(
                      conversationId: widget.message.conversationId,
                      uploadId: uploadId,
                      progress: ratio,
                    ),
                  );
            },
          )
          .then((_) {
        context.read<ChatBloc>().add(
              UpdateImageUploadProgressEvent(
                conversationId: widget.message.conversationId,
                uploadId: uploadId,
                progress: 1.0,
                isCompleted: true,
              ),
            );
      }).catchError((e) {
        context.read<ChatBloc>().add(
              UpdateImageUploadProgressEvent(
                conversationId: widget.message.conversationId,
                uploadId: uploadId,
                isFailed: true,
                error: e.toString(),
              ),
            );
      });
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildMinimalReactions() {
    final groupedReactions = <String, int>{};
    for (final reaction in widget.message.reactions) {
      groupedReactions[reaction.reactionType] =
          (groupedReactions[reaction.reactionType] ?? 0) + 1;
    }

    return Wrap(
      spacing: 2,
      runSpacing: 2,
      children: groupedReactions.entries.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkCard.withValues(alpha: 0.5),
                AppTheme.darkCard.withValues(alpha: 0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.darkBorder.withValues(alpha: 0.15),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_getEmojiForReaction(entry.key),
                  style: const TextStyle(fontSize: 10)),
              if (entry.value > 1) ...[
                const SizedBox(width: 2),
                Text(
                  entry.value.toString(),
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textWhite.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getEmojiForReaction(String reactionType) {
    switch (reactionType) {
      case 'like':
        return '👍';
      case 'love':
        return '❤️';
      case 'laugh':
        return '😂';
      case 'sad':
        return '😢';
      case 'angry':
        return '😠';
      case 'wow':
        return '😮';
      default:
        return '👍';
    }
  }
}

class _ImageMessageOptionsSheet extends StatelessWidget {
  final bool isMe;
  final VoidCallback? onReply;

  const _ImageMessageOptionsSheet({required this.isMe, this.onReply});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.darkCard.withValues(alpha: 0.85),
                AppTheme.darkCard.withValues(alpha: 0.9),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(
              color: AppTheme.darkBorder.withValues(alpha: 0.08),
              width: 0.5,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.darkBorder.withValues(alpha: 0.2),
                        AppTheme.darkBorder.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
                if (onReply != null)
                  _buildOption(
                    context,
                    icon: Icons.reply_rounded,
                    title: 'رد',
                    onTap: () {
                      Navigator.pop(context);
                      onReply!.call();
                    },
                  ),
                _buildOption(
                  context,
                  icon: Icons.download_rounded,
                  title: 'حفظ الصورة',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                if (isMe)
                  _buildOption(
                    context,
                    icon: Icons.delete_rounded,
                    title: 'حذف',
                    onTap: () {
                      Navigator.pop(context);
                    },
                    isDestructive: true,
                  ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDestructive
                      ? [
                          AppTheme.error.withValues(alpha: 0.12),
                          AppTheme.error.withValues(alpha: 0.06),
                        ]
                      : [
                          AppTheme.primaryBlue.withValues(alpha: 0.08),
                          AppTheme.primaryPurple.withValues(alpha: 0.04),
                        ],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: isDestructive
                    ? AppTheme.error.withValues(alpha: 0.8)
                    : AppTheme.primaryBlue.withValues(alpha: 0.8),
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDestructive
                    ? AppTheme.error.withValues(alpha: 0.8)
                    : AppTheme.textWhite.withValues(alpha: 0.8),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

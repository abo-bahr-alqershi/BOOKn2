import 'dart:math' as math;
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bookn_cp_app/injection_container.dart';
import 'package:bookn_cp_app/services/local_storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../../../core/constants/storage_constants.dart';
import '../../../../core/utils/image_utils.dart';
import '../../domain/entities/attachment.dart';
import '../../data/datasources/chat_local_datasource.dart';
import 'dart:io';

class AttachmentPreviewWidget extends StatefulWidget {
  final Attachment attachment;
  final bool isMe;
  final VoidCallback? onTap;
  final VoidCallback? onDownload;
  // Optional override to force audio UI when server MIME is generic
  final bool forceAudio;

  const AttachmentPreviewWidget({
    super.key,
    required this.attachment,
    required this.isMe,
    this.onTap,
    this.onDownload,
    this.forceAudio = false,
  });

  @override
  State<AttachmentPreviewWidget> createState() =>
      _AttachmentPreviewWidgetState();
}

class _AttachmentPreviewWidgetState extends State<AttachmentPreviewWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;
  Size? _displaySize;

  // Audio player for voice messages
  AudioPlayer? _audioPlayer;
  PlayerState? _playerState;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(
      begin: -1,
      end: 2,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOutSine,
    ));

    if (widget.attachment.downloadProgress != null &&
        widget.attachment.downloadProgress! < 1.0) {
      _shimmerController.repeat();
    }
    _resolveImageDimensions();

    // Lazy init audio only when needed
  }

  @override
  void dispose() {
    _removeImageStreamListener();
    _shimmerController.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AttachmentPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attachment.fileUrl != widget.attachment.fileUrl) {
      _resolveImageDimensions();
    }
  }

  void _resolveImageDimensions() {
    _removeImageStreamListener();
    final resolvedUrl = ImageUtils.resolveUrl(widget.attachment.fileUrl);
    if (resolvedUrl.isEmpty) {
      setState(() {
        _displaySize = const Size(180, 180);
      });
      return;
    }

    final headers = _buildAuthHeaders();
    final provider = CachedNetworkImageProvider(resolvedUrl, headers: headers);
    final stream = provider.resolve(const ImageConfiguration());
    final listener = ImageStreamListener((imageInfo, _) {
      final width = imageInfo.image.width / imageInfo.scale;
      final height = imageInfo.image.height / imageInfo.scale;
      final constrained = _constrainSize(Size(width, height));
      if (mounted) {
        setState(() {
          _displaySize = constrained;
        });
      }
      _removeImageStreamListener();
    }, onError: (_, __) {
      _removeImageStreamListener();
    });

    stream.addListener(listener);
    _imageStream = stream;
    _imageStreamListener = listener;
  }

  void _removeImageStreamListener() {
    if (_imageStream != null && _imageStreamListener != null) {
      _imageStream!.removeListener(_imageStreamListener!);
    }
    _imageStream = null;
    _imageStreamListener = null;
  }

  Size _constrainSize(Size original) {
    const maxWidth = 300.0;
    const maxHeight = 300.0;
    double width = original.width;
    double height = original.height;

    if (width <= 0 || height <= 0) {
      return const Size(180, 180);
    }

    if (width > maxWidth || height > maxHeight) {
      final widthScale = maxWidth / width;
      final heightScale = maxHeight / height;
      final scale = math.min(widthScale, heightScale);
      width *= scale;
      height *= scale;
    }

    return Size(width, height);
  }

  Map<String, String>? _buildAuthHeaders() {
    try {
      final local = sl<LocalStorageService>();
      final token = local.getData(StorageConstants.accessToken) as String?;
      if (token != null && token.isNotEmpty) {
        return {'Authorization': 'Bearer $token'};
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.attachment.isImage) {
      return _buildImagePreview();
    } else if (widget.attachment.isVideo) {
      return _buildVideoPreview();
    } else if (widget.forceAudio || widget.attachment.isAudio) {
      return _buildAudioPreview();
    } else {
      return _buildDocumentPreview();
    }
  }

  Widget _buildImagePreview() {
    final size = _displaySize ?? const Size(180, 180);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap?.call();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.isMe
                          ? AppTheme.primaryBlue.withValues(alpha: 0.05)
                          : AppTheme.darkCard.withValues(alpha: 0.3),
                      widget.isMe
                          ? AppTheme.primaryPurple.withValues(alpha: 0.03)
                          : AppTheme.darkSurface.withValues(alpha: 0.2),
                    ],
                  ),
                ),
              ),
              CachedImageWidget(
                imageUrl: widget.attachment.fileUrl,
                fit: BoxFit.cover,
                width: size.width,
                height: size.height,
              ),
              if (widget.attachment.downloadProgress != null &&
                  widget.attachment.downloadProgress! < 1.0)
                _buildMinimalProgressOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _loadLocalVideoThumb(String attachmentId) async {
    try {
      final local = sl<ChatLocalDataSource>();
      return await local.getThumbnail('attachment_$attachmentId');
    } catch (_) {
      return null;
    }
  }

  Widget _buildVideoPreview() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap?.call();
      },
      child: Container(
        height: 160, // Reduced from 200
        margin: const EdgeInsets.all(6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Prefer local cached thumbnail if available
              FutureBuilder<String?>(
                future: _loadLocalVideoThumb(widget.attachment.id),
                builder: (context, snap) {
                  final path = snap.data;
                  if (path != null && path.isNotEmpty && File(path).existsSync()) {
                    return Image.file(File(path), fit: BoxFit.cover);
                  }
                  if (widget.attachment.thumbnailUrl != null) {
                    return CachedImageWidget(
                      imageUrl: widget.attachment.thumbnailUrl!,
                      fit: BoxFit.cover,
                    );
                  }
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.darkCard.withValues(alpha: 0.8),
                          AppTheme.darkSurface.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.videocam_rounded,
                      size: 32, // Reduced from 48
                      color: AppTheme.textMuted.withValues(alpha: 0.5),
                    ),
                  );
                },
              ),

              // Glassmorphism play button
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: 44, // Reduced from 56
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.15),
                            Colors.white.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 0.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 24, // Reduced from 32
                      ),
                    ),
                  ),
                ),
              ),

              // Duration badge
              Positioned(
                bottom: 6,
                right: 6,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _formatDuration(widget.attachment.duration),
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              if (widget.attachment.downloadProgress != null &&
                  widget.attachment.downloadProgress! < 1.0)
                _buildMinimalProgressOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioPreview() {
    _ensureAudioInitialized();
    final totalSeconds = widget.attachment.duration ?? _duration.inSeconds;
    final pos = _position;
    final dur = _duration.inMilliseconds > 0
        ? _duration
        : Duration(seconds: totalSeconds);
    final isPlaying = _playerState?.playing == true;

    return Container(
      margin: const EdgeInsets.all(6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(10), // Reduced from 12
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.isMe
                    ? [
                        Colors.white.withValues(alpha: 0.08),
                        Colors.white.withValues(alpha: 0.04),
                      ]
                    : [
                        AppTheme.darkCard.withValues(alpha: 0.6),
                        AppTheme.darkCard.withValues(alpha: 0.3),
                      ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.isMe
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppTheme.darkBorder.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                // Play button
                GestureDetector(
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    if (isPlaying) {
                      await _audioPlayer?.pause();
                    } else {
                      await _audioPlayer?.play();
                    }
                  },
                  child: Container(
                    width: 32, // Reduced from 40
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.isMe
                            ? [
                                Colors.white.withValues(alpha: 0.9),
                                Colors.white.withValues(alpha: 0.7)
                              ]
                            : [AppTheme.primaryBlue, AppTheme.primaryPurple],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (widget.isMe
                                  ? Colors.white
                                  : AppTheme.primaryBlue)
                              .withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: widget.isMe ? AppTheme.primaryBlue : Colors.white,
                      size: 18, // Reduced from 24
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Waveform
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUploadAwareWaveform(
                          widget.attachment.downloadProgress ?? 1.0),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            _formatDuration(pos.inSeconds),
                            style: AppTextStyles.caption.copyWith(
                              color: widget.isMe
                                  ? Colors.white.withValues(alpha: 0.6)
                                  : AppTheme.textMuted.withValues(alpha: 0.7),
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Slider(
                              value: (widget.attachment.downloadProgress !=
                                          null &&
                                      (widget.attachment.downloadProgress ??
                                              0) <
                                          1.0)
                                  ? (widget.attachment.downloadProgress!
                                      .clamp(0.0, 1.0))
                                  : (dur.inMilliseconds == 0
                                      ? 0
                                      : (pos.inMilliseconds
                                              .clamp(0, dur.inMilliseconds) /
                                          dur.inMilliseconds)),
                              onChanged: (v) async {
                                // أثناء الرفع نمنع السحب (لأن الملف غير متاح بعد)
                                if ((widget.attachment.downloadProgress ??
                                        1.0) <
                                    1.0) return;
                                if (dur.inMilliseconds > 0) {
                                  final target = Duration(
                                      milliseconds:
                                          (v * dur.inMilliseconds).toInt());
                                  await _audioPlayer?.seek(target);
                                }
                              },
                              min: 0,
                              max: 1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatDuration(dur.inSeconds),
                            style: AppTextStyles.caption.copyWith(
                              color: widget.isMe
                                  ? Colors.white.withValues(alpha: 0.6)
                                  : AppTheme.textMuted.withValues(alpha: 0.7),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadAwareWaveform(double progress) {
    return SizedBox(
      height: 24,
      child: AnimatedBuilder(
        animation: _shimmerAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: _MinimalWaveformPainter(
              color: widget.isMe ? Colors.white : AppTheme.primaryBlue,
              progress: progress,
              shimmerPosition: _shimmerAnimation.value,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }

  void _ensureAudioInitialized() {
    if (_audioPlayer != null) return;
    _audioPlayer = AudioPlayer();

    // Build authenticated URL
    final rawUrl = widget.attachment.fileUrl;
    final resolvedUrl = rawUrl.startsWith('/api/')
        ? ImageUtils.resolveApiUrl(rawUrl)
        : ImageUtils.resolveUrl(rawUrl);
    final headers = _buildAuthHeaders() ?? {};

    // Set audio source with headers
    _audioPlayer!
        .setAudioSource(AudioSource.uri(Uri.parse(resolvedUrl),
            headers: headers.isEmpty ? null : headers))
        .then((_) async {
      try {
        final d = await _audioPlayer!.durationStream.firstWhere(
          (d) => d != null,
          orElse: () => null,
        );
        if (d != null && mounted) setState(() => _duration = d);
      } catch (_) {}
    }).catchError((_) {});

    _audioPlayer!.playerStateStream.listen((s) {
      if (!mounted) return;
      setState(() => _playerState = s);
    });
    _audioPlayer!.positionStream.listen((p) {
      if (!mounted) return;
      setState(() => _position = p);
    });
    _audioPlayer!.durationStream.listen((d) {
      if (!mounted) return;
      if (d != null) setState(() => _duration = d);
    });
  }

  Widget _buildMinimalWaveform() {
    return SizedBox(
      height: 24, // Reduced from 30
      child: AnimatedBuilder(
        animation: _shimmerAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: _MinimalWaveformPainter(
              color: widget.isMe ? Colors.white : AppTheme.primaryBlue,
              progress: 0.0,
              shimmerPosition: _shimmerAnimation.value,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }

  Widget _buildDocumentPreview() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap?.call();
      },
      child: Container(
        margin: const EdgeInsets.all(6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.isMe
                      ? [
                          Colors.white.withValues(alpha: 0.08),
                          Colors.white.withValues(alpha: 0.04),
                        ]
                      : [
                          AppTheme.darkCard.withValues(alpha: 0.6),
                          AppTheme.darkCard.withValues(alpha: 0.3),
                        ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: widget.isMe
                      ? Colors.white.withValues(alpha: 0.1)
                      : AppTheme.darkBorder.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  // File icon
                  Container(
                    width: 38, // Reduced from 48
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getFileIconColor().withValues(alpha: 0.15),
                          _getFileIconColor().withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getFileIcon(),
                      color: _getFileIconColor(),
                      size: 20, // Reduced from 24
                    ),
                  ),
                  const SizedBox(width: 10),

                  // File info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.attachment.fileName,
                          style: AppTextStyles.bodySmall.copyWith(
                            color:
                                widget.isMe ? Colors.white : AppTheme.textWhite,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.attachment.fileExtension.toUpperCase()} • ${_formatFileSize(widget.attachment.fileSize)}',
                          style: AppTextStyles.caption.copyWith(
                            color: widget.isMe
                                ? Colors.white.withValues(alpha: 0.5)
                                : AppTheme.textMuted.withValues(alpha: 0.6),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Download button
                  if (widget.onDownload != null)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.onDownload!();
                      },
                      child: Container(
                        width: 28,
                        height: 28,
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
                          Icons.download_rounded,
                          color:
                              widget.isMe ? Colors.white : AppTheme.primaryBlue,
                          size: 16,
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

  Widget _buildMinimalProgressOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            value: widget.attachment.downloadProgress,
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white.withValues(alpha: 0.9),
            ),
            backgroundColor: Colors.white.withValues(alpha: 0.2),
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon() {
    switch (widget.attachment.fileExtension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;
      case 'zip':
      case 'rar':
        return Icons.folder_zip_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _getFileIconColor() {
    switch (widget.attachment.fileExtension.toLowerCase()) {
      case 'pdf':
        return const Color(0xFFE74C3C);
      case 'doc':
      case 'docx':
        return const Color(0xFF2E86DE);
      case 'xls':
      case 'xlsx':
        return const Color(0xFF27AE60);
      case 'ppt':
      case 'pptx':
        return const Color(0xFFF39C12);
      case 'zip':
      case 'rar':
        return const Color(0xFF9B59B6);
      default:
        return AppTheme.textMuted;
    }
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) return '0:00';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class _MinimalWaveformPainter extends CustomPainter {
  final Color color;
  final double progress;
  final double shimmerPosition;

  _MinimalWaveformPainter({
    required this.color,
    required this.progress,
    this.shimmerPosition = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const barCount = 25; // Reduced from 30
    final barWidth = size.width / barCount;

    for (int i = 0; i < barCount; i++) {
      final x = i * barWidth + barWidth / 2;
      final normalizedPosition = (i / barCount - shimmerPosition).abs();
      final shimmerOpacity =
          normalizedPosition < 0.2 ? 1.0 - (normalizedPosition * 5) : 0.0;

      // Create more elegant wave pattern
      final waveHeight = (i % 3 == 0
              ? 0.2
              : i % 2 == 0
                  ? 0.4
                  : 0.6) *
          size.height;
      final y1 = (size.height - waveHeight) / 2;
      final y2 = y1 + waveHeight;

      final isProgressed = i / barCount <= progress;
      final currentPaint = isProgressed ? progressPaint : paint;

      if (shimmerOpacity > 0) {
        final shimmerPaint = Paint()
          ..color = color.withValues(alpha: 0.2 + shimmerOpacity * 0.3)
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(x, y1), Offset(x, y2), shimmerPaint);
      } else {
        canvas.drawLine(Offset(x, y1), Offset(x, y2), currentPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

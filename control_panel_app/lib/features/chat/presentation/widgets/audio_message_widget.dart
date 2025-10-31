import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:bookn_cp_app/injection_container.dart';
import 'package:bookn_cp_app/services/local_storage_service.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/storage_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/attachment.dart';

class AudioMessageWidget extends StatefulWidget {
  final Attachment attachment;
  final bool isMe;
  final Color bubbleColor;
  final Color waveformColor;
  final String? senderName;
  final String? senderAvatar;

  const AudioMessageWidget({
    super.key,
    required this.attachment,
    required this.isMe,
    required this.bubbleColor,
    required this.waveformColor,
    this.senderName,
    this.senderAvatar,
  });

  @override
  State<AudioMessageWidget> createState() => _AudioMessageWidgetState();
}

class _AudioMessageWidgetState extends State<AudioMessageWidget>
    with TickerProviderStateMixin {
  AudioPlayer? _audioPlayer;
  late AnimationController _playPauseAnimationController;
  late AnimationController _waveAnimationController;
  late Animation<double> _playPauseAnimation;

  bool _isPlaying = false;
  bool _isLoading = false;
  bool _hasError = false;
  bool _isPaused = false;
  bool _isPlayerInitialized = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _uploadProgress = 0.0;
  double _playbackSpeed = 1.0;
  Timer? _progressTimer;
  int _loadAttempts = 0;
  static const int _maxLoadAttempts = 5;
  Timer? _retryTimer;

  // WhatsApp-style waveform data
  List<double> _waveformData = [];
  static const int _waveformBars = 27; // عدد أعمدة الموجة كما في WhatsApp

  @override
  void initState() {
    super.initState();

    _uploadProgress = _resolveUploadProgress(widget.attachment);
    final initialDuration = _extractInitialDuration(widget.attachment);
    if (initialDuration != null) {
      _duration = initialDuration;
    }

    // توليد بيانات الموجة الصوتية
    _generateWaveformData();

    _playPauseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _waveAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _playPauseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _playPauseAnimationController,
      curve: Curves.easeInOut,
    ));

    if (_uploadProgress >= 1.0) {
      _initializeAudio();
    } else if (widget.attachment.downloadProgress != null) {
      _startProgressTimer();
    }
  }

  Future<void> _preflightFetch(String url, Map<String, String> headers) async {
    try {
      final api = sl<ApiClient>();
      await api.get(
        url,
        options: Options(
          headers: {
            ...headers,
            'Range': 'bytes=0-0',
          },
          extra: const {
            'suppressErrorToast': true,
          },
        ),
        retries: 0,
      );
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant AudioMessageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final hasDifferentAttachment =
        widget.attachment.id != oldWidget.attachment.id;
    final fileUrlChanged =
        widget.attachment.fileUrl != oldWidget.attachment.fileUrl;
    final newProgress = _resolveUploadProgress(widget.attachment);
    final progressChanged = (newProgress - _uploadProgress).abs() > 0.005;
    final newDuration = _extractInitialDuration(widget.attachment);
    final shouldUpdateDuration = newDuration != null &&
        (_duration == Duration.zero ||
            (newDuration - _duration).inMilliseconds.abs() >= 200);

    if (hasDifferentAttachment || fileUrlChanged) {
      _progressTimer?.cancel();
      _audioPlayer?.dispose();
      _audioPlayer = null;
      _isPlayerInitialized = false;
      _isPlaying = false;
      _isPaused = false;
      _position = Duration.zero;
    }

    if (progressChanged ||
        shouldUpdateDuration ||
        hasDifferentAttachment ||
        fileUrlChanged) {
      setState(() {
        _uploadProgress = newProgress;
        if (newDuration != null) {
          _duration = newDuration;
        }
        if (hasDifferentAttachment || fileUrlChanged) {
          _hasError = false;
          _isLoading = false;
        }
      });

      if (_uploadProgress >= 1.0) {
        _initializeAudio(forceReset: hasDifferentAttachment || fileUrlChanged);
      } else if (widget.attachment.downloadProgress != null) {
        _startProgressTimer();
      } else {
        _progressTimer?.cancel();
      }
    }
  }

  void _generateWaveformData() {
    final random = math.Random();
    _waveformData = List.generate(_waveformBars, (index) {
      // توليد موجات أكثر واقعية مثل WhatsApp
      if (index < 3 || index > _waveformBars - 3) {
        return 0.2 + random.nextDouble() * 0.2;
      } else if (index > _waveformBars ~/ 3 && index < 2 * _waveformBars ~/ 3) {
        return 0.5 + random.nextDouble() * 0.5;
      } else {
        return 0.3 + random.nextDouble() * 0.4;
      }
    });
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    if (_uploadProgress >= 1.0) {
      _initializeAudio();
      return;
    }

    _progressTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final targetProgress = widget.attachment.downloadProgress;
      final desiredProgress = targetProgress != null
          ? targetProgress.clamp(0.0, 1.0)
          : _uploadProgress + 0.01;

      if (_uploadProgress < 1.0) {
        setState(() {
          _uploadProgress = math.min(desiredProgress.toDouble(), 1.0);
        });
      }

      if (_uploadProgress >= 1.0) {
        timer.cancel();
        _initializeAudio();
      }
    });
  }

  Future<void> _initializeAudio({bool forceReset = false}) async {
    if (!mounted) return;
    if (_uploadProgress < 1.0) return;

    final playableUrl = _resolvePlayableUrl();
    if (playableUrl == null) {
      return;
    }

    if (_isPlayerInitialized && !forceReset) {
      return;
    }

    if (forceReset && _audioPlayer != null) {
      await _audioPlayer?.dispose();
      _audioPlayer = null;
    }

    _audioPlayer ??= AudioPlayer();

    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _hasError = false;
        });
      }

      final resolvedUrl = _normalizePlayableUrl(playableUrl);
      final headers = _buildAuthHeaders() ?? {};
      await _preflightFetch(resolvedUrl, headers);
      final refreshedHeaders = _buildAuthHeaders() ?? headers;

      await _audioPlayer!.setAudioSource(
        AudioSource.uri(
          Uri.parse(resolvedUrl),
          headers: refreshedHeaders.isEmpty ? null : refreshedHeaders,
        ),
      );

      _isPlayerInitialized = true;
      _loadAttempts = 0;

      // Get duration if available
      final duration = await _audioPlayer!.durationStream.firstWhere(
        (d) => d != null,
        orElse: () => null,
      );

      if (duration != null && mounted) {
        setState(() {
          _duration = duration;
          _isLoading = false;
        });
      }

      // Listen to position changes
      _audioPlayer!.positionStream.listen((position) {
        if (mounted) {
          setState(() => _position = position);
        }
      });

      // Listen to player state
      _audioPlayer!.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            _isPaused = !state.playing && _position.inSeconds > 0;

            if (state.processingState == ProcessingState.ready) {
              _isLoading = false;
              _hasError = false;
            }

            if (state.processingState == ProcessingState.completed) {
              _position = Duration.zero;
              _audioPlayer?.seek(Duration.zero);
              _audioPlayer?.pause();
              _playPauseAnimationController.reverse();
            } else if (state.processingState == ProcessingState.loading) {
              _isLoading = true;
            }
          });

          if (_isPlaying) {
            _waveAnimationController.repeat();
            _playPauseAnimationController.forward();
          } else {
            _waveAnimationController.stop();
            _playPauseAnimationController.reverse();
          }
        }
      });

      // Listen to speed changes
      _audioPlayer!.speedStream.listen((speed) {
        if (mounted) {
          setState(() => _playbackSpeed = speed);
        }
      });
    } catch (e) {
      _isPlayerInitialized = false;
      _loadAttempts++;
      final shouldRetry = _loadAttempts <= _maxLoadAttempts;
      if (shouldRetry) {
        final delayMs = 300 * (1 << (_loadAttempts - 1));
        _retryTimer?.cancel();
        _retryTimer = Timer(Duration(milliseconds: delayMs), () {
          if (!mounted) return;
          _initializeAudio(forceReset: true);
        });
        if (mounted) {
          setState(() {
            _isLoading = true;
            _hasError = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
      }
    }
  }

  double _resolveUploadProgress(Attachment attachment) {
    final progress = attachment.downloadProgress;
    final fileUrl = attachment.fileUrl.trim();
    final fallbackUrl = attachment.url.trim();
    final hasRemoteUrl = fileUrl.isNotEmpty || fallbackUrl.isNotEmpty;

    if (progress != null) {
      if (progress >= 1.0) {
        return 1.0;
      }
      if (progress <= 0 && hasRemoteUrl) {
        return 1.0;
      }
      return progress.clamp(0.0, 1.0);
    }

    return hasRemoteUrl ? 1.0 : 0.0;
  }

  Duration? _extractInitialDuration(Attachment attachment) {
    num? seconds = attachment.duration;

    seconds ??= _tryParseNum(attachment.metadata?['duration']);
    seconds ??= _tryParseNum(attachment.metadata?['durationSeconds']);
    seconds ??= _tryParseNum(attachment.metadata?['length']);
    seconds ??= _tryParseNum(attachment.metadata?['audioDuration']);

    num? milliseconds = _tryParseNum(attachment.metadata?['durationMs']) ??
        _tryParseNum(attachment.metadata?['durationMilliseconds']);

    if ((seconds == null || seconds <= 0) &&
        milliseconds != null &&
        milliseconds > 0) {
      seconds = milliseconds / 1000;
    }

    if (seconds == null || seconds <= 0) {
      return null;
    }

    if (seconds > 3600 * 24) {
      // Likely in milliseconds already
      return Duration(milliseconds: seconds.round());
    }

    return Duration(milliseconds: (seconds * 1000).round());
  }

  double? _tryParseNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.trim());
    }
    return null;
  }

  String? _resolvePlayableUrl() {
    final fileUrl = widget.attachment.fileUrl.trim();
    if (fileUrl.isNotEmpty) {
      return fileUrl;
    }

    final url = widget.attachment.url.trim();
    if (url.isNotEmpty) {
      return url;
    }

    final filePath = widget.attachment.filePath.trim();
    if (filePath.isNotEmpty) {
      final uri = Uri.tryParse(filePath);
      if (uri != null && uri.hasScheme) {
        return filePath;
      }
      return Uri.file(filePath).toString();
    }

    return null;
  }

  String _normalizePlayableUrl(String playableUrl) {
    final lower = playableUrl.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return playableUrl;
    }
    if (lower.startsWith('file://')) {
      return playableUrl;
    }
    final isApiPath = playableUrl.startsWith('/api/');
    return isApiPath
        ? ImageUtils.resolveApiUrl(playableUrl)
        : ImageUtils.resolveUrl(playableUrl);
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

  void _togglePlayback() async {
    if (_isLoading || _hasError || _uploadProgress < 1.0) return;

    HapticFeedback.lightImpact();

    if (_isPlaying) {
      await _audioPlayer?.pause();
    } else {
      await _audioPlayer?.play();
    }
  }

  void _changePlaybackSpeed() async {
    if (_audioPlayer == null) return;

    HapticFeedback.selectionClick();

    // Cycle through speeds: 1x -> 1.5x -> 2x -> 1x
    double newSpeed;
    if (_playbackSpeed == 1.0) {
      newSpeed = 1.5;
    } else if (_playbackSpeed == 1.5) {
      newSpeed = 2.0;
    } else {
      newSpeed = 1.0;
    }

    await _audioPlayer!.setSpeed(newSpeed);
  }

  void _seek(double value) async {
    if (_audioPlayer == null || _duration.inMilliseconds == 0) return;

    final position = Duration(
      milliseconds: (value * _duration.inMilliseconds).toInt(),
    );
    await _audioPlayer!.seek(position);
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _retryTimer?.cancel();
    _playPauseAnimationController.dispose();
    _waveAnimationController.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        left: 8,
        right: 12,
        top: 6,
        bottom: 8,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar or Mic icon (WhatsApp style)
              _buildAvatarSection(),
              const SizedBox(width: 8),
              // Main content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sender name if not me
                    if (!widget.isMe && widget.senderName != null) ...[
                      Text(
                        widget.senderName!,
                        style: AppTextStyles.caption.copyWith(
                          color: const Color(0xFF06CF9C),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    // Audio controls and waveform
                    Row(
                      children: [
                        // Play/Pause button
                        _buildPlayPauseButton(),
                        const SizedBox(width: 8),
                        // Waveform and progress
                        Expanded(
                          child: _uploadProgress < 1.0
                              ? _buildUploadProgress()
                              : _buildWaveformSection(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Duration and speed controls
          if (_uploadProgress >= 1.0) _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    const size = 34.0;

    if (widget.isMe) {
      // Microphone icon for sent messages
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF128C7E),
        ),
        child: const Icon(
          Icons.mic,
          color: Colors.white,
          size: 18,
        ),
      );
    } else if (widget.senderAvatar != null && widget.senderAvatar!.isNotEmpty) {
      // Sender avatar
      return ClipOval(
        child: CachedImageWidget(
          imageUrl: widget.senderAvatar!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    } else {
      // Default avatar with initial
      final initial = widget.senderName?.isNotEmpty == true
          ? widget.senderName![0].toUpperCase()
          : 'U';

      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF667781),
        ),
        child: Center(
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildPlayPauseButton() {
    final isUploading = _uploadProgress < 1.0;
    final iconColor =
        widget.isMe ? const Color(0xFF8696A0) : const Color(0xFF8696A0);

    return GestureDetector(
      onTap: () {
        if (isUploading || _isLoading) return;
        if (_hasError) {
          _initializeAudio(forceReset: true);
          return;
        }
        _togglePlayback();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isUploading)
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  value: _uploadProgress,
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                  backgroundColor: iconColor.withValues(alpha: 0.2),
                ),
              )
            else if (_isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                ),
              )
            else if (_hasError)
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFEF4444),
                size: 24,
              )
            else
              AnimatedIcon(
                icon: AnimatedIcons.play_pause,
                progress: _playPauseAnimation,
                color: iconColor,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadProgress() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: _uploadProgress,
          backgroundColor: widget.waveformColor.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(widget.waveformColor),
          minHeight: 2,
        ),
        const SizedBox(height: 4),
        Text(
          'جاري الرفع... ${(_uploadProgress * 100).toInt()}%',
          style: AppTextStyles.caption.copyWith(
            color: widget.waveformColor.withValues(alpha: 0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildWaveformSection() {
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    return GestureDetector(
      onTapDown: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localX = details.localPosition.dx;
        final width = box.size.width - 98; // Account for button and padding
        final seekValue = (localX / width).clamp(0.0, 1.0);
        _seek(seekValue);
      },
      onHorizontalDragUpdate: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localX = details.localPosition.dx;
        final width = box.size.width - 98;
        final seekValue = (localX / width).clamp(0.0, 1.0);
        _seek(seekValue);
      },
      child: SizedBox(
        height: 30,
        child: CustomPaint(
          painter: _WhatsAppWaveformPainter(
            waveformData: _waveformData,
            progress: progress,
            activeColor:
                widget.isMe ? const Color(0xFF054640) : const Color(0xFF06CF9C),
            inactiveColor: widget.isMe
                ? const Color(0xFF8696A0).withValues(alpha: 0.4)
                : const Color(0xFF8696A0).withValues(alpha: 0.3),
            isPlaying: _isPlaying,
            animationValue: _waveAnimationController.value,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 42),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Current time / Duration
          Row(
            children: [
              Text(
                _formatDuration(
                    _isPlaying || _isPaused ? _position : _duration),
                style: AppTextStyles.caption.copyWith(
                  color: (widget.isMe
                          ? const Color(0xFF8696A0)
                          : const Color(0xFF8696A0))
                      .withValues(alpha: 0.9),
                  fontSize: 11,
                ),
              ),
              if (!_isPlaying && !_isPaused && _duration.inSeconds > 0) ...[
                Text(
                  ' / ',
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF8696A0).withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
                Text(
                  widget.attachment.formattedFileSize,
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF8696A0).withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
          // Playback speed button
          if (_isPlaying || _isPaused)
            GestureDetector(
              onTap: _changePlaybackSpeed,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF8696A0).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${_playbackSpeed}x',
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF8696A0),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

// WhatsApp-style waveform painter
class _WhatsAppWaveformPainter extends CustomPainter {
  final List<double> waveformData;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;
  final bool isPlaying;
  final double animationValue;

  _WhatsAppWaveformPainter({
    required this.waveformData,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
    required this.isPlaying,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const barWidth = 2.0; // عرض العمود كما في WhatsApp
    const barSpacing = 2.0; // المسافة بين الأعمدة
    const totalBarWidth = barWidth + barSpacing;
    final barCount = waveformData.length;
    final maxBarHeight = size.height * 0.8;

    for (int i = 0; i < barCount; i++) {
      final x = i * totalBarWidth;
      final normalizedIndex = i / barCount;

      // حساب ارتفاع العمود
      double heightMultiplier = waveformData[i];

      // إضافة تأثير حركي للعمود الحالي أثناء التشغيل
      if (isPlaying) {
        final distanceFromProgress = (normalizedIndex - progress).abs();
        if (distanceFromProgress < 0.05) {
          final pulse = math.sin(animationValue * math.pi * 2) * 0.15;
          heightMultiplier = (heightMultiplier + pulse).clamp(0.2, 1.0);
        }
      }

      final barHeight = maxBarHeight * heightMultiplier;
      final y = (size.height - barHeight) / 2;

      // رسم العمود
      final paint = Paint()
        ..color = normalizedIndex <= progress ? activeColor : inactiveColor
        ..strokeWidth = barWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(x + barWidth / 2, y),
        Offset(x + barWidth / 2, y + barHeight),
        paint,
      );
    }

    // رسم مؤشر التقدم (دائرة صغيرة)
    if (progress > 0 && progress < 1) {
      final indicatorX = progress * (barCount * totalBarWidth);
      final indicatorPaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(indicatorX, size.height / 2),
        3,
        indicatorPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WhatsAppWaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isPlaying != isPlaying ||
        oldDelegate.animationValue != animationValue;
  }
}

// lib/features/home/presentation/widgets/analyticsection_visibility_detectors/.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:yemen_booking_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:yemen_booking_app/features/home/presentation/bloc/home_event.dart';

class SectionVisibilityDetector extends StatefulWidget {
  final String sectionId;
  final Widget child;
  final Function(bool)? onVisibilityChanged;
  final double visibilityThreshold;

  const SectionVisibilityDetector({
    super.key,
    required this.sectionId,
    required this.child,
    this.onVisibilityChanged,
    this.visibilityThreshold = 0.5,
  });

  @override
  State<SectionVisibilityDetector> createState() =>
      _SectionVisibilityDetectorState();
}

class _SectionVisibilityDetectorState extends State<SectionVisibilityDetector> {
  bool _hasRecordedImpression = false;
  bool _isVisible = false;
  DateTime? _visibilityStartTime;
  bool _isDisposed = false;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('section_${widget.sectionId}'),
      onVisibilityChanged: (info) {
        final visiblePercentage = info.visibleFraction;
        final isNowVisible = visiblePercentage >= widget.visibilityThreshold;

        if (_isDisposed) return;
        if (isNowVisible != _isVisible) {
          if (!mounted) return;
          _isVisible = isNowVisible;

          if (isNowVisible) {
            _onSectionBecameVisible();
          } else {
            _onSectionBecameHidden();
          }

          if (!mounted || _isDisposed) return;
          widget.onVisibilityChanged?.call(isNowVisible);
        }
      },
      child: widget.child,
    );
  }

  void _onSectionBecameVisible() {
    if (_isDisposed || !mounted) return;
    _visibilityStartTime = DateTime.now();

    // Record impression if not already recorded
    if (!_hasRecordedImpression) {
      _hasRecordedImpression = true;
      if (!_isDisposed && mounted) {
        context.read<HomeBloc>().add(
              RecordSectionImpressionEvent(sectionId: widget.sectionId),
            );
      }
    }
  }

  void _onSectionBecameHidden() {
    if (_isDisposed) return;
    if (_visibilityStartTime != null) {
      final duration = DateTime.now().difference(_visibilityStartTime!);

      // Record interaction if user spent more than 2 seconds viewing
      if (duration.inSeconds >= 2) {
        if (!_isDisposed && mounted) {
          context.read<HomeBloc>().add(
                RecordSectionInteractionEvent(
                  sectionId: widget.sectionId,
                  interactionType: 'view',
                  metadata: {
                    'duration_seconds': duration.inSeconds,
                  },
                ),
              );
        }
      }
    }

    _visibilityStartTime = null;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _visibilityStartTime = null;
    super.dispose();
  }
}

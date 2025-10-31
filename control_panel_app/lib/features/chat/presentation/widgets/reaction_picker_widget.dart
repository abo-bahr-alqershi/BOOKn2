import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';

class ReactionPickerWidget extends StatefulWidget {
  final Function(String) onReaction;

  const ReactionPickerWidget({
    super.key,
    required this.onReaction,
  });

  @override
  State<ReactionPickerWidget> createState() => _ReactionPickerWidgetState();
}

class _ReactionPickerWidgetState extends State<ReactionPickerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _scaleAnimations;
  late Animation<double> _containerAnimation;

  final List<ReactionItem> reactions = [
    ReactionItem(emoji: '👍', type: 'like'),
    ReactionItem(emoji: '❤️', type: 'love'),
    ReactionItem(emoji: '😂', type: 'laugh'),
    ReactionItem(emoji: '😮', type: 'wow'),
    ReactionItem(emoji: '😢', type: 'sad'),
    ReactionItem(emoji: '😠', type: 'angry'),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _containerAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _scaleAnimations = List.generate(reactions.length, (index) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            index * 0.08,
            0.4 + index * 0.1,
            curve: Curves.easeOutBack,
          ),
        ),
      );
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _containerAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _containerAnimation.value,
          child: Container(
            margin: const EdgeInsets.only(top: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.darkCard.withValues(alpha: 0.7),
                        AppTheme.darkCard.withValues(alpha: 0.5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.darkBorder.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.shadowDark.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(reactions.length, (index) {
                      return AnimatedBuilder(
                        animation: _scaleAnimations[index],
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimations[index].value,
                            child: _MinimalReactionButton(
                              reaction: reactions[index],
                              onTap: () {
                                HapticFeedback.selectionClick();
                                widget.onReaction(reactions[index].type);
                              },
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MinimalReactionButton extends StatefulWidget {
  final ReactionItem reaction;
  final VoidCallback onTap;

  const _MinimalReactionButton({
    required this.reaction,
    required this.onTap,
  });

  @override
  State<_MinimalReactionButton> createState() => 
      _MinimalReactionButtonState();
}

class _MinimalReactionButtonState extends State<_MinimalReactionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _animationController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _animationController.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _animationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: _isPressed
                  ? BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryBlue.withValues(alpha: 0.1),
                          AppTheme.primaryPurple.withValues(alpha: 0.05),
                        ],
                      ),
                      shape: BoxShape.circle,
                    )
                  : null,
              child: Text(
                widget.reaction.emoji,
                style: const TextStyle(fontSize: 20), // Reduced from 24
              ),
            ),
          );
        },
      ),
    );
  }
}

class ReactionItem {
  final String emoji;
  final String type;

  ReactionItem({
    required this.emoji,
    required this.type,
  });
}
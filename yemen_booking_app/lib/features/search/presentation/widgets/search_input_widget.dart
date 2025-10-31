// lib/features/search/presentation/widgets/search_input_widget.dart (محسّنة)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:async';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';

class SearchInputWidget extends StatefulWidget {
  final String? initialValue;
  final String? hintText;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;
  final bool showSuggestions;
  final List<String>? suggestions;
  final Function(String)? onSuggestionSelected;

  const SearchInputWidget({
    super.key,
    this.initialValue,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
    this.showSuggestions = true,
    this.suggestions,
    this.onSuggestionSelected,
  });

  @override
  State<SearchInputWidget> createState() => _SearchInputWidgetState();
}

class _SearchInputWidgetState extends State<SearchInputWidget>
    with TickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  
  // Ultra Animation Controllers
  late AnimationController _glowController;
  late AnimationController _iconController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _rippleController;
  
  // Ultra Animations
  late Animation<double> _glowAnimation;
  late Animation<double> _iconRotation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _rippleAnimation;
  
  // State
  bool _showClearButton = false;
  bool _isFocused = false;
  bool _isTyping = false;
  OverlayEntry? _overlayEntry;
  Timer? _debounceTimer;
  Timer? _typingTimer;
  
  // Enhanced suggestions
  final List<String> _defaultSuggestions = [
    'فندق في صنعاء',
    'شقة للإيجار في عدن',
    'فيلا في تعز',
    'منتجع ساحلي',
    'غرفة فندقية رخيصة',
    'شاليه على البحر',
    'استراحة عائلية',
    'مكان هادئ',
  ];
  
  // Recent searches
  final List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    
    // Initialize ultra animations
    _initializeUltraAnimations();
    
    _showClearButton = _controller.text.isNotEmpty;
    
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }
  
  void _initializeUltraAnimations() {
    // Glow animation
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(
      begin: 0.2,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    // Icon rotation
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _iconRotation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.easeOutBack,
    ));
    
    // Pulse animation
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Shimmer animation
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(_shimmerController);
    
    // Ripple animation
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));
  }
  
  void _onTextChanged() {
    setState(() {
      _showClearButton = _controller.text.isNotEmpty;
      _isTyping = true;
    });
    
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _isTyping = false;
      });
    });
    
    if (widget.onChanged != null) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        widget.onChanged!(_controller.text);
      });
    }
    
    if (widget.showSuggestions && _controller.text.isNotEmpty && _isFocused) {
      _showSuggestions();
    } else {
      _hideSuggestions();
    }
  }
  
  void _onFocusChanged() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    
    if (_isFocused) {
      _iconController.forward();
      _rippleController.forward();
      if (_controller.text.isNotEmpty && widget.showSuggestions) {
        _showSuggestions();
      }
    } else {
      _iconController.reverse();
      _rippleController.reverse();
      _hideSuggestions();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _typingTimer?.cancel();
    _hideSuggestions();
    _controller.dispose();
    _focusNode.dispose();
    _glowController.dispose();
    _iconController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _showSuggestions() {
    _hideSuggestions();
    
    final suggestions = _getFilteredSuggestions();
    if (suggestions.isEmpty) return;
    
    _overlayEntry = _createUltraOverlayEntry(suggestions);
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideSuggestions() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
  
  List<String> _getFilteredSuggestions() {
    final query = _controller.text.toLowerCase();
    final allSuggestions = [
      ..._recentSearches,
      ...(widget.suggestions ?? _defaultSuggestions),
    ];
    
    return allSuggestions.where((suggestion) {
      return suggestion.toLowerCase().contains(query);
    }).take(6).toList();
  }

  OverlayEntry _createUltraOverlayEntry(List<String> suggestions) {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 6,
        width: size.width,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.95 + (0.05 * value),
              alignment: Alignment.topCenter,
              child: Opacity(
                opacity: value,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 240),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.darkCard.withOpacity(0.98),
                          AppTheme.darkCard.withOpacity(0.95),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryBlue.withOpacity(0.2),
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.shadowDark.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: suggestions.length,
                          itemBuilder: (context, index) {
                            return _buildUltraSuggestionItem(
                              suggestion: suggestions[index],
                              index: index,
                              isRecent: _recentSearches.contains(suggestions[index]),
                              onTap: () {
                                HapticFeedback.lightImpact();
                                _selectSuggestion(suggestions[index]);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildUltraSuggestionItem({
    required String suggestion,
    required int index,
    required bool isRecent,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 200 + (index * 50)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset((1 - value) * 20, 0),
          child: Opacity(
            opacity: value,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppTheme.darkBorder.withOpacity(0.1),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Icon with gradient
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: isRecent
                              ? LinearGradient(
                                  colors: [
                                    AppTheme.primaryPurple,
                                    AppTheme.primaryViolet,
                                  ],
                                )
                              : AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: (isRecent 
                                  ? AppTheme.primaryPurple 
                                  : AppTheme.primaryBlue).withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(
                          isRecent 
                              ? Icons.history_rounded 
                              : Icons.search_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      
                      const SizedBox(width: 10),
                      
                      // Text with highlighting
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: _highlightUltraText(
                                  suggestion,
                                  _controller.text,
                                ),
                              ),
                            ),
                            if (isRecent)
                              Text(
                                'بحث سابق',
                                style: AppTextStyles.overline.copyWith(
                                  color: AppTheme.textMuted.withOpacity(0.5),
                                  fontSize: 9,
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      // Action icon
                      Icon(
                        Icons.north_west_rounded,
                        size: 14,
                        color: AppTheme.textMuted.withOpacity(0.3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  List<TextSpan> _highlightUltraText(String text, String query) {
    if (query.isEmpty) {
      return [
        TextSpan(
          text: text,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppTheme.textWhite,
            fontSize: 13,
          ),
        ),
      ];
    }
    
    final List<TextSpan> spans = [];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    int start = 0;
    int index = lowerText.indexOf(lowerQuery, start);
    
    while (index != -1) {
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: AppTextStyles.bodySmall.copyWith(
            color: AppTheme.textWhite,
            fontSize: 13,
          ),
        ));
      }
      
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: AppTextStyles.bodySmall.copyWith(
          color: AppTheme.neonBlue,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ));
      
      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }
    
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: AppTextStyles.bodySmall.copyWith(
          color: AppTheme.textWhite,
          fontSize: 13,
        ),
      ));
    }
    
    return spans;
  }
  
  void _selectSuggestion(String suggestion) {
    _controller.text = suggestion;
    _hideSuggestions();
    _focusNode.unfocus();
    
    // Add to recent searches
    if (!_recentSearches.contains(suggestion)) {
      _recentSearches.insert(0, suggestion);
      if (_recentSearches.length > 5) {
        _recentSearches.removeLast();
      }
    }
    
    if (widget.onSuggestionSelected != null) {
      widget.onSuggestionSelected!(suggestion);
    } else if (widget.onSubmitted != null) {
      widget.onSubmitted!(suggestion);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _glowAnimation,
        _iconRotation,
        _pulseAnimation,
        _rippleAnimation,
      ]),
      builder: (context, child) {
        return Container(
          height: 44,
          transform: Matrix4.identity()
            ..scale(_isFocused ? _pulseAnimation.value : 1.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(
                        _glowAnimation.value * 0.4
                      ),
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: AppTheme.neonBlue.withOpacity(
                        _glowAnimation.value * 0.2
                      ),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Stack(
            children: [
              // Ripple effect background
              if (_isFocused)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _rippleAnimation,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.primaryBlue.withOpacity(
                              0.3 * (1 - _rippleAnimation.value)
                            ),
                            width: 2 * _rippleAnimation.value,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              
              // Main input field
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: widget.autofocus,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.textWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText ?? 'ابحث عن الفنادق، الشقق، المدن...',
                  hintStyle: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textMuted.withOpacity(0.4),
                    fontSize: 12,
                  ),
                  filled: true,
                  fillColor: _isFocused
                      ? AppTheme.darkCard.withOpacity(0.9)
                      : AppTheme.darkCard.withOpacity(0.6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppTheme.darkBorder.withOpacity(0.2),
                      width: 0.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppTheme.primaryBlue.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  prefixIcon: _buildUltraSearchIcon(),
                  suffixIcon: _buildUltraSuffixIcon(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  isDense: true,
                ),
                onSubmitted: widget.onSubmitted,
                textInputAction: TextInputAction.search,
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildUltraSearchIcon() {
    return AnimatedBuilder(
      animation: _iconRotation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(10),
          child: AnimatedRotation(
            turns: _iconRotation.value * 0.5,
            duration: const Duration(milliseconds: 300),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: _isFocused 
                    ? AppTheme.primaryGradient 
                    : null,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.search_rounded,
                color: _isFocused 
                    ? Colors.white 
                    : AppTheme.textMuted.withOpacity(0.6),
                size: 16,
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildUltraSuffixIcon() {
    if (_showClearButton) {
      return AnimatedScale(
        scale: _showClearButton ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            _controller.clear();
            if (widget.onClear != null) {
              widget.onClear!();
            }
          },
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.textMuted.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.clear_rounded,
              size: 12,
              color: AppTheme.textMuted,
            ),
          ),
        ),
      );
    } else if (_isTyping && _isFocused) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppTheme.primaryBlue.withOpacity(0.5),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
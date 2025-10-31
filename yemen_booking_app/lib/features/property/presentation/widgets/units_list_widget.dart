import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../domain/entities/unit.dart';

class UnitsListWidget extends StatefulWidget {
  final List<Unit> units;
  final Function(Unit) onUnitSelect;
  final String? selectedUnitId;

  const UnitsListWidget({
    super.key,
    required this.units,
    required this.onUnitSelect,
    this.selectedUnitId,
  });

  @override
  State<UnitsListWidget> createState() => _UnitsListWidgetState();
}

class _UnitsListWidgetState extends State<UnitsListWidget>
    with TickerProviderStateMixin {
  late AnimationController _gridController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  
  late Animation<double> _gridAnimation;
  late Animation<double> _pulseAnimation;
  
  final Map<String, AnimationController> _cardControllers = {};
  final List<_FloatingOrb> _orbs = [];
  
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateOrbs();
    _startAnimations();
  }
  
  void _initializeAnimations() {
    _gridController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _gridAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _gridController,
      curve: Curves.easeOutBack,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.98,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }
  
  void _generateOrbs() {
    for (int i = 0; i < 5; i++) {
      _orbs.add(_FloatingOrb());
    }
  }
  
  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _gridController.forward();
      }
    });
  }

  @override
  void dispose() {
    _gridController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _cardControllers.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.units.isEmpty) {
      return _buildEmptyState();
    }

    return Stack(
      children: [
        _buildAnimatedBackground(),
        Column(
          children: [
            _buildViewToggle(),
            Expanded(
              child: AnimatedBuilder(
                animation: _gridAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.95 + (_gridAnimation.value * 0.05),
                    child: _isGridView ? _buildGridView() : _buildListView(),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildViewToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.darkCard.withOpacity(0.6),
                  AppTheme.darkCard.withOpacity(0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                _buildToggleButton(
                  icon: Icons.grid_view_rounded,
                  isSelected: _isGridView,
                  onTap: () {
                    setState(() => _isGridView = true);
                    HapticFeedback.lightImpact();
                  },
                ),
                _buildToggleButton(
                  icon: Icons.view_agenda_rounded,
                  isSelected: !_isGridView,
                  onTap: () {
                    setState(() => _isGridView = false);
                    HapticFeedback.lightImpact();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildToggleButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isSelected ? Colors.white : AppTheme.textMuted,
        ),
      ),
    );
  }
  
  Widget _buildGridView() {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        // Increase vertical space to avoid internal Column overflow
        childAspectRatio: 0.75,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: widget.units.length,
      itemBuilder: (context, index) {
        final unit = widget.units[index];
        final isSelected = widget.selectedUnitId != null && 
                         unit.id == widget.selectedUnitId;
        
        if (!_cardControllers.containsKey(unit.id)) {
          _cardControllers[unit.id] = AnimationController(
            duration: const Duration(milliseconds: 400),
            vsync: this,
          );
        }
        
        return _buildCompactUnitCard(unit, isSelected, index);
      },
    );
  }
  
  Widget _buildListView() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: widget.units.length,
      itemBuilder: (context, index) {
        final unit = widget.units[index];
        final isSelected = widget.selectedUnitId != null && 
                         unit.id == widget.selectedUnitId;
        
        if (!_cardControllers.containsKey(unit.id)) {
          _cardControllers[unit.id] = AnimationController(
            duration: const Duration(milliseconds: 400),
            vsync: this,
          );
        }
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildHorizontalUnitCard(unit, isSelected, index),
        );
      },
    );
  }
  
  Widget _buildCompactUnitCard(Unit unit, bool isSelected, int index) {
    return GestureDetector(
      onTap: () {
        widget.onUnitSelect(unit);
        HapticFeedback.lightImpact();
        _cardControllers[unit.id]?.forward().then((_) {
          _cardControllers[unit.id]?.reverse();
        });
      },
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isSelected ? _pulseAnimation.value : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isSelected
                      ? [
                          AppTheme.primaryBlue.withOpacity(0.25),
                          AppTheme.primaryPurple.withOpacity(0.15),
                        ]
                      : [
                          AppTheme.darkCard.withOpacity(0.7),
                          AppTheme.darkCard.withOpacity(0.5),
                        ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryBlue.withOpacity(0.5)
                      : AppTheme.darkBorder.withOpacity(0.2),
                  width: isSelected ? 1.5 : 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? AppTheme.primaryBlue.withOpacity(0.2)
                        : AppTheme.shadowDark.withOpacity(0.1),
                    blurRadius: isSelected ? 15 : 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCompactImageSection(unit, isSelected),
                      _buildCompactContent(unit, isSelected),
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
  
  Widget _buildHorizontalUnitCard(Unit unit, bool isSelected, int index) {
    return GestureDetector(
      onTap: () {
        widget.onUnitSelect(unit);
        HapticFeedback.lightImpact();
        _cardControllers[unit.id]?.forward().then((_) {
          _cardControllers[unit.id]?.reverse();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? [
                    AppTheme.primaryBlue.withOpacity(0.25),
                    AppTheme.primaryPurple.withOpacity(0.15),
                  ]
                : [
                    AppTheme.darkCard.withOpacity(0.7),
                    AppTheme.darkCard.withOpacity(0.5),
                  ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryBlue.withOpacity(0.5)
                : AppTheme.darkBorder.withOpacity(0.2),
            width: isSelected ? 1.5 : 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppTheme.primaryBlue.withOpacity(0.2)
                  : AppTheme.shadowDark.withOpacity(0.1),
              blurRadius: isSelected ? 15 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Row(
              children: [
                _buildHorizontalImageSection(unit, isSelected),
                Expanded(
                  child: _buildHorizontalContent(unit, isSelected),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildCompactImageSection(Unit unit, bool isSelected) {
    return Stack(
      children: [
        Hero(
          tag: 'unit_image_${unit.id}',
          child: Container(
            // Reduce image height to give more room for bottom content
            height: 128,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (unit.images.isNotEmpty)
                  CachedImageWidget(
                    imageUrl: unit.images.first.url,
                    fit: BoxFit.cover,
                  )
                else
                  Container(
                    color: AppTheme.darkCard,
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: AppTheme.textMuted,
                        size: 32,
                      ),
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppTheme.darkBackground.withOpacity(0.5),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        if (!unit.isAvailable)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.darkBackground.withOpacity(0.7),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.error,
                        AppTheme.error.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'غير متاح',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ),
          ),
        
        if (isSelected)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
        
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              unit.unitTypeName,
              style: AppTextStyles.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 9,
              ),
            ),
          ),
        ),
        
        if (unit.images.length > 1)
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.darkBackground.withOpacity(0.8),
                    AppTheme.darkBackground.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.photo_library_outlined,
                    size: 10,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${unit.images.length}',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildHorizontalImageSection(Unit unit, bool isSelected) {
    return Container(
      width: 120,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.horizontal(
          left: Radius.circular(14),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (unit.images.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14),
              ),
              child: CachedImageWidget(
                imageUrl: unit.images.first.url,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(14),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.image_not_supported,
                  color: AppTheme.textMuted,
                  size: 24,
                ),
              ),
            ),
          
          if (!unit.isAvailable)
            Container(
              decoration: BoxDecoration(
                color: AppTheme.darkBackground.withOpacity(0.7),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(14),
                ),
              ),
              child: Center(
                child: Text(
                  'محجوز',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          
          if (isSelected)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildCompactContent(Unit unit, bool isSelected) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => 
                      isSelected
                          ? AppTheme.primaryGradient.createShader(bounds)
                          : LinearGradient(
                              colors: [AppTheme.textWhite, AppTheme.textWhite],
                            ).createShader(bounds),
                  child: Text(
                    unit.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                if (unit.dynamicFields.isNotEmpty)
                  _buildMiniFeatures(unit),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => 
                          AppTheme.primaryGradient.createShader(bounds),
                      child: Text(
                        unit.basePrice.amount.toStringAsFixed(0),
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '${unit.basePrice.currency}/${_getPricingPeriod(unit.pricingMethod)}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textMuted,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: unit.isAvailable
                        ? (isSelected
                            ? AppTheme.primaryGradient
                            : null)
                        : null,
                    color: unit.isAvailable
                        ? (isSelected
                            ? null
                            : AppTheme.primaryBlue.withOpacity(0.2))
                        : AppTheme.error.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    unit.isAvailable
                        ? Icons.arrow_forward_ios
                        : Icons.lock,
                    size: 12,
                    color: unit.isAvailable
                        ? (isSelected ? Colors.white : AppTheme.primaryBlue)
                        : AppTheme.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHorizontalContent(Unit unit, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ShaderMask(
                      shaderCallback: (bounds) => 
                          isSelected
                              ? AppTheme.primaryGradient.createShader(bounds)
                              : LinearGradient(
                                  colors: [AppTheme.textWhite, AppTheme.textWhite],
                                ).createShader(bounds),
                      child: Text(
                        unit.name,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: unit.isAvailable
                          ? AppTheme.success
                          : AppTheme.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (unit.customFeatures.isNotEmpty)
                Text(
                  unit.customFeatures,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          if (unit.dynamicFields.isNotEmpty)
            _buildMiniFeatures(unit),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => 
                              AppTheme.primaryGradient.createShader(bounds),
                          child: Text(
                            unit.basePrice.amount.toStringAsFixed(0),
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${unit.basePrice.currency} / ${_getPricingPeriod(unit.pricingMethod)}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.textMuted,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (unit.isAvailable)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? AppTheme.primaryGradient
                        : null,
                    color: !isSelected
                        ? AppTheme.primaryBlue.withOpacity(0.2)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isSelected ? 'محدد' : 'اختيار',
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected ? Colors.white : AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildMiniFeatures(Unit unit) {
    final features = unit.dynamicFields
        .expand((group) => group.fieldValues)
        .take(3)
        .toList();
    
    return Wrap(
      spacing: 4,
      runSpacing: 3,
      children: features.map((field) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getFieldIcon(field.fieldName),
                size: 10,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(width: 3),
              Text(
                '${field.value}',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textWhite,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.2),
                    AppTheme.primaryBlue.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.meeting_room_outlined,
                size: 48,
                color: AppTheme.primaryBlue.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),
            ShaderMask(
              shaderCallback: (bounds) => 
                  AppTheme.primaryGradient.createShader(bounds),
              child: Text(
                'لا توجد وحدات متاحة',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'جميع الوحدات محجوزة حالياً',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAnimatedBackground() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          return CustomPaint(
            painter: _OrbsPainter(
              orbs: _orbs,
              animationValue: _shimmerController.value,
            ),
          );
        },
      ),
    );
  }
  
  IconData _getFieldIcon(String fieldName) {
    final name = fieldName.toLowerCase();
    if (name.contains('bed') || name.contains('سرير')) return Icons.bed;
    if (name.contains('bath') || name.contains('حمام')) return Icons.bathroom;
    if (name.contains('area') || name.contains('مساحة')) return Icons.square_foot;
    if (name.contains('guest') || name.contains('ضيف')) return Icons.people;
    return Icons.info_outline;
  }

  String _getPricingPeriod(PricingMethod method) {
    switch (method) {
      case PricingMethod.hourly:
        return 'ساعة';
      case PricingMethod.daily:
        return 'ليلة';
      case PricingMethod.weekly:
        return 'أسبوع';
      case PricingMethod.monthly:
        return 'شهر';
    }
  }
}

class _FloatingOrb {
  late double x;
  late double y;
  late double size;
  late double speed;
  late Color color;
  late double opacity;
  
  _FloatingOrb() {
    reset();
  }
  
  void reset() {
    x = math.Random().nextDouble();
    y = math.Random().nextDouble();
    size = math.Random().nextDouble() * 30 + 20;
    speed = math.Random().nextDouble() * 0.0005 + 0.0002;
    opacity = math.Random().nextDouble() * 0.05 + 0.02;
    
    final colors = [
      AppTheme.primaryBlue,
      AppTheme.primaryPurple,
      AppTheme.primaryCyan,
    ];
    color = colors[math.Random().nextInt(colors.length)];
  }
  
  void update() {
    y -= speed;
    if (y < -0.1) {
      y = 1.1;
      x = math.Random().nextDouble();
    }
  }
}

class _OrbsPainter extends CustomPainter {
  final List<_FloatingOrb> orbs;
  final double animationValue;
  
  _OrbsPainter({
    required this.orbs,
    required this.animationValue,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    for (var orb in orbs) {
      orb.update();
      
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            orb.color.withOpacity(orb.opacity),
            orb.color.withOpacity(0),
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(orb.x * size.width, orb.y * size.height),
          radius: orb.size,
        ))
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(orb.x * size.width, orb.y * size.height),
        orb.size,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/unit.dart';
import '../../../../core/utils/image_utils.dart';
import '../bloc/property_bloc.dart';
import '../bloc/property_event.dart';
import '../bloc/property_state.dart';

class PropertyUnitsPage extends StatefulWidget {
  final String propertyId;
  final String propertyName;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final int guestsCount;

  const PropertyUnitsPage({
    super.key,
    required this.propertyId,
    required this.propertyName,
    this.checkInDate,
    this.checkOutDate,
    this.guestsCount = 1,
  });

  @override
  State<PropertyUnitsPage> createState() => _PropertyUnitsPageState();
}

class _PropertyUnitsPageState extends State<PropertyUnitsPage>
    with TickerProviderStateMixin {
  late DateTime _checkInDate;
  late DateTime _checkOutDate;
  late int _guestsCount;
  String? _selectedUnitId;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  
  final List<_FloatingCube> _cubes = [];

  @override
  void initState() {
    super.initState();
    _checkInDate = widget.checkInDate ?? DateTime.now();
    _checkOutDate = widget.checkOutDate ?? DateTime.now().add(const Duration(days: 1));
    _guestsCount = widget.guestsCount;
    
    _initializeAnimations();
    _generateCubes();
    _startAnimations();
  }
  
  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _waveController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
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
  
  void _generateCubes() {
    for (int i = 0; i < 5; i++) {
      _cubes.add(_FloatingCube());
    }
  }
  
  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _fadeController.forward();
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<PropertyBloc>()
        ..add(GetPropertyUnitsEvent(
          propertyId: widget.propertyId,
          checkInDate: _checkInDate,
          checkOutDate: _checkOutDate,
          guestsCount: _guestsCount,
        )),
      child: Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Stack(
          children: [
            _buildAnimatedBackground(),
            _buildFloatingCubes(),
            Column(
              children: [
                _buildFuturisticAppBar(),
                _buildFuturisticDateSelector(),
                Expanded(
                  child: BlocBuilder<PropertyBloc, PropertyState>(
                    builder: (context, state) {
                      if (state is PropertyUnitsLoading) {
                        return _buildFuturisticLoader();
                      }

                      if (state is PropertyError) {
                        return _buildFuturisticError(context, state);
                      }

                      if (state is PropertyUnitsLoaded) {
                        if (state.units.isEmpty) {
                          return _buildFuturisticEmptyState(context);
                        }

                        return RefreshIndicator(
                          onRefresh: () async => _loadUnits(context),
                          displacement: 60,
                          backgroundColor: AppTheme.darkCard,
                          color: AppTheme.primaryBlue,
                          child: GridView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.all(12),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.85,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: state.units.length,
                            itemBuilder: (context, index) {
                              final unit = state.units[index];
                              return FadeTransition(
                                opacity: _fadeAnimation,
                                child: SlideTransition(
                                  position: _slideAnimation,
                                  child: _buildFuturisticUnitCard(
                                    context, 
                                    unit, 
                                    state.selectedUnitId == unit.id,
                                    index,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: _buildFuturisticBottomBar(),
      ),
    );
  }
  
  Widget _buildAnimatedBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkBackground,
            AppTheme.darkBackground.withOpacity(0.9),
            AppTheme.darkBackground.withGreen(10),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFloatingCubes() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return CustomPaint(
          painter: _CubePainter(
            cubes: _cubes,
            animationValue: _waveController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildFuturisticAppBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.95),
            AppTheme.darkCard.withOpacity(0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: SafeArea(
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _buildGlassBackButton(),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => 
                              AppTheme.primaryGradient.createShader(bounds),
                          child: Text(
                            'الوحدات المتاحة',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          widget.propertyName,
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.textMuted,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _buildFilterButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildGlassBackButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.6),
            AppTheme.darkCard.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: Icon(
              Icons.arrow_back_ios_new,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildFilterButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showFilterDialog(context),
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: Icon(
              Icons.filter_list,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFuturisticDateSelector() {
    final nights = _checkOutDate.difference(_checkInDate).inDays;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildFuturisticDateCard(
                        title: 'تسجيل الدخول',
                        date: _checkInDate,
                        icon: Icons.login,
                        color: AppTheme.primaryBlue,
                        onTap: () => _selectCheckInDate(context),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryBlue.withOpacity(0.4),
                                    blurRadius: 15,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.nights_stay,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$nights',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    nights == 1 ? 'ليلة' : 'ليالي',
                                    style: AppTextStyles.caption.copyWith(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: _buildFuturisticDateCard(
                        title: 'تسجيل الخروج',
                        date: _checkOutDate,
                        icon: Icons.logout,
                        color: AppTheme.primaryPurple,
                        onTap: () => _selectCheckOutDate(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildFuturisticGuestsSelector(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFuturisticDateCard({
    required String title,
    required DateTime date,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        onTap();
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.2),
              color.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: AppTextStyles.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ShaderMask(
              shaderCallback: (bounds) => 
                  LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                  ).createShader(bounds),
              child: Text(
                _formatDate(date),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuturisticGuestsSelector() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryCyan.withOpacity(0.2),
            AppTheme.primaryCyan.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryCyan.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.people_outline,
            color: AppTheme.primaryCyan,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'عدد الضيوف',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Row(
            children: [
              _buildGuestControlButton(
                icon: Icons.remove_circle,
                onPressed: _guestsCount > 1
                    ? () {
                        setState(() {
                          _guestsCount--;
                        });
                        _loadUnits(context);
                        HapticFeedback.lightImpact();
                      }
                    : null,
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _guestsCount.toString(),
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildGuestControlButton(
                icon: Icons.add_circle,
                onPressed: () {
                  setState(() {
                    _guestsCount++;
                  });
                  _loadUnits(context);
                  HapticFeedback.lightImpact();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildGuestControlButton({
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            color: onPressed != null 
                ? AppTheme.primaryCyan
                : AppTheme.textMuted.withOpacity(0.3),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildFuturisticUnitCard(
    BuildContext context,
    Unit unit,
    bool isSelected,
    int index,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedUnitId = unit.id;
        });
        context.read<PropertyBloc>().add(SelectUnitEvent(unitId: unit.id));
        HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.identity()
          ..scale(isSelected ? 1.01 : 1.0),
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
              blurRadius: isSelected ? 20 : 12,
              offset: const Offset(0, 6),
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
                if (unit.images.isNotEmpty)
                  _buildUnitImageSection(unit, isSelected),
                _buildUnitContent(unit, isSelected),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildUnitImageSection(Unit unit, bool isSelected) {
    return Stack(
      children: [
        Container(
          height: 120,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(14),
            ),
            image: (ImageUtils.resolveUrl(unit.images.first.url).isEmpty)
                ? null
                : DecorationImage(
                    image: NetworkImage(
                      ImageUtils.resolveUrl(unit.images.first.url),
                    ),
                    fit: BoxFit.cover,
                  ),
          ),
          child: Container(
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
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'غير متاح',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (isSelected)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        if (unit.images.length > 1)
          Positioned(
            bottom: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.darkBackground.withOpacity(0.8),
                    AppTheme.darkBackground.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.photo_library_outlined,
                    size: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${unit.images.length}',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildUnitContent(Unit unit, bool isSelected) {
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
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
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
              ],
            ),
            if (unit.dynamicFields.isNotEmpty)
              _buildMiniFeatures(unit),
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
                      '${unit.basePrice.currency} / ${_getPricingPeriod(unit.pricingMethod)}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textMuted,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
                if (unit.isAvailable)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? AppTheme.primaryGradient
                          : null,
                      color: !isSelected
                          ? AppTheme.primaryBlue.withOpacity(0.2)
                          : null,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: isSelected ? Colors.white : AppTheme.primaryBlue,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMiniFeatures(Unit unit) {
    final features = unit.dynamicFields
        .expand((group) => group.fieldValues)
        .take(2)
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

  Widget _buildFuturisticBottomBar() {
    return BlocBuilder<PropertyBloc, PropertyState>(
      builder: (context, state) {
        if (state is PropertyUnitsLoaded && _selectedUnitId != null) {
          final selectedUnit = state.units.firstWhere(
            (unit) => unit.id == _selectedUnitId,
          );

          final nights = _checkOutDate.difference(_checkInDate).inDays;
          final totalPrice = selectedUnit.basePrice.amount * nights;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.darkCard.withOpacity(0.95),
                  AppTheme.darkSurface,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'الوحدة المحددة',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppTheme.textMuted,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  selectedUnit.name,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppTheme.textWhite,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'المجموع ($nights ليالي)',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppTheme.textMuted,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                ShaderMask(
                                  shaderCallback: (bounds) => 
                                      AppTheme.primaryGradient.createShader(bounds),
                                  child: Text(
                                    '${totalPrice.toStringAsFixed(0)} ${selectedUnit.basePrice.currency}',
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildGlowingButton(
                          onPressed: () => _proceedToBooking(context, selectedUnit),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'متابعة الحجز',
                                style: AppTextStyles.buttonMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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

        return const SizedBox.shrink();
      },
    );
  }
  
  Widget _buildFuturisticLoader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CustomPaint(
              painter: _CubeLoaderPainter(
                animationValue: _waveController.value,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ShaderMask(
            shaderCallback: (bounds) => 
                AppTheme.primaryGradient.createShader(bounds),
            child: Text(
              'جاري البحث عن الوحدات المتاحة',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFuturisticError(BuildContext context, PropertyError state) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.error.withOpacity(0.7),
              AppTheme.error.withOpacity(0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.error.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 40,
              color: AppTheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              'حدث خطأ',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppTheme.error,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              state.message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildGlowingButton(
              onPressed: () => _loadUnits(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'إعادة المحاولة',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFuturisticEmptyState(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
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
                color: AppTheme.primaryBlue.withOpacity(0.7),
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
              'في التواريخ المحددة',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            _buildGlowingButton(
              onPressed: () => _showDatePicker(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'تغيير التواريخ',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGlowingButton({
    required VoidCallback onPressed,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: child,
          ),
        ),
      ),
    );
  }

  IconData _getFieldIcon(String fieldName) {
    final name = fieldName.toLowerCase();
    if (name.contains('bed') || name.contains('سرير')) return Icons.bed;
    if (name.contains('bath') || name.contains('حمام')) return Icons.bathroom;
    if (name.contains('area') || name.contains('مساحة')) return Icons.square_foot;
    if (name.contains('floor') || name.contains('طابق')) return Icons.stairs;
    if (name.contains('view') || name.contains('إطلالة')) return Icons.landscape;
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

  String _formatDate(DateTime date) {
    final months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  void _loadUnits(BuildContext context) {
    context.read<PropertyBloc>().add(GetPropertyUnitsEvent(
      propertyId: widget.propertyId,
      checkInDate: _checkInDate,
      checkOutDate: _checkOutDate,
      guestsCount: _guestsCount,
    ));
  }

  void _selectCheckInDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _checkInDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryBlue,
              surface: AppTheme.darkCard,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      setState(() {
        _checkInDate = date;
        if (_checkOutDate.isBefore(_checkInDate)) {
          _checkOutDate = _checkInDate.add(const Duration(days: 1));
        }
      });
      _loadUnits(context);
    }
  }

  void _selectCheckOutDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _checkOutDate,
      firstDate: _checkInDate.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryBlue,
              surface: AppTheme.darkCard,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      setState(() {
        _checkOutDate = date;
      });
      _loadUnits(context);
    }
  }

  void _showDatePicker(BuildContext context) {
    _selectCheckInDate(context);
  }

  void _showFilterDialog(BuildContext context) {
    HapticFeedback.mediumImpact();
  }

  void _selectUnit(BuildContext context, Unit unit) {
    setState(() {
      _selectedUnitId = unit.id;
    });
    context.read<PropertyBloc>().add(SelectUnitEvent(unitId: unit.id));
    HapticFeedback.mediumImpact();
  }

  void _proceedToBooking(BuildContext context, Unit unit) {
    HapticFeedback.heavyImpact();
  }
}

class _FloatingCube {
  late double x;
  late double y;
  late double z;
  late double size;
  late double rotationSpeed;
  late Color color;
  late double opacity;
  
  _FloatingCube() {
    reset();
  }
  
  void reset() {
    x = math.Random().nextDouble();
    y = math.Random().nextDouble();
    z = math.Random().nextDouble() * 0.5 + 0.5;
    size = math.Random().nextDouble() * 20 + 15;
    rotationSpeed = math.Random().nextDouble() * 0.01 + 0.005;
    opacity = math.Random().nextDouble() * 0.05 + 0.02;
    
    final colors = [
      AppTheme.primaryBlue,
      AppTheme.primaryPurple,
      AppTheme.primaryCyan,
    ];
    color = colors[math.Random().nextInt(colors.length)];
  }
  
  void update(double animationValue) {
    y -= 0.0005;
    if (y < -0.1) {
      y = 1.1;
      x = math.Random().nextDouble();
    }
  }
}

class _CubePainter extends CustomPainter {
  final List<_FloatingCube> cubes;
  final double animationValue;
  
  _CubePainter({
    required this.cubes,
    required this.animationValue,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    for (var cube in cubes) {
      cube.update(animationValue);
      
      final center = Offset(
        cube.x * size.width,
        cube.y * size.height,
      );
      
      final rotation = animationValue * cube.rotationSpeed * 2 * math.pi;
      
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotation);
      
      final paint = Paint()
        ..shader = LinearGradient(
          colors: [
            cube.color.withOpacity(cube.opacity),
            cube.color.withOpacity(cube.opacity * 0.5),
          ],
        ).createShader(Rect.fromCenter(
          center: Offset.zero,
          width: cube.size,
          height: cube.size,
        ))
        ..style = PaintingStyle.fill;
      
      final path = Path()
        ..addRect(Rect.fromCenter(
          center: Offset.zero,
          width: cube.size * cube.z,
          height: cube.size * cube.z,
        ));
      
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _CubeLoaderPainter extends CustomPainter {
  final double animationValue;
  
  _CubeLoaderPainter({required this.animationValue});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 + animationValue * 360) * math.pi / 180;
      const radius = 25.0;
      
      final cubeCenter = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      
      final paint = Paint()
        ..shader = AppTheme.primaryGradient.createShader(
          Rect.fromCenter(center: cubeCenter, width: 12, height: 12),
        )
        ..style = PaintingStyle.fill;
      
      canvas.save();
      canvas.translate(cubeCenter.dx, cubeCenter.dy);
      canvas.rotate(animationValue * 2 * math.pi);
      
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 12, height: 12),
        paint,
      );
      
      canvas.restore();
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
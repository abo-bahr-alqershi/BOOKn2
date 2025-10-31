// lib/presentation/screens/futuristic_main_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../core/theme/app_theme.dart';
import '../../features/chat/presentation/pages/conversations_page.dart';
import '../../features/auth/presentation/pages/profile_page.dart';
import '../../features/admin_hub/presentation/pages/admin_hub_page.dart';
// Removed imports for deleted features

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> 
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  
  // Animation Controllers
  late AnimationController _navAnimationController;
  late AnimationController _glowAnimationController;
  late AnimationController _particleAnimationController;
  late AnimationController _waveAnimationController;
  late AnimationController _pulseAnimationController;
  
  // Animations
  late Animation<double> _glowAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _pulseAnimation;
  
  // Individual item animations
  final Map<int, AnimationController> _itemAnimations = {};
  final Map<int, Animation<double>> _itemScaleAnimations = {};
  
  // List<Widget> get _pages => [
  //   const FuturisticHomePage(),
  //   SearchPage(initialParams: widget.initialSearchParams),
  //   const MyBookingsPage(),
  //   const ConversationsPage(),
  //   const ProfilePage(),
  // ];
  List<Widget> get _pages => [
    const NavigationPage(child: AdminHubPage()),
    const NavigationPage(child: ConversationsPage()),
    const NavigationPage(child: ProfilePage()),
  ];
  final List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.dashboard_customize_outlined,
      activeIcon: Icons.dashboard_customize_rounded,
      label: 'الإدارة',
      gradient: LinearGradient(
        colors: [AppTheme.neonBlue, AppTheme.neonPurple],
      ),
    ),
    _NavItem(
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
      label: 'الرسائل',
      gradient: LinearGradient(
        colors: [AppTheme.primaryBlue, AppTheme.primaryViolet],
      ),
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'حسابي',
      gradient: LinearGradient(
        colors: [AppTheme.primaryViolet, AppTheme.neonPurple],
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    // If we have initial search params, start on the Search tab (index 1)
    // if (widget.initialSearchParams != null) {
    //   _currentIndex = 1;
    // }
    _initializeControllers();
    _initializeAnimations();
    _startAnimations();
    
    // Notifications removed
  }
  
  void _initializeControllers() {
    _pageController = PageController(initialPage: _currentIndex);
    
    _navAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _glowAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _particleAnimationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    
    _waveAnimationController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    
    _pulseAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    // Initialize item animations
    for (int i = 0; i < _navItems.length; i++) {
      _itemAnimations[i] = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
      
      _itemScaleAnimations[i] = Tween<double>(
        begin: 0.8,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _itemAnimations[i]!,
        curve: Curves.easeOutBack,
      ));
    }
  }
  
  void _initializeAnimations() {
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));
  }
  
  void _startAnimations() {
    _glowAnimationController.repeat(reverse: true);
    _particleAnimationController.repeat();
    _waveAnimationController.repeat();
    _pulseAnimationController.repeat(reverse: true);
    
    // Start initial item animation
    Future.delayed(const Duration(milliseconds: 100), () {
      for (int i = 0; i < _navItems.length; i++) {
        Future.delayed(Duration(milliseconds: i * 50), () {
          if (mounted) {
            _itemAnimations[i]?.forward();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _navAnimationController.dispose();
    _glowAnimationController.dispose();
    _particleAnimationController.dispose();
    _waveAnimationController.dispose();
    _pulseAnimationController.dispose();
    
    for (var controller in _itemAnimations.values) {
      controller.dispose();
    }
    
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      // Haptic feedback
      HapticFeedback.lightImpact();
      
      // Animate transition
      _navAnimationController.forward().then((_) {
        _navAnimationController.reset();
      });
      
      setState(() {
        _currentIndex = index;
      });
      
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutExpo,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      extendBody: true,
      body: Stack(
        children: [
          // Pages with gesture support
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            physics: const NeverScrollableScrollPhysics(),
            children: _pages,
          ),
          
          // Futuristic bottom navigation
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildFuturisticBottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticBottomBar() {
    return Container(
      height: 75,
      child: Stack(
        children: [
          // Glass morphism background
          _buildGlassBackground(),
          
          // Wave effect
          _buildWaveEffect(),
          
          // Glow line
          _buildGlowLine(),
          
          // Navigation items
          _buildNavigationItems(),
        ],
      ),
    );
  }
  
  Widget _buildGlassBackground() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            height: 75,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.darkCard.withValues(alpha: 0.7),
                  AppTheme.darkSurface.withValues(alpha: 0.9),
                ],
              ),
              border: Border(
                top: BorderSide(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  width: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildWaveEffect() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _waveAnimation,
        builder: (context, child) {
          return CustomPaint(
            size: const Size(double.infinity, 75),
            painter: _WaveEffectPainter(
              animation: _waveAnimation.value,
              currentIndex: _currentIndex,
              itemColors: _navItems.map((e) => e.gradient.colors[0]).toList(),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildGlowLine() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  _navItems[_currentIndex].gradient.colors[0].withValues(alpha: 0.3 + (_glowAnimation.value * 0.4),
                  ),
                  _navItems[_currentIndex].gradient.colors[1].withValues(alpha: 0.3 + (_glowAnimation.value * 0.4),
                  ),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: _navItems[_currentIndex].gradient.colors[0].withValues(alpha: 0.5),
                  blurRadius: 10 + (_glowAnimation.value * 5),
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildNavigationItems() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              _navItems.length,
              (index) => _buildCompactNavItem(index),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactNavItem(int index) {
    final isSelected = _currentIndex == index;
    final item = _navItems[index];
    
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _itemScaleAnimations[index]!,
          _pulseAnimation,
          _glowAnimation,
        ]),
        builder: (context, child) {
          final scale = _itemScaleAnimations[index]!.value * 
                        (isSelected ? _pulseAnimation.value : 1.0);
          
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 60,
              height: 60,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon with effects
                  Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Glow effect
                      if (isSelected)
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                item.gradient.colors[0].withValues(alpha: 0.3 * _glowAnimation.value,),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      
                      // Icon container
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isSelected ? 36 : 32,
                        height: isSelected ? 36 : 32,
                        decoration: BoxDecoration(
                          gradient: isSelected ? item.gradient : null,
                          color: !isSelected 
                              ? Colors.transparent
                              : null,
                          borderRadius: BorderRadius.circular(isSelected ? 12 : 10),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: item.gradient.colors[0].withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : [],
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(scale: animation, child: child),
                              );
                            },
                            layoutBuilder: (currentChild, previousChildren) {
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  ...previousChildren,
                                  if (currentChild != null) currentChild,
                                ],
                              );
                            },
                            child: Icon(
                              isSelected ? item.activeIcon : item.icon,
                              key: ValueKey<String>('nav_icon_${index}_${isSelected ? 'active' : 'inactive'}'),
                              size: isSelected ? 20 : 18,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textMuted.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                      
                      // Notification badge removed
                    ],
                  ),
                  
                  const SizedBox(height: 2),
                  
                  // Label
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: isSelected ? 10 : 9,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected 
                          ? item.gradient.colors[0]
                          : AppTheme.textMuted.withValues(alpha: 0.6),
                      height: 1.0,
                    ),
                    child: Text(item.label),
                  ),
                  
                  // Active indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(top: 2),
                    width: isSelected ? 16 : 0,
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: isSelected ? item.gradient : null,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  // Notification badge removed with notifications feature
}

// Navigation Item Model
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final LinearGradient gradient;
  
  _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.gradient,
  });
}

// Wave Effect Painter
class _WaveEffectPainter extends CustomPainter {
  final double animation;
  final int currentIndex;
  final List<Color> itemColors;
  
  _WaveEffectPainter({
    required this.animation,
    required this.currentIndex,
    required this.itemColors,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          itemColors[currentIndex].withValues(alpha: 0.1),
          itemColors[currentIndex].withValues(alpha: 0.05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final path = Path();
    final itemWidth = size.width / itemColors.length;
    final centerX = itemWidth * currentIndex + itemWidth / 2;
    
    path.moveTo(0, size.height);
    
    for (double x = 0; x <= size.width; x += 5) {
      final distance = (x - centerX).abs();
      final normalizedDistance = distance / (size.width / 2);
      final waveHeight = (1 - normalizedDistance) * 15 * 
                         math.sin(animation * 2 * math.pi);
      
      path.lineTo(x, size.height - 20 - waveHeight);
    }
    
    path.lineTo(size.width, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class NavigationPage extends StatelessWidget {
  final Widget child;
  
  const NavigationPage({
    super.key,
    required this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 75),
      child: child,
    );
  }
}


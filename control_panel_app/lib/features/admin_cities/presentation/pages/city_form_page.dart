// lib/features/admin_cities/presentation/pages/city_form_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/city.dart';
import 'package:bookn_cp_app/injection_container.dart';
import '../../domain/usecases/upload_city_image_usecase.dart';
import '../widgets/city_image_gallery.dart';
import '../bloc/cities_bloc.dart';
import '../bloc/cities_event.dart';
import '../bloc/cities_state.dart';

class CityFormPage extends StatefulWidget {
  final City? city;

  const CityFormPage({
    super.key,
    this.city,
  });

  @override
  State<CityFormPage> createState() => _CityFormPageState();
}

class _CityFormPageState extends State<CityFormPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _formAnimationController;
  late AnimationController _saveButtonAnimationController;

  late TextEditingController _nameController;
  late TextEditingController _countryController;

  List<String> _images = [];
  final Map<String, double> _uploadProgress = {};
  bool _isActive = true;
  bool _isLoading = false;
  bool _hasChanges = false;

  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _formAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _saveButtonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _nameController = TextEditingController(text: widget.city?.name ?? '');
    _countryController =
        TextEditingController(text: widget.city?.country ?? '');
    _images = List.from(widget.city?.images ?? []);
    _isActive = widget.city?.isActive ?? true;

    // Listen for changes
    _nameController.addListener(_onFormChanged);
    _countryController.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _formAnimationController.dispose();
    _saveButtonAnimationController.dispose();
    _nameController.dispose();
    _countryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: BlocListener<CitiesBloc, CitiesState>(
          listener: (context, state) {
            if (state is CityOperationSuccess) {
              _showSuccessAnimation();
            } else if (state is CityOperationFailure) {
              _showErrorMessage(state.message);
            }
          },
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              _buildFormContent(),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.darkBackground,
      leading: _buildBackButton(),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Animated gradient background
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryBlue.withValues(
                          alpha: 0.2 * _animationController.value,
                        ),
                        AppTheme.primaryPurple.withValues(
                          alpha: 0.15 * _animationController.value,
                        ),
                        AppTheme.primaryViolet.withValues(
                          alpha: 0.1 * _animationController.value,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Floating elements animation
            ...List.generate(3, (index) {
              return AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Positioned(
                    top: 50 + (index * 40) * _animationController.value,
                    right: -50 + (index * 60) * _animationController.value,
                    child: Transform.rotate(
                      angle: _animationController.value * 0.5,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppTheme.primaryBlue.withValues(
                                alpha: 0.1 * _animationController.value,
                              ),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),

            // Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Animated icon
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(-1, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _animationController,
                        curve: Curves.easeOutBack,
                      )),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppTheme.primaryBlue.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.city == null
                              ? CupertinoIcons.plus_circle_fill
                              : CupertinoIcons.pencil_circle_fill,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title with animation
                    FadeTransition(
                      opacity: _animationController,
                      child: Text(
                        widget.city == null ? 'مدينة جديدة' : 'تعديل المدينة',
                        style: AppTextStyles.displaySmall.copyWith(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color:
                                  AppTheme.primaryBlue.withValues(alpha: 0.3),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    FadeTransition(
                      opacity: _animationController,
                      child: Text(
                        widget.city == null
                            ? 'أضف معلومات المدينة الجديدة'
                            : 'قم بتحديث معلومات ${widget.city!.name}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (_hasChanges)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: _buildSaveIndicator(),
          ),
      ],
    );
  }

  Widget _buildBackButton() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (await _onWillPop()) {
              context.pop();
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Icon(
              CupertinoIcons.arrow_right,
              color: AppTheme.textWhite,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveIndicator() {
    return AnimatedBuilder(
      animation: _saveButtonAnimationController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.warning.withValues(
                  alpha: 0.2 + (0.1 * _saveButtonAnimationController.value),
                ),
                AppTheme.warning.withValues(
                  alpha: 0.1 + (0.05 * _saveButtonAnimationController.value),
                ),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.warning.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.warning,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.warning.withValues(
                        alpha: 0.5 * _saveButtonAnimationController.value,
                      ),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'لم يتم الحفظ',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFormContent() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: AnimationLimiter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 600),
                childAnimationBuilder: (widget) => SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(child: widget),
                ),
                children: [
                  _buildSectionTitle('معلومات أساسية'),
                  const SizedBox(height: 20),
                  _buildNameField(),
                  const SizedBox(height: 20),
                  _buildCountryField(),
                  const SizedBox(height: 24),
                  _buildActiveSwitch(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('معرض الصور'),
                  const SizedBox(height: 20),
                  _buildImagesSection(),
                  const SizedBox(height: 100), // Space for bottom bar
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: AppTextStyles.heading2.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              CupertinoIcons.building_2_fill,
              size: 18,
              color: AppTheme.primaryBlue,
            ),
            const SizedBox(width: 8),
            Text(
              'اسم المدينة',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '*',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowDark.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: _nameController,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
            ),
            decoration: InputDecoration(
              hintText: 'مثال: صنعاء',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted.withValues(alpha: 0.5),
              ),
              filled: true,
              fillColor: AppTheme.darkCard.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppTheme.darkBorder.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppTheme.primaryBlue,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppTheme.error,
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppTheme.error,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.all(16),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryBlue.withValues(alpha: 0.1),
                      AppTheme.primaryPurple.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  CupertinoIcons.building_2_fill,
                  color: AppTheme.primaryBlue,
                  size: 16,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'الرجاء إدخال اسم المدينة';
              }
              if (value.trim().length < 2) {
                return 'اسم المدينة قصير جداً';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCountryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              CupertinoIcons.globe,
              size: 18,
              color: AppTheme.primaryPurple,
            ),
            const SizedBox(width: 8),
            Text(
              'الدولة',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '*',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowDark.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: _countryController,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
            ),
            decoration: InputDecoration(
              hintText: 'مثال: اليمن',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted.withValues(alpha: 0.5),
              ),
              filled: true,
              fillColor: AppTheme.darkCard.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppTheme.darkBorder.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppTheme.primaryPurple,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppTheme.error,
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppTheme.error,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.all(16),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryPurple.withValues(alpha: 0.1),
                      AppTheme.primaryViolet.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  CupertinoIcons.globe,
                  color: AppTheme.primaryPurple,
                  size: 16,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'الرجاء إدخال اسم الدولة';
              }
              if (value.trim().length < 2) {
                return 'اسم الدولة قصير جداً';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActiveSwitch() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (_isActive ? AppTheme.success : AppTheme.textMuted)
                .withValues(alpha: 0.05),
            (_isActive ? AppTheme.success : AppTheme.textMuted)
                .withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (_isActive ? AppTheme.success : AppTheme.textMuted)
              .withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: _isActive
                      ? LinearGradient(
                          colors: [AppTheme.success, AppTheme.neonGreen],
                        )
                      : null,
                  color: _isActive ? null : AppTheme.textMuted,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _isActive
                      ? [
                          BoxShadow(
                            color: AppTheme.success.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    _isActive
                        ? CupertinoIcons.checkmark_circle_fill
                        : CupertinoIcons.xmark_circle_fill,
                    key: ValueKey(_isActive),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'حالة المدينة',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppTheme.textWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: _isActive ? AppTheme.success : AppTheme.textMuted,
                    ),
                    child: Text(
                      _isActive
                          ? 'المدينة نشطة ومتاحة للحجز'
                          : 'المدينة غير نشطة ولن تظهر للعملاء',
                    ),
                  ),
                ],
              ),
            ],
          ),
          Transform.scale(
            scale: 1.2,
            child: CupertinoSwitch(
              value: _isActive,
              onChanged: (value) {
                HapticFeedback.lightImpact();
                setState(() {
                  _isActive = value;
                  _hasChanges = true;
                });
              },
              activeTrackColor: AppTheme.success,
              inactiveTrackColor: AppTheme.textMuted.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withValues(alpha: 0.3),
            AppTheme.darkCard.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      CupertinoIcons.photo_fill_on_rectangle_fill,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'صور المدينة',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppTheme.textWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryBlue.withValues(alpha: 0.1),
                      AppTheme.primaryPurple.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_images.length}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '/10',
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          CityImageGallery(
            initialLocalImages: _images,
            onLocalImagesChanged: (paths) {
              setState(() {
                _images = List.from(paths);
                _hasChanges = true;
              });
              // ارفع أي صور محلية فوراً مثل آلية العقارات ثم استبدلها بالرابط
              for (int i = 0; i < paths.length; i++) {
                final path = paths[i];
                final lower = path.toLowerCase();
                final isRemote = lower.startsWith('http://') ||
                    lower.startsWith('https://') ||
                    lower.startsWith('/uploads') ||
                    lower.startsWith('uploads/') ||
                    lower.startsWith('/images') ||
                    lower.startsWith('images/');
                if (!isRemote) {
                  setState(() {
                    _uploadProgress[path] = 0.0;
                  });
                  final uploader = sl<UploadCityImageUseCase>();
                  uploader(
                    UploadCityImageParams(
                      cityName: _nameController.text.trim(),
                      imagePath: path,
                      onSendProgress: (sent, total) {
                        if (total > 0) {
                          final p = sent / total;
                          if (mounted) {
                            setState(() {
                              _uploadProgress[path] = p;
                            });
                          }
                        }
                      },
                    ),
                  ).then((either) {
                    either.fold(
                      (_) => null,
                      (url) {
                        if (!mounted) return;
                        setState(() {
                          if (i >= 0 &&
                              i < _images.length &&
                              _images[i] == path) {
                            _images[i] = url;
                          } else {
                            // fallback: replace first matching local occurrence
                            final idx = _images.indexOf(path);
                            if (idx != -1) _images[idx] = url;
                          }
                          _hasChanges = true;
                          _uploadProgress.remove(path);
                        });
                      },
                    );
                  });
                }
              }
            },
            maxImages: 10,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowDark.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.darkBorder.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            if (await _onWillPop()) {
                              context.pop();
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                            child: Text(
                              'إلغاء',
                              style: AppTextStyles.buttonMedium.copyWith(
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Save button
                  Expanded(
                    flex: 2,
                    child: AnimatedBuilder(
                      animation: _saveButtonAnimationController,
                      builder: (context, child) {
                        return Container(
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryBlue.withValues(
                                  alpha: 0.3 +
                                      (0.1 *
                                          _saveButtonAnimationController.value),
                                ),
                                blurRadius: 20 +
                                    (5 * _saveButtonAnimationController.value),
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isLoading ? null : _handleSave,
                              borderRadius: BorderRadius.circular(16),
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            widget.city == null
                                                ? CupertinoIcons
                                                    .plus_circle_fill
                                                : CupertinoIcons
                                                    .checkmark_circle_fill,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            widget.city == null
                                                ? 'إضافة المدينة'
                                                : 'حفظ التغييرات',
                                            style: AppTextStyles.buttonLarge
                                                .copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        );
                      },
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

  Future<bool> _onWillPop() async {
    if (_hasChanges) {
      return await showCupertinoDialog<bool>(
            context: context,
            builder: (context) => BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: CupertinoAlertDialog(
                title: const Text('هناك تغييرات غير محفوظة'),
                content: const Text('هل تريد الخروج بدون حفظ التغييرات؟'),
                actions: [
                  CupertinoDialogAction(
                    isDestructiveAction: true,
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('خروج بدون حفظ'),
                  ),
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('البقاء'),
                  ),
                ],
              ),
            ),
          ) ??
          false;
    }
    return true;
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();

      setState(() => _isLoading = true);

      // Ensure all images are uploaded and replaced with proper URLs
      final List<String> finalImages = [];
      for (final img in _images) {
        // Keep remote images as is (absolute or server-relative like /uploads/...)
        if (img.startsWith('http://') ||
            img.startsWith('https://') ||
            img.startsWith('/')) {
          finalImages.add(img);
          continue;
        }
        try {
          final uploader = sl<UploadCityImageUseCase>();
          final result = await uploader(
            UploadCityImageParams(
              cityName: _nameController.text.trim(),
              imagePath: img,
              onSendProgress: null,
            ),
          );
          result.fold(
            (_) {
              // If upload fails, skip this image silently to avoid saving invalid local paths
            },
            (url) => finalImages.add(url),
          );
        } catch (_) {
          // Skip on unexpected errors
        }
      }

      // Deduplicate and normalize URLs before sending to API (case-insensitive, preserve first occurrence order)
      final List<String> dedupedImages = [];
      final Set<String> seen = <String>{};
      for (final url in finalImages) {
        final trimmed = url.trim();
        if (trimmed.isEmpty) continue;
        final key = trimmed.toLowerCase();
        if (seen.add(key)) {
          dedupedImages.add(trimmed);
        }
      }

      final city = City(
        name: _nameController.text.trim(),
        country: _countryController.text.trim(),
        images: dedupedImages,
        isActive: _isActive,
        propertiesCount: widget.city?.propertiesCount,
        createdAt: widget.city?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        metadata: widget.city?.metadata,
      );

      if (widget.city == null) {
        context.read<CitiesBloc>().add(CreateCityEvent(city: city));
      } else {
        context.read<CitiesBloc>().add(UpdateCityEvent(
              oldName: widget.city!.name,
              city: city,
            ));
      }
    }
  }

  void _showSuccessAnimation() {
    setState(() => _isLoading = false);

    showDialog(
      fullscreenDialog: true,
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.success.withValues(alpha: 0.9),
                        AppTheme.neonGreen.withValues(alpha: 0.9),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.success.withValues(alpha: 0.5),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    CupertinoIcons.checkmark_alt,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pop(context); // Close dialog
      context.pop(); // Return to previous page
    });
  }

  void _showErrorMessage(String message) {
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(20),
      ),
    );
  }
}

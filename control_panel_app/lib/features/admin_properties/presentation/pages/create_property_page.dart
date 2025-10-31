// lib/features/admin_properties/presentation/pages/create_property_page.dart

import 'package:bookn_cp_app/core/theme/app_theme.dart';
import 'package:bookn_cp_app/features/admin_properties/domain/entities/property_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:bookn_cp_app/core/network/api_client.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:bookn_cp_app/core/theme/app_colors.dart';
import 'package:bookn_cp_app/core/theme/app_text_styles.dart';
import '../bloc/properties/properties_bloc.dart';
import '../bloc/property_types/property_types_bloc.dart';
import '../bloc/amenities/amenities_bloc.dart';
import '../widgets/property_image_gallery.dart';
import '../widgets/amenity_selector_widget.dart';
import '../widgets/property_map_view.dart';
import '../bloc/property_images/property_images_bloc.dart';
import '../bloc/property_images/property_images_event.dart';
import 'package:bookn_cp_app/features/helpers/presentation/utils/search_navigation_helper.dart';
import 'package:bookn_cp_app/features/admin_users/domain/entities/user.dart';
import 'package:bookn_cp_app/injection_container.dart' as di;
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import 'package:bookn_cp_app/features/admin_currencies/domain/usecases/get_currencies_usecase.dart';
import 'package:bookn_cp_app/features/admin_cities/domain/usecases/get_cities_usecase.dart'
    as ci_uc;
import '../../../reference/presentation/widgets/city_selector_dialog.dart';

class CreatePropertyPage extends StatelessWidget {
  const CreatePropertyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<PropertiesBloc>(
          create: (context) => GetIt.instance<PropertiesBloc>(),
        ),
        BlocProvider<PropertyTypesBloc>(
          create: (context) => GetIt.instance<PropertyTypesBloc>()
            ..add(const LoadPropertyTypesEvent(pageSize: 100)),
        ),
        BlocProvider<AmenitiesBloc>(
          create: (context) => GetIt.instance<AmenitiesBloc>()
            ..add(const LoadAmenitiesEvent(pageSize: 100)),
        ),
        BlocProvider(
          create: (context) => GetIt.instance<PropertyImagesBloc>(),
        ),
      ],
      child: const _CreatePropertyView(),
    );
  }
}

class _CreatePropertyView extends StatefulWidget {
  const _CreatePropertyView();

  @override
  State<_CreatePropertyView> createState() => _CreatePropertyViewState();
}

class _CreatePropertyViewState extends State<_CreatePropertyView>
    with TickerProviderStateMixin {
  // Controllers
  late AnimationController _animationController;
  late AnimationController _glowController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final GlobalKey<PropertyImageGalleryState> _galleryKey = GlobalKey();

  // Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _shortDescriptionController = TextEditingController();

  // State
  String? _selectedPropertyTypeId;
  User? _selectedOwner;
  int _starRating = 3;
  List<PropertyImage> _selectedImages = [];
  List<String> _selectedLocalImages = [];
  List<String> _selectedAmenities = [];
  int _currentStep = 0;
  String? _tempKey;
  String _currency = 'YER';
  String? _selectedCity;
  bool _isFeatured = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // Generate a temp key for pre-save uploads
    _tempKey = DateTime.now().millisecondsSinceEpoch.toString();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    ));

    // Start animation after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    // Purge temp images if user leaves without saving
    if (_tempKey != null) {
      try {
        GetIt.instance<ApiClient>().delete('/api/images/purge-temp',
            queryParameters: {'tempKey': _tempKey});
      } catch (_) {}
    }
    _animationController.dispose();
    _glowController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _shortDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PropertiesBloc, PropertiesState>(
      listener: (context, state) {
        if (state is PropertyCreated) {
          // Upload local images if exist
          final propertyId = state.propertyId;
          if (_selectedLocalImages.isNotEmpty) {
            try {
              _galleryKey.currentState?.uploadLocalImages(propertyId);
            } catch (_) {}
          }
          // Clear tempKey since entity is saved
          _tempKey = null;
          _showSuccessMessage('تم إنشاء العقار بنجاح');
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              context.pop();
            }
          });
        } else if (state is PropertiesError) {
          _showErrorMessage(state.message);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Stack(
          children: [
            // Animated Background
            _buildAnimatedBackground(),

            // Main Content
            SafeArea(
              child: Column(
                children: [
                  // Header
                  _buildHeader(),

                  // Progress Indicator
                  _buildProgressIndicator(),

                  // Form Content
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildFormContent(),
                      ),
                    ),
                  ),

                  // Action Buttons
                  _buildActionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkBackground,
                AppTheme.darkBackground2.withOpacity(0.8),
                AppTheme.darkBackground3.withOpacity(0.6),
              ],
            ),
          ),
          child: CustomPaint(
            painter: _CreatePropertyBackgroundPainter(
              glowIntensity: _glowController.value,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.7),
            AppTheme.darkCard.withOpacity(0.3),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: _handleBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.darkSurface.withOpacity(0.5),
                    AppTheme.darkSurface.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.darkBorder.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: AppTheme.textWhite,
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppTheme.primaryGradient.createShader(bounds),
                  child: Text(
                    'إضافة عقار جديد',
                    style: AppTextStyles.heading2.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'قم بملء البيانات المطلوبة لإضافة العقار',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final steps = [
      'المعلومات الأساسية',
      'الموقع',
      'الصور والمرافق',
      'المراجعة'
    ];

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: Row(
              children: [
                // Step Indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: isActive ? AppTheme.primaryGradient : null,
                    color: !isActive
                        ? AppTheme.darkSurface.withOpacity(0.5)
                        : null,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive
                          ? AppTheme.primaryBlue.withOpacity(0.5)
                          : AppTheme.darkBorder.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryBlue.withOpacity(0.3),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Colors.white,
                          )
                        : Text(
                            '${index + 1}',
                            style: AppTextStyles.caption.copyWith(
                              color:
                                  isActive ? Colors.white : AppTheme.textMuted,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                // Line
                if (index < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        gradient: isCompleted ? AppTheme.primaryGradient : null,
                        color: !isCompleted
                            ? AppTheme.darkBorder.withOpacity(0.2)
                            : null,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFormContent() {
    return BlocBuilder<PropertiesBloc, PropertiesState>(
      builder: (context, state) {
        return Form(
          key: _formKey,
          child: IndexedStack(
            index: _currentStep,
            children: [
              _buildBasicInfoStep(state),
              _buildLocationStep(state),
              _buildImagesAmenitiesStep(state),
              _buildReviewStep(state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBasicInfoStep(PropertiesState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property Name
          _buildInputField(
            controller: _nameController,
            label: 'اسم العقار',
            hint: 'أدخل اسم العقار',
            icon: Icons.business_rounded,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء إدخال اسم العقار';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Property Type
          _buildPropertyTypeSelector(),

          const SizedBox(height: 20),

          // Owner
          _buildOwnerSelector(),

          const SizedBox(height: 20),

          // Currency
          Row(
            children: [
              Expanded(
                child: _CurrencyDropdown(
                  value: _currency,
                  onChanged: (v) => setState(() => _currency = v),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Star Rating
          _buildStarRatingSelector(),

          const SizedBox(height: 20),

          // Featured Switch
          _buildFeaturedSwitch(),

          const SizedBox(height: 20),

          // Short Description
          _buildInputField(
            controller: _shortDescriptionController,
            label: 'وصف مختصر',
            hint: 'نص مختصر يظهر في القوائم',
            icon: Icons.short_text_rounded,
          ),

          const SizedBox(height: 20),

          // Description
          _buildInputField(
            controller: _descriptionController,
            label: 'الوصف التفصيلي',
            hint: 'أدخل وصف تفصيلي للعقار',
            icon: Icons.description_rounded,
            maxLines: 5,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء إدخال وصف العقار';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStep(PropertiesState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            'تحديد موقع العقار',
            style: AppTextStyles.heading3.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Map View
          Container(
            height: 300,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.darkCard.withOpacity(0.7),
                  AppTheme.darkCard.withOpacity(0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.darkBorder.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: PropertyMapView(
                onLocationSelected: (latLng) {
                  setState(() {
                    _latitudeController.text = latLng.latitude.toString();
                    _longitudeController.text = latLng.longitude.toString();
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Coordinates Section
          Text(
            'الإحداثيات',
            style: AppTextStyles.heading3.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              // Latitude
              Expanded(
                child: _buildInputField(
                  controller: _latitudeController,
                  label: 'خط العرض',
                  hint: 'أدخل خط العرض',
                  icon: Icons.my_location_rounded,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال خط العرض';
                    }
                    final lat = double.tryParse(value);
                    if (lat == null || lat < -90 || lat > 90) {
                      return 'خط العرض غير صحيح';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(width: 16),

              // Longitude
              Expanded(
                child: _buildInputField(
                  controller: _longitudeController,
                  label: 'خط الطول',
                  hint: 'أدخل خط الطول',
                  icon: Icons.my_location_rounded,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال خط الطول';
                    }
                    final lng = double.tryParse(value);
                    if (lng == null || lng < -180 || lng > 180) {
                      return 'خط الطول غير صحيح';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Address Section
          Text(
            'العنوان',
            style: AppTextStyles.heading3.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Address
          _buildInputField(
            controller: _addressController,
            label: 'العنوان الكامل',
            hint: 'أدخل العنوان التفصيلي',
            icon: Icons.location_on_rounded,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء إدخال العنوان';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // City
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'المدينة',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final selected = await CitySelectorDialog.show(context);
                  if (selected != null && selected.isNotEmpty) {
                    setState(() {
                      _selectedCity = selected;
                      _cityController.text = selected;
                    });
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.darkCard.withOpacity(0.5),
                        AppTheme.darkCard.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.darkBorder.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_city_rounded,
                        size: 18,
                        color: AppTheme.primaryBlue.withOpacity(0.7),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          (_selectedCity ?? '').isNotEmpty ? _selectedCity! : 'اختر المدينة',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: (_selectedCity ?? '').isNotEmpty
                                ? AppTheme.textWhite
                                : AppTheme.textMuted.withOpacity(0.5),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if ((_selectedCity ?? '').isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCity = null;
                              _cityController.text = '';
                            });
                          },
                          child: Icon(
                            Icons.clear,
                            size: 18,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_drop_down_rounded,
                        color: AppTheme.primaryBlue.withOpacity(0.7),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagesAmenitiesStep(PropertiesState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Images Section
          Text(
            'صور العقار',
            style: AppTextStyles.heading3.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          PropertyImageGallery(
            key: _galleryKey,
            propertyId: null,
            tempKey: _tempKey,
            maxImages: 10,
            onImagesChanged: (images) {
              setState(() {
                _selectedImages = images;
              });
            },
            onLocalImagesChanged: (paths) {
              setState(() {
                _selectedLocalImages = paths;
              });
            },
          ),

          const SizedBox(height: 30),

          // Amenities Section
          Text(
            'المرافق المتاحة',
            style: AppTextStyles.heading3.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          BlocBuilder<AmenitiesBloc, AmenitiesState>(
            builder: (context, state) {
              if (state is AmenitiesLoading) {
                return _buildAmenitiesLoadingState();
              } else if (state is AmenitiesError) {
                return _buildErrorWidget(
                  state.message,
                  onRetry: () {
                    context
                        .read<AmenitiesBloc>()
                        .add(const LoadAmenitiesEvent());
                  },
                );
              } else if (state is AmenitiesLoaded) {
                return AmenitySelectorWidget(
                  selectedAmenities: _selectedAmenities,
                  onAmenitiesChanged: (amenities) {
                    setState(() {
                      _selectedAmenities = amenities;
                    });
                  },
                  propertyTypeId: _selectedPropertyTypeId,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep(PropertiesState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مراجعة البيانات',
            style: AppTextStyles.heading2.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Basic Info Review
          _buildReviewCard(
            title: 'المعلومات الأساسية',
            icon: Icons.info_rounded,
            iconColor: AppTheme.primaryBlue,
            items: [
              {'label': 'الاسم', 'value': _nameController.text},
              {'label': 'النوع', 'value': _getPropertyTypeName()},
              {'label': 'المالك', 'value': _selectedOwner?.name ?? 'غير محدد'},
              {'label': 'التقييم', 'value': '$_starRating نجوم'},
              {'label': 'العملة', 'value': _currency},
              {'label': 'عقار مميز', 'value': _isFeatured ? 'نعم' : 'لا'},
            ],
          ),

          const SizedBox(height: 16),

          // Location Review
          _buildReviewCard(
            title: 'الموقع',
            icon: Icons.location_on_rounded,
            iconColor: AppTheme.success,
            items: [
              {'label': 'العنوان', 'value': _addressController.text},
              {'label': 'المدينة', 'value': _cityController.text},
              {'label': 'خط العرض', 'value': _latitudeController.text},
              {'label': 'خط الطول', 'value': _longitudeController.text},
            ],
          ),

          const SizedBox(height: 16),

          // Images & Amenities Review
          _buildReviewCard(
            title: 'الصور والمرافق',
            icon: Icons.image_rounded,
            iconColor: AppTheme.info,
            items: [
              {
                'label': 'عدد الصور',
                'value':
                    '${_selectedLocalImages.isNotEmpty ? _selectedLocalImages.length : _selectedImages.length}'
              },
              {'label': 'عدد المرافق', 'value': '${_selectedAmenities.length}'},
            ],
          ),

          const SizedBox(height: 16),

          // Description Review
          _buildReviewCard(
            title: 'الوصف',
            icon: Icons.description_rounded,
            iconColor: AppTheme.warning,
            items: [
              {
                'label': 'الوصف المختصر',
                'value': _shortDescriptionController.text.isEmpty
                    ? 'لا يوجد'
                    : _shortDescriptionController.text
              },
              {'label': 'الوصف التفصيلي', 'value': _descriptionController.text},
            ],
          ),

          // Images Preview
          if (_selectedLocalImages.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildImagesPreviewCard(),
          ],

          // Selected Amenities
          if (_selectedAmenities.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSelectedAmenitiesCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkCard.withOpacity(0.5),
                AppTheme.darkCard.withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.darkBorder.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted.withOpacity(0.5),
              ),
              prefixIcon: maxLines == 1
                  ? Icon(
                      icon,
                      color: AppTheme.primaryBlue.withOpacity(0.7),
                      size: 20,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            validator: validator,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نوع العقار',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        BlocBuilder<PropertyTypesBloc, PropertyTypesState>(
          builder: (context, state) {
            if (state is PropertyTypesLoading) {
              return _buildLoadingDropdown();
            } else if (state is PropertyTypesError) {
              return _buildErrorDropdown(state.message);
            } else if (state is PropertyTypesLoaded) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.darkCard.withOpacity(0.5),
                      AppTheme.darkCard.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.darkBorder.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPropertyTypeId,
                    isExpanded: true,
                    dropdownColor: AppTheme.darkCard,
                    icon: Icon(
                      Icons.arrow_drop_down_rounded,
                      color: AppTheme.primaryBlue.withOpacity(0.7),
                    ),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppTheme.textWhite,
                    ),
                    hint: Text(
                      'اختر نوع العقار',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppTheme.textMuted.withOpacity(0.5),
                      ),
                    ),
                    items: state.propertyTypes.map((type) {
                      return DropdownMenuItem(
                        value: type.id,
                        child: Row(
                          children: [
                            if (type.icon.isNotEmpty)
                              Icon(
                                _getIconFromString(type.icon),
                                size: 18,
                                color: AppTheme.primaryBlue.withOpacity(0.7),
                              ),
                            if (type.icon.isNotEmpty) const SizedBox(width: 8),
                            Text(type.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPropertyTypeId = value;
                      });
                      if (value != null && value.isNotEmpty) {
                        context.read<AmenitiesBloc>().add(
                              LoadAmenitiesEventWithType(
                                propertyTypeId: value,
                                pageSize: 100,
                              ),
                            );
                      }
                    },
                  ),
                ),
              );
            }
            return _buildLoadingDropdown();
          },
        ),
      ],
    );
  }

  Widget _buildOwnerSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'مالك العقار',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final user = await SearchNavigationHelper.searchSingleUser(context);
            if (user != null) {
              setState(() {
                _selectedOwner = user;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.darkCard.withOpacity(0.5),
                  AppTheme.darkCard.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.darkBorder.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person_search_rounded,
                  color: AppTheme.primaryBlue.withOpacity(0.7),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedOwner?.name ?? 'اختر مالك العقار',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: _selectedOwner == null
                          ? AppTheme.textMuted.withOpacity(0.5)
                          : AppTheme.textWhite,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppTheme.textMuted.withOpacity(0.7),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStarRatingSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تقييم النجوم',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            final isSelected = index < _starRating;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _starRating = index + 1;
                });
                HapticFeedback.lightImpact();
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                child: AnimatedScale(
                  scale: isSelected ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 32,
                    color: isSelected
                        ? AppTheme.warning
                        : AppTheme.textMuted.withOpacity(0.5),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFeaturedSwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.3),
            AppTheme.darkCard.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isFeatured
              ? AppTheme.warning.withOpacity(0.3)
              : AppTheme.darkBorder.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.star_rounded,
                color: _isFeatured ? AppTheme.warning : AppTheme.textMuted,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'عقار مميز',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _isFeatured
                      ? AppTheme.warning.withOpacity(0.2)
                      : AppTheme.darkSurface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isFeatured
                        ? AppTheme.warning.withOpacity(0.5)
                        : AppTheme.darkBorder.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  _isFeatured ? 'مفعل' : 'غير مفعل',
                  style: AppTextStyles.caption.copyWith(
                    color: _isFeatured ? AppTheme.warning : AppTheme.textMuted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Switch(
            value: _isFeatured,
            onChanged: (value) {
              setState(() {
                _isFeatured = value;
              });
              HapticFeedback.lightImpact();
            },
            activeTrackColor: AppTheme.warning.withOpacity(0.5),
            activeThumbColor: AppTheme.warning,
            inactiveThumbColor: AppTheme.textMuted,
            inactiveTrackColor: AppTheme.darkBorder.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingDropdown() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.5),
            AppTheme.darkCard.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryBlue.withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'جاري تحميل الأنواع...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorDropdown(String message) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.5),
            AppTheme.darkCard.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: AppTheme.error,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'خطأ في تحميل الأنواع',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmenitiesLoadingState() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.5),
            AppTheme.darkCard.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryBlue.withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'جاري تحميل المرافق...',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Map<String, String>> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.5),
            AppTheme.darkCard.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [iconColor, iconColor.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: iconColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getItemIcon(item['label']!),
                          size: 14,
                          color: AppTheme.textMuted.withOpacity(0.7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item['label']!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Text(
                        item['value']!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.end,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildImagesPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.info.withOpacity(0.1),
            AppTheme.info.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.info.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.info, AppTheme.info.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.photo_library_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'الصور المحددة',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.info,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.info.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_selectedLocalImages.length} صورة',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.info,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'سيتم رفع الصور بعد إنشاء العقار',
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedAmenitiesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.success.withOpacity(0.1),
            AppTheme.success.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.success.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.success,
                      AppTheme.success.withOpacity(0.7)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'المرافق المحددة',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_selectedAmenities.length} مرفق',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message, {VoidCallback? onRetry}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: AppTheme.error,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.error,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: Text(
                'إعادة المحاولة',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.7),
            AppTheme.darkCard.withOpacity(0.5),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Previous Button
          if (_currentStep > 0)
            Expanded(
              child: GestureDetector(
                onTap: _previousStep,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.darkSurface.withOpacity(0.5),
                        AppTheme.darkSurface.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.darkBorder.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'السابق',
                      style: AppTextStyles.buttonMedium.copyWith(
                        color: AppTheme.textWhite,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          if (_currentStep > 0) const SizedBox(width: 12),

          // Next/Submit Button
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: GestureDetector(
              onTap: _currentStep < 3 ? _nextStep : _submitForm,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: BlocBuilder<PropertiesBloc, PropertiesState>(
                    builder: (context, state) {
                      if (state is PropertyCreating) {
                        return const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        );
                      }
                      return Text(
                        _currentStep < 3 ? 'التالي' : 'إضافة العقار',
                        style: AppTextStyles.buttonMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  void _handleBack() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      context.pop();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _nextStep() {
    if (_currentStep < 3) {
      // Validate current step
      bool isValid = true;

      if (_currentStep == 0) {
        isValid = _validateBasicInfo();
      } else if (_currentStep == 1) {
        isValid = _validateLocation();
      } else if (_currentStep == 2) {
        isValid = _validateImagesAndAmenities();
      }

      if (isValid) {
        setState(() {
          _currentStep++;
        });
      }
    }
  }

  bool _validateBasicInfo() {
    if (_nameController.text.isEmpty ||
        _selectedPropertyTypeId == null ||
        _selectedOwner == null ||
        _descriptionController.text.isEmpty) {
      _showErrorMessage('الرجاء ملء جميع الحقول المطلوبة');
      return false;
    }
    return true;
  }

  bool _validateLocation() {
    if (_addressController.text.isEmpty ||
        _cityController.text.isEmpty ||
        _latitudeController.text.isEmpty ||
        _longitudeController.text.isEmpty) {
      _showErrorMessage('الرجاء ملء جميع الحقول المطلوبة');
      return false;
    }

    final lat = double.tryParse(_latitudeController.text);
    final lng = double.tryParse(_longitudeController.text);

    if (lat == null || lng == null) {
      _showErrorMessage('إحداثيات الموقع غير صحيحة');
      return false;
    }

    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      _showErrorMessage('إحداثيات الموقع خارج النطاق المسموح');
      return false;
    }

    return true;
  }

  bool _validateImagesAndAmenities() {
    // Consider local images during creation
    final bool hasAnyImage =
        _selectedLocalImages.isNotEmpty || _selectedImages.isNotEmpty;
    if (!hasAnyImage) {
      _showErrorMessage('الرجاء إضافة صورة واحدة على الأقل');
      return false;
    }
    return true;
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Validate required fields
      if (_selectedPropertyTypeId == null) {
        _showErrorMessage('الرجاء اختيار نوع العقار');
        return;
      }

      // Get owner ID from selection
      final ownerId = _selectedOwner?.id;
      if (ownerId == null || ownerId.isEmpty) {
        _showErrorMessage('الرجاء اختيار مالك العقار');
        return;
      }

      // Submit the form
      context.read<PropertiesBloc>().add(
            CreatePropertyEvent(
              name: _nameController.text.trim(),
              address: _addressController.text.trim(),
              propertyTypeId: _selectedPropertyTypeId!,
              ownerId: ownerId,
              description: _descriptionController.text.trim(),
              latitude: double.tryParse(_latitudeController.text) ?? 0.0,
              longitude: double.tryParse(_longitudeController.text) ?? 0.0,
              city: _cityController.text.trim(),
              starRating: _starRating,
              images: _selectedLocalImages.isEmpty ? [] : _selectedLocalImages,
              amenityIds:
                  _selectedAmenities.isEmpty ? null : _selectedAmenities,
              tempKey: _tempKey,
              shortDescription: (_shortDescriptionController.text.isNotEmpty
                      ? _shortDescriptionController.text
                      : _descriptionController.text)
                  .trim(),
              currency: _currency,
              isFeatured: _isFeatured,
            ),
          );
    }
  }

  String _getPropertyTypeName() {
    final state = context.read<PropertyTypesBloc>().state;
    if (state is PropertyTypesLoaded && _selectedPropertyTypeId != null) {
      try {
        final type = state.propertyTypes.firstWhere(
          (t) => t.id == _selectedPropertyTypeId,
        );
        return type.name;
      } catch (e) {
        return 'غير محدد';
      }
    }
    return 'غير محدد';
  }

  IconData _getIconFromString(String iconName) {
    // Map common icon names to IconData
    switch (iconName) {
      case 'home':
        return Icons.home_rounded;
      case 'apartment':
        return Icons.apartment_rounded;
      case 'villa':
        return Icons.villa_rounded;
      case 'store':
        return Icons.store_rounded;
      case 'business':
        return Icons.business_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  IconData _getItemIcon(String label) {
    switch (label) {
      case 'الاسم':
        return Icons.text_fields_rounded;
      case 'النوع':
        return Icons.category_rounded;
      case 'المالك':
        return Icons.person_rounded;
      case 'التقييم':
        return Icons.star_rounded;
      case 'العملة':
        return Icons.attach_money_rounded;
      case 'عقار مميز':
        return Icons.workspace_premium_rounded;
      case 'العنوان':
        return Icons.location_on_rounded;
      case 'المدينة':
        return Icons.location_city_rounded;
      case 'خط العرض':
      case 'خط الطول':
        return Icons.my_location_rounded;
      case 'عدد الصور':
        return Icons.photo_library_rounded;
      case 'عدد المرافق':
        return Icons.checklist_rounded;
      case 'الوصف المختصر':
        return Icons.short_text_rounded;
      case 'الوصف التفصيلي':
        return Icons.description_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// Currency Dropdown Widget
class _CurrencyDropdown extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _CurrencyDropdown({required this.value, required this.onChanged});

  @override
  State<_CurrencyDropdown> createState() => _CurrencyDropdownState();
}

class _CurrencyDropdownState extends State<_CurrencyDropdown> {
  List<String> _codes = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final usecase = di.sl<GetCurrenciesUseCase>();
    final result = await usecase(NoParams());
    result.fold(
      (f) => setState(() {
        _error = f.message;
        _loading = false;
      }),
      (list) => setState(() {
        _codes = list.map((c) => c.code).toList();
        _loading = false;
        if (_codes.isNotEmpty && !_codes.contains(widget.value)) {
          widget.onChanged(_codes.first);
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final decoration = InputDecoration(
      labelText: 'العملة',
      labelStyle: AppTextStyles.bodySmall.copyWith(color: AppTheme.textMuted),
      filled: true,
      fillColor: AppTheme.darkSurface.withOpacity(0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
    if (_loading) {
      return InputDecorator(
        decoration: decoration,
        child: Row(children: [
          const SizedBox(width: 4, height: 4),
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppTheme.textMuted),
          ),
          const SizedBox(width: 8),
          Text('جاري تحميل العملات...',
              style: AppTextStyles.caption.copyWith(color: AppTheme.textMuted)),
        ]),
      );
    }
    if (_error != null) {
      return DropdownButtonFormField<String>(
        initialValue: _codes.contains(widget.value) ? widget.value : null,
        decoration: decoration.copyWith(errorText: _error),
        items: _codes
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(),
        onChanged: (v) {
          if (v != null) widget.onChanged(v);
        },
      );
    }
    return DropdownButtonFormField<String>(
      initialValue: _codes.contains(widget.value) ? widget.value : null,
      decoration: decoration,
      dropdownColor: AppTheme.darkCard,
      style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textWhite),
      items: _codes
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (v) {
        if (v != null) widget.onChanged(v);
      },
    );
  }
}

// City Dropdown Widget
class _CityDropdown extends StatefulWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool requiredField;
  const _CityDropdown(
      {required this.value,
      required this.onChanged,
      this.requiredField = false});

  @override
  State<_CityDropdown> createState() => _CityDropdownState();
}

class _CityDropdownState extends State<_CityDropdown> {
  List<String> _cities = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final usecase = di.sl<ci_uc.GetCitiesUseCase>();
      final result = await usecase(const ci_uc.GetCitiesParams());
      result.fold(
        (f) => setState(() {
          _error = f.message;
          _loading = false;
        }),
        (list) => setState(() {
          _cities = list.map((c) => c.name).toList();
          _loading = false;
          if (_cities.isNotEmpty &&
              (widget.value == null || !_cities.contains(widget.value))) {
            // Do not auto-select when required; keep null so validator can trigger
          }
        }),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final decoration = InputDecoration(
      labelText:
          widget.requiredField ? 'المدينة (إجباري)' : 'المدينة (اختياري)',
      labelStyle: AppTextStyles.bodySmall.copyWith(color: AppTheme.textMuted),
      filled: true,
      fillColor: AppTheme.darkSurface.withOpacity(0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );

    if (_loading) {
      return InputDecorator(
        decoration: decoration,
        child: Row(children: [
          const SizedBox(width: 4, height: 4),
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppTheme.textMuted),
          ),
          const SizedBox(width: 8),
          Text('جاري تحميل المدن...',
              style: AppTextStyles.caption.copyWith(color: AppTheme.textMuted)),
        ]),
      );
    }

    final items =
        _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList();

    if (_error != null) {
      return DropdownButtonFormField<String?>(
        initialValue: _cities.contains(widget.value) ? widget.value : null,
        decoration: decoration.copyWith(errorText: _error),
        items: items,
        onChanged: (v) => widget.onChanged(v),
        validator: widget.requiredField
            ? (v) => (v == null || (v).isEmpty) ? 'المدينة مطلوبة' : null
            : null,
      );
    }

    return DropdownButtonFormField<String?>(
      initialValue: _cities.contains(widget.value) ? widget.value : null,
      decoration: decoration,
      dropdownColor: AppTheme.darkCard,
      style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textWhite),
      items: items,
      onChanged: (v) => widget.onChanged(v),
      validator: widget.requiredField
          ? (v) => (v == null || (v).isEmpty) ? 'المدينة مطلوبة' : null
          : null,
    );
  }
}

// Background Painter
class _CreatePropertyBackgroundPainter extends CustomPainter {
  final double glowIntensity;

  _CreatePropertyBackgroundPainter({required this.glowIntensity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw glowing orbs
    paint.shader = RadialGradient(
      colors: [
        AppTheme.primaryBlue.withOpacity(0.1 * glowIntensity),
        AppTheme.primaryBlue.withOpacity(0.05 * glowIntensity),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(
      center: Offset(size.width * 0.8, size.height * 0.2),
      radius: 150,
    ));

    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.2),
      150,
      paint,
    );

    paint.shader = RadialGradient(
      colors: [
        AppTheme.primaryPurple.withOpacity(0.1 * glowIntensity),
        AppTheme.primaryPurple.withOpacity(0.05 * glowIntensity),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(
      center: Offset(size.width * 0.2, size.height * 0.7),
      radius: 100,
    ));

    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.7),
      100,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

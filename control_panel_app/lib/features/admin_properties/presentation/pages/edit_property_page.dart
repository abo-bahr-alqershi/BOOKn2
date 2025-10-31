// lib/features/admin_properties/presentation/pages/edit_property_page.dart

import 'package:bookn_cp_app/core/theme/app_theme.dart';
import 'package:bookn_cp_app/features/admin_properties/domain/entities/property_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:bookn_cp_app/core/theme/app_colors.dart';
import 'package:bookn_cp_app/core/theme/app_text_styles.dart';
import '../bloc/properties/properties_bloc.dart';
import '../bloc/property_types/property_types_bloc.dart';
import '../bloc/amenities/amenities_bloc.dart';
import '../bloc/property_images/property_images_bloc.dart';
import '../widgets/property_image_gallery.dart';
import '../widgets/amenity_selector_widget.dart';
import '../widgets/property_map_view.dart';
import 'package:bookn_cp_app/injection_container.dart' as di;
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import 'package:bookn_cp_app/features/admin_currencies/domain/usecases/get_currencies_usecase.dart';
import 'package:bookn_cp_app/features/admin_cities/domain/usecases/get_cities_usecase.dart'
    as ci_uc;
import '../../domain/entities/property.dart';
import '../../domain/entities/property_type.dart';
import 'package:bookn_cp_app/features/helpers/presentation/utils/search_navigation_helper.dart';
import 'package:bookn_cp_app/features/admin_users/domain/entities/user.dart';

class EditPropertyPage extends StatelessWidget {
  final String propertyId;

  const EditPropertyPage({
    super.key,
    required this.propertyId,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => di.sl<PropertiesBloc>()
            ..add(LoadPropertyDetailsEvent(propertyId: propertyId)),
        ),
        BlocProvider(
          create: (_) => di.sl<PropertyTypesBloc>()
            ..add(const LoadPropertyTypesEvent(pageSize: 100)),
        ),
        BlocProvider(
          create: (_) => di.sl<AmenitiesBloc>(),
        ),
        BlocProvider(
          create: (_) => di.sl<PropertyImagesBloc>(),
        ),
      ],
      child: _EditPropertyView(propertyId: propertyId),
    );
  }
}

class _EditPropertyView extends StatefulWidget {
  final String propertyId;

  const _EditPropertyView({
    required this.propertyId,
  });

  @override
  State<_EditPropertyView> createState() => _EditPropertyViewState();
}

class _EditPropertyViewState extends State<_EditPropertyView>
    with TickerProviderStateMixin {
  // Controllers
  late AnimationController _animationController;
  late AnimationController _glowController;
  late AnimationController _loadingAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _loadingRotation;

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
  List<String> _selectedAmenities = [];
  bool _isFeatured = false;
  String _currency = 'YER';
  String? _selectedCity;
  int _currentStep = 0;
  final GlobalKey<PropertyImageGalleryState> _galleryKey = GlobalKey();

  // Edit specific state
  Property? _originalProperty;
  bool _isDataLoaded = false;
  bool _hasChanges = false;
  List<String> _originalImageUrls = [];
  bool _imagesChanged = false;
  List<String> _originalAmenities = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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

    _loadingAnimationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();

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

    _loadingRotation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _loadingAnimationController,
      curve: Curves.linear,
    ));
  }

  void _populateFormWithPropertyData(Property property) {
    if (_isDataLoaded) return;

    setState(() {
      _originalProperty = property;
      _isDataLoaded = true;

      // Populate text controllers
      _nameController.text = property.name;
      _shortDescriptionController.text = property.shortDescription ?? '';
      _addressController.text = property.address;
      _cityController.text = property.city;
      _selectedCity = property.city.isNotEmpty ? property.city : null;
      _descriptionController.text = property.description;
      _latitudeController.text = property.latitude?.toString() ?? '';
      _longitudeController.text = property.longitude?.toString() ?? '';

      // Set property details
      _selectedPropertyTypeId = property.typeId;
      // No owner object exists on Property entity; keep null until user selects
      _selectedOwner = null;
      _starRating = property.starRating;
      _isFeatured = property.isFeatured;
      _currency = property.currency;

      // Set images
      _selectedImages = property.images;
      _originalImageUrls = property.images.map((e) => e.url).toList();

      // Set amenities
      _selectedAmenities =
          property.amenities.map((amenity) => amenity.id).toList();
      _originalAmenities = List<String>.from(_selectedAmenities);
    });

    // Load amenities for property type
    if (property.typeId.isNotEmpty) {
      context.read<AmenitiesBloc>().add(
            LoadAmenitiesEventWithType(
              propertyTypeId: property.typeId,
              pageSize: 100,
            ),
          );
    }

    // Start animation after data is loaded
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _glowController.dispose();
    _loadingAnimationController.dispose();
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
    return WillPopScope(
      onWillPop: _onWillPop,
      child: BlocListener<PropertiesBloc, PropertiesState>(
        listener: (context, state) {
          if (state is PropertyDetailsLoaded && !_isDataLoaded) {
            _populateFormWithPropertyData(state.property);
          } else if (state is PropertyDetailsError) {
            _showErrorMessage(state.message);
          } else if (state is PropertyUpdated) {
            _showSuccessMessage('تم تحديث العقار بنجاح');
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                context.pop(true);
              }
            });
          } else if (state is PropertyDeleted) {
            _showSuccessMessage('تم حذف العقار بنجاح');
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                context.pop(true);
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

              // Main Content or Loading
              SafeArea(
                child: BlocBuilder<PropertiesBloc, PropertiesState>(
                  builder: (context, state) {
                    if (state is PropertyDetailsLoading || !_isDataLoaded) {
                      return _buildLoadingState();
                    } else if (state is PropertyDetailsError) {
                      return _buildErrorState(state.message);
                    } else if (state is PropertyDetailsLoaded) {
                      return Column(
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
                      );
                    } else if (state is PropertyUpdating) {
                      return _buildUpdatingState();
                    } else {
                      return _buildLoadingState();
                    }
                  },
                ),
              ),
            ],
          ),
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
            painter: _EditPropertyBackgroundPainter(
              glowIntensity: _glowController.value,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _loadingRotation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _loadingRotation.value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryBlue.withOpacity(0.3),
                        AppTheme.primaryPurple.withOpacity(0.2),
                        AppTheme.primaryViolet.withOpacity(0.1),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.darkBackground,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.business_rounded,
                          color: AppTheme.primaryBlue,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          ShaderMask(
            shaderCallback: (bounds) =>
                AppTheme.primaryGradient.createShader(bounds),
            child: Text(
              'جاري تحميل بيانات العقار...',
              style: AppTextStyles.heading3.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'الرجاء الانتظار',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
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
                Row(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppTheme.primaryGradient.createShader(bounds),
                      child: Text(
                        'تعديل العقار',
                        style: AppTextStyles.heading2.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_hasChanges)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.warning.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'محرر',
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _originalProperty?.name ?? 'قم بتعديل البيانات المطلوبة',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Reset Button
          if (_hasChanges)
            GestureDetector(
              onTap: _resetChanges,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.error.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.refresh_rounded,
                  color: AppTheme.error,
                  size: 20,
                ),
              ),
            ),

          const SizedBox(width: 8),

          // Delete Button
          GestureDetector(
            onTap: _showDeleteConfirmation,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.error.withOpacity(0.2),
                    AppTheme.error.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.error.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.delete_rounded,
                color: AppTheme.error,
                size: 20,
              ),
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
          final isModified = _hasChangesInStep(index);

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
                      color: isModified
                          ? AppTheme.warning.withOpacity(0.5)
                          : isActive
                              ? AppTheme.primaryBlue.withOpacity(0.5)
                              : AppTheme.darkBorder.withOpacity(0.3),
                      width: isModified ? 2 : 1,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: isModified
                                  ? AppTheme.warning.withOpacity(0.3)
                                  : AppTheme.primaryBlue.withOpacity(0.3),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(
                            isModified
                                ? Icons.edit_rounded
                                : Icons.check_rounded,
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
                        gradient: isCompleted
                            ? isModified
                                ? LinearGradient(colors: [
                                    AppTheme.warning,
                                    AppTheme.warning.withOpacity(0.5)
                                  ])
                                : AppTheme.primaryGradient
                            : null,
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
          onChanged: () {
            setState(() {
              _hasChanges = _checkForChanges();
            });
          },
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
          // Change Indicator
          if (_originalProperty != null)
            _buildOriginalValueIndicator(
              'اسم العقار الأصلي',
              _originalProperty!.name,
              _nameController.text != _originalProperty!.name,
            ),

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
            onChanged: (value) {
              setState(() {
                _hasChanges = _checkForChanges();
              });
            },
          ),

          const SizedBox(height: 20),

          // Property Type (Read-only in edit mode)
          _buildReadOnlyField(
            label: 'نوع العقار',
            value: _originalProperty?.typeName ?? 'غير محدد',
            icon: Icons.category_rounded,
          ),

          const SizedBox(height: 20),

          // Owner Selector
          _buildOwnerSelector(),

          const SizedBox(height: 20),

          // Currency
          Row(
            children: [
              Expanded(
                child: _CurrencyDropdown(
                  value: _currency,
                  onChanged: (v) => setState(() {
                    _currency = v;
                    _hasChanges = _checkForChanges();
                  }),
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
          if (_originalProperty != null &&
              _shortDescriptionController.text !=
                  (_originalProperty!.shortDescription ?? ''))
            _buildOriginalValueIndicator(
              'الوصف المختصر الأصلي',
              _originalProperty!.shortDescription?.isEmpty ?? true
                  ? 'لا يوجد'
                  : _originalProperty!.shortDescription!,
              true,
            ),

          _buildInputField(
            controller: _shortDescriptionController,
            label: 'وصف مختصر',
            hint: 'نص مختصر يظهر في القوائم',
            icon: Icons.short_text_rounded,
            onChanged: (value) {
              setState(() {
                _hasChanges = _checkForChanges();
              });
            },
          ),

          const SizedBox(height: 20),

          // Description
          if (_originalProperty != null &&
              _descriptionController.text != _originalProperty!.description)
            _buildOriginalValueIndicator(
              'الوصف الأصلي',
              _originalProperty!.description.isEmpty
                  ? 'لا يوجد'
                  : _originalProperty!.description,
              true,
            ),

          _buildInputField(
            controller: _descriptionController,
            label: 'الوصف',
            hint: 'أدخل وصف تفصيلي للعقار',
            icon: Icons.description_rounded,
            maxLines: 5,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء إدخال وصف العقار';
              }
              return null;
            },
            onChanged: (value) {
              setState(() {
                _hasChanges = _checkForChanges();
              });
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
                    _hasChanges = _checkForChanges();
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Latitude
          if (_originalProperty != null &&
              _latitudeController.text !=
                  (_originalProperty!.latitude?.toString() ?? ''))
            _buildOriginalValueIndicator(
              'خط العرض الأصلي',
              _originalProperty!.latitude?.toString() ?? 'غير محدد',
              true,
            ),

          _buildInputField(
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
            onChanged: (value) {
              setState(() {
                _hasChanges = _checkForChanges();
              });
            },
          ),

          const SizedBox(height: 20),

          // Longitude
          if (_originalProperty != null &&
              _longitudeController.text !=
                  (_originalProperty!.longitude?.toString() ?? ''))
            _buildOriginalValueIndicator(
              'خط الطول الأصلي',
              _originalProperty!.longitude?.toString() ?? 'غير محدد',
              true,
            ),

          _buildInputField(
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
            onChanged: (value) {
              setState(() {
                _hasChanges = _checkForChanges();
              });
            },
          ),

          const SizedBox(height: 20),

          // Address
          if (_originalProperty != null &&
              _addressController.text != _originalProperty!.address)
            _buildOriginalValueIndicator(
              'العنوان الأصلي',
              _originalProperty!.address,
              true,
            ),

          _buildInputField(
            controller: _addressController,
            label: 'العنوان',
            hint: 'أدخل العنوان الكامل',
            icon: Icons.location_on_rounded,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء إدخال العنوان';
              }
              return null;
            },
            onChanged: (value) {
              setState(() {
                _hasChanges = _checkForChanges();
              });
            },
          ),

          const SizedBox(height: 20),

          // City
          _CityDropdown(
            value: _selectedCity,
            onChanged: (v) {
              setState(() {
                _selectedCity = v;
                _cityController.text = v ?? '';
                _hasChanges = _checkForChanges();
              });
            },
            requiredField: true,
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
            propertyId: widget.propertyId,
            initialImages: _selectedImages,
            onImagesChanged: (images) {
              setState(() {
                _selectedImages = images;
                final current = _selectedImages.map((e) => e.url).toList();
                _imagesChanged = !_areImagesEqual(current, _originalImageUrls);
                _hasChanges = _checkForChanges();
              });
            },
            maxImages: 10,
          ),
          const SizedBox(height: 30),
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
                return const Center(
                  child: CircularProgressIndicator(),
                );
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
                      _hasChanges = _checkForChanges();
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
          Row(
            children: [
              Text(
                'مراجعة التغييرات',
                style: AppTextStyles.heading2.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              if (_hasChanges)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.warning,
                        AppTheme.warning.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'يوجد تغييرات',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Changes Summary
          if (_hasChanges) _buildChangesSummary(),

          const SizedBox(height: 20),

          _buildReviewCard(
            title: 'المعلومات الأساسية',
            items: [
              {
                'label': 'الاسم',
                'value': _nameController.text,
                'changed': _nameController.text != _originalProperty?.name
              },
              {
                'label': 'نوع العقار',
                'value': _originalProperty?.typeName ?? '',
                'changed': false
              },
              {
                'label': 'المالك',
                'value': _selectedOwner?.name ??
                    (_originalProperty?.ownerName ?? 'غير محدد'),
                'changed': _selectedOwner != null &&
                    _originalProperty?.ownerId != null &&
                    _selectedOwner!.id != _originalProperty!.ownerId
              },
              {
                'label': 'التقييم',
                'value': '$_starRating نجوم',
                'changed': _starRating != _originalProperty?.starRating
              },
              {
                'label': 'العملة',
                'value': _currency,
                'changed': _currency != _originalProperty?.currency
              },
              {
                'label': 'مميز',
                'value': _isFeatured ? 'نعم' : 'لا',
                'changed': _isFeatured != _originalProperty?.isFeatured
              },
            ],
          ),

          const SizedBox(height: 16),

          _buildReviewCard(
            title: 'الموقع',
            items: [
              {
                'label': 'العنوان',
                'value': _addressController.text,
                'changed': _addressController.text != _originalProperty?.address
              },
              {
                'label': 'المدينة',
                'value': _cityController.text,
                'changed': _cityController.text != _originalProperty?.city
              },
              {
                'label': 'خط العرض',
                'value': _latitudeController.text,
                'changed': double.tryParse(_latitudeController.text) !=
                    _originalProperty?.latitude
              },
              {
                'label': 'خط الطول',
                'value': _longitudeController.text,
                'changed': double.tryParse(_longitudeController.text) !=
                    _originalProperty?.longitude
              },
            ],
          ),

          const SizedBox(height: 16),

          _buildReviewCard(
            title: 'الصور والمرافق',
            items: [
              {
                'label': 'عدد الصور',
                'value': '${_selectedImages.length} صورة',
                'changed': _imagesChanged
              },
              {
                'label': 'عدد المرافق',
                'value': '${_selectedAmenities.length}',
                'changed':
                    !_areListsEqual(_selectedAmenities, _originalAmenities)
              },
            ],
          ),

          const SizedBox(height: 16),

          _buildReviewCard(
            title: 'الوصف',
            items: [
              {
                'label': 'الوصف المختصر',
                'value': _shortDescriptionController.text.isEmpty
                    ? 'لا يوجد'
                    : _shortDescriptionController.text,
                'changed': _shortDescriptionController.text !=
                    (_originalProperty?.shortDescription ?? '')
              },
              {
                'label': 'الوصف التفصيلي',
                'value': _descriptionController.text,
                'changed': _descriptionController.text !=
                    _originalProperty?.description
              },
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOriginalValueIndicator(
      String label, String value, bool isChanged) {
    if (!isChanged) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.warning.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 14,
            color: AppTheme.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.warning.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkCard.withOpacity(0.3),
                AppTheme.darkCard.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.darkBorder.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: AppTheme.textMuted.withOpacity(0.5),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
              Icon(
                Icons.lock_outline_rounded,
                color: AppTheme.textMuted.withOpacity(0.3),
                size: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChangesSummary() {
    final changes = _getChangedFields();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.warning.withOpacity(0.1),
            AppTheme.warning.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.warning.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.track_changes_rounded,
                color: AppTheme.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'ملخص التغييرات (${changes.length})',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.warning,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...changes.map((change) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            change['field']!,
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.textWhite,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'من: ${change['oldValue']}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppTheme.textMuted,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 12,
                                color: AppTheme.warning,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'إلى: ${change['newValue']}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppTheme.success,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
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

  Widget _buildOwnerSelector() {
    final hasChanged = _selectedOwner != null &&
        _originalProperty?.ownerId != null &&
        _selectedOwner!.id != _originalProperty!.ownerId;

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
                _hasChanges = _checkForChanges();
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: hasChanged
                    ? [
                        AppTheme.warning.withOpacity(0.1),
                        AppTheme.warning.withOpacity(0.05),
                      ]
                    : [
                        AppTheme.darkCard.withOpacity(0.5),
                        AppTheme.darkCard.withOpacity(0.3),
                      ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasChanged
                    ? AppTheme.warning.withOpacity(0.3)
                    : AppTheme.darkBorder.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person_search_rounded,
                  color: hasChanged
                      ? AppTheme.warning
                      : AppTheme.primaryBlue.withOpacity(0.7),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedOwner?.name ??
                            (_originalProperty?.ownerName ??
                                'اختر مالك العقار'),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: (_selectedOwner == null &&
                                  (_originalProperty?.ownerName == null ||
                                      _originalProperty!.ownerName.isEmpty))
                              ? AppTheme.textMuted.withOpacity(0.5)
                              : AppTheme.textWhite,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (hasChanged) ...[
                        const SizedBox(height: 4),
                        Text(
                          'الأصل: ${_originalProperty!.ownerName}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ],
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
    final hasChanged = _starRating != _originalProperty?.starRating;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'تقييم النجوم',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (hasChanged) ...[
              const SizedBox(width: 8),
              Text(
                'الأصل: ${_originalProperty?.starRating ?? 0}',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            final isSelected = index < _starRating;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _starRating = index + 1;
                  _hasChanges = _checkForChanges();
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
                        ? (hasChanged ? AppTheme.warning : AppTheme.warning)
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
    final hasChanged = _isFeatured != _originalProperty?.isFeatured;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasChanged
              ? [
                  AppTheme.warning.withOpacity(0.1),
                  AppTheme.warning.withOpacity(0.05),
                ]
              : [
                  AppTheme.darkCard.withOpacity(0.3),
                  AppTheme.darkCard.withOpacity(0.2),
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasChanged
              ? AppTheme.warning.withOpacity(0.3)
              : _isFeatured
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'عقار مميز',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppTheme.textWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (hasChanged) ...[
                    const SizedBox(height: 2),
                    Text(
                      'الأصل: ${_originalProperty?.isFeatured == true ? 'نعم' : 'لا'}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          Switch(
            value: _isFeatured,
            onChanged: (value) {
              setState(() {
                _isFeatured = value;
                _hasChanges = _checkForChanges();
              });
            },
            activeThumbColor: AppTheme.warning,
            inactiveThumbColor: AppTheme.textMuted,
            inactiveTrackColor: AppTheme.darkBorder.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard({
    required String title,
    required List<Map<String, dynamic>> items,
  }) {
    final hasChanges = items.any((item) => item['changed'] == true);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasChanges
              ? [
                  AppTheme.warning.withOpacity(0.05),
                  AppTheme.darkCard.withOpacity(0.4),
                ]
              : [
                  AppTheme.darkCard.withOpacity(0.5),
                  AppTheme.darkCard.withOpacity(0.3),
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasChanges
              ? AppTheme.warning.withOpacity(0.3)
              : AppTheme.darkBorder.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: hasChanges ? AppTheme.warning : AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (hasChanges) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'معدّل',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.warning,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (item['changed'] == true)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Text(
                          item['label']!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: item['changed'] == true
                                ? AppTheme.warning
                                : AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Text(
                        item['value']!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: item['changed'] == true
                              ? AppTheme.textWhite
                              : AppTheme.textWhite,
                          fontWeight: item['changed'] == true
                              ? FontWeight.w600
                              : FontWeight.w600,
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
                  gradient: _hasChanges
                      ? LinearGradient(colors: [
                          AppTheme.warning,
                          AppTheme.warning.withOpacity(0.8)
                        ])
                      : AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _hasChanges
                          ? AppTheme.warning.withOpacity(0.3)
                          : AppTheme.primaryBlue.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: BlocBuilder<PropertiesBloc, PropertiesState>(
                    builder: (context, state) {
                      if (state is PropertyUpdating) {
                        return const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        );
                      }
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_currentStep == 3 && _hasChanges)
                            const Icon(
                              Icons.save_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          if (_currentStep == 3 && _hasChanges)
                            const SizedBox(width: 8),
                          Text(
                            _currentStep < 3
                                ? 'التالي'
                                : _hasChanges
                                    ? 'حفظ التغييرات'
                                    : 'لا توجد تغييرات',
                            style: AppTextStyles.buttonMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.error.withOpacity(0.2),
                    AppTheme.error.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_rounded,
                size: 48,
                color: AppTheme.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'خطأ في تحميل البيانات',
              style: AppTextStyles.heading2.copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: () {
                context.read<PropertiesBloc>().add(
                      LoadPropertyDetailsEvent(propertyId: widget.propertyId),
                    );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'إعادة المحاولة',
                  style: AppTextStyles.buttonMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdatingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
          ),
          const SizedBox(height: 16),
          Text(
            'جاري حفظ التغييرات...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  bool _checkForChanges() {
    if (_originalProperty == null) return false;

    // التحقق من الحقول الأساسية
    final basicFieldsChanged =
        _nameController.text != _originalProperty!.name ||
            _descriptionController.text != _originalProperty!.description ||
            _shortDescriptionController.text !=
                (_originalProperty!.shortDescription ?? '') ||
            _addressController.text != _originalProperty!.address ||
            _cityController.text != _originalProperty!.city ||
            double.tryParse(_latitudeController.text) !=
                _originalProperty!.latitude ||
            double.tryParse(_longitudeController.text) !=
                _originalProperty!.longitude ||
            _starRating != _originalProperty!.starRating ||
            _isFeatured != _originalProperty!.isFeatured ||
            _currency != _originalProperty!.currency ||
            (_selectedOwner != null &&
                _selectedOwner!.id != _originalProperty!.ownerId);

    // التحقق من تغييرات الصور
    final imagesChanged = _imagesChanged ||
        !_areImagesEqual(
            _selectedImages.map((e) => e.url).toList(), _originalImageUrls);

    // التحقق من تغييرات المرافق
    final amenitiesChanged =
        !_areListsEqual(_selectedAmenities, _originalAmenities);

    return basicFieldsChanged || imagesChanged || amenitiesChanged;
  }

  bool _hasChangesInStep(int step) {
    if (_originalProperty == null) return false;

    switch (step) {
      case 0: // Basic Info
        return _nameController.text != _originalProperty!.name ||
            _descriptionController.text != _originalProperty!.description ||
            _shortDescriptionController.text !=
                (_originalProperty!.shortDescription ?? '') ||
            _starRating != _originalProperty!.starRating ||
            _isFeatured != _originalProperty!.isFeatured ||
            _currency != _originalProperty!.currency ||
            (_selectedOwner != null &&
                _selectedOwner!.id != _originalProperty!.ownerId);
      case 1: // Location
        return _addressController.text != _originalProperty!.address ||
            _cityController.text != _originalProperty!.city ||
            double.tryParse(_latitudeController.text) !=
                _originalProperty!.latitude ||
            double.tryParse(_longitudeController.text) !=
                _originalProperty!.longitude;
      case 2: // Images & Amenities
        return _imagesChanged ||
            !_areListsEqual(_selectedAmenities, _originalAmenities);
      default:
        return false;
    }
  }

  List<Map<String, String>> _getChangedFields() {
    final changes = <Map<String, String>>[];
    if (_originalProperty == null) return changes;

    if (_nameController.text != _originalProperty!.name) {
      changes.add({
        'field': 'اسم العقار',
        'oldValue': _originalProperty!.name,
        'newValue': _nameController.text,
      });
    }

    if (_selectedOwner != null &&
        _selectedOwner!.id != _originalProperty!.ownerId) {
      changes.add({
        'field': 'المالك',
        'oldValue': _originalProperty!.ownerName.isEmpty
            ? 'غير محدد'
            : _originalProperty!.ownerName,
        'newValue': _selectedOwner!.name,
      });
    }

    if (_descriptionController.text != _originalProperty!.description) {
      changes.add({
        'field': 'الوصف',
        'oldValue': _originalProperty!.description.isEmpty
            ? 'لا يوجد'
            : _originalProperty!.description,
        'newValue': _descriptionController.text,
      });
    }

    if (_shortDescriptionController.text !=
        (_originalProperty!.shortDescription ?? '')) {
      changes.add({
        'field': 'الوصف المختصر',
        'oldValue': _originalProperty!.shortDescription?.isEmpty ?? true
            ? 'لا يوجد'
            : _originalProperty!.shortDescription!,
        'newValue': _shortDescriptionController.text.isEmpty
            ? 'لا يوجد'
            : _shortDescriptionController.text,
      });
    }

    if (_starRating != _originalProperty!.starRating) {
      changes.add({
        'field': 'التقييم',
        'oldValue': '${_originalProperty!.starRating} نجوم',
        'newValue': '$_starRating نجوم',
      });
    }

    if (_isFeatured != _originalProperty!.isFeatured) {
      changes.add({
        'field': 'عقار مميز',
        'oldValue': _originalProperty!.isFeatured ? 'نعم' : 'لا',
        'newValue': _isFeatured ? 'نعم' : 'لا',
      });
    }

    if (_currency != _originalProperty!.currency) {
      changes.add({
        'field': 'العملة',
        'oldValue': _originalProperty!.currency,
        'newValue': _currency,
      });
    }

    if (_addressController.text != _originalProperty!.address) {
      changes.add({
        'field': 'العنوان',
        'oldValue': _originalProperty!.address,
        'newValue': _addressController.text,
      });
    }

    if (_cityController.text != _originalProperty!.city) {
      changes.add({
        'field': 'المدينة',
        'oldValue': _originalProperty!.city.isEmpty
            ? 'غير محدد'
            : _originalProperty!.city,
        'newValue':
            _cityController.text.isEmpty ? 'غير محدد' : _cityController.text,
      });
    }

    if (double.tryParse(_latitudeController.text) !=
        _originalProperty!.latitude) {
      changes.add({
        'field': 'خط العرض',
        'oldValue': _originalProperty!.latitude?.toString() ?? 'غير محدد',
        'newValue': _latitudeController.text,
      });
    }

    if (double.tryParse(_longitudeController.text) !=
        _originalProperty!.longitude) {
      changes.add({
        'field': 'خط الطول',
        'oldValue': _originalProperty!.longitude?.toString() ?? 'غير محدد',
        'newValue': _longitudeController.text,
      });
    }

    if (_imagesChanged) {
      changes.add({
        'field': 'الصور',
        'oldValue': '${_originalImageUrls.length} صورة',
        'newValue': '${_selectedImages.length} صورة',
      });
    }

    if (!_areListsEqual(_selectedAmenities, _originalAmenities)) {
      changes.add({
        'field': 'المرافق',
        'oldValue': '${_originalAmenities.length} مرفق',
        'newValue': '${_selectedAmenities.length} مرفق',
      });
    }

    return changes;
  }

  void _resetChanges() {
    if (_originalProperty == null) return;

    showDialog(
      context: context,
      builder: (context) => _ResetConfirmationDialog(
        onConfirm: () {
          Navigator.pop(context);

          // إعادة تعيين جميع القيم
          setState(() {
            _nameController.text = _originalProperty!.name;
            _shortDescriptionController.text =
                _originalProperty!.shortDescription ?? '';
            _addressController.text = _originalProperty!.address;
            _cityController.text = _originalProperty!.city;
            _selectedCity = _originalProperty!.city.isNotEmpty
                ? _originalProperty!.city
                : null;
            _descriptionController.text = _originalProperty!.description;
            _latitudeController.text =
                _originalProperty!.latitude?.toString() ?? '';
            _longitudeController.text =
                _originalProperty!.longitude?.toString() ?? '';
            _selectedPropertyTypeId = _originalProperty!.typeId;
            // Reset selection; original owner shown from property fields
            _selectedOwner = null;
            _starRating = _originalProperty!.starRating;
            _isFeatured = _originalProperty!.isFeatured;
            _currency = _originalProperty!.currency;
            _selectedImages = _originalProperty!.images;
            _imagesChanged = false;
            _selectedAmenities = List<String>.from(_originalAmenities);

            _hasChanges = false;
          });

          _showSuccessMessage('تم استرجاع البيانات الأصلية');
        },
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _UnsavedChangesDialog(),
    );

    return result ?? false;
  }

  void _handleBack() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      if (_hasChanges) {
        _onWillPop().then((canPop) {
          if (canPop) {
            context.pop();
          }
        });
      } else {
        context.pop();
      }
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
      bool isValid = true;

      if (_currentStep == 0) {
        isValid = _validateBasicInfo();
      } else if (_currentStep == 1) {
        isValid = _validateLocation();
      }

      if (isValid) {
        setState(() {
          _currentStep++;
        });
      }
    }
  }

  bool _validateBasicInfo() {
    if (_nameController.text.isEmpty || _descriptionController.text.isEmpty) {
      _showErrorMessage('الرجاء ملء جميع الحقول المطلوبة');
      return false;
    }
    return true;
  }

  bool _validateLocation() {
    if (_addressController.text.isEmpty ||
        _latitudeController.text.isEmpty ||
        _longitudeController.text.isEmpty) {
      _showErrorMessage('الرجاء ملء جميع الحقول المطلوبة');
      return false;
    }

    final lat = double.tryParse(_latitudeController.text);
    final lng = double.tryParse(_longitudeController.text);

    if (lat == null || lat < -90 || lat > 90) {
      _showErrorMessage('خط العرض غير صحيح');
      return false;
    }

    if (lng == null || lng < -180 || lng > 180) {
      _showErrorMessage('خط الطول غير صحيح');
      return false;
    }

    return true;
  }

  void _submitForm() {
    if (!_hasChanges) {
      _showInfoMessage('لا توجد تغييرات للحفظ');
      return;
    }

    if (_formKey.currentState!.validate()) {
      // استخراج URLs من PropertyImage objects
      final List<String> imageUrls =
          _selectedImages.map((img) => img.url).toList();

      context.read<PropertiesBloc>().add(
            UpdatePropertyEvent(
              propertyId: widget.propertyId,
              name: _nameController.text,
              address: _addressController.text,
              city: _cityController.text.isEmpty ? null : _cityController.text,
              description: _descriptionController.text,
              latitude: double.tryParse(_latitudeController.text),
              longitude: double.tryParse(_longitudeController.text),
              starRating: _starRating,
              images: imageUrls,
              shortDescription: _shortDescriptionController.text.isNotEmpty
                  ? _shortDescriptionController.text
                  : null,
              currency: _currency,
              isFeatured: _isFeatured,
              ownerId: _selectedOwner?.id,
              amenityIds:
                  _selectedAmenities.isEmpty ? null : _selectedAmenities,
            ),
          );
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => _DeleteConfirmationDialog(
        onConfirm: () {
          Navigator.pop(context);
          context.read<PropertiesBloc>().add(
                DeletePropertyEvent(widget.propertyId),
              );
        },
      ),
    );
  }

  // Utility methods
  bool _areImagesEqual(List<String> current, List<String> original) {
    if (current.length != original.length) return false;
    for (var i = 0; i < current.length; i++) {
      if (current[i] != original[i]) return false;
    }
    return true;
  }

  bool _areListsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
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

  void _showInfoMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryBlue,
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
    try {
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

// Additional Dialogs
class _ResetConfirmationDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const _ResetConfirmationDialog({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkCard.withOpacity(0.95),
              AppTheme.darkCard.withOpacity(0.85),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.warning.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.warning.withOpacity(0.2),
                    AppTheme.warning.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.refresh_rounded,
                color: AppTheme.warning,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'استرجاع البيانات الأصلية',
              style: AppTextStyles.heading3.copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'سيتم التراجع عن جميع التغييرات\nواسترجاع البيانات الأصلية',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.darkSurface.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.darkBorder.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
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
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      onConfirm();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.warning,
                            AppTheme.warning.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'استرجاع',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UnsavedChangesDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkCard.withOpacity(0.95),
              AppTheme.darkCard.withOpacity(0.85),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.error.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.error.withOpacity(0.2),
                    AppTheme.error.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_rounded,
                color: AppTheme.error,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'تغييرات غير محفوظة',
              style: AppTextStyles.heading3.copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'لديك تغييرات غير محفوظة.\nهل تريد الخروج بدون حفظ؟',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'البقاء',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context, true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.error.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'خروج بدون حفظ',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: AppTheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteConfirmationDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const _DeleteConfirmationDialog({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkCard.withOpacity(0.95),
                AppTheme.darkCard.withOpacity(0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.error.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.error.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.error.withOpacity(0.2),
                      AppTheme.error.withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_forever_rounded,
                  size: 48,
                  color: AppTheme.error,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'تأكيد الحذف',
                style: AppTextStyles.heading2.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'هل أنت متأكد من حذف هذا العقار؟',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'لا يمكن التراجع عن هذا الإجراء',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.error.withOpacity(0.8),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
                            'إلغاء',
                            style: AppTextStyles.buttonMedium.copyWith(
                              color: AppTheme.textLight,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: onConfirm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.error,
                              AppTheme.error.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.error.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'حذف',
                            style: AppTextStyles.buttonMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Background Painter for Edit Mode
class _EditPropertyBackgroundPainter extends CustomPainter {
  final double glowIntensity;

  _EditPropertyBackgroundPainter({required this.glowIntensity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw glowing orbs with edit theme
    paint.shader = RadialGradient(
      colors: [
        AppTheme.warning.withOpacity(0.1 * glowIntensity),
        AppTheme.warning.withOpacity(0.05 * glowIntensity),
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

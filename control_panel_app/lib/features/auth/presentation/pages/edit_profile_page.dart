// lib/features/auth/presentation/pages/edit_profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/user.dart' as domain;
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../../features/admin_properties/domain/usecases/properties/get_property_details_public_usecase.dart'
    as ap_uc_prop_public_details;
import '../../../../features/admin_properties/domain/usecases/properties/owner_update_property_usecase.dart'
    as ap_uc_prop_owner_update;
import '../../../../features/admin_properties/domain/usecases/properties/get_property_details_usecase.dart'
    as ap_uc_prop_details;
import '../widgets/upload_user_image.dart';
import '../../../../features/admin_properties/presentation/widgets/property_image_gallery.dart';
import '../../../../features/admin_properties/presentation/widgets/amenity_selector_widget.dart';
import '../../../../features/admin_properties/presentation/widgets/property_map_view.dart';
import '../../../../features/admin_properties/presentation/bloc/amenities/amenities_bloc.dart';
import '../../../../features/admin_properties/presentation/bloc/property_images/property_images_bloc.dart';
import '../../../../features/admin_properties/domain/entities/property_image.dart';
import '../../../../features/admin_properties/domain/entities/property.dart'
    as prop_entity;
import '../../../../features/admin_currencies/domain/usecases/get_currencies_usecase.dart';
import '../../../../features/admin_cities/domain/usecases/get_cities_usecase.dart'
    as ci_uc;
import '../../../../core/usecases/usecase.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage>
    with TickerProviderStateMixin {
  // Form Keys
  final _formKey = GlobalKey<FormState>();

  // User Profile Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  // Owner Property Controllers - Basic Info
  final _propNameController = TextEditingController();
  final _propAddressController = TextEditingController();
  final _propCityController = TextEditingController();

  // Location Details
  final _propLatitudeController = TextEditingController();
  final _propLongitudeController = TextEditingController();

  // Property Details
  final _propShortDescController = TextEditingController();
  final _propDescController = TextEditingController();

  // Focus Nodes
  final _nameFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();

  // Animation Controllers
  late AnimationController _animationController;
  late AnimationController _glowController;
  late AnimationController _loadingAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _loadingRotation;

  // State Management
  domain.User? _originalUser;
  prop_entity.Property? _originalProperty;
  bool _isDataLoaded = false;
  bool _hasChanges = false;
  int _currentStep = 0;
  bool _saving = false;
  String? _ownerPropertyId;
  bool _isOwner = false;

  // Property specific state
  String _currency = 'YER';
  String? _selectedCity;
  int _starRating = 3;
  bool _isFeatured = false;
  List<PropertyImage> _selectedImages = [];
  List<String> _originalImageUrls = [];
  bool _imagesChanged = false;
  List<String> _selectedAmenities = [];
  List<String> _originalAmenities = [];
  String? _currentImageUrl;
  String? _originalImageUrl;
  Map<String, dynamic> _initialPropertySnapshot = {};
  bool _isPropertyDataLoaded = false;

  final GlobalKey<PropertyImageGalleryState> _galleryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
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

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  void _loadUserData() {
    final state = context.read<AuthBloc>().state;
    domain.User? user;

    if (state is AuthAuthenticated) user = state.user;
    if (state is AuthLoginSuccess) user = state.user;
    if (state is AuthProfileUpdateSuccess) user = state.user;
    if (state is AuthProfileImageUploadSuccess) user = state.user;

    print('📱 Loading user data...');
    print('   Is Owner: ${user?.isOwner}');
    print('   Property ID: ${user?.propertyId}');

    if (user != null) {
      setState(() {
        _originalUser = user;
        _originalImageUrl = user?.profileImage;

        _nameController.text = user?.name ?? '';
        _phoneController.text = user?.phone ?? '';
        _emailController.text = user?.email ?? '';
        _currentImageUrl = user?.profileImage;
        _isOwner = user?.isOwner ?? false;
        _ownerPropertyId = user?.propertyId;
        // Only mark as loaded if not owner, or if owner but no property
        if (!_isOwner || _ownerPropertyId == null) {
          _isDataLoaded = true;
        }
      });

      if (_isOwner && _ownerPropertyId != null) {
        print('🏢 Fetching property details for ID: $_ownerPropertyId');
        _fetchOwnerPropertyDetails(_ownerPropertyId!);
      } else {
        print('ℹ️ Not an owner or no property ID - skipping property fetch');
      }
    }
  }

  Future<void> _fetchOwnerPropertyDetails(String propertyId) async {
    try {
      // Try internal details endpoint first (more complete), then fallback to public
      final getInternal = di.sl<ap_uc_prop_details.GetPropertyDetailsUseCase>();
      final internalRes = await getInternal(
        ap_uc_prop_details.GetPropertyDetailsParams(
          propertyId: propertyId,
          includeUnits: false,
        ),
      );

      prop_entity.Property? loadedProperty;
      internalRes.fold(
        (failure) => loadedProperty = null,
        (prop) => loadedProperty = prop,
      );

      if (loadedProperty == null) {
        print(
            'ℹ️ Internal details failed or not available. Falling back to public details...');
        final getPublic =
            di.sl<ap_uc_prop_public_details.GetPropertyDetailsPublicUseCase>();
        final result = await getPublic(
          ap_uc_prop_public_details.GetPropertyDetailsPublicParams(
            propertyId: propertyId,
            includeUnits: false,
          ),
        );

        result.fold(
          (failure) {
            // On error, still mark as loaded so user can see their profile
            print('❌ Error loading property data (public): $failure');
            if (mounted) {
              setState(() {
                _isDataLoaded = true;
              });
            }
            return;
          },
          (prop) {
            loadedProperty = prop;
          },
        );
      }

      final property = loadedProperty;
      if (property == null) return;

      // Debug: Log property data loading
      print('✅ Property data loaded successfully:');
      print('   Name: ${property.name}');
      print('   Address: ${property.address}');
      print('   City: ${property.city}');
      print(
          '   Description: ${property.description.substring(0, property.description.length > 50 ? 50 : property.description.length)}...');

      if (mounted) {
        setState(() {
          _originalProperty = property;
          _propNameController.text = property.name;
          _propAddressController.text = property.address;
          _propCityController.text = property.city;
          _selectedCity = property.city.isNotEmpty ? property.city : null;
          _propShortDescController.text = property.shortDescription ?? '';
          _propDescController.text = property.description;
          _propLatitudeController.text = property.latitude?.toString() ?? '';
          _propLongitudeController.text = property.longitude?.toString() ?? '';
          _currency = property.currency;
          _starRating = property.starRating;
          _isFeatured = property.isFeatured;
          _selectedImages = List<PropertyImage>.from(property.images);
          _originalImageUrls = property.images.map((e) => e.url).toList();
          _selectedAmenities = property.amenities.map((a) => a.id).toList();
          _originalAmenities = List<String>.from(_selectedAmenities);
          _imagesChanged = false;
          _isPropertyDataLoaded = true;
          _isDataLoaded = true; // Mark as fully loaded now
        });

        print('✅ Controllers updated:');
        print('   Name controller: ${_propNameController.text}');
        print('   Address controller: ${_propAddressController.text}');
        print('   City controller: ${_propCityController.text}');

        // Set the initial snapshot AFTER setState completes to ensure all values are set
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _initialPropertySnapshot = _buildCurrentPropertySnapshot();
            });
            print('📸 Initial property snapshot created');
            print(
                '   Snapshot keys: ${_initialPropertySnapshot.keys.toList()}');
          }
        });
      }

      if (property.typeId.isNotEmpty) {
        context.read<AmenitiesBloc>().add(
              LoadAmenitiesEventWithType(
                propertyTypeId: property.typeId,
                pageSize: 100,
              ),
            );
      }
    } catch (e) {
      // Handle error and still mark as loaded
      if (mounted) {
        setState(() {
          _isDataLoaded = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _glowController.dispose();
    _loadingAnimationController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _propNameController.dispose();
    _propAddressController.dispose();
    _propCityController.dispose();
    _propShortDescController.dispose();
    _propDescController.dispose();
    _propLatitudeController.dispose();
    _propLongitudeController.dispose();
    _nameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  List<String> get _stepTitles {
    if (_isOwner) {
      return [
        'البيانات الشخصية',
        'معلومات العقار الأساسية',
        'الموقع والتفاصيل',
        'الصور والمرافق',
        'المراجعة النهائية'
      ];
    } else {
      return ['البيانات الشخصية', 'المراجعة النهائية'];
    }
  }

  int get _totalSteps => _stepTitles.length;

  @override
  Widget build(BuildContext context) {
    Widget mainWidget = WillPopScope(
      onWillPop: _onWillPop,
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthProfileUpdateSuccess) {
            _showSuccessMessage('تم تحديث الملف الشخصي بنجاح');
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                context.pop(true);
              }
            });
          } else if (state is AuthProfileImageUploadSuccess) {
            setState(() {
              _currentImageUrl = state.user.profileImage;
            });
            _showSuccessMessage('تم تحديث الصورة الشخصية بنجاح');
          } else if (state is AuthError) {
            _showErrorMessage(state.message);
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading || _saving;

          return Scaffold(
            backgroundColor: AppTheme.darkBackground,
            body: Stack(
              children: [
                _buildAnimatedBackground(),
                SafeArea(
                  child: !_isDataLoaded
                      ? _buildLoadingState()
                      : Column(
                          children: [
                            _buildHeader(),
                            _buildProgressIndicator(),
                            Expanded(
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: SlideTransition(
                                  position: _slideAnimation,
                                  child: _buildFormContent(isLoading),
                                ),
                              ),
                            ),
                            _buildActionButtons(isLoading),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (_isOwner && _ownerPropertyId != null) {
      return MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => di.sl<AmenitiesBloc>(),
          ),
          BlocProvider(
            create: (_) => di.sl<PropertyImagesBloc>(),
          ),
        ],
        child: mainWidget,
      );
    }

    return mainWidget;
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
            painter: _EditProfileBackgroundPainter(
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
                          Icons.person_rounded,
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
              'جاري تحميل البيانات...',
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
                        'تعديل الملف الشخصي',
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
                  _stepTitles[_currentStep],
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
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
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;
          final isModified = _hasChangesInStep(index);

          return Expanded(
            child: Row(
              children: [
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
                if (index < _totalSteps - 1)
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

  Widget _buildFormContent(bool isLoading) {
    return Form(
      key: _formKey,
      onChanged: () {
        setState(() {
          _hasChanges = _checkForChanges();
        });
      },
      child: IndexedStack(
        index: _currentStep,
        children: _isOwner
            ? [
                _buildUserInfoStep(isLoading),
                _buildPropertyBasicInfoStep(isLoading),
                _buildPropertyLocationDetailsStep(isLoading),
                _buildPropertyImagesAmenitiesStep(isLoading),
                _buildReviewStep(isLoading),
              ]
            : [
                _buildUserInfoStep(isLoading),
                _buildReviewStep(isLoading),
              ],
      ),
    );
  }

  Widget _buildUserInfoStep(bool isLoading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    return Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            AppTheme.primaryBlue.withOpacity(
                              0.08 + (_glowController.value * 0.04),
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),
                UploadUserImage(
                  currentImageUrl: _currentImageUrl,
                  onImageSelected: (imagePath) {
                    setState(() {
                      if (imagePath.isNotEmpty) {
                        _currentImageUrl = imagePath;
                      } else {
                        _currentImageUrl = null;
                      }
                      _hasChanges = _checkForChanges();
                    });
                    if (imagePath.isNotEmpty) {
                      context.read<AuthBloc>().add(
                            UploadProfileImageEvent(imagePath: imagePath),
                          );
                    }
                  },
                  size: 90,
                ),
              ],
            ),
          ),
          if (_currentImageUrl != _originalImageUrl) ...[
            const SizedBox(height: 8),
            _buildOriginalValueIndicator(
              'الصورة الشخصية',
              _originalImageUrl != null ? 'موجودة' : 'غير موجودة',
              true,
            ),
          ],
          const SizedBox(height: 30),
          if (_originalUser != null &&
              _nameController.text.trim() != _originalUser!.name.trim())
            _buildOriginalValueIndicator(
              'الاسم الأصلي',
              _originalUser!.name,
              true,
            ),
          _buildInputField(
            controller: _nameController,
            label: 'الاسم الكامل',
            hint: 'أدخل اسمك الكامل',
            icon: Icons.person_rounded,
            focusNode: _nameFocusNode,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'الرجاء إدخال الاسم';
              }
              if (value.trim().length < 2) {
                return 'الاسم يجب أن يكون حرفين على الأقل';
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
          if (_originalUser != null &&
              _emailController.text.trim() != _originalUser!.email.trim())
            _buildOriginalValueIndicator(
              'البريد الإلكتروني الأصلي',
              _originalUser!.email.isEmpty ? 'غير محدد' : _originalUser!.email,
              true,
            ),
          _buildInputField(
            controller: _emailController,
            label: 'البريد الإلكتروني',
            hint: 'example@email.com',
            icon: Icons.email_rounded,
            focusNode: _emailFocusNode,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value.trim())) {
                  return 'البريد الإلكتروني غير صحيح';
                }
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
          if (_originalUser != null &&
              _phoneController.text.trim() != _originalUser!.phone.trim())
            _buildOriginalValueIndicator(
              'رقم الهاتف الأصلي',
              _originalUser!.phone.isEmpty ? 'غير محدد' : _originalUser!.phone,
              true,
            ),
          _buildInputField(
            controller: _phoneController,
            label: 'رقم الهاتف',
            hint: '+967 XXX XXX XXX',
            icon: Icons.phone_rounded,
            focusNode: _phoneFocusNode,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                if (value.trim().length < 9) {
                  return 'رقم الهاتف غير صحيح';
                }
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

  Widget _buildPropertyBasicInfoStep(bool isLoading) {
    if (!_isOwner || _ownerPropertyId == null) {
      return Center(
        child: Text(
          'لا توجد بيانات عقار',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'المعلومات الأساسية للعقار',
            style: AppTextStyles.heading3.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Property Name
          if (_originalProperty != null &&
              _propNameController.text.trim() != _originalProperty!.name.trim())
            _buildOriginalValueIndicator(
              'اسم العقار الأصلي',
              _originalProperty!.name,
              true,
            ),

          _buildInputField(
            controller: _propNameController,
            label: 'اسم العقار',
            hint: 'أدخل اسم العقار',
            icon: Icons.business_rounded,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
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

          // Address
          if (_originalProperty != null &&
              _propAddressController.text.trim() !=
                  _originalProperty!.address.trim())
            _buildOriginalValueIndicator(
              'العنوان الأصلي',
              _originalProperty!.address,
              true,
            ),

          _buildInputField(
            controller: _propAddressController,
            label: 'العنوان',
            hint: 'أدخل العنوان الكامل',
            icon: Icons.location_on_rounded,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
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
          if (_originalProperty != null &&
              _selectedCity != _originalProperty!.city)
            _buildOriginalValueIndicator(
              'المدينة الأصلية',
              _originalProperty!.city.isEmpty
                  ? 'غير محدد'
                  : _originalProperty!.city,
              true,
            ),

          _CityDropdown(
            value: _selectedCity,
            onChanged: (v) {
              setState(() {
                _selectedCity = v;
                _propCityController.text = v ?? '';
                _hasChanges = _checkForChanges();
              });
            },
            requiredField: true,
          ),

          const SizedBox(height: 20),

          // Currency & Star Rating
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_originalProperty != null &&
                        _currency != _originalProperty!.currency)
                      _buildOriginalValueIndicator(
                        'العملة',
                        _originalProperty!.currency,
                        true,
                      ),
                    _CurrencyDropdown(
                      value: _currency,
                      onChanged: (v) => setState(() {
                        _currency = v;
                        _hasChanges = _checkForChanges();
                      }),
                    ),
                  ],
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
        ],
      ),
    );
  }

  Widget _buildPropertyLocationDetailsStep(bool isLoading) {
    if (!_isOwner || _ownerPropertyId == null) {
      return Center(
        child: Text(
          'لا توجد بيانات عقار',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الموقع والتفاصيل',
            style: AppTextStyles.heading3.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

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
                    _propLatitudeController.text = latLng.latitude.toString();
                    _propLongitudeController.text = latLng.longitude.toString();
                    _hasChanges = _checkForChanges();
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Latitude & Longitude
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_originalProperty != null &&
                        _propLatitudeController.text.trim() !=
                            (_originalProperty!.latitude?.toString() ?? ''))
                      _buildOriginalValueIndicator(
                        'خط العرض',
                        _originalProperty!.latitude?.toString() ?? 'غير محدد',
                        true,
                      ),
                    _buildInputField(
                      controller: _propLatitudeController,
                      label: 'خط العرض',
                      hint: 'أدخل خط العرض',
                      icon: Icons.my_location_rounded,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final lat = double.tryParse(value.trim());
                          if (lat == null || lat < -90 || lat > 90) {
                            return 'خط عرض غير صحيح';
                          }
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
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_originalProperty != null &&
                        _propLongitudeController.text.trim() !=
                            (_originalProperty!.longitude?.toString() ?? ''))
                      _buildOriginalValueIndicator(
                        'خط الطول',
                        _originalProperty!.longitude?.toString() ?? 'غير محدد',
                        true,
                      ),
                    _buildInputField(
                      controller: _propLongitudeController,
                      label: 'خط الطول',
                      hint: 'أدخل خط الطول',
                      icon: Icons.my_location_rounded,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final lng = double.tryParse(value.trim());
                          if (lng == null || lng < -180 || lng > 180) {
                            return 'خط طول غير صحيح';
                          }
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
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Short Description
          if (_originalProperty != null &&
              _propShortDescController.text.trim() !=
                  (_originalProperty!.shortDescription?.trim() ?? ''))
            _buildOriginalValueIndicator(
              'الوصف المختصر الأصلي',
              _originalProperty!.shortDescription?.isEmpty ?? true
                  ? 'لا يوجد'
                  : _originalProperty!.shortDescription!,
              true,
            ),

          _buildInputField(
            controller: _propShortDescController,
            label: 'وصف مختصر',
            hint: 'نص مختصر يظهر في القوائم',
            icon: Icons.short_text_rounded,
            maxLines: 2,
            onChanged: (value) {
              setState(() {
                _hasChanges = _checkForChanges();
              });
            },
          ),

          const SizedBox(height: 20),

          // Description
          if (_originalProperty != null &&
              _propDescController.text.trim() !=
                  _originalProperty!.description.trim())
            _buildOriginalValueIndicator(
              'الوصف الأصلي',
              _originalProperty!.description.isEmpty
                  ? 'لا يوجد'
                  : _originalProperty!.description,
              true,
            ),

          _buildInputField(
            controller: _propDescController,
            label: 'الوصف التفصيلي',
            hint: 'أدخل وصف تفصيلي للعقار',
            icon: Icons.description_rounded,
            maxLines: 5,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
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

  Widget _buildPropertyImagesAmenitiesStep(bool isLoading) {
    if (!_isOwner || _ownerPropertyId == null) {
      return Center(
        child: Text(
          'لا توجد بيانات عقار',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property Images
          Text(
            'صور العقار',
            style: AppTextStyles.heading3.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          if (_imagesChanged)
            _buildOriginalValueIndicator(
              'عدد الصور الأصلي',
              '${_originalImageUrls.length} صورة',
              true,
            ),

          PropertyImageGallery(
            key: _galleryKey,
            propertyId: _ownerPropertyId!,
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

          // Amenities
          Text(
            'المرافق المتاحة',
            style: AppTextStyles.heading3.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          if (!_areListsEqual(_selectedAmenities, _originalAmenities))
            _buildOriginalValueIndicator(
              'عدد المرافق الأصلي',
              '${_originalAmenities.length} مرفق',
              true,
            ),

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
                  propertyTypeId: _originalProperty?.typeId,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep(bool isLoading) {
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

          if (_hasChanges) _buildChangesSummary(),

          const SizedBox(height: 20),

          // User Info Review
          _buildReviewCard(
            title: 'المعلومات الشخصية',
            items: [
              {
                'label': 'الاسم',
                'value': _nameController.text.trim(),
                'changed':
                    _nameController.text.trim() != _originalUser?.name.trim()
              },
              {
                'label': 'البريد الإلكتروني',
                'value': _emailController.text.trim().isEmpty
                    ? 'غير محدد'
                    : _emailController.text.trim(),
                'changed':
                    _emailController.text.trim() != _originalUser?.email.trim()
              },
              {
                'label': 'رقم الهاتف',
                'value': _phoneController.text.trim().isEmpty
                    ? 'غير محدد'
                    : _phoneController.text.trim(),
                'changed':
                    _phoneController.text.trim() != _originalUser?.phone.trim()
              },
              {
                'label': 'الصورة الشخصية',
                'value': _currentImageUrl != null ? 'موجودة' : 'غير موجودة',
                'changed': _currentImageUrl != _originalImageUrl
              },
            ],
          ),

          // Property Info Review (if owner)
          if (_isOwner && _originalProperty != null) ...[
            const SizedBox(height: 16),
            _buildReviewCard(
              title: 'معلومات العقار',
              items: [
                {
                  'label': 'اسم العقار',
                  'value': _propNameController.text.trim(),
                  'changed': _propNameController.text.trim() !=
                      _originalProperty!.name.trim()
                },
                {
                  'label': 'العنوان',
                  'value': _propAddressController.text.trim(),
                  'changed': _propAddressController.text.trim() !=
                      _originalProperty!.address.trim()
                },
                {
                  'label': 'المدينة',
                  'value': _propCityController.text.trim().isEmpty
                      ? 'غير محدد'
                      : _propCityController.text.trim(),
                  'changed': _propCityController.text.trim() !=
                      _originalProperty!.city.trim()
                },
                {
                  'label': 'الوصف المختصر',
                  'value': _propShortDescController.text.trim().isEmpty
                      ? 'لا يوجد'
                      : _propShortDescController.text.trim(),
                  'changed': _propShortDescController.text.trim() !=
                      (_originalProperty!.shortDescription?.trim() ?? '')
                },
                {
                  'label': 'الوصف التفصيلي',
                  'value': _propDescController.text.trim().isEmpty
                      ? 'لا يوجد'
                      : 'موجود',
                  'changed': _propDescController.text.trim() !=
                      _originalProperty!.description.trim()
                },
                {
                  'label': 'خط العرض',
                  'value': _propLatitudeController.text.trim().isEmpty
                      ? 'غير محدد'
                      : _propLatitudeController.text.trim(),
                  'changed':
                      double.tryParse(_propLatitudeController.text.trim()) !=
                          _originalProperty!.latitude
                },
                {
                  'label': 'خط الطول',
                  'value': _propLongitudeController.text.trim().isEmpty
                      ? 'غير محدد'
                      : _propLongitudeController.text.trim(),
                  'changed':
                      double.tryParse(_propLongitudeController.text.trim()) !=
                          _originalProperty!.longitude
                },
                {
                  'label': 'التقييم',
                  'value': '$_starRating نجوم',
                  'changed': _starRating != _originalProperty!.starRating
                },
                {
                  'label': 'العملة',
                  'value': _currency,
                  'changed': _currency != _originalProperty!.currency
                },
                {
                  'label': 'مميز',
                  'value': _isFeatured ? 'نعم' : 'لا',
                  'changed': _isFeatured != _originalProperty!.isFeatured
                },
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
          ],
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    FocusNode? focusNode,
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
            focusNode: focusNode,
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

  Widget _buildActionButtons(bool isLoading) {
    final lastStep = _totalSteps - 1;

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
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: GestureDetector(
              onTap: _currentStep < lastStep
                  ? _nextStep
                  : (isLoading ? null : _submitForm),
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
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_currentStep == lastStep && _hasChanges)
                              const Icon(
                                Icons.save_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            if (_currentStep == lastStep && _hasChanges)
                              const SizedBox(width: 8),
                            Text(
                              _currentStep < lastStep
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
  bool _checkForChanges() {
    if (_originalUser == null) return false;

    final userFieldsChanged =
        _nameController.text.trim() != _originalUser!.name.trim() ||
            _emailController.text.trim() != _originalUser!.email.trim() ||
            _phoneController.text.trim() != _originalUser!.phone.trim() ||
            _currentImageUrl != _originalImageUrl;

    final propertyFieldsChanged = _isOwner && _isPropertyDataLoaded
        ? _hasPropertySnapshotDiff(
            _initialPropertySnapshot, _buildCurrentPropertySnapshot())
        : false;

    return userFieldsChanged || propertyFieldsChanged;
  }

  Map<String, dynamic> _buildCurrentPropertySnapshot() {
    return {
      'name': _propNameController.text.trim(),
      'address': _propAddressController.text.trim(),
      'city': _propCityController.text.trim(),
      'shortDescription': _propShortDescController.text.trim(),
      'description': _propDescController.text.trim(),
      'latitude': double.tryParse(_propLatitudeController.text.trim()),
      'longitude': double.tryParse(_propLongitudeController.text.trim()),
      'starRating': _starRating,
      'currency': _currency,
      'isFeatured': _isFeatured,
      'imageUrls': _selectedImages.map((img) => img.url).toList(),
      'amenityIds': List<String>.from(_selectedAmenities),
    };
  }

  Map<String, dynamic> _defaultPropertySnapshot() {
    return {
      'name': '',
      'address': '',
      'city': '',
      'shortDescription': '',
      'description': '',
      'latitude': null,
      'longitude': null,
      'starRating': _starRating,
      'currency': _currency,
      'isFeatured': _isFeatured,
      'imageUrls': <String>[],
      'amenityIds': <String>[],
    };
  }

  bool _hasPropertySnapshotDiff(
    Map<String, dynamic> initial,
    Map<String, dynamic> current,
  ) {
    // If initial snapshot is empty or not yet populated, no changes detected
    if (initial.isEmpty) return false;

    // Compare each field
    if (current['name'] != initial['name']) return true;
    if (current['address'] != initial['address']) return true;
    if (current['city'] != initial['city']) return true;
    if (current['shortDescription'] != initial['shortDescription']) {
      return true;
    }
    if (current['description'] != initial['description']) return true;

    if ((current['latitude'] as double?) != (initial['latitude'] as double?))
      return true;
    if ((current['longitude'] as double?) != (initial['longitude'] as double?))
      return true;

    if ((current['starRating'] as int?) != (initial['starRating'] as int?)) {
      return true;
    }
    if (current['currency'] != initial['currency']) return true;
    if ((current['isFeatured'] as bool?) != (initial['isFeatured'] as bool?))
      return true;

    final initialImages = _stringListFromSnapshot(initial['imageUrls']);
    final currentImages = _stringListFromSnapshot(current['imageUrls']);
    if (!_areImagesEqual(currentImages, initialImages)) return true;

    final initialAmenities = _stringListFromSnapshot(initial['amenityIds']);
    final currentAmenities = _stringListFromSnapshot(current['amenityIds']);
    if (!_areListsEqual(currentAmenities, initialAmenities)) return true;

    return false;
  }

  List<String> _stringListFromSnapshot(dynamic value) {
    if (value is List<String>) {
      return List<String>.from(value);
    }
    if (value is List) {
      return value.map((e) => e?.toString() ?? '').toList();
    }
    return <String>[];
  }

  bool _hasChangesInStep(int step) {
    if (_originalUser == null) return false;

    if (_isOwner) {
      switch (step) {
        case 0: // User Info
          return _nameController.text.trim() != _originalUser!.name.trim() ||
              _emailController.text.trim() != _originalUser!.email.trim() ||
              _phoneController.text.trim() != _originalUser!.phone.trim() ||
              _currentImageUrl != _originalImageUrl;
        case 1: // Property Basic Info
          if (_originalProperty == null) return false;
          return _propNameController.text.trim() !=
                  _originalProperty!.name.trim() ||
              _propAddressController.text.trim() !=
                  _originalProperty!.address.trim() ||
              _propCityController.text.trim() !=
                  _originalProperty!.city.trim() ||
              _starRating != _originalProperty!.starRating ||
              _isFeatured != _originalProperty!.isFeatured ||
              _currency != _originalProperty!.currency;
        case 2: // Location & Details
          if (_originalProperty == null) return false;
          return double.tryParse(_propLatitudeController.text.trim()) !=
                  _originalProperty!.latitude ||
              double.tryParse(_propLongitudeController.text.trim()) !=
                  _originalProperty!.longitude ||
              _propShortDescController.text.trim() !=
                  (_originalProperty!.shortDescription?.trim() ?? '') ||
              _propDescController.text.trim() !=
                  _originalProperty!.description.trim();
        case 3: // Images & Amenities
          if (_originalProperty == null) return false;
          return _imagesChanged ||
              !_areListsEqual(_selectedAmenities, _originalAmenities);
        default:
          return false;
      }
    } else {
      switch (step) {
        case 0: // User Info
          return _nameController.text.trim() != _originalUser!.name.trim() ||
              _emailController.text.trim() != _originalUser!.email.trim() ||
              _phoneController.text.trim() != _originalUser!.phone.trim() ||
              _currentImageUrl != _originalImageUrl;
        default:
          return false;
      }
    }
  }

  List<Map<String, String>> _getChangedFields() {
    final changes = <Map<String, String>>[];
    if (_originalUser == null) return changes;

    if (_nameController.text.trim() != _originalUser!.name.trim()) {
      changes.add({
        'field': 'الاسم',
        'oldValue': _originalUser!.name,
        'newValue': _nameController.text.trim(),
      });
    }

    if (_emailController.text.trim() != _originalUser!.email.trim()) {
      changes.add({
        'field': 'البريد الإلكتروني',
        'oldValue':
            _originalUser!.email.isEmpty ? 'غير محدد' : _originalUser!.email,
        'newValue': _emailController.text.trim().isEmpty
            ? 'غير محدد'
            : _emailController.text.trim(),
      });
    }

    if (_phoneController.text.trim() != _originalUser!.phone.trim()) {
      changes.add({
        'field': 'رقم الهاتف',
        'oldValue':
            _originalUser!.phone.isEmpty ? 'غير محدد' : _originalUser!.phone,
        'newValue': _phoneController.text.trim().isEmpty
            ? 'غير محدد'
            : _phoneController.text.trim(),
      });
    }

    if (_currentImageUrl != _originalImageUrl) {
      changes.add({
        'field': 'الصورة الشخصية',
        'oldValue': _originalImageUrl != null ? 'موجودة' : 'غير موجودة',
        'newValue': _currentImageUrl != null ? 'موجودة' : 'غير موجودة',
      });
    }

    if (_isOwner && _originalProperty != null) {
      if (_propNameController.text.trim() != _originalProperty!.name.trim()) {
        changes.add({
          'field': 'اسم العقار',
          'oldValue': _originalProperty!.name,
          'newValue': _propNameController.text.trim(),
        });
      }

      if (_propAddressController.text.trim() !=
          _originalProperty!.address.trim()) {
        changes.add({
          'field': 'عنوان العقار',
          'oldValue': _originalProperty!.address,
          'newValue': _propAddressController.text.trim(),
        });
      }

      if (_propCityController.text.trim() != _originalProperty!.city.trim()) {
        changes.add({
          'field': 'مدينة العقار',
          'oldValue': _originalProperty!.city.isEmpty
              ? 'غير محدد'
              : _originalProperty!.city,
          'newValue': _propCityController.text.trim().isEmpty
              ? 'غير محدد'
              : _propCityController.text.trim(),
        });
      }

      if (_propShortDescController.text.trim() !=
          (_originalProperty!.shortDescription?.trim() ?? '')) {
        changes.add({
          'field': 'الوصف المختصر للعقار',
          'oldValue': _originalProperty!.shortDescription?.isEmpty ?? true
              ? 'لا يوجد'
              : _originalProperty!.shortDescription!,
          'newValue': _propShortDescController.text.trim().isEmpty
              ? 'لا يوجد'
              : _propShortDescController.text.trim(),
        });
      }

      if (_propDescController.text.trim() !=
          _originalProperty!.description.trim()) {
        changes.add({
          'field': 'وصف العقار',
          'oldValue': _originalProperty!.description.isEmpty
              ? 'لا يوجد'
              : _originalProperty!.description,
          'newValue': _propDescController.text.trim().isEmpty
              ? 'لا يوجد'
              : _propDescController.text.trim(),
        });
      }

      final newLat = double.tryParse(_propLatitudeController.text.trim());
      if (newLat != _originalProperty!.latitude) {
        changes.add({
          'field': 'خط العرض',
          'oldValue': _originalProperty!.latitude?.toString() ?? 'غير محدد',
          'newValue': newLat?.toString() ?? 'غير محدد',
        });
      }

      final newLng = double.tryParse(_propLongitudeController.text.trim());
      if (newLng != _originalProperty!.longitude) {
        changes.add({
          'field': 'خط الطول',
          'oldValue': _originalProperty!.longitude?.toString() ?? 'غير محدد',
          'newValue': newLng?.toString() ?? 'غير محدد',
        });
      }

      if (_starRating != _originalProperty!.starRating) {
        changes.add({
          'field': 'تقييم النجوم',
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

      if (_imagesChanged) {
        changes.add({
          'field': 'صور العقار',
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
    }

    return changes;
  }

  void _resetChanges() {
    if (_originalUser == null) return;

    showDialog(
      context: context,
      builder: (context) => _ResetConfirmationDialog(
        onConfirm: () {
          Navigator.pop(context);

          setState(() {
            _nameController.text = _originalUser!.name;
            _emailController.text = _originalUser!.email;
            _phoneController.text = _originalUser!.phone;
            _currentImageUrl = _originalUser!.profileImage;

            if (_isOwner && _originalProperty != null) {
              _propNameController.text = _originalProperty!.name;
              _propAddressController.text = _originalProperty!.address;
              _propCityController.text = _originalProperty!.city;
              _selectedCity = _originalProperty!.city.isNotEmpty
                  ? _originalProperty!.city
                  : null;
              _propShortDescController.text =
                  _originalProperty!.shortDescription ?? '';
              _propDescController.text = _originalProperty!.description;
              _propLatitudeController.text =
                  _originalProperty!.latitude?.toString() ?? '';
              _propLongitudeController.text =
                  _originalProperty!.longitude?.toString() ?? '';
              _currency = _originalProperty!.currency;
              _starRating = _originalProperty!.starRating;
              _isFeatured = _originalProperty!.isFeatured;
              _selectedImages =
                  List<PropertyImage>.from(_originalProperty!.images);
              _imagesChanged = false;
              _selectedAmenities = List<String>.from(_originalAmenities);
              _isPropertyDataLoaded = true;
            }

            _hasChanges = false;
            _currentStep = 0; // العودة للخطوة الأولى
          });

          // Rebuild property snapshot after reset
          if (_isOwner && _originalProperty != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _initialPropertySnapshot = _buildCurrentPropertySnapshot();
                });
              }
            });
          }

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
    final lastStep = _totalSteps - 1;
    if (_currentStep < lastStep) {
      bool isValid = true;

      if (_isOwner) {
        switch (_currentStep) {
          case 0:
            isValid = _validateUserInfo();
            break;
          case 1:
            isValid = _validatePropertyBasicInfo();
            break;
          case 2:
            isValid = _validatePropertyLocationDetails();
            break;
          case 3:
            // No validation needed for images & amenities
            break;
        }
      } else {
        if (_currentStep == 0) {
          isValid = _validateUserInfo();
        }
      }

      if (isValid) {
        setState(() {
          _currentStep++;
        });
      }
    }
  }

  bool _validateUserInfo() {
    if (_nameController.text.trim().isEmpty) {
      _showErrorMessage('الرجاء إدخال الاسم');
      return false;
    }

    if (_nameController.text.trim().length < 2) {
      _showErrorMessage('الاسم يجب أن يكون حرفين على الأقل');
      return false;
    }

    if (_emailController.text.trim().isNotEmpty) {
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
          .hasMatch(_emailController.text.trim())) {
        _showErrorMessage('البريد الإلكتروني غير صحيح');
        return false;
      }
    }

    if (_phoneController.text.trim().isNotEmpty) {
      if (_phoneController.text.trim().length < 9) {
        _showErrorMessage('رقم الهاتف غير صحيح');
        return false;
      }
    }

    return true;
  }

  bool _validatePropertyBasicInfo() {
    if (!_isOwner || _originalProperty == null) return true;

    if (_propNameController.text.trim().isEmpty) {
      _showErrorMessage('الرجاء إدخال اسم العقار');
      return false;
    }

    if (_propAddressController.text.trim().isEmpty) {
      _showErrorMessage('الرجاء إدخال عنوان العقار');
      return false;
    }

    if (_selectedCity == null || _selectedCity!.isEmpty) {
      _showErrorMessage('الرجاء اختيار المدينة');
      return false;
    }

    return true;
  }

  bool _validatePropertyLocationDetails() {
    if (!_isOwner || _originalProperty == null) return true;

    if (_propLatitudeController.text.trim().isNotEmpty) {
      final lat = double.tryParse(_propLatitudeController.text.trim());
      if (lat == null || lat < -90 || lat > 90) {
        _showErrorMessage('خط العرض غير صحيح');
        return false;
      }
    }

    if (_propLongitudeController.text.trim().isNotEmpty) {
      final lng = double.tryParse(_propLongitudeController.text.trim());
      if (lng == null || lng < -180 || lng > 180) {
        _showErrorMessage('خط الطول غير صحيح');
        return false;
      }
    }

    if (_propDescController.text.trim().isEmpty) {
      _showErrorMessage('الرجاء إدخال وصف العقار');
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
      setState(() => _saving = true);

      // Submit user profile changes
      context.read<AuthBloc>().add(UpdateProfileEvent(
            name: _nameController.text.trim(),
            email: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            propertyId: _isOwner ? _ownerPropertyId : null,
            propertyName: _isOwner && _propNameController.text.trim().isNotEmpty
                ? _propNameController.text.trim()
                : null,
            propertyAddress:
                _isOwner && _propAddressController.text.trim().isNotEmpty
                    ? _propAddressController.text.trim()
                    : null,
            propertyCity: _isOwner && _propCityController.text.trim().isNotEmpty
                ? _propCityController.text.trim()
                : null,
            propertyShortDescription:
                _isOwner && _propShortDescController.text.trim().isNotEmpty
                    ? _propShortDescController.text.trim()
                    : null,
            propertyDescription:
                _isOwner && _propDescController.text.trim().isNotEmpty
                    ? _propDescController.text.trim()
                    : null,
            propertyCurrency:
                _isOwner && _currency.isNotEmpty ? _currency : null,
            propertyStarRating: _isOwner ? _starRating : null,
            propertyLatitude:
                _isOwner && _propLatitudeController.text.trim().isNotEmpty
                    ? double.tryParse(_propLatitudeController.text.trim())
                    : null,
            propertyLongitude:
                _isOwner && _propLongitudeController.text.trim().isNotEmpty
                    ? double.tryParse(_propLongitudeController.text.trim())
                    : null,
          ));

      // Submit property specific changes if owner
      if (_isOwner && _ownerPropertyId != null) {
        _submitPropertyChanges();
      }
    }
  }

  Future<void> _submitPropertyChanges() async {
    if (_ownerPropertyId == null) return;

    try {
      final updateOwner =
          di.sl<ap_uc_prop_owner_update.OwnerUpdatePropertyUseCase>();
      final data = <String, dynamic>{
        'name': _propNameController.text.trim(),
        'address': _propAddressController.text.trim(),
        'city': _propCityController.text.trim(),
        if (_propShortDescController.text.trim().isNotEmpty)
          'shortDescription': _propShortDescController.text.trim(),
        'description': _propDescController.text.trim(),
        if (_propLatitudeController.text.trim().isNotEmpty)
          'latitude': double.tryParse(_propLatitudeController.text.trim()),
        if (_propLongitudeController.text.trim().isNotEmpty)
          'longitude': double.tryParse(_propLongitudeController.text.trim()),
        'starRating': _starRating,
        'currency': _currency,
        'isFeatured': _isFeatured,
        'images': _selectedImages.map((img) => img.url).toList(),
        'amenityIds': _selectedAmenities.isEmpty ? null : _selectedAmenities,
      };

      final result = await updateOwner(
        ap_uc_prop_owner_update.OwnerUpdatePropertyParams(
          propertyId: _ownerPropertyId!,
          data: data,
        ),
      );

      result.fold(
        (failure) {
          setState(() => _saving = false);
          final failureMessage = failure.message.trim().isEmpty
              ? 'فشل تحديث بيانات العقار'
              : failure.message;
          _showErrorMessage(failureMessage);
        },
        (_) {
          // Property update successful
          setState(() => _saving = false);
        },
      );
    } catch (e) {
      setState(() => _saving = false);
      _showErrorMessage('حدث خطأ أثناء تحديث بيانات العقار');
    }
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
    final sortedA = List<String>.from(a)..sort();
    final sortedB = List<String>.from(b)..sort();
    for (var i = 0; i < sortedA.length; i++) {
      if (sortedA[i] != sortedB[i]) return false;
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
          // Ensure current value is available even if API doesn't return it
          if (widget.value.isNotEmpty && !_codes.contains(widget.value)) {
            _codes = [widget.value, ..._codes];
          }
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
      initialValue: _codes.contains(widget.value)
          ? widget.value
          : (_codes.isNotEmpty ? _codes.first : null),
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
  const _CityDropdown({
    required this.value,
    required this.onChanged,
    this.requiredField = false,
  });

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
          // Ensure the current city value appears even if not returned from API
          final v = widget.value;
          if (v != null && v.isNotEmpty && !_cities.contains(v)) {
            _cities = [v, ..._cities];
          }
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
            ? (v) => (v == null || v.isEmpty) ? 'المدينة مطلوبة' : null
            : null,
      );
    }

    return DropdownButtonFormField<String?>(
      initialValue: _cities.contains(widget.value)
          ? widget.value
          : (_cities.isNotEmpty ? _cities.first : null),
      decoration: decoration,
      dropdownColor: AppTheme.darkCard,
      style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textWhite),
      items: items,
      onChanged: (v) => widget.onChanged(v),
      validator: widget.requiredField
          ? (v) => (v == null || v.isEmpty) ? 'المدينة مطلوبة' : null
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

// Custom Background Painter for Edit Profile
class _EditProfileBackgroundPainter extends CustomPainter {
  final double glowIntensity;

  _EditProfileBackgroundPainter({required this.glowIntensity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw glowing orbs with edit theme
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

    // Draw accent lines
    paint.shader = LinearGradient(
      colors: [
        AppTheme.warning.withOpacity(0.05 * glowIntensity),
        Colors.transparent,
      ],
    ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));

    final path = Path();
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.35,
      size.width,
      size.height * 0.3,
    );
    path.lineTo(size.width, size.height * 0.32);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.37,
      0,
      size.height * 0.32,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

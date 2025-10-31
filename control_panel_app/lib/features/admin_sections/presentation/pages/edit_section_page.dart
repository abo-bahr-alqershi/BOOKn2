import 'package:bookn_cp_app/features/admin_sections/presentation/bloc/section_images/section_images_bloc.dart';
import 'package:bookn_cp_app/features/admin_sections/presentation/bloc/section_images/section_images_event.dart';
import 'package:bookn_cp_app/features/admin_sections/domain/entities/section_image.dart';
import 'package:bookn_cp_app/features/admin_sections/presentation/bloc/section_images/section_images_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/section_form/section_form_bloc.dart';
import '../bloc/section_form/section_form_event.dart';
import '../bloc/section_form/section_form_state.dart';
import '../widgets/section_form_widget.dart';
import '../widgets/section_image_gallery.dart';
import 'package:bookn_cp_app/injection_container.dart' as di;

class EditSectionPage extends StatefulWidget {
  final String sectionId;

  const EditSectionPage({
    super.key,
    required this.sectionId,
  });

  @override
  State<EditSectionPage> createState() => _EditSectionPageState();
}

class _EditSectionPageState extends State<EditSectionPage>
    with TickerProviderStateMixin {
  // Gallery State
  final GlobalKey<SectionImageGalleryState> _galleryKey = GlobalKey();
  List<SectionImage> _selectedImages = [];
  List<String> _selectedLocalImages = [];
  bool _isDataLoaded = false;
  bool _isNavigating = false;
  bool _isDisposed = false;

  // Store the bloc instances
  late final SectionFormBloc _formBloc;
  late final SectionImagesBloc _imagesBloc;

  // Animation Controllers
  late AnimationController _animationController;
  late AnimationController _glowController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    // Initialize the blocs
    _imagesBloc = di.sl<SectionImagesBloc>();
    _formBloc = di.sl<SectionFormBloc>();

    // Load data after frame is built to ensure proper initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        // Load section data for editing
        _formBloc.add(InitializeSectionFormEvent(sectionId: widget.sectionId));

        // Load section images
        _imagesBloc.add(LoadSectionImagesEvent(sectionId: widget.sectionId));
      }
    });
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

    _animationController.forward();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _animationController.dispose();
    _glowController.dispose();
    _imagesBloc.close();
    _formBloc.close();
    super.dispose();
  }

  void _navigateBack() {
    if (!_isNavigating && mounted) {
      _isNavigating = true;
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          context.pop();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _imagesBloc),
        BlocProvider.value(value: _formBloc),
      ],
      child: BlocListener<SectionFormBloc, SectionFormState>(
        listener: (context, state) {
          if (!mounted) return;

          print('EditSectionPage - State: ${state.runtimeType}'); // للتشخيص

          if (state is SectionFormSubmitted) {
            // Upload any new local images if available
            if (_selectedLocalImages.isNotEmpty) {
              try {
                _imagesBloc.add(UploadMultipleSectionImagesEvent(
                  sectionId: widget.sectionId,
                  filePaths: List<String>.from(_selectedLocalImages),
                ));
              } catch (_) {}
            }

            _showSuccessMessage('تم تحديث القسم بنجاح');
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                context.pop(true); // Return true to indicate success
              }
            });
          } else if (state is SectionFormError) {
            _showErrorMessage(state.message);
          }
        },
        child: Scaffold(
          backgroundColor: AppTheme.darkBackground,
          body: Stack(
            children: [
              _buildAnimatedBackground(),
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: BlocBuilder<SectionFormBloc, SectionFormState>(
                        builder: (context, state) {
                          print(
                              'EditSectionPage Builder - State: ${state.runtimeType}'); // للتشخيص

                          // Handle initial loading state
                          if (state is SectionFormInitial ||
                              (state is SectionFormLoading && !_isDataLoaded)) {
                            return _buildLoadingState();
                          }
                          // Handle error state (but not the temporary error state)
                          else if (state is SectionFormError &&
                              !_isDataLoaded) {
                            return _buildErrorState(state.message);
                          }
                          // Handle ready state or any other state after data is loaded
                          else if (state is SectionFormReady || _isDataLoaded) {
                            // Mark data as loaded once we receive the ready state
                            if (state is SectionFormReady && !_isDataLoaded) {
                              _isDataLoaded = true;
                            }

                            return FadeTransition(
                              opacity: _fadeAnimation,
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: SectionFormWidget(
                                  isEditing: true,
                                  sectionId: widget.sectionId,
                                ),
                              ),
                            );
                          }
                          // Default loading state
                          else {
                            return _buildLoadingState();
                          }
                        },
                      ),
                    ),
                  ],
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
          GestureDetector(
            onTap: _isNavigating ? null : () => _navigateBack(),
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
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppTheme.primaryGradient.createShader(bounds),
                  child: Text(
                    'تعديل القسم',
                    style: AppTextStyles.heading2.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'قم بتحديث البيانات المطلوبة',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _openSectionMediaDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryPurple.withOpacity(0.3),
                    AppTheme.primaryViolet.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryPurple.withOpacity(0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.collections,
                    size: 18,
                    color: AppTheme.primaryPurple,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'وسائط القسم',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.primaryPurple,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            'جاري تحميل بيانات القسم...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted,
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
                // Retry loading
                _isDataLoaded = false;
                _formBloc.add(
                  InitializeSectionFormEvent(sectionId: widget.sectionId),
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

  void _openSectionMediaDialog() {
    showDialog(
      fullscreenDialog: true,
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(10),
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.darkCard.withOpacity(0.98),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.darkBorder.withOpacity(0.2),
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: BlocProvider.value(
                value: _imagesBloc,
                child: BlocBuilder<SectionImagesBloc, SectionImagesState>(
                  builder: (context, state) {
                    List<SectionImage> images = [];
                    if (state is SectionImagesLoaded) {
                      images = state.images;
                      // Update selected images when loaded from server
                      if (!_isDataLoaded && images.isNotEmpty) {
                        _selectedImages = images;
                        _isDataLoaded = true;
                      }
                    }

                    return SectionImageGallery(
                      key: _galleryKey,
                      sectionId: widget.sectionId,
                      tempKey: null,
                      isReadOnly: false,
                      maxImages: 20,
                      maxVideos: 5,
                      initialImages: images,
                      onImagesChanged: (images) {
                        setState(() {
                          _selectedImages = images;
                        });
                        // إذا كانت هناك صورة رئيسية محددة ضمن الصور، يتم تحديث الخلفية عند المستوى الدومين بواسطة الخلفية
                        // هنا نضمن إعادة التحميل بعد أي تغيير لتنعكس صورة رئيسية جديدة في الواجهة
                        try {
                          _imagesBloc.add(RefreshSectionImagesEvent(sectionId: widget.sectionId));
                        } catch (_) {}
                      },
                      onLocalImagesChanged: (paths) {
                        setState(() {
                          _selectedLocalImages = paths;
                        });
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;

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
    if (!mounted) return;

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

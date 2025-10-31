import 'package:bookn_cp_app/features/admin_sections/presentation/bloc/section_images/section_images_bloc.dart';
import 'package:bookn_cp_app/features/admin_sections/presentation/bloc/section_images/section_images_event.dart';
import 'package:bookn_cp_app/features/admin_sections/domain/entities/section_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/enums/section_type.dart';
import '../../../../core/enums/section_content_type.dart';
import '../../../../core/enums/section_display_style.dart';
import '../../../../core/enums/section_target.dart';
import '../bloc/section_form/section_form_bloc.dart';
import '../bloc/section_form/section_form_event.dart';
import '../bloc/section_form/section_form_state.dart';
import '../widgets/section_form_widget.dart';
import '../widgets/section_image_gallery.dart';
import 'package:bookn_cp_app/injection_container.dart' as di;
import 'package:bookn_cp_app/core/network/api_client.dart';
import 'package:get_it/get_it.dart';

class CreateSectionPage extends StatefulWidget {
  const CreateSectionPage({super.key});

  @override
  State<CreateSectionPage> createState() => _CreateSectionPageState();
}

class _CreateSectionPageState extends State<CreateSectionPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _glowController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Media gallery integration
  final GlobalKey<SectionImageGalleryState> _galleryKey = GlobalKey();
  String? _tempKey;
  List<SectionImage> _selectedImages = [];
  List<String> _selectedLocalImages = [];
  String? _createdSectionId;
  bool _isDisposed = false;

  // Store the bloc instances
  late final SectionImagesBloc _imagesBloc;
  late final SectionFormBloc _formBloc; // إضافة هذا السطر

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    // Generate a temp key
    _tempKey = DateTime.now().millisecondsSinceEpoch.toString();

    // Initialize the blocs
    _imagesBloc = di.sl<SectionImagesBloc>();
    _formBloc = di.sl<SectionFormBloc>();

    // Initialize form first, then attach tempKey
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _formBloc.add(const InitializeSectionFormEvent());

      // Add delay to ensure initialization is complete
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_tempKey != null) {
          _formBloc.add(AttachSectionTempKeyEvent(tempKey: _tempKey!));
        }
      });
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    // If user leaves without saving and no section was created, purge temp images
    if (_tempKey != null && _createdSectionId == null) {
      try {
        GetIt.instance<ApiClient>().delete('/api/sections/images/purge-temp',
            queryParameters: {'tempKey': _tempKey});
      } catch (_) {}
    }
    _isDisposed = true;
    _animationController.dispose();
    _glowController.dispose();
    _imagesBloc.close();
    _formBloc.close(); // إضافة هذا السطر
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    // توفير كلا الـ Blocs
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _imagesBloc),
        BlocProvider.value(value: _formBloc), // إضافة هذا السطر - مهم جداً!
      ],
      child: BlocListener<SectionFormBloc, SectionFormState>(
        listener: (context, state) {
          if (!mounted) return;

          print('SectionFormState: ${state.runtimeType}'); // للتشخيص

          if (state is SectionFormSubmitted) {
            // Store the created section ID
            _createdSectionId = state.sectionId;

            // إن وُجدت صور محلية، قم برفعها للقسم الذي تم إنشاؤه
            if (_selectedLocalImages.isNotEmpty) {
              try {
                _imagesBloc.add(UploadMultipleSectionImagesEvent(
                  sectionId: state.sectionId,
                  filePaths: List<String>.from(_selectedLocalImages),
                ));
              } catch (_) {}
            }
            // إن لم تكن هناك صورة رئيسية بعد الرفع، حاول تعيين أول صورة كصورة رئيسية
            Future.delayed(const Duration(milliseconds: 400), () {
              try {
                _imagesBloc.add(RefreshSectionImagesEvent(sectionId: state.sectionId));
              } catch (_) {}
            });
            // Clear tempKey after successful save
            _tempKey = null;

            _showSuccessMessage('تم إنشاء القسم بنجاح');
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                context.pop(true);
              }
            });
          } else if (state is SectionFormError) {
            _showErrorMessage(state.message);
          } else if (state is SectionFormLoading) {
            print('Loading state...'); // للتشخيص
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
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: const SectionFormWidget(
                            isEditing: false,
                          ),
                        ),
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
          child: CustomPaint(
            painter: _CreateSectionBackgroundPainter(
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
          GestureDetector(
            onTap: () => context.pop(),
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
                    'إضافة قسم جديد',
                    style: AppTextStyles.heading2.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'قم بملء البيانات المطلوبة لإضافة القسم',
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
                child: SectionImageGallery(
                  key: _galleryKey,
                  sectionId: null,
                  tempKey: _tempKey,
                  isReadOnly: false,
                  maxImages: 20,
                  maxVideos: 5,
                  onImagesChanged: (images) {
                    _safeSetState(() {
                      _selectedImages = images;
                    });
                  },
                  onLocalImagesChanged: (paths) {
                    _safeSetState(() {
                      _selectedLocalImages = paths;
                    });
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

class _CreateSectionBackgroundPainter extends CustomPainter {
  final double glowIntensity;

  _CreateSectionBackgroundPainter({required this.glowIntensity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../injection_container.dart';
import '../bloc/review_bloc.dart';
import '../bloc/review_event.dart';
import '../bloc/review_state.dart';
import '../widgets/review_form_widget.dart';

class WriteReviewPage extends StatelessWidget {
  final String bookingId;
  final String propertyId;
  final String propertyName;

  const WriteReviewPage({
    super.key,
    required this.bookingId,
    required this.propertyId,
    required this.propertyName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ReviewBloc>(),
      child: _WriteReviewView(
        bookingId: bookingId,
        propertyId: propertyId,
        propertyName: propertyName,
      ),
    );
  }
}

class _WriteReviewView extends StatelessWidget {
  final String bookingId;
  final String propertyId;
  final String propertyName;

  const _WriteReviewView({
    required this.bookingId,
    required this.propertyId,
    required this.propertyName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: _buildAppBar(context),
      body: BlocConsumer<ReviewBloc, ReviewState>(
        listener: (context, state) {
          if (state is ReviewCreated) {
            _showSuccessDialog(context);
          } else if (state is ReviewCreateError) {
            _showErrorSnackBar(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is ReviewCreating) {
            return const Center(
              child: LoadingWidget(
                type: LoadingType.circular,
                message: 'جاري إرسال التقييم...',
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPropertyInfo(),
                const SizedBox(height: AppDimensions.spacingMd),
                ReviewFormWidget(
                  onSubmit: (ratings, comment, images) {
                    context.read<ReviewBloc>().add(
                      CreateReviewEvent(
                        bookingId: bookingId,
                        propertyId: propertyId,
                        cleanliness: ratings['cleanliness']!,
                        service: ratings['service']!,
                        location: ratings['location']!,
                        value: ratings['value']!,
                        comment: comment,
                        imagesBase64: images,
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.textWhite,
      elevation: 0,
      title: Text(
        'كتابة تقييم',
        style: AppTextStyles.heading3.copyWith(
          color: AppTheme.textWhite,
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.close, color: AppTheme.textWhite),
        onPressed: () => context.pop(),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: AppTheme.darkBorder,
        ),
      ),
    );
  }

  Widget _buildPropertyInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      color: AppTheme.primaryBlue.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تقييمك لـ',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            propertyName,
            style: AppTextStyles.heading2.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLg),
          ),
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: AppTheme.success,
                    size: 48,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingLg),
                Text(
                  'شكراً لك!',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppTheme.textWhite,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingSm),
                Text(
                  'تم إرسال تقييمك بنجاح',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.spacingXl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      context.pop(true); // Return true to indicate success
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.paddingMedium,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.borderRadiusMd,
                        ),
                      ),
                    ),
                    child: Text(
                      'حسناً',
                      style: AppTextStyles.buttonLarge.copyWith(
                        color: AppTheme.textWhite,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSm),
        ),
      ),
    );
  }
}
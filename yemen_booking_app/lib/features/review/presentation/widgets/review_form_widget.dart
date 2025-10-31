import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'rating_selector_widget.dart';
import 'review_images_picker_widget.dart';

class ReviewFormWidget extends StatefulWidget {
  final Function(Map<String, int> ratings, String comment, List<String>? images) onSubmit;

  const ReviewFormWidget({
    super.key,
    required this.onSubmit,
  });

  @override
  State<ReviewFormWidget> createState() => _ReviewFormWidgetState();
}

class _ReviewFormWidgetState extends State<ReviewFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final Map<String, int> _ratings = {
    'cleanliness': 0,
    'service': 0,
    'location': 0,
    'value': 0,
  };
  List<String> _selectedImages = [];
  bool _isRecommended = true;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Container(
        color: AppTheme.textWhite,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverallExperience(),
            const Divider(height: 1),
            _buildRatingSection(),
            const Divider(height: 1),
            _buildCommentSection(),
            const Divider(height: 1),
            _buildImagesSection(),
            const Divider(height: 1),
            _buildRecommendationSection(),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallExperience() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'كيف كانت تجربتك بشكل عام؟',
            style: AppTextStyles.heading2.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildExperienceOption(
                  icon: Icons.sentiment_very_satisfied,
                  label: 'ممتازة',
                  color: AppTheme.success,
                  value: 5,
                ),
                _buildExperienceOption(
                  icon: Icons.sentiment_satisfied,
                  label: 'جيدة',
                  color: AppTheme.warning,
                  value: 4,
                ),
                _buildExperienceOption(
                  icon: Icons.sentiment_neutral,
                  label: 'متوسطة',
                  color: AppTheme.warning,
                  value: 3,
                ),
                _buildExperienceOption(
                  icon: Icons.sentiment_dissatisfied,
                  label: 'سيئة',
                  color: AppTheme.error,
                  value: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceOption({
    required IconData icon,
    required String label,
    required Color color,
    required int value,
  }) {
    final isSelected = _getOverallRating() == value;
    
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _ratings['cleanliness'] = value;
            _ratings['service'] = value;
            _ratings['location'] = value;
            _ratings['value'] = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.paddingMedium,
          ),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
            border: isSelected
                ? Border(
                    bottom: BorderSide(
                      color: color,
                      width: 3,
                    ),
                  )
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: isSelected ? color : AppTheme.textMuted,
              ),
              const SizedBox(height: AppDimensions.spacingXs),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: isSelected ? color : AppTheme.textMuted,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'قيّم الجوانب المختلفة',
            style: AppTextStyles.heading2.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          _buildRatingItem(
            'النظافة',
            'cleanliness',
            Icons.cleaning_services_outlined,
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          _buildRatingItem(
            'الخدمة',
            'service',
            Icons.room_service_outlined,
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          _buildRatingItem(
            'الموقع',
            'location',
            Icons.location_on_outlined,
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          _buildRatingItem(
            'القيمة مقابل السعر',
            'value',
            Icons.attach_money_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildRatingItem(String label, String key, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textMuted, size: 20),
        const SizedBox(width: AppDimensions.spacingSm),
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: AppTextStyles.bodyMedium,
          ),
        ),
        const Spacer(),
        RatingSelectorWidget(
          rating: _ratings[key]!,
          onRatingChanged: (rating) {
            setState(() {
              _ratings[key] = rating;
            });
          },
        ),
      ],
    );
  }

  Widget _buildCommentSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'شاركنا تفاصيل تجربتك',
            style: AppTextStyles.heading2.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          TextFormField(
            controller: _commentController,
            maxLines: 5,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'اكتب تقييمك هنا...',
              filled: true,
              fillColor: AppTheme.inputBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  AppDimensions.borderRadiusMd,
                ),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  AppDimensions.borderRadiusMd,
                ),
                borderSide: BorderSide(
                  color: AppTheme.primaryBlue,
                  width: 2,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'من فضلك اكتب تقييمك';
              }
              if (value.length < 10) {
                return 'التقييم يجب أن يكون 10 أحرف على الأقل';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImagesSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.photo_library_outlined,
                color: AppTheme.textMuted,
                size: 20,
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Text(
                'أضف صور (اختياري)',
                style: AppTextStyles.heading2.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          ReviewImagesPickerWidget(
            onImagesSelected: (images) {
              setState(() {
                _selectedImages = images;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'هل توصي بهذا المكان؟',
              style: AppTextStyles.heading2.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Switch(
            value: _isRecommended,
            onChanged: (value) {
              setState(() {
                _isRecommended = value;
              });
            },
            activeColor: AppTheme.primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: ElevatedButton(
        onPressed: _canSubmit() ? _submitReview : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          disabledBackgroundColor: AppTheme.darkBorder,
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.paddingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppDimensions.borderRadiusMd,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.send, size: 20),
            const SizedBox(width: AppDimensions.spacingSm),
            Text(
              'إرسال التقييم',
              style: AppTextStyles.buttonLarge.copyWith(
                color: AppTheme.textWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canSubmit() {
    return _ratings.values.every((rating) => rating > 0) &&
        _commentController.text.isNotEmpty;
  }

  int _getOverallRating() {
    final total = _ratings.values.fold(0, (sum, rating) => sum + rating);
    if (total == 0) return 0;
    return (total / _ratings.length).round();
  }

  void _submitReview() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(
        _ratings,
        _commentController.text,
        _selectedImages.isNotEmpty ? _selectedImages : null,
      );
    }
  }
}
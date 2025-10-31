// lib/features/admin_reviews/presentation/widgets/add_response_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

class AddResponseDialog extends StatefulWidget {
  final String reviewId;
  final Function(String) onSubmit;
  
  const AddResponseDialog({
    super.key,
    required this.reviewId,
    required this.onSubmit,
  });
  
  @override
  State<AddResponseDialog> createState() => _AddResponseDialogState();
}

class _AddResponseDialogState extends State<AddResponseDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  final TextEditingController _responseController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  bool _isSubmitting = false;
  int _characterCount = 0;
  final int _maxCharacters = 1000;
  
  // قوالب الردود السريعة
  final List<String> _templates = [
    'شكراً لك على تقييمك! نقدر ملاحظاتك القيمة.',
    'نأسف لسماع تجربتك. سنعمل على التحسين.',
    'نشكرك على الوقت الذي قضيته في مشاركة أفكارك معنا.',
    'يسعدنا أنك استمتعت بإقامتك! نتطلع لاستقبالك مرة أخرى.',
  ];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    _animationController.forward();
    
    _responseController.addListener(() {
      setState(() {
        _characterCount = _responseController.text.length;
      });
    });
    
    // التركيز التلقائي بعد الحركة
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _responseController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  
  void _submitResponse() async {
    if (_responseController.text.trim().isEmpty) {
      HapticFeedback.mediumImpact();
      return;
    }
    
    setState(() => _isSubmitting = true);
    HapticFeedback.lightImpact();
    
    // محاكاة استدعاء API
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      widget.onSubmit(_responseController.text.trim());
      Navigator.pop(context);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 0;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: isKeyboardOpen ? 20 : 40,
              ),
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: size.height * (isKeyboardOpen ? 0.5 : 0.7),
                      maxWidth: size.width > 600 ? 600 : size.width,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: AppTheme.darkCard,
                      border: Border.all(
                        color: AppTheme.darkBorder.withOpacity(0.3),
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // الرأس
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: AppTheme.darkBorder.withOpacity(0.1),
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: AppTheme.primaryGradient,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primaryBlue.withOpacity(0.3),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.reply,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'إضافة رد',
                                          style: AppTextStyles.heading3.copyWith(
                                            color: AppTheme.textWhite,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'الرد على تقييم العميل',
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppTheme.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      Navigator.pop(context);
                                    },
                                    icon: Icon(
                                      Icons.close,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // المحتوى
                            Flexible(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // القوالب السريعة (تظهر فقط عند إغلاق لوحة المفاتيح)
                                    if (!isKeyboardOpen) ...[
                                      SizedBox(
                                        height: 40,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: _templates.length,
                                          itemBuilder: (context, index) {
                                            return Padding(
                                              padding: const EdgeInsets.only(left: 8),
                                              child: _buildTemplateChip(_templates[index]),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                    
                                    // حقل الإدخال
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        color: AppTheme.inputBackground.withOpacity(0.3),
                                        border: Border.all(
                                          color: _focusNode.hasFocus
                                              ? AppTheme.primaryBlue.withOpacity(0.5)
                                              : AppTheme.darkBorder.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          TextField(
                                            controller: _responseController,
                                            focusNode: _focusNode,
                                            maxLines: isKeyboardOpen ? 4 : 6,
                                            maxLength: _maxCharacters,
                                            textInputAction: TextInputAction.newline,
                                            style: AppTextStyles.bodyMedium.copyWith(
                                              height: 1.5,
                                              color: AppTheme.textWhite,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: 'اكتب ردك هنا...',
                                              hintStyle: AppTextStyles.bodyMedium.copyWith(
                                                color: AppTheme.textMuted.withOpacity(0.5),
                                              ),
                                              border: InputBorder.none,
                                              counterText: '',
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              // عداد الأحرف
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(8),
                                                  color: _characterCount > _maxCharacters * 0.8
                                                      ? AppTheme.warning.withOpacity(0.1)
                                                      : AppTheme.primaryBlue.withOpacity(0.1),
                                                ),
                                                child: Text(
                                                  '$_characterCount / $_maxCharacters',
                                                  style: AppTextStyles.caption.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: _characterCount > _maxCharacters * 0.8
                                                        ? AppTheme.warning
                                                        : AppTheme.primaryBlue,
                                                  ),
                                                ),
                                              ),
                                              
                                              // خيارات التنسيق
                                              if (!isKeyboardOpen)
                                                Row(
                                                  children: [
                                                    _buildFormatButton(Icons.format_bold),
                                                    const SizedBox(width: 8),
                                                    _buildFormatButton(Icons.format_italic),
                                                    const SizedBox(width: 8),
                                                    _buildFormatButton(Icons.link),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            // أزرار الإجراءات
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: AppTheme.darkBorder.withOpacity(0.1),
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: _isSubmitting
                                          ? null
                                          : () {
                                              HapticFeedback.lightImpact();
                                              Navigator.pop(context);
                                            },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        'إلغاء',
                                        style: AppTextStyles.buttonMedium.copyWith(
                                          color: AppTheme.textLight,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: ElevatedButton(
                                      onPressed: _isSubmitting ||
                                              _responseController.text.trim().isEmpty
                                          ? null
                                          : _submitResponse,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        backgroundColor: AppTheme.primaryBlue,
                                        disabledBackgroundColor:
                                            AppTheme.primaryBlue.withOpacity(0.3),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: _isSubmitting
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(
                                              'إرسال الرد',
                                              style: AppTextStyles.buttonMedium.copyWith(
                                                color: Colors.white,
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
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildTemplateChip(String template) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _responseController.text = template;
        _focusNode.requestFocus();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryBlue.withOpacity(0.1),
              AppTheme.primaryPurple.withOpacity(0.1),
            ],
          ),
          border: Border.all(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Text(
          template.length > 30 
              ? '${template.substring(0, 30)}...'
              : template,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryBlue,
          ),
        ),
      ),
    );
  }
  
  Widget _buildFormatButton(IconData icon) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // معالجة التنسيق
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: AppTheme.inputBackground.withOpacity(0.3),
        ),
        child: Icon(
          icon,
          size: 16,
          color: AppTheme.textMuted,
        ),
      ),
    );
  }
}
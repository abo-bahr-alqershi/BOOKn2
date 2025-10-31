import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';

class ReviewImagesPickerWidget extends StatefulWidget {
  final Function(List<String>) onImagesSelected;
  final int maxImages;

  const ReviewImagesPickerWidget({
    super.key,
    required this.onImagesSelected,
    this.maxImages = 5,
  });

  @override
  State<ReviewImagesPickerWidget> createState() => _ReviewImagesPickerWidgetState();
}

class _ReviewImagesPickerWidgetState extends State<ReviewImagesPickerWidget> {
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedImages.isNotEmpty) ...[
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length + (_canAddMore() ? 1 : 0),
              separatorBuilder: (context, index) => const SizedBox(
                width: AppDimensions.spacingSm,
              ),
              itemBuilder: (context, index) {
                if (index == _selectedImages.length && _canAddMore()) {
                  return _buildAddImageButton();
                }
                return _buildImagePreview(index);
              },
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Text(
            '${_selectedImages.length}/${widget.maxImages} صور',
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ] else
          _buildEmptyState(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(
            color: AppTheme.darkBorder,
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMd),
          color: AppTheme.inputBackground,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 32,
                color: AppTheme.textMuted,
              ),
              const SizedBox(height: AppDimensions.spacingSm),
              Text(
                'اضغط لإضافة صور',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(
            color: AppTheme.darkBorder,
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMd),
          color: AppTheme.inputBackground,
        ),
        child: Center(
          child: Icon(
            Icons.add,
            size: 32,
            color: AppTheme.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(int index) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMd),
            image: DecorationImage(
              image: FileImage(_selectedImages[index]),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 16,
                color: AppTheme.textWhite,
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _canAddMore() => _selectedImages.length < widget.maxImages;

  Future<void> _pickImage() async {
    if (!_canAddMore()) {
      _showMaxImagesMessage();
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.borderRadiusLg),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppDimensions.spacingMd),
              decoration: BoxDecoration(
                color: AppTheme.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('الكاميرا'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromSource(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('معرض الصور'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromSource(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
        _updateImagesCallback();
      }
    } catch (e) {
      _showErrorMessage('فشل في اختيار الصورة');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
    _updateImagesCallback();
  }

  void _updateImagesCallback() async {
    final List<String> base64Images = [];
    
    for (final image in _selectedImages) {
      final bytes = await image.readAsBytes();
      final base64 = base64Encode(bytes);
      base64Images.add('data:image/jpeg;base64,$base64');
    }
    
    widget.onImagesSelected(base64Images);
  }

  void _showMaxImagesMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('يمكنك إضافة ${widget.maxImages} صور كحد أقصى'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSm),
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
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
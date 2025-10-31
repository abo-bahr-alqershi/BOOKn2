// lib/features/admin_properties/presentation/widgets/amenity_selector_widget.dart

import 'package:bookn_cp_app/core/theme/app_theme.dart';
import 'package:bookn_cp_app/features/admin_amenities/presentation/utils/amenity_icons.dart';
import 'package:bookn_cp_app/features/admin_properties/domain/entities/amenity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bookn_cp_app/core/theme/app_colors.dart';
import 'package:bookn_cp_app/core/theme/app_text_styles.dart';
import '../bloc/amenities/amenities_bloc.dart';

class AmenitySelectorWidget extends StatefulWidget {
  final List<String> selectedAmenities;
  final Function(List<String>) onAmenitiesChanged;
  final bool isReadOnly;
  final String? propertyTypeId;

  const AmenitySelectorWidget({
    super.key,
    required this.selectedAmenities,
    required this.onAmenitiesChanged,
    this.isReadOnly = false,
    this.propertyTypeId,
  });

  @override
  State<AmenitySelectorWidget> createState() => _AmenitySelectorWidgetState();
}

class _AmenitySelectorWidgetState extends State<AmenitySelectorWidget> {
  // لا نحتاج لتحميل المرافق هنا لأنها محملة بالفعل في الصفحة الرئيسية

  @override
  Widget build(BuildContext context) {
    // Require property type selection first
    if (widget.propertyTypeId == null || widget.propertyTypeId!.isEmpty) {
      return _buildSelectPropertyTypeHint();
    }
    return BlocBuilder<AmenitiesBloc, AmenitiesState>(
      builder: (context, state) {
        if (state is AmenitiesLoading) {
          return _buildLoadingState();
        }

        if (state is AmenitiesError) {
          return _buildErrorState(state.message);
        }

        if (state is AmenitiesLoaded) {
          if (state.amenities.isEmpty) {
            return _buildEmptyState();
          }

          return _buildAmenitiesGrid(state.amenities);
        }

        // Initial state - request filtered load by property type
        if (state is AmenitiesInitial) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted &&
                widget.propertyTypeId != null &&
                widget.propertyTypeId!.isNotEmpty) {
              context.read<AmenitiesBloc>().add(
                    LoadAmenitiesEventWithType(
                      propertyTypeId: widget.propertyTypeId!,
                      pageSize: 100,
                    ),
                  );
            }
          });
        }

        return _buildLoadingState();
      },
    );
  }

  Widget _buildSelectPropertyTypeHint() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkBorder.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.category_rounded, color: AppTheme.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'اختر نوع العقار أولاً لعرض المرافق المتاحة له فقط',
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppTheme.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
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
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: AppTheme.error,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'خطأ في تحميل المرافق',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              context.read<AmenitiesBloc>().add(
                    const LoadAmenitiesEvent(pageSize: 100),
                  );
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.apartment_outlined,
              size: 48,
              color: AppTheme.textMuted.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'لا توجد مرافق متاحة',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'يرجى إضافة مرافق من لوحة التحكم',
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmenitiesGrid(List<Amenity> amenities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected amenities count
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.primaryBlue.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 16,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(width: 6),
              Text(
                'تم اختيار ${widget.selectedAmenities.length} من ${amenities.length} مرفق',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Amenities grid
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: amenities.map((amenity) {
            final isSelected = widget.selectedAmenities.contains(amenity.id);

            return GestureDetector(
              onTap: widget.isReadOnly
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      final newSelection = [...widget.selectedAmenities];
                      if (isSelected) {
                        newSelection.remove(amenity.id);
                      } else {
                        newSelection.add(amenity.id);
                      }
                      widget.onAmenitiesChanged(newSelection);
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? AppTheme.primaryGradient
                      : LinearGradient(
                          colors: [
                            AppTheme.darkCard.withOpacity(0.5),
                            AppTheme.darkCard.withOpacity(0.3),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryBlue.withOpacity(0.5)
                        : AppTheme.darkBorder.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Icon(
                      _getAmenityIcon(amenity.icon),
                      size: 18,
                      color: isSelected
                          ? Colors.white
                          : AppTheme.textMuted.withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),

                    // Name
                    Text(
                      amenity.name,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isSelected ? Colors.white : AppTheme.textLight,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),

                    // Free/Paid badge
                    if (amenity.extraCost != null &&
                        amenity.extraCost! > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${amenity.extraCost} ${amenity.currency ?? 'YER'}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.warning,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],

                    // Check icon
                    if (isSelected) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        // Clear all button (if items selected)
        if (widget.selectedAmenities.isNotEmpty && !widget.isReadOnly) ...[
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                widget.onAmenitiesChanged([]);
              },
              icon: const Icon(Icons.clear_all_rounded, size: 18),
              label: const Text('إلغاء تحديد الكل'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textMuted,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
        ],
      ],
    );
  }

  IconData _getAmenityIcon(String iconName) {
    return AmenityIcons.getIconByName(iconName)?.icon ?? Icons.star_rounded;
  }
}

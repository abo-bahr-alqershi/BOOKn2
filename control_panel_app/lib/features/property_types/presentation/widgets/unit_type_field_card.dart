import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:bookn_cp_app/core/theme/app_theme.dart';
import 'package:bookn_cp_app/core/theme/app_text_styles.dart';
import '../../domain/entities/unit_type_field.dart';

class UnitTypeFieldCard extends StatefulWidget {
  final UnitTypeField field;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const UnitTypeFieldCard({
    super.key,
    required this.field,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<UnitTypeFieldCard> createState() => _UnitTypeFieldCardState();
}

class _UnitTypeFieldCardState extends State<UnitTypeFieldCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  IconData _getFieldTypeIcon(String fieldType) {
    final iconMap = {
      'text': Icons.text_fields_rounded,
      'textarea': Icons.notes_rounded,
      'number': Icons.numbers_rounded,
      'currency': Icons.attach_money_rounded,
      'boolean': Icons.toggle_on_rounded,
      'select': Icons.arrow_drop_down_circle_rounded,
      'multiselect': Icons.checklist_rounded,
      'date': Icons.calendar_today_rounded,
      'email': Icons.email_rounded,
      'phone': Icons.phone_rounded,
      'file': Icons.attach_file_rounded,
      'image': Icons.image_rounded,
    };
    return iconMap[fieldType] ?? Icons.text_fields_rounded;
  }

  Color _getFieldTypeColor(String fieldType) {
    final colorMap = {
      'text': AppTheme.primaryBlue,
      'textarea': AppTheme.primaryPurple,
      'number': AppTheme.neonGreen,
      'currency': AppTheme.warning,
      'boolean': AppTheme.info,
      'select': AppTheme.primaryViolet,
      'multiselect': AppTheme.primaryCyan,
      'date': AppTheme.neonPurple,
      'email': AppTheme.primaryBlue,
      'phone': AppTheme.neonGreen,
      'file': AppTheme.warning,
      'image': AppTheme.primaryPurple,
    };
    return colorMap[fieldType] ?? AppTheme.primaryBlue;
  }

  @override
  Widget build(BuildContext context) {
    final fieldColor = _getFieldTypeColor(widget.field.fieldTypeId);
    final isSmall = MediaQuery.of(context).size.width < 600;
    
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _animationController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _animationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isHovered
                      ? [
                          fieldColor.withOpacity(0.15),
                          fieldColor.withOpacity(0.08),
                        ]
                      : [
                          AppTheme.darkCard.withOpacity(0.5),
                          AppTheme.darkCard.withOpacity(0.3),
                        ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isHovered
                      ? fieldColor.withOpacity(0.4)
                      : AppTheme.darkBorder.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: _isHovered
                    ? [
                        BoxShadow(
                          color: fieldColor.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                fieldColor,
                                fieldColor.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getFieldTypeIcon(widget.field.fieldTypeId),
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.field.displayName,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppTheme.textWhite,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (widget.field.isRequired)
                                    Container(
                                      margin: const EdgeInsets.only(left: 4),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.error.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'مطلوب',
                                        style: AppTextStyles.overline.copyWith(
                                          color: AppTheme.error,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.field.fieldName,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppTheme.textMuted.withOpacity(0.7),
                                  fontFamily: 'monospace',
                                ),
                              ),
                              if (widget.field.description.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  widget.field.description,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppTheme.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 4,
                                runSpacing: 2,
                                children: [
                                  _buildBadge(
                                    widget.field.fieldTypeId.toUpperCase(),
                                    fieldColor,
                                  ),
                                  if (widget.field.isSearchable)
                                    _buildBadge(
                                      'قابل للبحث',
                                      AppTheme.info,
                                      icon: Icons.search_rounded,
                                    ),
                                  if (widget.field.isPublic)
                                    _buildBadge(
                                      'عام',
                                      AppTheme.success,
                                      icon: Icons.public_rounded,
                                    )
                                  else
                                    _buildBadge(
                                      'خاص',
                                      AppTheme.warning,
                                      icon: Icons.lock_rounded,
                                    ),
                                  if (widget.field.showInCards)
                                    _buildBadge(
                                      'البطاقات',
                                      AppTheme.primaryPurple,
                                      icon: Icons.view_agenda_rounded,
                                    ),
                                  if (widget.field.isPrimaryFilter)
                                    _buildBadge(
                                      'فلتر أساسي',
                                      AppTheme.primaryCyan,
                                      icon: Icons.filter_alt_rounded,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (_isHovered && !isSmall) ...[
                          IconButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              widget.onEdit();
                            },
                            icon: Icon(
                              Icons.edit_rounded,
                              color: fieldColor,
                              size: 18,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              widget.onDelete();
                            },
                            icon: Icon(
                              Icons.delete_rounded,
                              color: AppTheme.error,
                              size: 18,
                            ),
                          ),
                        ]
                        else if (isSmall) ...[
                          PopupMenuButton<String>(
                            color: AppTheme.darkCard,
                            onSelected: (value) {
                              if (value == 'edit') {
                                widget.onEdit();
                              } else if (value == 'delete') {
                                widget.onDelete();
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_rounded, color: fieldColor, size: 18),
                                    const SizedBox(width: 8),
                                    const Text('تعديل'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_rounded, color: AppTheme.error, size: 18),
                                    const SizedBox(width: 8),
                                    const Text('حذف'),
                                  ],
                                ),
                              ),
                            ],
                            icon: Icon(Icons.more_vert_rounded, color: AppTheme.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBadge(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 2),
          ],
          Text(
            label,
            style: AppTextStyles.overline.copyWith(
              color: color,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}
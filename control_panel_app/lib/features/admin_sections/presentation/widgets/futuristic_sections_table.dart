import 'package:bookn_cp_app/core/enums/section_content_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/section.dart';
import 'section_status_badge.dart';

class FuturisticSectionsTable extends StatefulWidget {
  final List<Section> sections;
  final Function(String) onSectionTap;
  final Function(String) onEdit;
  final Function(Section) onDelete;
  final Function(Section) onToggleStatus;
  final Function(Section)? onManageItems;

  const FuturisticSectionsTable({
    super.key,
    required this.sections,
    required this.onSectionTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
    this.onManageItems,
  });

  @override
  State<FuturisticSectionsTable> createState() =>
      _FuturisticSectionsTableState();
}

class _FuturisticSectionsTableState extends State<FuturisticSectionsTable> {
  int? _hoveredIndex;
  String _sortColumn = 'order';
  bool _sortAscending = true;
  late List<Section> _sorted;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 800;

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.darkCard.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.darkBorder.withValues(alpha: 0.2),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Column(
                children: [
                  _buildHeader(isCompact),
                  isCompact
                      ? _buildCompactView()
                      : _buildTableView(constraints),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  'قائمة الأقسام',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppTheme.textWhite,
                    fontSize: isCompact ? 16 : null,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.sections.length}',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isCompact ? 10 : 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!isCompact) _buildSortDropdown(isCompact),
        ],
      ),
    );
  }

  Widget _buildSortDropdown(bool isCompact) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.sort_down,
            size: isCompact ? 14 : 16,
            color: AppTheme.textMuted,
          ),
          SizedBox(width: isCompact ? 4 : 6),
          Text(
            'ترتيب',
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted,
              fontSize: isCompact ? 11 : 12,
            ),
          ),
          SizedBox(width: isCompact ? 4 : 8),
          DropdownButton<String>(
            value: _sortColumn,
            dropdownColor: AppTheme.darkCard,
            underline: const SizedBox.shrink(),
            icon: Icon(
              CupertinoIcons.chevron_down,
              size: isCompact ? 12 : 14,
              color: AppTheme.primaryBlue,
            ),
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.primaryBlue,
              fontSize: isCompact ? 11 : 12,
            ),
            items: const [
              DropdownMenuItem(value: 'order', child: Text('الترتيب')),
              DropdownMenuItem(value: 'name', child: Text('الاسم')),
              DropdownMenuItem(value: 'type', child: Text('النوع')),
              DropdownMenuItem(value: 'status', child: Text('الحالة')),
            ],
            onChanged: (value) {
              setState(() {
                _sortColumn = value!;
              });
            },
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _sortAscending = !_sortAscending;
              });
            },
            icon: Icon(
              _sortAscending
                  ? CupertinoIcons.arrow_up
                  : CupertinoIcons.arrow_down,
              size: isCompact ? 14 : 16,
              color: AppTheme.primaryBlue,
            ),
            padding: EdgeInsets.all(isCompact ? 4 : 8),
            constraints: BoxConstraints(
              minWidth: isCompact ? 24 : 32,
              minHeight: isCompact ? 24 : 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactView() {
    _sorted = List<Section>.from(widget.sections);
    _sortSections();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _sorted.length,
      itemBuilder: (context, index) {
        final section = _sorted[index];

        return GestureDetector(
          onTap: () => widget.onSectionTap(section.id),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.darkCard.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.darkBorder.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.title ?? section.name ?? 'قسم',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppTheme.textWhite,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            section.type.name,
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SectionStatusBadge(
                      isActive: section.isActive,
                      size: BadgeSize.small,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildCompactInfo(
                      icon: CupertinoIcons.square_stack_3d_up,
                      value: section.contentType.name ==
                              SectionContentType.properties.name
                          ? 'عقارات'
                          : section.contentType.name ==
                                  SectionContentType.units.name
                              ? 'وحدات'
                              : 'مختلط',
                    ),
                    const SizedBox(width: 12),
                    _buildCompactInfo(
                      icon: CupertinoIcons.eye,
                      value: section.displayStyle.name == 'grid'
                          ? 'شبكة'
                          : section.displayStyle.name == 'list'
                              ? 'قائمة'
                              : section.displayStyle.name == 'carousel'
                                  ? 'كاروسيل'
                                  : 'خريطة',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ترتيب: ${section.displayOrder}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                    _buildCompactActions(section),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactInfo({
    required IconData icon,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: AppTheme.textMuted,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactActions(Section section) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionIcon(
          icon: CupertinoIcons.pencil,
          onTap: () => widget.onEdit(section.id),
          tooltip: 'تعديل',
          color: AppTheme.primaryBlue,
        ),
        _buildActionIcon(
          icon: section.isActive
              ? CupertinoIcons.pause_circle
              : CupertinoIcons.play_circle,
          onTap: () => widget.onToggleStatus(section),
          tooltip: section.isActive ? 'إيقاف' : 'تفعيل',
          color: section.isActive ? AppTheme.warning : AppTheme.success,
        ),
        _buildActionIcon(
          icon: CupertinoIcons.trash,
          onTap: () => widget.onDelete(section),
          tooltip: 'حذف',
          color: AppTheme.error,
        ),
      ],
    );
  }

  Widget _buildTableView(BoxConstraints constraints) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: constraints.maxWidth > 1200 ? constraints.maxWidth : 1200,
        child: Column(
          children: [
            _buildTableHeader(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              // compute sorted list for table view
              itemCount: (() {
                _sorted = List<Section>.from(widget.sections);
                _sortSections();
                return _sorted.length;
              })(),
              itemBuilder: (context, index) {
                return _buildTableRow(index, _sorted[index]);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          _buildHeaderCell('القسم', 200),
          _buildHeaderCell('النوع', 120),
          _buildHeaderCell('المحتوى', 120),
          _buildHeaderCell('العرض', 120),
          _buildHeaderCell('الهدف', 100),
          _buildHeaderCell('الترتيب', 80),
          _buildHeaderCell('العناصر', 80),
          _buildHeaderCell('الحالة', 100),
          _buildHeaderCell('الإجراءات', 200),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: AppTheme.textMuted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTableRow(int index, Section section) {
    final isHovered = _hoveredIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: GestureDetector(
        onTap: () => widget.onSectionTap(section.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isHovered
                ? AppTheme.primaryBlue.withValues(alpha: 0.05)
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: AppTheme.darkBorder.withValues(alpha: 0.05),
              ),
              left: BorderSide(
                color: section.isActive
                    ? AppTheme.primaryBlue
                    : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              _buildCell(
                section.title ?? section.name ?? 'قسم',
                200,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _buildCell(section.type.name, 120),
              _buildCell(section.contentType.name, 120),
              _buildCell(section.displayStyle.name, 120),
              _buildCell(section.target.name, 100),
              _buildCell(section.displayOrder.toString(), 80),
              _buildCell(section.itemsToShow.toString(), 80),
              SizedBox(
                width: 100,
                child: SectionStatusBadge(
                  isActive: section.isActive,
                  size: BadgeSize.small,
                ),
              ),
              SizedBox(
                width: 200,
                child: _buildActions(section),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCell(String text, double width, {TextStyle? style}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: style ??
            AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textWhite,
            ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildActions(Section section) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        _buildActionIcon(
          icon: CupertinoIcons.eye,
          onTap: () => widget.onSectionTap(section.id),
          tooltip: 'عرض',
        ),
        _buildActionIcon(
          icon: CupertinoIcons.pencil,
          onTap: () => widget.onEdit(section.id),
          tooltip: 'تعديل',
          color: AppTheme.primaryBlue,
        ),
        if (widget.onManageItems != null && section.contentType != SectionContentType.none)
          _buildActionIcon(
            icon: CupertinoIcons.square_stack_3d_down_right,
            onTap: () => widget.onManageItems!(section),
            tooltip: 'إدارة العناصر',
            color: AppTheme.primaryPurple,
          ),
        _buildActionIcon(
          icon: section.isActive
              ? CupertinoIcons.pause_circle
              : CupertinoIcons.play_circle,
          onTap: () => widget.onToggleStatus(section),
          tooltip: section.isActive ? 'إيقاف' : 'تفعيل',
          color: section.isActive ? AppTheme.warning : AppTheme.success,
        ),
        _buildActionIcon(
          icon: CupertinoIcons.trash,
          onTap: () => widget.onDelete(section),
          tooltip: 'حذف',
          color: AppTheme.error,
        ),
      ],
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    Color? color,
    double size = 14,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: (color ?? AppTheme.primaryBlue).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: EdgeInsets.all(size == 14 ? 4 : 6),
              child: Icon(
                icon,
                size: size,
                color: color ?? AppTheme.primaryBlue,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _sortSections() {
    _sorted.sort((a, b) {
      int result;
      switch (_sortColumn) {
        case 'order':
          result = a.displayOrder.compareTo(b.displayOrder);
          break;
        case 'name':
          result = (a.title ?? a.name ?? '').compareTo(b.title ?? b.name ?? '');
          break;
        case 'type':
          result = a.type.name.compareTo(b.type.name);
          break;
        case 'status':
          result = a.isActive.toString().compareTo(b.isActive.toString());
          break;
        default:
          result = 0;
      }
      return _sortAscending ? result : -result;
    });
  }
}

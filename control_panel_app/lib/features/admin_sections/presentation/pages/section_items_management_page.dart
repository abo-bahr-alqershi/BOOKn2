import 'package:bookn_cp_app/core/widgets/error_widget.dart';
import 'package:bookn_cp_app/features/admin_sections/domain/entities/section.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../widgets/section_preview_widget.dart';
import '../../domain/usecases/sections/get_section_by_id_usecase.dart';
import '../../../../core/widgets/empty_widget.dart';
import '../../../../core/enums/section_target.dart';
import '../../../../core/models/section_item_dto.dart';
import '../../domain/entities/property_in_section.dart';
import '../../domain/entities/unit_in_section.dart';
import '../bloc/section_items/section_items_bloc.dart';
import '../bloc/section_items/section_items_event.dart';
import '../bloc/section_items/section_items_state.dart';
import '../widgets/section_items_list.dart';
import '../widgets/add_items_dialog.dart';

class SectionItemsManagementPage extends StatefulWidget {
  final String sectionId;
  final SectionTarget target;

  const SectionItemsManagementPage({
    super.key,
    required this.sectionId,
    required this.target,
  });

  @override
  State<SectionItemsManagementPage> createState() =>
      _SectionItemsManagementPageState();
}

class _SectionItemsManagementPageState extends State<SectionItemsManagementPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();
  bool _isReordering = false;
  Section? _section;
  bool _showPreview = false;
  List<dynamic> _orderedItems = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadSection(); // إضافة هنا
    _loadItems();
  }

// تحديث _buildActionBar لإضافة زر المعاينة
  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildActionChip(
              icon: CupertinoIcons.eye_fill,
              label: 'معاينة القسم',
              onTap: () => setState(() => _showPreview = !_showPreview),
              isPrimary: _showPreview,
            ),
            const SizedBox(width: 8),
            _buildActionChip(
              icon: _isReordering
                  ? CupertinoIcons.checkmark_circle
                  : CupertinoIcons.arrow_up_arrow_down,
              label: _isReordering ? 'حفظ الترتيب' : 'إعادة الترتيب',
              onTap: () {
                setState(() {
                  _isReordering = !_isReordering;
                });
                if (!_isReordering) {
                  _saveOrder();
                }
              },
              isPrimary: _isReordering,
            ),
            const SizedBox(width: 8),
            _buildActionChip(
              icon: CupertinoIcons.arrow_clockwise,
              label: 'تحديث',
              onTap: _loadItems,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadSection() async {
    // استخدام GetSectionByIdUseCase
    // يمكنك حقن الـ usecase أو الحصول عليه من GetIt
    // هذا مثال:
    try {
      // final useCase = GetIt.instance<GetSectionByIdUseCase>();
      // final result = await useCase(GetSectionByIdParams(widget.sectionId));
      // result.fold(
      //   (failure) => print('Error loading section'),
      //   (section) => setState(() => _section = section),
      // );
    } catch (e) {
      print('Error: $e');
    }
  }

  void _loadItems() {
    context.read<SectionItemsBloc>().add(
          LoadSectionItemsEvent(
            sectionId: widget.sectionId,
            target: widget.target,
            pageNumber: 1,
            pageSize: 20,
          ),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

// تحديث build method لإضافة معاينة القسم
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: BlocListener<SectionItemsBloc, SectionItemsState>(
          listener: (context, state) {
            if (state is SectionItemsOperationSuccess) {
              setState(() {
                _isReordering = false;
              });
              _loadItems();
            }
          },
          child: Column(
            children: [
              _buildHeader(),
              _buildActionBar(),
              if (_showPreview && _section != null)
                Container(
                  height: 300,
                  padding: const EdgeInsets.all(16),
                  child: SectionPreviewWidget(
                    section: _section!,
                    items: _getCurrentItems(), // استخراج العناصر من state
                    isExpanded: false,
                    onExpand: () => _showFullPreview(),
                  ),
                ),
              Expanded(
                child: BlocBuilder<SectionItemsBloc, SectionItemsState>(
                  builder: (context, state) {
                    if (state is SectionItemsLoading) {
                      return const LoadingWidget(
                        type: LoadingType.futuristic,
                        message: 'جاري تحميل العناصر...',
                      );
                    }

                    if (state is SectionItemsError) {
                      return CustomErrorWidget(
                        message: state.message,
                        onRetry: _loadItems,
                      );
                    }

                    if (state is SectionItemsLoaded) {
                      // حافظ على نسخة محلية لإعادة الترتيب
                      if (!_isReordering || _orderedItems.isEmpty) {
                        _orderedItems = List<dynamic>.from(state.page.items);
                      }
                      if (state.page.items.isEmpty) {
                        return EmptyWidget(
                          message: 'لا توجد عناصر في هذا القسم',
                          actionWidget: _buildAddButton(),
                        );
                      }

                      return SectionItemsList(
                        items: _isReordering ? _orderedItems : state.page.items,
                        target: widget.target,
                        isReordering: _isReordering,
                        onReorder: _handleReorder,
                        onRemove: _handleRemove,
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

// إضافة method للحصول على العناصر الحالية
  List<dynamic> _getCurrentItems() {
    final state = context.read<SectionItemsBloc>().state;
    if (state is SectionItemsLoaded) {
      return state.page.items;
    }
    return [];
  }

// إضافة method لعرض المعاينة الكاملة
  void _showFullPreview() {
    if (_section == null) return;

    showDialog(
      fullscreenDialog: true,
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(10),
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'معاينة القسم الكاملة',
                      style: AppTextStyles.heading2.copyWith(
                        color: AppTheme.textWhite,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        CupertinoIcons.xmark_circle_fill,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SectionPreviewWidget(
                    section: _section!,
                    items: _getCurrentItems(),
                    isExpanded: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withValues(alpha: 0.7),
            AppTheme.darkCard.withValues(alpha: 0.3),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
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
                    AppTheme.darkSurface.withValues(alpha: 0.5),
                    AppTheme.darkSurface.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.darkBorder.withValues(alpha: 0.3),
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
                    'إدارة عناصر القسم',
                    style: AppTextStyles.heading2.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.target == SectionTarget.properties
                      ? 'العقارات في القسم'
                      : 'الوحدات في القسم',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isPrimary ? AppTheme.primaryGradient : null,
          color: isPrimary ? null : AppTheme.darkCard.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPrimary
                ? Colors.transparent
                : AppTheme.darkBorder.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isPrimary ? Colors.white : AppTheme.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isPrimary ? Colors.white : AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return ElevatedButton.icon(
      onPressed: _showAddItemsDialog,
      icon: const Icon(CupertinoIcons.plus),
      label: const Text('إضافة عناصر'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _showAddItemsDialog,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(
          CupertinoIcons.plus,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  void _showAddItemsDialog() {
    final bloc = context.read<SectionItemsBloc>();
    showDialog(
      fullscreenDialog: true,
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: bloc,
        child: AddItemsDialog(
          sectionId: widget.sectionId,
          target: widget.target,
        ),
      ),
    );
  }

  void _handleReorder(int oldIndex, int newIndex) {
    if (_orderedItems.isEmpty) return;
    if (oldIndex < 0 || oldIndex >= _orderedItems.length) return;
    if (newIndex < 0 || newIndex >= _orderedItems.length) return;

    setState(() {
      if (oldIndex < newIndex) newIndex -= 1;
      final item = _orderedItems.removeAt(oldIndex);
      _orderedItems.insert(newIndex, item);
    });
  }

  void _handleRemove(String itemId) {
    context.read<SectionItemsBloc>().add(
          RemoveItemsFromSectionEvent(
            sectionId: widget.sectionId,
            itemIds: [itemId],
          ),
        );
  }

  void _saveOrder() {
    if (_orderedItems.isEmpty) return;
    final orders = <ItemOrderDto>[];
    for (var i = 0; i < _orderedItems.length; i++) {
      final item = _orderedItems[i];
      final itemId = (item as dynamic).id?.toString() ?? '';
      if (itemId.isEmpty) continue;
      orders.add(ItemOrderDto(itemId: itemId, sortOrder: i + 1));
    }

    if (orders.isEmpty) return;

    context.read<SectionItemsBloc>().add(
          ReorderSectionItemsEvent(
            sectionId: widget.sectionId,
            orders: orders,
          ),
        );
  }
}

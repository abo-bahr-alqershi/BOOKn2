import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import 'dart:async';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/enums/section_target.dart';
import 'package:bookn_cp_app/injection_container.dart' as di;
import '../../../helpers/domain/entities/search_result.dart';
import '../../../helpers/domain/usecases/search_properties_usecase.dart';
import '../../../helpers/domain/usecases/search_units_usecase.dart';
import '../../../helpers/presentation/widgets/search_item_card.dart';
import '../bloc/section_items/section_items_bloc.dart';
import '../bloc/section_items/section_items_event.dart';

class AddItemsDialog extends StatefulWidget {
  final String sectionId;
  final SectionTarget target;
  final VoidCallback? onItemsAdded;

  const AddItemsDialog({
    super.key,
    required this.sectionId,
    required this.target,
    this.onItemsAdded,
  });

  @override
  State<AddItemsDialog> createState() => _AddItemsDialogState();
}

class _AddItemsDialogState extends State<AddItemsDialog> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<String> _selectedIds = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasError = false;
  String? _errorMessage;
  Timer? _debounce;

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;

  // Data
  List<SearchResult> _items = [];

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadItems();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _currentPage < _totalPages) {
        _loadMoreItems();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(10),
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.darkBorder.withValues(alpha: 0.3),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              children: [
                _buildHeader(),
                _buildSearchBar(),
                Expanded(
                  child: _buildItemsList(),
                ),
                _buildFooter(),
              ],
            ),
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
            color: AppTheme.darkBorder.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppTheme.primaryGradient.createShader(bounds),
                  child: Text(
                    widget.target == SectionTarget.properties
                        ? 'إضافة عقارات'
                        : 'إضافة وحدات',
                    style: AppTextStyles.heading3.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'اختر العناصر المطلوب إضافتها للقسم',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              CupertinoIcons.xmark_circle_fill,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.darkBackground.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.darkBorder.withValues(alpha: 0.3),
          ),
        ),
        child: TextField(
          controller: _searchController,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
          ),
          decoration: InputDecoration(
            hintText: 'بحث...',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted,
            ),
            prefixIcon: Icon(
              CupertinoIcons.search,
              color: AppTheme.textMuted,
              size: 20,
            ),
            border: InputBorder.none,
          ),
          onChanged: (value) {
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 450), () {
              if (value == _searchController.text) {
                _loadItems(isRefresh: true);
              }
            });
          },
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    if (_isLoading && _items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage ?? 'حدث خطأ أثناء التحميل',
              style:
                  AppTextStyles.bodyMedium.copyWith(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _loadItems(isRefresh: true),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Text(
          'لا توجد نتائج',
          style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textMuted),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _items.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _items.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final item = _items[index];
        final isSelected = _selectedIds.contains(item.id);

        return SearchItemCard(
          item: item,
          isSelected: isSelected,
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedIds.remove(item.id);
              } else {
                _selectedIds.add(item.id);
              }
            });
          },
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withValues(alpha: 0.7),
            AppTheme.darkCard.withValues(alpha: 0.5),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: AppTheme.darkBorder.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          if (_selectedIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                '${_selectedIds.length} محدد',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'إلغاء',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _selectedIds.isEmpty ? null : _addItems,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient:
                    _selectedIds.isEmpty ? null : AppTheme.primaryGradient,
                color: _selectedIds.isEmpty
                    ? AppTheme.darkSurface.withValues(alpha: 0.5)
                    : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'إضافة',
                      style: AppTextStyles.buttonMedium.copyWith(
                        color: _selectedIds.isEmpty
                            ? AppTheme.textMuted
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _addItems() {
    setState(() => _isLoading = true);

    if (widget.target == SectionTarget.properties) {
      context.read<SectionItemsBloc>().add(
            AddItemsToSectionEvent(
              sectionId: widget.sectionId,
              propertyIds: _selectedIds,
            ),
          );
    } else {
      context.read<SectionItemsBloc>().add(
            AddItemsToSectionEvent(
              sectionId: widget.sectionId,
              unitIds: _selectedIds,
            ),
          );
    }

    // Close dialog after a short delay to allow BlocListener to react
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _loadItems({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 1;
      _items.clear();
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    if (widget.target == SectionTarget.properties) {
      final usecase = di.sl<SearchPropertiesUseCase>();
      final result = await usecase(
        searchTerm:
            _searchController.text.isEmpty ? null : _searchController.text,
        pageNumber: _currentPage,
        pageSize: 20,
      );
      result.fold((failure) {
        setState(() {
          _hasError = true;
          _errorMessage = failure.message;
          _isLoading = false;
        });
      }, (page) {
        setState(() {
          _items = page.items;
          _totalPages = page.totalPages;
          _isLoading = false;
        });
      });
    } else {
      final usecase = di.sl<SearchUnitsUseCase>();
      final result = await usecase(
        searchTerm:
            _searchController.text.isEmpty ? null : _searchController.text,
        pageNumber: _currentPage,
        pageSize: 20,
      );
      result.fold((failure) {
        setState(() {
          _hasError = true;
          _errorMessage = failure.message;
          _isLoading = false;
        });
      }, (page) {
        setState(() {
          _items = page.items;
          _totalPages = page.totalPages;
          _isLoading = false;
        });
      });
    }
  }

  Future<void> _loadMoreItems() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    _currentPage++;

    if (widget.target == SectionTarget.properties) {
      final usecase = di.sl<SearchPropertiesUseCase>();
      final result = await usecase(
        searchTerm:
            _searchController.text.isEmpty ? null : _searchController.text,
        pageNumber: _currentPage,
        pageSize: 20,
      );
      result.fold((failure) {
        _currentPage--;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      }, (page) {
        setState(() {
          _items.addAll(page.items);
        });
      });
    } else {
      final usecase = di.sl<SearchUnitsUseCase>();
      final result = await usecase(
        searchTerm:
            _searchController.text.isEmpty ? null : _searchController.text,
        pageNumber: _currentPage,
        pageSize: 20,
      );
      result.fold((failure) {
        _currentPage--;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      }, (page) {
        setState(() {
          _items.addAll(page.items);
        });
      });
    }

    setState(() => _isLoadingMore = false);
  }
}

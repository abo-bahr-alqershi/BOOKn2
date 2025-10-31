import 'package:flutter/material.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/empty_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../admin_properties/domain/entities/property.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/usecases/search_properties_usecase.dart';
import 'package:bookn_cp_app/injection_container.dart' as di;
import '../widgets/search_header.dart';
import '../widgets/search_item_card.dart';
import '../widgets/simple_filter_bar.dart';

class PropertySearchPage extends StatefulWidget {
  final String? initialSearchTerm;
  final bool allowMultiSelect;
  final Function(List<Property>)? onPropertiesSelected;
  final Function(Property)? onPropertySelected;

  const PropertySearchPage({
    super.key,
    this.initialSearchTerm,
    this.allowMultiSelect = false,
    this.onPropertiesSelected,
    this.onPropertySelected,
  });

  @override
  State<PropertySearchPage> createState() => _PropertySearchPageState();
}

class _PropertySearchPageState extends State<PropertySearchPage> {
  final SearchPropertiesUseCase _searchPropertiesUseCase =
      di.sl<SearchPropertiesUseCase>();

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<SearchResult> _properties = [];
  List<String> _selectedIds = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  String? _selectedCity;
  bool? _isApprovedFilter;

  int _currentPage = 1;
  int _pageSize = 20;
  bool _hasMore = false;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialSearchTerm ?? '';
    _scrollController.addListener(_onScroll);
    _loadProperties();

    // Extra check after widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        debugPrint(
            '📖 Properties page fully built. Current page: $_currentPage, hasMore: $_hasMore');
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;

    // Trigger when near bottom (200px threshold)
    if (position.pixels >= position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMoreProperties();
      }
    }
  }

  // Check if we need to load more to fill the screen
  void _checkIfShouldLoadMore() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      final position = _scrollController.position;
      // If list doesn't fill screen (no scrollable area) or we're at bottom, load more
      if (_hasMore && !_isLoadingMore) {
        if (position.maxScrollExtent == 0 ||
            position.pixels >= position.maxScrollExtent - 50) {
          debugPrint(
              '🔄 Auto-loading more - maxScrollExtent: ${position.maxScrollExtent}');
          _loadMoreProperties();
        }
      }
    });
  }

  Future<void> _loadProperties({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 1;
      _properties.clear();
      _hasMore = false;
      _isLoadingMore = false;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final result = await _searchPropertiesUseCase(
      searchTerm:
          _searchController.text.isEmpty ? null : _searchController.text,
      city: _selectedCity,
      isApproved: _isApprovedFilter,
      pageNumber: _currentPage,
      pageSize: _pageSize,
    );

    result.fold(
      (failure) {
        setState(() {
          _hasError = true;
          _errorMessage = failure.message;
          _isLoading = false;
        });
      },
      (paginatedResult) {
        setState(() {
          _properties = List<SearchResult>.from(paginatedResult.items);
          _currentPage = paginatedResult.currentPage;
          _pageSize = paginatedResult.pageSize > 0
              ? paginatedResult.pageSize
              : _pageSize;
          _hasMore = _shouldLoadMore(paginatedResult);
          _isLoading = false;
        });

        // Check if we need to load more to fill the screen
        _checkIfShouldLoadMore();
      },
    );
  }

  Future<void> _loadMoreProperties() async {
    if (_isLoadingMore || !_hasMore || !mounted) return;

    setState(() {
      _isLoadingMore = true;
    });

    final nextPage = _currentPage + 1;

    final result = await _searchPropertiesUseCase(
      searchTerm:
          _searchController.text.isEmpty ? null : _searchController.text,
      city: _selectedCity,
      isApproved: _isApprovedFilter,
      pageNumber: nextPage,
      pageSize: _pageSize,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (paginatedResult) {
        setState(() {
          _properties.addAll(paginatedResult.items);
          final fetchedPage = paginatedResult.currentPage;
          _currentPage = fetchedPage > _currentPage ? fetchedPage : nextPage;
          _pageSize = paginatedResult.pageSize > 0
              ? paginatedResult.pageSize
              : _pageSize;
          _hasMore = _shouldLoadMore(paginatedResult);
          _isLoadingMore = false;
        });

        // Check if we need to load more to fill the screen
        _checkIfShouldLoadMore();
      },
    );
  }

  void _toggleSelection(String id) {
    setState(() {
      if (widget.allowMultiSelect) {
        if (_selectedIds.contains(id)) {
          _selectedIds.remove(id);
        } else {
          _selectedIds.add(id);
        }
      } else {
        _selectedIds = [id];
      }
    });
  }

  void _confirmSelection() {
    final selectedProperties = _properties
        .where((result) => _selectedIds.contains(result.id))
        .map((result) => result.item as Property)
        .toList();

    if (widget.allowMultiSelect && widget.onPropertiesSelected != null) {
      widget.onPropertiesSelected!(selectedProperties);
    } else if (!widget.allowMultiSelect &&
        widget.onPropertySelected != null &&
        selectedProperties.isNotEmpty) {
      widget.onPropertySelected!(selectedProperties.first);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Search
            SearchHeader(
              title: widget.allowMultiSelect ? 'اختر العقارات' : 'اختر عقار',
              searchHint: 'ابحث بالاسم أو المدينة...',
              searchController: _searchController,
              onSearchChanged: (value) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (value == _searchController.text) {
                    _loadProperties(isRefresh: true);
                  }
                });
              },
              onClearSearch: () {
                _loadProperties(isRefresh: true);
              },
            ),

            // Filters
            SimpleFilterBar(
              filters: [
                FilterOption(
                  label: 'الكل',
                  isSelected: _isApprovedFilter == null,
                  onChanged: (selected) {
                    if (selected) {
                      setState(() => _isApprovedFilter = null);
                      _loadProperties(isRefresh: true);
                    }
                  },
                ),
                FilterOption(
                  label: 'معتمد',
                  isSelected: _isApprovedFilter == true,
                  onChanged: (selected) {
                    setState(() => _isApprovedFilter = selected ? true : null);
                    _loadProperties(isRefresh: true);
                  },
                ),
                FilterOption(
                  label: 'قيد المراجعة',
                  isSelected: _isApprovedFilter == false,
                  onChanged: (selected) {
                    setState(() => _isApprovedFilter = selected ? false : null);
                    _loadProperties(isRefresh: true);
                  },
                ),
              ],
              onClearFilters: () {
                setState(() {
                  _selectedCity = null;
                  _isApprovedFilter = null;
                });
                _loadProperties(isRefresh: true);
              },
            ),

            // Results
            Expanded(
              child: _buildContent(),
            ),

            // Action Buttons
            if (_selectedIds.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard.withValues(alpha: 0.5),
                  border: Border(
                    top: BorderSide(
                      color: AppTheme.darkBorder.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'تم اختيار ${_selectedIds.length} ${_selectedIds.length == 1 ? 'عقار' : 'عقارات'}',
                        style: TextStyle(color: AppTheme.textWhite),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _selectedIds.clear()),
                      child: Text(
                        'إلغاء',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _confirmSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                      ),
                      child: const Text('تأكيد'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _properties.isEmpty) {
      return const LoadingWidget(
        message: 'جاري البحث عن العقارات...',
      );
    }

    if (_hasError) {
      return CustomErrorWidget(
        message: _errorMessage,
        onRetry: () => _loadProperties(isRefresh: true),
      );
    }

    if (_properties.isEmpty) {
      return const EmptyWidget(
        message: 'لا توجد نتائج',
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadProperties(isRefresh: true),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: _properties.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _properties.length) {
            return _buildLoadMoreIndicator();
          }

          final property = _properties[index];
          return SearchItemCard(
            item: property,
            isSelected: _selectedIds.contains(property.id),
            onTap: () => _toggleSelection(property.id),
          );
        },
      ),
    );
  }

  bool _shouldLoadMore(PaginatedResult<SearchResult> result) {
    if (result.hasNextPage) {
      return true;
    }

    final effectivePageSize = result.pageSize > 0 ? result.pageSize : _pageSize;
    return result.items.length >= effectivePageSize;
  }

  Widget _buildLoadMoreIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: LoadingWidget(
        message: 'جاري تحميل المزيد...',
      ),
    );
  }
}

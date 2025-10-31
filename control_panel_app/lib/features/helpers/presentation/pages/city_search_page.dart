import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/empty_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../admin_cities/domain/entities/city.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/usecases/search_cities_usecase.dart';
import 'package:bookn_cp_app/injection_container.dart' as di;
import '../widgets/search_header.dart';
import '../widgets/search_item_card.dart';
import '../widgets/simple_filter_bar.dart';

class CitySearchPage extends StatefulWidget {
  final String? initialSearchTerm;
  final String? country;
  final bool allowMultiSelect;
  final Function(List<City>)? onCitiesSelected;
  final Function(City)? onCitySelected;

  const CitySearchPage({
    super.key,
    this.initialSearchTerm,
    this.country,
    this.allowMultiSelect = false,
    this.onCitiesSelected,
    this.onCitySelected,
  });

  @override
  State<CitySearchPage> createState() => _CitySearchPageState();
}

class _CitySearchPageState extends State<CitySearchPage> {
  final SearchCitiesUseCase _searchCitiesUseCase = di.sl<SearchCitiesUseCase>();
  
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<SearchResult> _cities = [];
  List<String> _selectedIds = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  
  String? _selectedCountry;
  
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialSearchTerm ?? '';
    _selectedCountry = widget.country;
    _scrollController.addListener(_onScroll);
    _loadCities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _currentPage < _totalPages) {
        _loadMoreCities();
      }
    }
  }

  Future<void> _loadCities({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 1;
      _cities.clear();
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final result = await _searchCitiesUseCase(
      searchTerm: _searchController.text.isEmpty ? null : _searchController.text,
      country: _selectedCountry,
      pageNumber: _currentPage,
      pageSize: 20,
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
          _cities = paginatedResult.items;
          _totalPages = paginatedResult.totalPages;
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _loadMoreCities() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    _currentPage++;
    
    final result = await _searchCitiesUseCase(
      searchTerm: _searchController.text.isEmpty ? null : _searchController.text,
      country: _selectedCountry,
      pageNumber: _currentPage,
      pageSize: 20,
    );

    result.fold(
      (failure) {
        _currentPage--;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (paginatedResult) {
        setState(() {
          _cities.addAll(paginatedResult.items);
        });
      },
    );

    setState(() {
      _isLoadingMore = false;
    });
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
    final selectedCities = _cities
        .where((result) => _selectedIds.contains(result.id))
        .map((result) => result.item as City)
        .toList();

    if (widget.allowMultiSelect && widget.onCitiesSelected != null) {
      widget.onCitiesSelected!(selectedCities);
    } else if (!widget.allowMultiSelect && 
               widget.onCitySelected != null && 
               selectedCities.isNotEmpty) {
      widget.onCitySelected!(selectedCities.first);
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
              title: widget.allowMultiSelect ? 'اختر المدن' : 'اختر مدينة',
              searchHint: 'ابحث بالاسم...',
              searchController: _searchController,
              onSearchChanged: (value) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (value == _searchController.text) {
                    _loadCities(isRefresh: true);
                  }
                });
              },
              onClearSearch: () {
                _loadCities(isRefresh: true);
              },
            ),
            
            // Filters
            SimpleFilterBar(
              filters: [
                FilterOption(
                  label: 'الكل',
                  isSelected: _selectedCountry == null,
                  onChanged: (selected) {
                    if (selected) {
                      setState(() => _selectedCountry = null);
                      _loadCities(isRefresh: true);
                    }
                  },
                ),
                FilterOption(
                  label: 'اليمن',
                  isSelected: _selectedCountry == 'Yemen',
                  onChanged: (selected) {
                    setState(() => _selectedCountry = selected ? 'Yemen' : null);
                    _loadCities(isRefresh: true);
                  },
                ),
                FilterOption(
                  label: 'السعودية',
                  isSelected: _selectedCountry == 'Saudi Arabia',
                  onChanged: (selected) {
                    setState(() => _selectedCountry = selected ? 'Saudi Arabia' : null);
                    _loadCities(isRefresh: true);
                  },
                ),
              ],
              onClearFilters: () {
                setState(() {
                  _selectedCountry = null;
                });
                _loadCities(isRefresh: true);
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
                  color: AppTheme.darkCard.withOpacity(0.5),
                  border: Border(
                    top: BorderSide(
                      color: AppTheme.darkBorder.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'تم اختيار ${_selectedIds.length} ${_selectedIds.length == 1 ? 'مدينة' : 'مدن'}',
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
    if (_isLoading && _cities.isEmpty) {
      return const LoadingWidget(
        message: 'جاري البحث عن المدن...',
      );
    }

    if (_hasError) {
      return CustomErrorWidget(
        message: _errorMessage,
        onRetry: () => _loadCities(isRefresh: true),
      );
    }

    if (_cities.isEmpty) {
      return const EmptyWidget(
        message: 'لا توجد نتائج',
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadCities(isRefresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: _cities.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _cities.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final city = _cities[index];
          return SearchItemCard(
            item: city,
            isSelected: _selectedIds.contains(city.id),
            onTap: () => _toggleSelection(city.id),
          );
        },
      ),
    );
  }
}
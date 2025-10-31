import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/empty_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/usecases/search_bookings_usecase.dart';
import 'package:bookn_cp_app/injection_container.dart' as di;
import '../widgets/search_header.dart';
import '../widgets/search_item_card.dart';
import '../widgets/simple_filter_bar.dart';

class BookingSearchPage extends StatefulWidget {
  final String? initialSearchTerm;
  final String? userId;
  final String? unitId;
  final bool allowMultiSelect;
  final Function(List<Map<String, dynamic>>)? onBookingsSelected;
  final Function(Map<String, dynamic>)? onBookingSelected;

  const BookingSearchPage({
    super.key,
    this.initialSearchTerm,
    this.userId,
    this.unitId,
    this.allowMultiSelect = false,
    this.onBookingsSelected,
    this.onBookingSelected,
  });

  @override
  State<BookingSearchPage> createState() => _BookingSearchPageState();
}

class _BookingSearchPageState extends State<BookingSearchPage> {
  final SearchBookingsUseCase _searchBookingsUseCase = di.sl<SearchBookingsUseCase>();
  
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<SearchResult> _bookings = [];
  List<String> _selectedIds = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  
  String? _statusFilter;
  DateTime? _startDate;
  DateTime? _endDate;
  
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialSearchTerm ?? '';
    _scrollController.addListener(_onScroll);
    _loadBookings();
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
        _loadMoreBookings();
      }
    }
  }

  Future<void> _loadBookings({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 1;
      _bookings.clear();
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final result = await _searchBookingsUseCase(
      searchTerm: _searchController.text.isEmpty ? null : _searchController.text,
      userId: widget.userId,
      unitId: widget.unitId,
      status: _statusFilter,
      startDate: _startDate,
      endDate: _endDate,
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
          _bookings = paginatedResult.items;
          _totalPages = paginatedResult.totalPages;
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _loadMoreBookings() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    _currentPage++;
    
    final result = await _searchBookingsUseCase(
      searchTerm: _searchController.text.isEmpty ? null : _searchController.text,
      userId: widget.userId,
      unitId: widget.unitId,
      status: _statusFilter,
      startDate: _startDate,
      endDate: _endDate,
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
          _bookings.addAll(paginatedResult.items);
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
    final selectedBookings = _bookings
        .where((result) => _selectedIds.contains(result.id))
        .map((result) => result.item as Map<String, dynamic>)
        .toList();

    if (widget.allowMultiSelect && widget.onBookingsSelected != null) {
      widget.onBookingsSelected!(selectedBookings);
    } else if (!widget.allowMultiSelect && 
               widget.onBookingSelected != null && 
               selectedBookings.isNotEmpty) {
      widget.onBookingSelected!(selectedBookings.first);
    }

    Navigator.of(context).pop();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryBlue,
              surface: AppTheme.darkCard,
            ),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      setState(() {
        _startDate = result.start;
        _endDate = result.end;
      });
      _loadBookings(isRefresh: true);
    }
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
              title: widget.allowMultiSelect ? 'اختر الحجوزات' : 'اختر حجز',
              searchHint: 'ابحث باسم الضيف أو البريد الإلكتروني...',
              searchController: _searchController,
              onSearchChanged: (value) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (value == _searchController.text) {
                    _loadBookings(isRefresh: true);
                  }
                });
              },
              onClearSearch: () {
                _loadBookings(isRefresh: true);
              },
            ),
            
            // Date Range Selector
            if (_startDate != null || _endDate != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.date_range_rounded,
                      color: AppTheme.primaryBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _startDate != null && _endDate != null
                            ? '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}'
                            : 'اختر نطاق التواريخ',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppTheme.textWhite,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.clear_rounded,
                        color: AppTheme.textMuted,
                        size: 18,
                      ),
                      onPressed: () {
                        setState(() {
                          _startDate = null;
                          _endDate = null;
                        });
                        _loadBookings(isRefresh: true);
                      },
                    ),
                  ],
                ),
              ),
            
            // Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Date Range Button
                  GestureDetector(
                    onTap: _selectDateRange,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: (_startDate != null || _endDate != null)
                            ? AppTheme.primaryBlue.withOpacity(0.2)
                            : AppTheme.darkSurface.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: (_startDate != null || _endDate != null)
                              ? AppTheme.primaryBlue.withOpacity(0.5)
                              : AppTheme.darkBorder.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: (_startDate != null || _endDate != null)
                                ? AppTheme.primaryBlue
                                : AppTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'التاريخ',
                            style: AppTextStyles.caption.copyWith(
                              color: (_startDate != null || _endDate != null)
                                  ? AppTheme.primaryBlue
                                  : AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status Filters
                  ..._buildStatusFilters(),
                ],
              ),
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
                        'تم اختيار ${_selectedIds.length} ${_selectedIds.length == 1 ? 'حجز' : 'حجوزات'}',
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

  List<Widget> _buildStatusFilters() {
    final statuses = [
      {'value': null, 'label': 'الكل'},
      {'value': 'Pending', 'label': 'معلق'},
      {'value': 'Confirmed', 'label': 'مؤكد'},
      {'value': 'Cancelled', 'label': 'ملغي'},
      {'value': 'Completed', 'label': 'مكتمل'},
    ];

    return statuses.map((status) {
      final isSelected = _statusFilter == status['value'];
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(status['label'] as String),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _statusFilter = selected ? status['value'] as String? : null;
            });
            _loadBookings(isRefresh: true);
          },
          backgroundColor: AppTheme.darkSurface.withOpacity(0.3),
          selectedColor: AppTheme.primaryBlue.withOpacity(0.2),
          labelStyle: AppTextStyles.caption.copyWith(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.textMuted,
          ),
          side: BorderSide(
            color: isSelected
                ? AppTheme.primaryBlue.withOpacity(0.5)
                : AppTheme.darkBorder.withOpacity(0.3),
            width: 1,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildContent() {
    if (_isLoading && _bookings.isEmpty) {
      return const LoadingWidget(
        message: 'جاري البحث عن الحجوزات...',
      );
    }

    if (_hasError) {
      return CustomErrorWidget(
        message: _errorMessage,
        onRetry: () => _loadBookings(isRefresh: true),
      );
    }

    if (_bookings.isEmpty) {
      return const EmptyWidget(
        message: 'لا توجد نتائج',
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadBookings(isRefresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: _bookings.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _bookings.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final booking = _bookings[index];
          return SearchItemCard(
            item: booking,
            isSelected: _selectedIds.contains(booking.id),
            onTap: () => _toggleSelection(booking.id),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
import 'package:flutter/material.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/empty_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../admin_users/domain/entities/user.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/usecases/search_users_usecase.dart';
import 'package:bookn_cp_app/injection_container.dart' as di;
import '../widgets/search_header.dart';
import '../widgets/search_item_card.dart';
import '../widgets/simple_filter_bar.dart';

class UserSearchPage extends StatefulWidget {
  final String? initialSearchTerm;
  final bool allowMultiSelect;
  final Function(List<User>)? onUsersSelected;
  final Function(User)? onUserSelected;

  const UserSearchPage({
    super.key,
    this.initialSearchTerm,
    this.allowMultiSelect = false,
    this.onUsersSelected,
    this.onUserSelected,
  });

  @override
  State<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final SearchUsersUseCase _searchUsersUseCase = di.sl<SearchUsersUseCase>();
  
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<SearchResult> _users = [];
  List<String> _selectedIds = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  
  String? _selectedRole;
  bool? _isActiveFilter;
  
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialSearchTerm ?? '';
    _scrollController.addListener(_onScroll);
    _loadUsers();
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
        _loadMoreUsers();
      }
    }
  }

  Future<void> _loadUsers({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 1;
      _users.clear();
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final result = await _searchUsersUseCase(
      searchTerm: _searchController.text.isEmpty ? null : _searchController.text,
      role: _selectedRole,
      isActive: _isActiveFilter,
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
          _users = paginatedResult.items;
          _totalPages = paginatedResult.totalPages;
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _loadMoreUsers() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    _currentPage++;
    
    final result = await _searchUsersUseCase(
      searchTerm: _searchController.text.isEmpty ? null : _searchController.text,
      role: _selectedRole,
      isActive: _isActiveFilter,
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
          _users.addAll(paginatedResult.items);
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
    final selectedUsers = _users
        .where((result) => _selectedIds.contains(result.id))
        .map((result) => result.item as User)
        .toList();

    if (widget.allowMultiSelect && widget.onUsersSelected != null) {
      widget.onUsersSelected!(selectedUsers);
    } else if (!widget.allowMultiSelect && 
               widget.onUserSelected != null && 
               selectedUsers.isNotEmpty) {
      widget.onUserSelected!(selectedUsers.first);
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
              title: widget.allowMultiSelect ? 'اختر المستخدمين' : 'اختر مستخدم',
              searchHint: 'ابحث بالاسم أو البريد الإلكتروني...',
              searchController: _searchController,
              onSearchChanged: (value) {
                // Debounce search
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (value == _searchController.text) {
                    _loadUsers(isRefresh: true);
                  }
                });
              },
              onClearSearch: () {
                _loadUsers(isRefresh: true);
              },
            ),
            
            // Filters
            SimpleFilterBar(
              filters: [
                FilterOption(
                  label: 'الكل',
                  isSelected: _selectedRole == null,
                  onChanged: (selected) {
                    if (selected) {
                      setState(() => _selectedRole = null);
                      _loadUsers(isRefresh: true);
                    }
                  },
                ),
                FilterOption(
                  label: 'مدير',
                  isSelected: _selectedRole == 'admin',
                  onChanged: (selected) {
                    setState(() => _selectedRole = selected ? 'admin' : null);
                    _loadUsers(isRefresh: true);
                  },
                ),
                FilterOption(
                  label: 'عميل',
                  isSelected: _selectedRole == 'customer',
                  onChanged: (selected) {
                    setState(() => _selectedRole = selected ? 'customer' : null);
                    _loadUsers(isRefresh: true);
                  },
                ),
                FilterOption(
                  label: 'نشط',
                  isSelected: _isActiveFilter == true,
                  onChanged: (selected) {
                    setState(() => _isActiveFilter = selected ? true : null);
                    _loadUsers(isRefresh: true);
                  },
                ),
              ],
              onClearFilters: () {
                setState(() {
                  _selectedRole = null;
                  _isActiveFilter = null;
                });
                _loadUsers(isRefresh: true);
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
                        'تم اختيار ${_selectedIds.length} ${_selectedIds.length == 1 ? 'مستخدم' : 'مستخدمين'}',
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
                      child: Text('تأكيد',style: TextStyle(color: AppTheme.textWhite),),
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
    if (_isLoading && _users.isEmpty) {
      return const LoadingWidget(
        message: 'جاري البحث عن المستخدمين...',
      );
    }

    if (_hasError) {
      return CustomErrorWidget(
        message: _errorMessage,
        onRetry: () => _loadUsers(isRefresh: true),
      );
    }

    if (_users.isEmpty) {
      return const EmptyWidget(
        message: 'لا توجد نتائج',
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadUsers(isRefresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: _users.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _users.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final user = _users[index];
          return SearchItemCard(
            item: user,
            isSelected: _selectedIds.contains(user.id),
            onTap: () => _toggleSelection(user.id),
          );
        },
      ),
    );
  }
}
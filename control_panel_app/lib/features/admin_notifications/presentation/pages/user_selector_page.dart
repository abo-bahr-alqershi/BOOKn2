import 'package:flutter/material.dart';
import 'package:bookn_cp_app/features/helpers/presentation/widgets/simple_filter_bar.dart';
import 'package:bookn_cp_app/features/helpers/presentation/widgets/search_header.dart';
import 'package:bookn_cp_app/features/helpers/domain/usecases/search_users_usecase.dart';
import 'package:bookn_cp_app/features/helpers/domain/entities/search_result.dart';
import 'package:bookn_cp_app/features/admin_users/domain/entities/user.dart';
import 'package:bookn_cp_app/features/helpers/presentation/widgets/search_item_card.dart';
import 'package:bookn_cp_app/core/theme/app_theme.dart';
import 'package:bookn_cp_app/core/widgets/loading_widget.dart';
import 'package:bookn_cp_app/core/widgets/error_widget.dart';
import 'package:bookn_cp_app/core/widgets/empty_widget.dart';
import 'package:bookn_cp_app/injection_container.dart' as di;

class AdminUserSelectorPage extends StatefulWidget {
  final bool allowMultiSelect;
  final void Function(List<User>)? onUsersSelected;
  final void Function(User)? onUserSelected;
  final String? initialSearchTerm;
  final String? initialRole; // 'Owner' | 'Admin' | 'Staff' | 'Client'

  const AdminUserSelectorPage({
    super.key,
    this.allowMultiSelect = false,
    this.onUsersSelected,
    this.onUserSelected,
    this.initialSearchTerm,
    this.initialRole,
  });

  @override
  State<AdminUserSelectorPage> createState() => _AdminUserSelectorPageState();
}

class _AdminUserSelectorPageState extends State<AdminUserSelectorPage> {
  final SearchUsersUseCase _searchUsers = di.sl<SearchUsersUseCase>();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<SearchResult> _users = [];
  final List<String> _selectedIds = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  String? _roleName; // Admin, Owner, Client, Staff, Guest
  bool? _isActive;
  int _page = 1;
  int _totalPages = 1;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialSearchTerm ?? '';
    _roleName = _normalizeRole(widget.initialRole);
    _scrollController.addListener(_onScroll);
    _load();
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
      if (!_loadingMore && _page < _totalPages) _loadMore();
    }
  }

  String? _normalizeRole(String? role) {
    if (role == null) return null;
    final lower = role.toLowerCase();
    if (lower.contains('admin')) return 'Admin';
    if (lower.contains('owner')) return 'Owner';
    if (lower.contains('staff') || lower.contains('manager') || lower.contains('reception')) return 'Staff';
    if (lower.contains('client') || lower.contains('customer')) return 'Client';
    return role;
  }

  Future<void> _load({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _users.clear();
    }
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final res = await _searchUsers(
      searchTerm: _searchController.text.isEmpty ? null : _searchController.text,
      role: _roleName,
      isActive: _isActive,
      pageNumber: _page,
      pageSize: 20,
    );

    res.fold((f) {
      setState(() {
        _hasError = true;
        _errorMessage = f.message;
        _isLoading = false;
      });
    }, (p) {
      setState(() {
        _users = p.items;
        _totalPages = p.totalPages;
        _isLoading = false;
      });
    });
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    _page++;
    final res = await _searchUsers(
      searchTerm: _searchController.text.isEmpty ? null : _searchController.text,
      role: _roleName,
      isActive: _isActive,
      pageNumber: _page,
      pageSize: 20,
    );
    res.fold((f) {
      _page--;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message)));
    }, (p) {
      setState(() {
        _users.addAll(p.items);
      });
    });
    setState(() => _loadingMore = false);
  }

  void _toggle(String id) {
    setState(() {
      if (widget.allowMultiSelect) {
        if (_selectedIds.contains(id)) {
          _selectedIds.remove(id);
        } else {
          _selectedIds.add(id);
        }
      } else {
        _selectedIds
          ..clear()
          ..add(id);
      }
    });
  }

  void _confirm() {
    final selected = _users
        .where((u) => _selectedIds.contains(u.id))
        .map((u) => u.item as User)
        .toList();
    if (widget.allowMultiSelect) {
      widget.onUsersSelected?.call(selected);
    } else if (selected.isNotEmpty) {
      widget.onUserSelected?.call(selected.first);
    }
    Navigator.of(context).pop(selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            SearchHeader(
              title: widget.allowMultiSelect ? 'اختر المستخدمين' : 'اختر مستخدماً',
              searchHint: 'ابحث بالاسم أو البريد أو الهاتف...',
              searchController: _searchController,
              onSearchChanged: (v) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (v == _searchController.text) _load(refresh: true);
                });
              },
              onClearSearch: () => _load(refresh: true),
            ),
            SimpleFilterBar(
              filters: [
                FilterOption(
                  label: 'الكل',
                  isSelected: _roleName == null,
                  onChanged: (s) {
                    if (s) setState(() => _roleName = null);
                    _load(refresh: true);
                  },
                ),
                FilterOption(
                  label: 'Admin',
                  isSelected: _roleName == 'Admin',
                  onChanged: (s) {
                    setState(() => _roleName = s ? 'Admin' : null);
                    _load(refresh: true);
                  },
                ),
                FilterOption(
                  label: 'Owner',
                  isSelected: _roleName == 'Owner',
                  onChanged: (s) {
                    setState(() => _roleName = s ? 'Owner' : null);
                    _load(refresh: true);
                  },
                ),
                FilterOption(
                  label: 'Staff',
                isSelected: _roleName == 'Staff',
                  onChanged: (s) {
                    setState(() => _roleName = s ? 'Manager' : null);
                    _load(refresh: true);
                  },
                ),
                FilterOption(
                  label: 'Client',
                isSelected: _roleName == 'Client',
                  onChanged: (s) {
                    setState(() => _roleName = s ? 'Customer' : null);
                    _load(refresh: true);
                  },
                ),
                FilterOption(
                  label: 'نشط',
                  isSelected: _isActive == true,
                  onChanged: (s) {
                    setState(() => _isActive = s ? true : null);
                    _load(refresh: true);
                  },
                ),
              ],
              onClearFilters: () {
                setState(() {
                  _roleName = null;
                  _isActive = null;
                });
                _load(refresh: true);
              },
            ),
            Expanded(child: _buildContent()),
            if (_selectedIds.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard.withOpacity(0.5),
                  border: Border(
                    top: BorderSide(color: AppTheme.darkBorder.withOpacity(0.3)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'تم اختيار ${_selectedIds.length}',
                        style: TextStyle(color: AppTheme.textWhite),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _selectedIds.clear()),
                      child: Text('إلغاء', style: TextStyle(color: AppTheme.textMuted)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _confirm,
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                      child: Text('تأكيد', style: TextStyle(color: AppTheme.textWhite)),
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
      return const LoadingWidget(message: 'جاري تحميل المستخدمين...');
    }
    if (_hasError) {
      return CustomErrorWidget(message: _errorMessage, onRetry: () => _load(refresh: true));
    }
    if (_users.isEmpty) {
      return const EmptyWidget(message: 'لا توجد نتائج');
    }
    return RefreshIndicator(
      onRefresh: () => _load(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: _users.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _users.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final user = _users[index];
          return SearchItemCard(
            item: user,
            isSelected: _selectedIds.contains(user.id),
            onTap: () => _toggle(user.id),
          );
        },
      ),
    );
  }
}


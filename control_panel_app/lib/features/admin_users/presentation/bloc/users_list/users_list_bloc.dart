import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/models/paginated_result.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/usecases/get_all_users_usecase.dart';
import '../../../domain/usecases/create_user_usecase.dart';
import '../../../domain/usecases/update_user_usecase.dart';
import '../../../domain/usecases/assign_role_usecase.dart';
import '../../../domain/usecases/activate_user_usecase.dart';
import '../../../domain/usecases/deactivate_user_usecase.dart';

part 'users_list_event.dart';
part 'users_list_state.dart';

class UsersListBloc extends Bloc<UsersListEvent, UsersListState> {
  final GetAllUsersUseCase _getAllUsersUseCase;
  final CreateUserUseCase _createUserUseCase;
  final UpdateUserUseCase _updateUserUseCase;
  final AssignRoleUseCase _assignRoleUseCase;
  final ActivateUserUseCase _activateUserUseCase;
  final DeactivateUserUseCase _deactivateUserUseCase;

  static const int _pageSize = 20;
  List<User> _allUsers = [];
  int _currentPage = 1;
  bool _hasMoreData = true;
  String? _lastSearchTerm;
  String? _lastRoleFilter;
  bool? _lastActiveFilter;

  UsersListBloc({
    required GetAllUsersUseCase getAllUsersUseCase,
    required ActivateUserUseCase activateUserUseCase,
    required DeactivateUserUseCase deactivateUserUseCase,
    required CreateUserUseCase createUserUseCase,
    required UpdateUserUseCase updateUserUseCase,
    required AssignRoleUseCase assignRoleUseCase,
  })  : _getAllUsersUseCase = getAllUsersUseCase,
        _activateUserUseCase = activateUserUseCase,
        _deactivateUserUseCase = deactivateUserUseCase,
        _createUserUseCase = createUserUseCase,
        _updateUserUseCase = updateUserUseCase,
        _assignRoleUseCase = assignRoleUseCase,
        super(UsersListInitial()) {
    on<LoadUsersEvent>(_onLoadUsers);
    on<LoadMoreUsersEvent>(_onLoadMoreUsers);
    on<RefreshUsersEvent>(_onRefreshUsers);
    on<SearchUsersEvent>(_onSearchUsers);
    on<FilterUsersEvent>(_onFilterUsers);
    on<ToggleUserStatusEvent>(_onToggleUserStatus);
    on<SortUsersEvent>(_onSortUsers);
    on<CreateUserEvent>(_onCreateUser);
    on<UpdateUserEvent>(_onUpdateUser);
    on<DeleteUserEvent>(_onDeleteUser);
  }

  Future<void> _onLoadUsers(
    LoadUsersEvent event,
    Emitter<UsersListState> emit,
  ) async {
    emit(UsersListLoading());

    _currentPage = 1;
    _allUsers = [];
    _hasMoreData = true;

    final result = await _getAllUsersUseCase(
      GetAllUsersParams(
        pageNumber: _currentPage,
        pageSize: _pageSize,
      ),
    );

    result.fold(
      (failure) => emit(UsersListError(message: failure.message)),
      (paginatedResult) {
        _allUsers = paginatedResult.items;
        _hasMoreData = paginatedResult.pageNumber < paginatedResult.totalPages;

        emit(UsersListLoaded(
          users: _allUsers,
          hasMore: _hasMoreData,
          totalCount: paginatedResult.totalCount,
          stats: (paginatedResult.metadata is Map<String, dynamic>)
              ? (paginatedResult.metadata as Map<String, dynamic>)
              : null,
          isLoadingMore: false,
        ));
      },
    );
  }

  Future<void> _onUpdateUser(
    UpdateUserEvent event,
    Emitter<UsersListState> emit,
  ) async {
    // Emit loading state first
    emit(UsersListLoading());
    
    try {
      final result = await _updateUserUseCase(UpdateUserParams(
        userId: event.userId,
        name: event.name,
        email: event.email,
        phone: event.phone,
        profileImage: event.profileImage,
      ));

      await result.fold(
        (failure) async {
          emit(UsersListError(message: failure.message));
        },
        (success) async {
          if (success) {
            // محاولة تخصيص الدور إذا تم توفيره
            bool assignRoleSuccess = true;
            String? assignRoleError;

            if (event.roleId != null && event.roleId!.isNotEmpty) {
              final assignResult = await _assignRoleUseCase(
                AssignRoleParams(userId: event.userId, roleId: event.roleId!),
              );

              assignResult.fold(
                (failure) {
                  assignRoleSuccess = false;
                  assignRoleError = failure.message;
                },
                (result) {
                  assignRoleSuccess = result;
                },
              );
            }

            // إعادة تحميل القائمة بغض النظر عن نتيجة تخصيص الدور
            // لأن التحديث الأساسي نجح
            final reload = await _getAllUsersUseCase(
              GetAllUsersParams(
                pageNumber: 1,
                pageSize: _pageSize,
                searchTerm: _lastSearchTerm,
                roleId: _lastRoleFilter,
                isActive: _lastActiveFilter,
              ),
            );

            reload.fold(
              (failure) => emit(UsersListError(message: failure.message)),
              (paginatedResult) {
                _currentPage = 1;
                _allUsers = paginatedResult.items;
                _hasMoreData =
                    paginatedResult.pageNumber < paginatedResult.totalPages;

                // إصدار حالة نجاح العملية بدلاً من UsersListLoaded
                emit(UserOperationSuccess(
                  message: 'تم تحديث المستخدم بنجاح',
                  users: _allUsers,
                  hasMore: _hasMoreData,
                  totalCount: paginatedResult.totalCount,
                ));

                // إذا فشل تخصيص الدور، نعرض رسالة تحذير (اختياري)
                // لكن لا نفشل العملية بأكملها
                if (!assignRoleSuccess && assignRoleError != null) {
                  // يمكن إضافة لوق أو معالجة إضافية هنا إذا لزم الأمر
                  print(
                      'تحذير: تم تحديث المستخدم لكن فشل تخصيص الدور: $assignRoleError');
                }
              },
            );
          } else {
            emit(const UsersListError(message: 'فشل تحديث المستخدم'));
          }
        },
      );
    } catch (e) {
      emit(UsersListError(message: e.toString()));
    }
  }

  Future<void> _onLoadMoreUsers(
    LoadMoreUsersEvent event,
    Emitter<UsersListState> emit,
  ) async {
    if (state is! UsersListLoaded || !_hasMoreData) return;

    final currentState = state as UsersListLoaded;
    emit(currentState.copyWith(isLoadingMore: true));

    _currentPage++;

    final result = await _getAllUsersUseCase(
      GetAllUsersParams(
        pageNumber: _currentPage,
        pageSize: _pageSize,
        searchTerm: _lastSearchTerm,
        roleId: _lastRoleFilter,
        isActive: _lastActiveFilter,
      ),
    );

    result.fold(
      (failure) {
        _currentPage--;
        emit(currentState.copyWith(isLoadingMore: false));
      },
      (paginatedResult) {
        _allUsers.addAll(paginatedResult.items);
        _hasMoreData = paginatedResult.pageNumber < paginatedResult.totalPages;

        emit(UsersListLoaded(
          users: _allUsers,
          hasMore: _hasMoreData,
          totalCount: paginatedResult.totalCount,
          isLoadingMore: false,
        ));
      },
    );
  }

  Future<void> _onRefreshUsers(
    RefreshUsersEvent event,
    Emitter<UsersListState> emit,
  ) async {
    if (state is UsersListLoaded) {
      final current = state as UsersListLoaded;
      emit(UsersRefreshing(users: current.users, totalCount: current.totalCount));

      _currentPage = 1;
      _allUsers = [];
      _hasMoreData = true;

      final result = await _getAllUsersUseCase(
        GetAllUsersParams(
          pageNumber: _currentPage,
          pageSize: _pageSize,
          searchTerm: _lastSearchTerm,
          roleId: _lastRoleFilter,
          isActive: _lastActiveFilter,
        ),
      );

      result.fold(
        (failure) => emit(UsersListError(message: failure.message)),
        (paginatedResult) {
          _allUsers = paginatedResult.items;
          _hasMoreData = paginatedResult.pageNumber < paginatedResult.totalPages;

          emit(UsersListLoaded(
            users: _allUsers,
            hasMore: _hasMoreData,
            totalCount: paginatedResult.totalCount,
            isLoadingMore: false,
          ));
        },
      );
    }
  }

  Future<void> _onSearchUsers(
    SearchUsersEvent event,
    Emitter<UsersListState> emit,
  ) async {
    emit(UsersListLoading());

    _currentPage = 1;
    _allUsers = [];
    _hasMoreData = true;
    _lastSearchTerm = event.searchTerm;

    final result = await _getAllUsersUseCase(
      GetAllUsersParams(
        pageNumber: _currentPage,
        pageSize: _pageSize,
        searchTerm: event.searchTerm,
        roleId: _lastRoleFilter,
        isActive: _lastActiveFilter,
      ),
    );

    result.fold(
      (failure) => emit(UsersListError(message: failure.message)),
      (paginatedResult) {
        _allUsers = paginatedResult.items;
        _hasMoreData = paginatedResult.pageNumber < paginatedResult.totalPages;

        emit(UsersListLoaded(
          users: _allUsers,
          hasMore: _hasMoreData,
          totalCount: paginatedResult.totalCount,
          isLoadingMore: false,
        ));
      },
    );
  }

  Future<void> _onFilterUsers(
    FilterUsersEvent event,
    Emitter<UsersListState> emit,
  ) async {
    emit(UsersListLoading());

    _currentPage = 1;
    _allUsers = [];
    _hasMoreData = true;
    _lastRoleFilter = event.roleId;
    _lastActiveFilter = event.isActive;

    final result = await _getAllUsersUseCase(
      GetAllUsersParams(
        pageNumber: _currentPage,
        pageSize: _pageSize,
        searchTerm: _lastSearchTerm,
        roleId: event.roleId,
        isActive: event.isActive,
        createdAfter: event.createdAfter,
        createdBefore: event.createdBefore,
      ),
    );

    result.fold(
      (failure) => emit(UsersListError(message: failure.message)),
      (paginatedResult) {
        _allUsers = paginatedResult.items;
        _hasMoreData = paginatedResult.pageNumber < paginatedResult.totalPages;

        emit(UsersListLoaded(
          users: _allUsers,
          hasMore: _hasMoreData,
          totalCount: paginatedResult.totalCount,
          isLoadingMore: false,
        ));
      },
    );
  }

  Future<void> _onToggleUserStatus(
    ToggleUserStatusEvent event,
    Emitter<UsersListState> emit,
  ) async {
    if (state is! UsersListLoaded) return;

    final currentState = state as UsersListLoaded;

    final result = event.activate
        ? await _activateUserUseCase(ActivateUserParams(userId: event.userId))
        : await _deactivateUserUseCase(
            DeactivateUserParams(userId: event.userId));

    result.fold(
      (failure) {
        // Show error but keep current state
      },
      (success) {
        if (success) {
          // Update user status in the list
          final updatedUsers = _allUsers.map((user) {
            if (user.id == event.userId) {
              return user.copyWith(isActive: event.activate);
            }
            return user;
          }).toList();

          _allUsers = updatedUsers;

          emit(UsersListLoaded(
            users: _allUsers,
            hasMore: _hasMoreData,
            totalCount: currentState.totalCount,
            isLoadingMore: false,
          ));
        }
      },
    );
  }

  Future<void> _onSortUsers(
    SortUsersEvent event,
    Emitter<UsersListState> emit,
  ) async {
    emit(UsersListLoading());

    _currentPage = 1;
    _allUsers = [];
    _hasMoreData = true;

    final result = await _getAllUsersUseCase(
      GetAllUsersParams(
        pageNumber: _currentPage,
        pageSize: _pageSize,
        searchTerm: _lastSearchTerm,
        roleId: _lastRoleFilter,
        isActive: _lastActiveFilter,
        sortBy: event.sortBy,
        isAscending: event.isAscending,
      ),
    );

    result.fold(
      (failure) => emit(UsersListError(message: failure.message)),
      (paginatedResult) {
        _allUsers = paginatedResult.items;
        _hasMoreData = paginatedResult.pageNumber < paginatedResult.totalPages;

        emit(UsersListLoaded(
          users: _allUsers,
          hasMore: _hasMoreData,
          totalCount: paginatedResult.totalCount,
          isLoadingMore: false,
        ));
      },
    );
  }

  Future<void> _onCreateUser(
    CreateUserEvent event,
    Emitter<UsersListState> emit,
  ) async {
    try {
      // Emit loading state first
      emit(UsersListLoading());
      
      // Create user then reload and emit state to notify listeners
      final result = await _createUserUseCase(CreateUserParams(
        name: event.name,
        email: event.email,
        password: event.password,
        phone: event.phone,
        profileImage: event.profileImage,
      ));

      await result.fold(
        (failure) async {
          emit(UsersListError(message: failure.message));
        },
        (userId) async {
          // محاولة تخصيص الدور إذا تم توفيره
          bool assignRoleSuccess = true;
          String? assignRoleError;

          if (event.roleId != null && event.roleId!.isNotEmpty) {
            final assignResult = await _assignRoleUseCase(
              AssignRoleParams(userId: userId, roleId: event.roleId!),
            );

            assignResult.fold(
              (failure) {
                assignRoleSuccess = false;
                assignRoleError = failure.message;
              },
              (result) {
                assignRoleSuccess = result;
              },
            );
          }

          // إعادة تحميل القائمة بغض النظر عن نتيجة تخصيص الدور
          final reload = await _getAllUsersUseCase(
            GetAllUsersParams(
              pageNumber: 1,
              pageSize: _pageSize,
              searchTerm: _lastSearchTerm,
              roleId: _lastRoleFilter,
              isActive: _lastActiveFilter,
            ),
          );
          reload.fold(
            (failure) => emit(UsersListError(message: failure.message)),
            (paginatedResult) {
              _currentPage = 1;
              _allUsers = paginatedResult.items;
              _hasMoreData =
                  paginatedResult.pageNumber < paginatedResult.totalPages;

              // إصدار حالة نجاح العملية بدلاً من UsersListLoaded
              emit(UserOperationSuccess(
                message: 'تم إنشاء المستخدم بنجاح',
                users: _allUsers,
                hasMore: _hasMoreData,
                totalCount: paginatedResult.totalCount,
              ));

              // إذا فشل تخصيص الدور، نعرض رسالة تحذير (اختياري)
              if (!assignRoleSuccess && assignRoleError != null) {
                print(
                    'تحذير: تم إنشاء المستخدم لكن فشل تخصيص الدور: $assignRoleError');
              }
            },
          );
        },
      );
    } catch (e) {
      emit(UsersListError(message: e.toString()));
    }
  }

  Future<void> _onDeleteUser(
    DeleteUserEvent event,
    Emitter<UsersListState> emit,
  ) async {
    // Backend does not expose hard delete; emulate by deactivating and removing from current list
    final result = await _deactivateUserUseCase(
        DeactivateUserParams(userId: event.userId));

    result.fold(
      (_) {},
      (success) {
        if (success) {
          // Remove the user from the in-memory list and emit an updated state
          _allUsers = _allUsers.where((u) => u.id != event.userId).toList();
          if (state is UsersListLoaded) {
            final currentState = state as UsersListLoaded;
            emit(UsersListLoaded(
              users: _allUsers,
              hasMore: _hasMoreData,
              totalCount:
                  currentState.totalCount > 0 ? currentState.totalCount - 1 : 0,
              isLoadingMore: false,
            ));
          }
        }
      },
    );
  }
}

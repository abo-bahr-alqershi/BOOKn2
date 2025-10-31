import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/user_details.dart';
import '../../../domain/entities/user_lifetime_stats.dart';
import '../../../domain/usecases/get_user_details_usecase.dart';
import '../../../domain/usecases/get_user_lifetime_stats_usecase.dart';
import '../../../domain/usecases/update_user_usecase.dart';
import '../../../domain/usecases/activate_user_usecase.dart';
import '../../../domain/usecases/deactivate_user_usecase.dart';
import '../../../domain/usecases/assign_role_usecase.dart';

part 'user_details_event.dart';
part 'user_details_state.dart';

class UserDetailsBloc extends Bloc<UserDetailsEvent, UserDetailsState> {
  final GetUserDetailsUseCase _getUserDetailsUseCase;
  final GetUserLifetimeStatsUseCase _getUserLifetimeStatsUseCase;
  final UpdateUserUseCase _updateUserUseCase;
  final ActivateUserUseCase _activateUserUseCase;
  final DeactivateUserUseCase _deactivateUserUseCase;
  final AssignRoleUseCase _assignRoleUseCase;

  UserDetailsBloc({
    required GetUserDetailsUseCase getUserDetailsUseCase,
    required GetUserLifetimeStatsUseCase getUserLifetimeStatsUseCase,
    required UpdateUserUseCase updateUserUseCase,
    required ActivateUserUseCase activateUserUseCase,
    required DeactivateUserUseCase deactivateUserUseCase,
    required AssignRoleUseCase assignRoleUseCase,
  })  : _getUserDetailsUseCase = getUserDetailsUseCase,
        _getUserLifetimeStatsUseCase = getUserLifetimeStatsUseCase,
        _updateUserUseCase = updateUserUseCase,
        _activateUserUseCase = activateUserUseCase,
        _deactivateUserUseCase = deactivateUserUseCase,
        _assignRoleUseCase = assignRoleUseCase,
        super(UserDetailsInitial()) {
    on<LoadUserDetailsEvent>(_onLoadUserDetails);
    on<UpdateUserDetailsEvent>(_onUpdateUserDetails);
    on<ToggleUserStatusEvent>(_onToggleUserStatus);
    on<AssignUserRoleEvent>(_onAssignUserRole);
    on<DeleteUserEvent>(_onDeleteUser);
  }

  Future<void> _onLoadUserDetails(
    LoadUserDetailsEvent event,
    Emitter<UserDetailsState> emit,
  ) async {
    emit(UserDetailsLoading());

    final detailsResult = await _getUserDetailsUseCase(
      GetUserDetailsParams(userId: event.userId),
    );

    final statsResult = await _getUserLifetimeStatsUseCase(
      GetUserLifetimeStatsParams(userId: event.userId),
    );

    detailsResult.fold(
      (failure) => emit(UserDetailsError(message: failure.message)),
      (userDetails) {
        statsResult.fold(
          (failure) => emit(UserDetailsLoaded(
            userDetails: userDetails,
            lifetimeStats: null,
          )),
          (stats) => emit(UserDetailsLoaded(
            userDetails: userDetails,
            lifetimeStats: stats,
          )),
        );
      },
    );
  }

  Future<void> _onUpdateUserDetails(
    UpdateUserDetailsEvent event,
    Emitter<UserDetailsState> emit,
  ) async {
    if (state is! UserDetailsLoaded) return;

    final currentState = state as UserDetailsLoaded;
    emit(currentState.copyWith(isUpdating: true));

    final result = await _updateUserUseCase(
      UpdateUserParams(
        userId: event.userId,
        name: event.name,
        email: event.email,
        phone: event.phone,
        profileImage: event.profileImage,
      ),
    );

    result.fold(
      (failure) => emit(currentState.copyWith(
        isUpdating: false,
        updateError: failure.message,
      )),
      (success) async {
        if (success) {
          // Reload user details after update
          add(LoadUserDetailsEvent(userId: event.userId));
        } else {
          emit(currentState.copyWith(
            isUpdating: false,
            updateError: 'Failed to update user',
          ));
        }
      },
    );
  }

  Future<void> _onToggleUserStatus(
    ToggleUserStatusEvent event,
    Emitter<UserDetailsState> emit,
  ) async {
    if (state is! UserDetailsLoaded) return;

    final currentState = state as UserDetailsLoaded;
    emit(currentState.copyWith(isUpdating: true));

    final result = event.activate
        ? await _activateUserUseCase(ActivateUserParams(userId: event.userId))
        : await _deactivateUserUseCase(DeactivateUserParams(userId: event.userId));

    result.fold(
      (failure) => emit(currentState.copyWith(
        isUpdating: false,
        updateError: failure.message,
      )),
      (success) {
        if (success) {
          // Update local state
          final updatedDetails = UserDetails(
            id: currentState.userDetails.id,
            userName: currentState.userDetails.userName,
            avatarUrl: currentState.userDetails.avatarUrl,
            email: currentState.userDetails.email,
            phoneNumber: currentState.userDetails.phoneNumber,
            createdAt: currentState.userDetails.createdAt,
            isActive: event.activate,
            bookingsCount: currentState.userDetails.bookingsCount,
            canceledBookingsCount: currentState.userDetails.canceledBookingsCount,
            pendingBookingsCount: currentState.userDetails.pendingBookingsCount,
            firstBookingDate: currentState.userDetails.firstBookingDate,
            lastBookingDate: currentState.userDetails.lastBookingDate,
            reportsCreatedCount: currentState.userDetails.reportsCreatedCount,
            reportsAgainstCount: currentState.userDetails.reportsAgainstCount,
            totalPayments: currentState.userDetails.totalPayments,
            totalRefunds: currentState.userDetails.totalRefunds,
            reviewsCount: currentState.userDetails.reviewsCount,
            role: currentState.userDetails.role,
            propertyId: currentState.userDetails.propertyId,
            propertyName: currentState.userDetails.propertyName,
            unitsCount: currentState.userDetails.unitsCount,
            propertyImagesCount: currentState.userDetails.propertyImagesCount,
            unitImagesCount: currentState.userDetails.unitImagesCount,
            netRevenue: currentState.userDetails.netRevenue,
            repliesCount: currentState.userDetails.repliesCount,
          );

          emit(UserDetailsLoaded(
            userDetails: updatedDetails,
            lifetimeStats: currentState.lifetimeStats,
            isUpdating: false,
          ));
        } else {
          emit(currentState.copyWith(
            isUpdating: false,
            updateError: 'Failed to update user status',
          ));
        }
      },
    );
  }

  Future<void> _onAssignUserRole(
    AssignUserRoleEvent event,
    Emitter<UserDetailsState> emit,
  ) async {
    if (state is! UserDetailsLoaded) return;

    final currentState = state as UserDetailsLoaded;
    emit(currentState.copyWith(isUpdating: true));

    final result = await _assignRoleUseCase(
      AssignRoleParams(
        userId: event.userId,
        roleId: event.roleId,
      ),
    );

    result.fold(
      (failure) => emit(currentState.copyWith(
        isUpdating: false,
        updateError: failure.message,
      )),
      (success) async {
        if (success) {
          // Reload user details after role change
          add(LoadUserDetailsEvent(userId: event.userId));
        } else {
          emit(currentState.copyWith(
            isUpdating: false,
            updateError: 'Failed to assign role',
          ));
        }
      },
    );
  }

  Future<void> _onDeleteUser(
    DeleteUserEvent event,
    Emitter<UserDetailsState> emit,
  ) async {
    // Backend does not expose delete; emulate by deactivating
    await _deactivateUserUseCase(DeactivateUserParams(userId: event.userId));
  }
}
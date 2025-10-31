part of 'users_list_bloc.dart';

abstract class UsersListEvent extends Equatable {
  const UsersListEvent();

  @override
  List<Object?> get props => [];
}

class LoadUsersEvent extends UsersListEvent {}

class LoadMoreUsersEvent extends UsersListEvent {}

class RefreshUsersEvent extends UsersListEvent {}

class SearchUsersEvent extends UsersListEvent {
  final String searchTerm;

  const SearchUsersEvent({required this.searchTerm});

  @override
  List<Object> get props => [searchTerm];
}

class FilterUsersEvent extends UsersListEvent {
  final String? roleId;
  final bool? isActive;
  final DateTime? createdAfter;
  final DateTime? createdBefore;

  const FilterUsersEvent({
    this.roleId,
    this.isActive,
    this.createdAfter,
    this.createdBefore,
  });

  @override
  List<Object?> get props => [roleId, isActive, createdAfter, createdBefore];
}

class ToggleUserStatusEvent extends UsersListEvent {
  final String userId;
  final bool activate;

  const ToggleUserStatusEvent({
    required this.userId,
    required this.activate,
  });

  @override
  List<Object> get props => [userId, activate];
}

class SortUsersEvent extends UsersListEvent {
  final String sortBy;
  final bool isAscending;

  const SortUsersEvent({
    required this.sortBy,
    required this.isAscending,
  });

  @override
  List<Object> get props => [sortBy, isAscending];
}

class CreateUserEvent extends UsersListEvent {
  final String name;
  final String email;
  final String password;
  final String phone;
  final String? roleId;
  final String? profileImage;
  final bool emailConfirmed;
  final bool phoneNumberConfirmed;

  const CreateUserEvent({
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    this.roleId,
    this.profileImage,
    this.emailConfirmed = false,
    this.phoneNumberConfirmed = false,
  });

  @override
  List<Object?> get props => [name, email, password, phone, roleId, profileImage, emailConfirmed, phoneNumberConfirmed];
}

class UpdateUserEvent extends UsersListEvent {
  final String userId;
  final String? name;
  final String? email;
  final String? phone;
  final String? profileImage;
  final String? roleId;
  final bool? emailConfirmed;
  final bool? phoneNumberConfirmed;

  const UpdateUserEvent({
    required this.userId,
    this.name,
    this.email,
    this.phone,
    this.profileImage,
    this.roleId,
    this.emailConfirmed,
    this.phoneNumberConfirmed,
  });

  @override
  List<Object?> get props => [userId, name, email, phone, profileImage, roleId, emailConfirmed, phoneNumberConfirmed];
}


class DeleteUserEvent extends UsersListEvent {
  final String userId;

  const DeleteUserEvent(this.userId);

  @override
  List<Object> get props => [userId];
}

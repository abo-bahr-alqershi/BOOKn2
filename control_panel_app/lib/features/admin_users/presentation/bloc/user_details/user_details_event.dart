part of 'user_details_bloc.dart';

abstract class UserDetailsEvent extends Equatable {
  const UserDetailsEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserDetailsEvent extends UserDetailsEvent {
  final String userId;

  const LoadUserDetailsEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}

class UpdateUserDetailsEvent extends UserDetailsEvent {
  final String userId;
  final String? name;
  final String? email;
  final String? phone;
  final String? profileImage;

  const UpdateUserDetailsEvent({
    required this.userId,
    this.name,
    this.email,
    this.phone,
    this.profileImage,
  });

  @override
  List<Object?> get props => [userId, name, email, phone, profileImage];
}

class ToggleUserStatusEvent extends UserDetailsEvent {
  final String userId;
  final bool activate;

  const ToggleUserStatusEvent({
    required this.userId,
    required this.activate,
  });

  @override
  List<Object> get props => [userId, activate];
}

class AssignUserRoleEvent extends UserDetailsEvent {
  final String userId;
  final String roleId;

  const AssignUserRoleEvent({
    required this.userId,
    required this.roleId,
  });

  @override
  List<Object> get props => [userId, roleId];
}

class DeleteUserEvent extends UserDetailsEvent {
  final String userId;

  const DeleteUserEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}

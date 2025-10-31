part of 'user_details_bloc.dart';

abstract class UserDetailsState extends Equatable {
  const UserDetailsState();

  @override
  List<Object?> get props => [];
}

class UserDetailsInitial extends UserDetailsState {}

class UserDetailsLoading extends UserDetailsState {}

class UserDetailsLoaded extends UserDetailsState {
  final UserDetails userDetails;
  final UserLifetimeStats? lifetimeStats;
  final bool isUpdating;
  final String? updateError;

  const UserDetailsLoaded({
    required this.userDetails,
    this.lifetimeStats,
    this.isUpdating = false,
    this.updateError,
  });

  UserDetailsLoaded copyWith({
    UserDetails? userDetails,
    UserLifetimeStats? lifetimeStats,
    bool? isUpdating,
    String? updateError,
  }) {
    return UserDetailsLoaded(
      userDetails: userDetails ?? this.userDetails,
      lifetimeStats: lifetimeStats ?? this.lifetimeStats,
      isUpdating: isUpdating ?? this.isUpdating,
      updateError: updateError,
    );
  }

  @override
  List<Object?> get props => [userDetails, lifetimeStats, isUpdating, updateError];
}

class UserDetailsError extends UserDetailsState {
  final String message;

  const UserDetailsError({required this.message});

  @override
  List<Object> get props => [message];
}
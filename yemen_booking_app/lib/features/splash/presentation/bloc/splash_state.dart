import 'package:equatable/equatable.dart';

abstract class SplashState extends Equatable {
  const SplashState();
  @override
  List<Object?> get props => [];
}

class SplashInitial extends SplashState {
  const SplashInitial();
}

class SplashLoading extends SplashState {
  final double progress; // 0..1
  const SplashLoading({this.progress = 0});
  @override
  List<Object?> get props => [progress];
}

class SplashLoaded extends SplashState {
  final Map<String, dynamic> stats;
  const SplashLoaded({this.stats = const {}});
  @override
  List<Object?> get props => [stats];
}

class SplashError extends SplashState {
  final String message;
  const SplashError(this.message);
  @override
  List<Object?> get props => [message];
}


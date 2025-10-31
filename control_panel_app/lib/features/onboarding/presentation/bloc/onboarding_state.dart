import 'package:equatable/equatable.dart';

abstract class OnboardingState extends Equatable {
  const OnboardingState();
  @override
  List<Object?> get props => [];
}

class OnboardingInitial extends OnboardingState {
  const OnboardingInitial();
}

class OnboardingRequired extends OnboardingState {
  const OnboardingRequired();
}

class OnboardingNotRequired extends OnboardingState {
  const OnboardingNotRequired();
}

class OnboardingCompleting extends OnboardingState {
  const OnboardingCompleting();
}

class OnboardingCompleted extends OnboardingState {
  const OnboardingCompleted();
}


import 'package:equatable/equatable.dart';

abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();
  @override
  List<Object?> get props => [];
}

class CheckFirstRunEvent extends OnboardingEvent {
  const CheckFirstRunEvent();
}

class CompleteOnboardingEvent extends OnboardingEvent {
  final String city;
  final String currencyCode;
  const CompleteOnboardingEvent({required this.city, required this.currencyCode});
  @override
  List<Object?> get props => [city, currencyCode];
}


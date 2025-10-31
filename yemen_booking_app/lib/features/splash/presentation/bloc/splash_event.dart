import 'package:equatable/equatable.dart';

abstract class SplashEvent extends Equatable {
  const SplashEvent();
  @override
  List<Object?> get props => [];
}

class PreloadAppDataEvent extends SplashEvent {
  final bool forceRefresh;
  const PreloadAppDataEvent({this.forceRefresh = false});
}


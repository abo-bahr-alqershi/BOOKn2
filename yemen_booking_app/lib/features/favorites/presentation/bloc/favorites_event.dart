import 'package:equatable/equatable.dart';

abstract class FavoritesEvent extends Equatable {
  const FavoritesEvent();

  @override
  List<Object?> get props => [];
}

class LoadFavoritesEvent extends FavoritesEvent {
  const LoadFavoritesEvent();
}

class AddToFavoritesEvent extends FavoritesEvent {
  final String propertyId;
  final String userId;

  const AddToFavoritesEvent({
    required this.propertyId,
    required this.userId,
  });

  @override
  List<Object?> get props => [propertyId, userId];
}

class RemoveFromFavoritesEvent extends FavoritesEvent {
  final String propertyId;
  final String userId;

  const RemoveFromFavoritesEvent({
    required this.propertyId,
    required this.userId,
  });

  @override
  List<Object?> get props => [propertyId, userId];
}

class CheckFavoriteStatusEvent extends FavoritesEvent {
  final String propertyId;
  final String userId;

  const CheckFavoriteStatusEvent({
    required this.propertyId,
    required this.userId,
  });

  @override
  List<Object?> get props => [propertyId, userId];
}

class RefreshFavoritesEvent extends FavoritesEvent {
  const RefreshFavoritesEvent();
}

class ClearFavoritesEvent extends FavoritesEvent {
  const ClearFavoritesEvent();
}
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/favorite.dart';
import '../../domain/usecases/get_favorites_usecase.dart';
import '../../domain/usecases/add_to_favorites_usecase.dart';
import '../../domain/usecases/remove_from_favorites_usecase.dart';
import '../../domain/usecases/check_favorite_status_usecase.dart';
import 'favorites_event.dart';
import 'favorites_state.dart';

class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final GetFavoritesUseCase getFavoritesUseCase;
  final AddToFavoritesUseCase addToFavoritesUseCase;
  final RemoveFromFavoritesUseCase removeFromFavoritesUseCase;
  final CheckFavoriteStatusUseCase checkFavoriteStatusUseCase;

  FavoritesBloc({
    required this.getFavoritesUseCase,
    required this.addToFavoritesUseCase,
    required this.removeFromFavoritesUseCase,
    required this.checkFavoriteStatusUseCase,
  }) : super(const FavoritesInitial()) {
    on<LoadFavoritesEvent>(_onLoadFavorites);
    on<AddToFavoritesEvent>(_onAddToFavorites);
    on<RemoveFromFavoritesEvent>(_onRemoveFromFavorites);
    on<CheckFavoriteStatusEvent>(_onCheckFavoriteStatus);
    on<RefreshFavoritesEvent>(_onRefreshFavorites);
    on<ClearFavoritesEvent>(_onClearFavorites);
  }

  Future<void> _onLoadFavorites(
    LoadFavoritesEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    emit(const FavoritesLoading());

    final result = await getFavoritesUseCase(NoParams());
    
    await result.fold(
      (failure) async => emit(FavoritesError(message: _mapFailureToMessage(failure))),
      (favorites) async => emit(FavoritesLoaded(favorites: favorites)),
    );
  }

  Future<void> _onAddToFavorites(
    AddToFavoritesEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    emit(const FavoritesLoading());

    final params = AddToFavoritesParams(
      propertyId: event.propertyId,
      userId: event.userId,
    );

    final result = await addToFavoritesUseCase(params);
    
    await result.fold(
      (failure) async => emit(FavoritesError(message: _mapFailureToMessage(failure))),
      (favorite) async {
        // Reload favorites after adding
        final favoritesResult = await getFavoritesUseCase(NoParams());
        await favoritesResult.fold(
          (failure) async => emit(FavoritesError(message: _mapFailureToMessage(failure))),
          (favorites) async => emit(FavoritesLoaded(favorites: favorites)),
        );
      },
    );
  }

  Future<void> _onRemoveFromFavorites(
    RemoveFromFavoritesEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    emit(const FavoritesLoading());

    final params = RemoveFromFavoritesParams(
      propertyId: event.propertyId,
      userId: event.userId,
    );

    final result = await removeFromFavoritesUseCase(params);
    
    await result.fold(
      (failure) async => emit(FavoritesError(message: _mapFailureToMessage(failure))),
      (_) async {
        // Reload favorites after removing
        final favoritesResult = await getFavoritesUseCase(NoParams());
        await favoritesResult.fold(
          (failure) async => emit(FavoritesError(message: _mapFailureToMessage(failure))),
          (favorites) async => emit(FavoritesLoaded(favorites: favorites)),
        );
      },
    );
  }

  Future<void> _onCheckFavoriteStatus(
    CheckFavoriteStatusEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    final params = CheckFavoriteStatusParams(
      propertyId: event.propertyId,
      userId: event.userId,
    );

    final result = await checkFavoriteStatusUseCase(params);
    
    await result.fold(
      (failure) async => emit(FavoritesError(message: _mapFailureToMessage(failure))),
      (isFavorite) async => emit(FavoriteStatusChecked(isFavorite: isFavorite)),
    );
  }

  Future<void> _onRefreshFavorites(
    RefreshFavoritesEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    emit(const FavoritesLoading());

    final result = await getFavoritesUseCase(NoParams());
    
    await result.fold(
      (failure) async => emit(FavoritesError(message: _mapFailureToMessage(failure))),
      (favorites) async => emit(FavoritesLoaded(favorites: favorites)),
    );
  }

  Future<void> _onClearFavorites(
    ClearFavoritesEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    emit(const FavoritesInitial());
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'حدث خطأ في الخادم. يرجى المحاولة مرة أخرى لاحقاً';
      case CacheFailure:
        return 'حدث خطأ في التخزين المحلي';
      case NetworkFailure:
        return 'يرجى التحقق من اتصالك بالإنترنت';
      case ValidationFailure:
        return (failure as ValidationFailure).message;
      case AuthenticationFailure:
        return 'يجب تسجيل الدخول لإضافة المفضلة';
      case UnauthorizedFailure:
        return 'غير مصرح لك بالقيام بهذا الإجراء';
      default:
        return 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى';
    }
  }
}
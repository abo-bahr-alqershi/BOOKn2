import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/notification.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/get_notification_settings_usecase.dart';
import '../../domain/usecases/get_unread_count_usecase.dart';
import '../../domain/usecases/mark_as_read_usecase.dart';
import '../../domain/usecases/dismiss_notification_usecase.dart';
import '../../domain/usecases/update_notification_settings_usecase.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final GetNotificationsUseCase? getNotificationsUseCase;
  final MarkAsReadUseCase? markAsReadUseCase;
  final DismissNotificationUseCase? dismissNotificationUseCase;
  final UpdateNotificationSettingsUseCase? updateNotificationSettingsUseCase;
  final GetUnreadCountUseCase? getUnreadCountUseCase;
  final GetNotificationSettingsUseCase? getNotificationSettingsUseCase;

  List<NotificationEntity> _cachedNotifications = [];
  int _currentPage = 1;
  bool _hasReachedMax = false;
  int _unreadCount = 0;

  NotificationBloc({
    this.getNotificationsUseCase,
    this.markAsReadUseCase,
    this.dismissNotificationUseCase,
    this.updateNotificationSettingsUseCase,
    this.getUnreadCountUseCase,
    this.getNotificationSettingsUseCase,
  }) : super(const NotificationInitial()) {
    on<LoadNotificationsEvent>(_onLoadNotifications);
    on<MarkNotificationAsReadEvent>(_onMarkAsRead);
    on<MarkAllNotificationsAsReadEvent>(_onMarkAllAsRead);
    on<DismissNotificationEvent>(_onDismissNotification);
    on<UpdateNotificationSettingsEvent>(_onUpdateSettings);
    on<LoadUnreadCountEvent>(_onLoadUnreadCount);
    on<LoadNotificationSettingsEvent>(_onLoadNotificationSettings);
  }

  Future<void> _onLoadNotifications(
    LoadNotificationsEvent event,
    Emitter<NotificationState> emit,
  ) async {
    if (getNotificationsUseCase == null) {
      emit(const NotificationError(
          message: 'Notifications feature not initialized'));
      return;
    }

    final bool isRefresh = event.refresh || event.page <= 1;

    if (isRefresh) {
      _cachedNotifications = [];
      _currentPage = 1;
      _hasReachedMax = false;
      emit(const NotificationLoading());
    }

    final params = GetNotificationsParams(
      page: event.page,
      limit: event.limit,
      type: event.type,
    );

    final result = await getNotificationsUseCase!(params);

    await result.fold(
      (failure) async =>
          emit(NotificationError(message: _mapFailureToMessage(failure))),
      (paginatedResult) async {
        _currentPage = paginatedResult.pageNumber;
        _hasReachedMax = !paginatedResult.hasNextPage;
        _updateCachedNotifications(paginatedResult.items, refresh: isRefresh);
        _emitLoadedState(emit);
      },
    );
  }

  Future<void> _onMarkAsRead(
    MarkNotificationAsReadEvent event,
    Emitter<NotificationState> emit,
  ) async {
    if (markAsReadUseCase == null) {
      emit(const NotificationError(
          message: 'Mark as read feature not initialized'));
      return;
    }

    final params = MarkAsReadParams(notificationId: event.notificationId);
    final result = await markAsReadUseCase!(params);

    await result.fold(
      (failure) async =>
          emit(NotificationError(message: _mapFailureToMessage(failure))),
      (_) async {
        _cachedNotifications = _cachedNotifications
            .map((notification) => notification.id == event.notificationId
                ? _markNotificationAsRead(notification)
                : notification)
            .toList(growable: false);
        await _refreshUnreadCount();
        emit(const NotificationOperationSuccess(
            message: 'Notification marked as read'));
        _emitLoadedState(emit);
      },
    );
  }

  Future<void> _onMarkAllAsRead(
    MarkAllNotificationsAsReadEvent event,
    Emitter<NotificationState> emit,
  ) async {
    if (markAsReadUseCase == null) {
      emit(const NotificationError(
          message: 'Mark as read feature not initialized'));
      return;
    }

    const params = MarkAsReadParams();
    final result = await markAsReadUseCase!(params);

    await result.fold(
      (failure) async =>
          emit(NotificationError(message: _mapFailureToMessage(failure))),
      (_) async {
        _cachedNotifications = _cachedNotifications
            .map((notification) => _markNotificationAsRead(notification))
            .toList(growable: false);
        await _refreshUnreadCount();
        emit(const NotificationOperationSuccess(
            message: 'All notifications marked as read'));
        _emitLoadedState(emit);
      },
    );
  }

  Future<void> _onDismissNotification(
    DismissNotificationEvent event,
    Emitter<NotificationState> emit,
  ) async {
    if (dismissNotificationUseCase == null) {
      emit(const NotificationError(
          message: 'Dismiss notification feature not initialized'));
      return;
    }

    final params =
        DismissNotificationParams(notificationId: event.notificationId);
    final result = await dismissNotificationUseCase!(params);

    await result.fold(
      (failure) async =>
          emit(NotificationError(message: _mapFailureToMessage(failure))),
      (_) async {
        _cachedNotifications = _cachedNotifications
            .where((notification) => notification.id != event.notificationId)
            .toList(growable: false);
        await _refreshUnreadCount();
        emit(const NotificationOperationSuccess(
            message: 'Notification dismissed'));
        _emitLoadedState(emit);
      },
    );
  }

  Future<void> _onUpdateSettings(
    UpdateNotificationSettingsEvent event,
    Emitter<NotificationState> emit,
  ) async {
    if (updateNotificationSettingsUseCase == null) {
      emit(const NotificationError(
          message: 'Update settings feature not initialized'));
      return;
    }

    final params = UpdateNotificationSettingsParams(settings: event.settings);
    final result = await updateNotificationSettingsUseCase!(params);

    await result.fold(
      (failure) async =>
          emit(NotificationError(message: _mapFailureToMessage(failure))),
      (_) async => emit(const NotificationOperationSuccess(
          message: 'Settings updated successfully')),
    );
  }

  Future<void> _onLoadNotificationSettings(
    LoadNotificationSettingsEvent event,
    Emitter<NotificationState> emit,
  ) async {
    if (getNotificationSettingsUseCase == null) {
      emit(const NotificationError(
          message: 'Notification settings feature not initialized'));
      return;
    }

    emit(const NotificationSettingsLoading());

    final result = await getNotificationSettingsUseCase!(
        const GetNotificationSettingsParams());

    await result.fold(
      (failure) async =>
          emit(NotificationError(message: _mapFailureToMessage(failure))),
      (settings) async => emit(NotificationSettingsLoaded(settings: settings)),
    );
  }

  Future<void> _onLoadUnreadCount(
    LoadUnreadCountEvent event,
    Emitter<NotificationState> emit,
  ) async {
    if (getUnreadCountUseCase == null) {
      emit(const NotificationError(
          message: 'Unread count feature not initialized'));
      return;
    }
    final result = await getUnreadCountUseCase!(const GetUnreadCountParams());
    await result.fold(
      (failure) async {
        if (_cachedNotifications.isEmpty && state is! NotificationLoaded) {
          emit(NotificationError(message: _mapFailureToMessage(failure)));
        } else {
          _emitLoadedState(emit);
        }
      },
      (count) async {
        _unreadCount = count;
        if (_cachedNotifications.isNotEmpty || state is NotificationLoaded) {
          _emitLoadedState(emit);
        } else {
          emit(NotificationUnreadCountLoaded(unreadCount: count));
        }
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Server error occurred. Please try again later.';
      case NetworkFailure:
        return 'Please check your internet connection.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  void _updateCachedNotifications(
    List<NotificationEntity> freshNotifications, {
    required bool refresh,
  }) {
    if (refresh) {
      _cachedNotifications = List<NotificationEntity>.from(freshNotifications);
    } else {
      final updated = List<NotificationEntity>.from(_cachedNotifications);
      for (final notification in freshNotifications) {
        final index =
            updated.indexWhere((element) => element.id == notification.id);
        if (index >= 0) {
          updated[index] = notification;
        } else {
          updated.add(notification);
        }
      }
      _cachedNotifications = updated;
    }
    _unreadCount = _cachedNotifications
        .where((notification) => !notification.isRead)
        .length;
  }

  NotificationEntity _markNotificationAsRead(NotificationEntity notification) {
    if (notification.isRead) {
      return notification;
    }

    return NotificationEntity(
      id: notification.id,
      title: notification.title,
      message: notification.message,
      type: notification.type,
      data: notification.data,
      isRead: true,
      createdAt: notification.createdAt,
      readAt: notification.readAt ?? DateTime.now(),
    );
  }

  Future<void> _refreshUnreadCount() async {
    if (getUnreadCountUseCase == null) {
      _unreadCount = _cachedNotifications
          .where((notification) => !notification.isRead)
          .length;
      return;
    }

    final unreadRes =
        await getUnreadCountUseCase!(const GetUnreadCountParams());
    await unreadRes.fold(
      (failure) async {
        _unreadCount = _cachedNotifications
            .where((notification) => !notification.isRead)
            .length;
      },
      (count) async {
        _unreadCount = count;
      },
    );
  }

  void _emitLoadedState(Emitter<NotificationState> emit) {
    emit(NotificationLoaded(
      notifications:
          List<NotificationEntity>.unmodifiable(_cachedNotifications),
      hasReachedMax: _hasReachedMax,
      currentPage: _currentPage,
      unreadCount: _unreadCount,
    ));
  }
}

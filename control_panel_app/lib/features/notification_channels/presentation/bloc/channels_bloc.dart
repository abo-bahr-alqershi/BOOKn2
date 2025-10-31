import 'package:flutter_bloc/flutter_bloc.dart';
// removed unused imports after split
import '../../domain/repositories/notification_channels_repository.dart';
import 'channels_event.dart';
import 'channels_state.dart';


// Bloc
class ChannelsBloc extends Bloc<ChannelsEvent, ChannelsState> {
  final INotificationChannelsRepository _repository;

  ChannelsBloc({required INotificationChannelsRepository repository})
      : _repository = repository,
        super(const ChannelsState()) {
    on<LoadChannelsEvent>(_onLoadChannels);
    on<LoadChannelStatisticsEvent>(_onLoadStatistics);
    on<CreateChannelEvent>(_onCreateChannel);
    on<UpdateChannelEvent>(_onUpdateChannel);
    on<DeleteChannelEvent>(_onDeleteChannel);
    on<LoadChannelDetailsEvent>(_onLoadChannelDetails);
    on<LoadChannelSubscribersEvent>(_onLoadSubscribers);
    on<AddSubscribersEvent>(_onAddSubscribers);
    on<RemoveSubscribersEvent>(_onRemoveSubscribers);
    on<SendChannelNotificationEvent>(_onSendNotification);
    on<LoadChannelHistoryEvent>(_onLoadHistory);
    on<LoadUserChannelsEvent>(_onLoadUserChannels);
    on<UpdateUserSubscriptionsEvent>(_onUpdateUserSubscriptions);
  }

  Future<void> _onLoadChannels(
    LoadChannelsEvent event,
    Emitter<ChannelsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    final result = await _repository.getChannels(
      search: event.search,
      type: event.type,
      isActive: event.isActive,
      page: event.page,
      pageSize: event.pageSize,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        error: failure.message,
      )),
      (channels) => emit(state.copyWith(
        isLoading: false,
        channels: channels,
      )),
    );
  }

  Future<void> _onLoadStatistics(
    LoadChannelStatisticsEvent event,
    Emitter<ChannelsState> emit,
  ) async {
    final result = await _repository.getStatistics();

    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (statistics) => emit(state.copyWith(statistics: statistics)),
    );
  }

  Future<void> _onCreateChannel(
    CreateChannelEvent event,
    Emitter<ChannelsState> emit,
  ) async {
    emit(state.copyWith(isCreating: true, error: null));

    final result = await _repository.createChannel(
      name: event.name,
      identifier: event.identifier,
      description: event.description,
      type: event.type,
      icon: event.icon,
      color: event.color,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isCreating: false,
        error: failure.message,
      )),
      (channel) {
        final updatedChannels = [...state.channels, channel];
        emit(state.copyWith(
          isCreating: false,
          channels: updatedChannels,
          successMessage: 'تم إنشاء القناة بنجاح',
        ));
      },
    );
  }

  Future<void> _onUpdateChannel(
    UpdateChannelEvent event,
    Emitter<ChannelsState> emit,
  ) async {
    emit(state.copyWith(isUpdating: true, error: null));

    final result = await _repository.updateChannel(
      event.id,
      name: event.name,
      description: event.description,
      isActive: event.isActive,
      icon: event.icon,
      color: event.color,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isUpdating: false,
        error: failure.message,
      )),
      (channel) {
        final updatedChannels = state.channels.map((c) {
          return c.id == channel.id ? channel : c;
        }).toList();
        emit(state.copyWith(
          isUpdating: false,
          channels: updatedChannels,
          selectedChannel: channel,
          successMessage: 'تم تحديث القناة بنجاح',
        ));
      },
    );
  }

  Future<void> _onDeleteChannel(
    DeleteChannelEvent event,
    Emitter<ChannelsState> emit,
  ) async {
    emit(state.copyWith(isDeleting: true, error: null));

    final result = await _repository.deleteChannel(event.channelId);

    result.fold(
      (failure) => emit(state.copyWith(
        isDeleting: false,
        error: failure.message,
      )),
      (_) {
        final updatedChannels = state.channels
            .where((c) => c.id != event.channelId)
            .toList();
        emit(state.copyWith(
          isDeleting: false,
          channels: updatedChannels,
          successMessage: 'تم حذف القناة بنجاح',
        ));
      },
    );
  }

  Future<void> _onLoadChannelDetails(
    LoadChannelDetailsEvent event,
    Emitter<ChannelsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    final channelResult = await _repository.getChannel(event.channelId);
    final statsResult = await _repository.getChannelStatistics(event.channelId);

    channelResult.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        error: failure.message,
      )),
      (channel) {
        emit(state.copyWith(
          isLoading: false,
          selectedChannel: channel,
          channelStatistics: statsResult.fold(
            (_) => null,
            (stats) => stats,
          ),
        ));
      },
    );
  }

  Future<void> _onLoadSubscribers(
    LoadChannelSubscribersEvent event,
    Emitter<ChannelsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    final result = await _repository.getChannelSubscribers(
      event.channelId,
      activeOnly: event.activeOnly,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        error: failure.message,
      )),
      (subscribers) => emit(state.copyWith(
        isLoading: false,
        subscribers: subscribers,
      )),
    );
  }

  Future<void> _onAddSubscribers(
    AddSubscribersEvent event,
    Emitter<ChannelsState> emit,
  ) async {
    emit(state.copyWith(isUpdating: true, error: null));

    final result = await _repository.addSubscribers(
      event.channelId,
      event.userIds,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isUpdating: false,
        error: failure.message,
      )),
      (count) {
        emit(state.copyWith(
          isUpdating: false,
          successMessage: 'تم إضافة $count مشترك بنجاح',
        ));
        // Reload subscribers
        add(LoadChannelSubscribersEvent(channelId: event.channelId));
      },
    );
  }

  Future<void> _onRemoveSubscribers(
    RemoveSubscribersEvent event,
    Emitter<ChannelsState> emit,
  ) async {
    emit(state.copyWith(isUpdating: true, error: null));

    final result = await _repository.removeSubscribers(
      event.channelId,
      event.userIds,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isUpdating: false,
        error: failure.message,
      )),
      (count) {
        emit(state.copyWith(
          isUpdating: false,
          successMessage: 'تم إزالة $count مشترك بنجاح',
        ));
        // Reload subscribers
        add(LoadChannelSubscribersEvent(channelId: event.channelId));
      },
    );
  }

  Future<void> _onSendNotification(
    SendChannelNotificationEvent event,
    Emitter<ChannelsState> emit,
  ) async {
    emit(state.copyWith(isSending: true, error: null));

    final result = await _repository.sendChannelNotification(
      event.channelId,
      title: event.title,
      content: event.content,
      type: event.type,
      data: event.data,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isSending: false,
        error: failure.message,
      )),
      (history) {
        emit(state.copyWith(
          isSending: false,
          successMessage: 'تم إرسال الإشعار إلى ${history.recipientsCount} مستخدم',
        ));
        // Reload history
        add(LoadChannelHistoryEvent(channelId: event.channelId));
      },
    );
  }

  Future<void> _onLoadHistory(
    LoadChannelHistoryEvent event,
    Emitter<ChannelsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    final result = await _repository.getChannelHistory(
      event.channelId,
      page: event.page,
      pageSize: event.pageSize,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        error: failure.message,
      )),
      (history) => emit(state.copyWith(
        isLoading: false,
        history: history,
      )),
    );
  }

  Future<void> _onLoadUserChannels(
    LoadUserChannelsEvent event,
    Emitter<ChannelsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    final result = await _repository.getUserChannels(event.userId);

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        error: failure.message,
      )),
      (channels) => emit(state.copyWith(
        isLoading: false,
        channels: channels,
      )),
    );
  }

  Future<void> _onUpdateUserSubscriptions(
    UpdateUserSubscriptionsEvent event,
    Emitter<ChannelsState> emit,
  ) async {
    emit(state.copyWith(isUpdating: true, error: null));

    final result = await _repository.updateUserSubscriptions(
      event.userId,
      channelsToAdd: event.channelsToAdd,
      channelsToRemove: event.channelsToRemove,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isUpdating: false,
        error: failure.message,
      )),
      (_) {
        emit(state.copyWith(
          isUpdating: false,
          successMessage: 'تم تحديث اشتراكات المستخدم بنجاح',
        ));
        // Reload user channels
        add(LoadUserChannelsEvent(event.userId));
      },
    );
  }
}

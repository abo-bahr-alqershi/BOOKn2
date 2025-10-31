import 'package:equatable/equatable.dart';
import '../../domain/entities/notification_channel.dart';

class ChannelsState extends Equatable {
  final List<NotificationChannel> channels;
  final NotificationChannel? selectedChannel;
  final List<UserChannelSubscription> subscribers;
  final List<ChannelNotificationHistory> history;
  final ChannelStatistics? statistics;
  final Map<String, dynamic>? channelStatistics;
  final bool isLoading;
  final bool isCreating;
  final bool isUpdating;
  final bool isDeleting;
  final bool isSending;
  final String? error;
  final String? successMessage;

  const ChannelsState({
    this.channels = const [],
    this.selectedChannel,
    this.subscribers = const [],
    this.history = const [],
    this.statistics,
    this.channelStatistics,
    this.isLoading = false,
    this.isCreating = false,
    this.isUpdating = false,
    this.isDeleting = false,
    this.isSending = false,
    this.error,
    this.successMessage,
  });

  ChannelsState copyWith({
    List<NotificationChannel>? channels,
    NotificationChannel? selectedChannel,
    List<UserChannelSubscription>? subscribers,
    List<ChannelNotificationHistory>? history,
    ChannelStatistics? statistics,
    Map<String, dynamic>? channelStatistics,
    bool? isLoading,
    bool? isCreating,
    bool? isUpdating,
    bool? isDeleting,
    bool? isSending,
    String? error,
    String? successMessage,
  }) {
    return ChannelsState(
      channels: channels ?? this.channels,
      selectedChannel: selectedChannel ?? this.selectedChannel,
      subscribers: subscribers ?? this.subscribers,
      history: history ?? this.history,
      statistics: statistics ?? this.statistics,
      channelStatistics: channelStatistics ?? this.channelStatistics,
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
      isDeleting: isDeleting ?? this.isDeleting,
      isSending: isSending ?? this.isSending,
      error: error,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        channels,
        selectedChannel,
        subscribers,
        history,
        statistics,
        channelStatistics,
        isLoading,
        isCreating,
        isUpdating,
        isDeleting,
        isSending,
        error,
        successMessage,
      ];
}

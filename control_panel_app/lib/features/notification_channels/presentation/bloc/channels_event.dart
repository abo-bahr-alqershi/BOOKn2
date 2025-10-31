import 'package:equatable/equatable.dart';

abstract class ChannelsEvent extends Equatable {
  const ChannelsEvent();

  @override
  List<Object?> get props => [];
}

class LoadChannelsEvent extends ChannelsEvent {
  final String? search;
  final String? type;
  final bool? isActive;
  final int page;
  final int pageSize;

  const LoadChannelsEvent({
    this.search,
    this.type,
    this.isActive,
    this.page = 1,
    this.pageSize = 20,
  });

  @override
  List<Object?> get props => [search, type, isActive, page, pageSize];
}

class LoadChannelStatisticsEvent extends ChannelsEvent {
  const LoadChannelStatisticsEvent();
}

class CreateChannelEvent extends ChannelsEvent {
  final String name;
  final String identifier;
  final String? description;
  final String? type;
  final String? icon;
  final String? color;

  const CreateChannelEvent({
    required this.name,
    required this.identifier,
    this.description,
    this.type,
    this.icon,
    this.color,
  });

  @override
  List<Object?> get props => [name, identifier, description, type, icon, color];
}

class UpdateChannelEvent extends ChannelsEvent {
  final String id;
  final String? name;
  final String? description;
  final bool? isActive;
  final String? icon;
  final String? color;

  const UpdateChannelEvent({
    required this.id,
    this.name,
    this.description,
    this.isActive,
    this.icon,
    this.color,
  });

  @override
  List<Object?> get props => [id, name, description, isActive, icon, color];
}

class DeleteChannelEvent extends ChannelsEvent {
  final String channelId;

  const DeleteChannelEvent(this.channelId);

  @override
  List<Object> get props => [channelId];
}

class LoadChannelDetailsEvent extends ChannelsEvent {
  final String channelId;

  const LoadChannelDetailsEvent(this.channelId);

  @override
  List<Object> get props => [channelId];
}

class LoadChannelSubscribersEvent extends ChannelsEvent {
  final String channelId;
  final bool activeOnly;

  const LoadChannelSubscribersEvent({
    required this.channelId,
    this.activeOnly = true,
  });

  @override
  List<Object> get props => [channelId, activeOnly];
}

class AddSubscribersEvent extends ChannelsEvent {
  final String channelId;
  final List<String> userIds;

  const AddSubscribersEvent({
    required this.channelId,
    required this.userIds,
  });

  @override
  List<Object> get props => [channelId, userIds];
}

class RemoveSubscribersEvent extends ChannelsEvent {
  final String channelId;
  final List<String> userIds;

  const RemoveSubscribersEvent({
    required this.channelId,
    required this.userIds,
  });

  @override
  List<Object> get props => [channelId, userIds];
}

class SendChannelNotificationEvent extends ChannelsEvent {
  final String channelId;
  final String title;
  final String content;
  final String? type;
  final Map<String, String>? data;

  const SendChannelNotificationEvent({
    required this.channelId,
    required this.title,
    required this.content,
    this.type,
    this.data,
  });

  @override
  List<Object?> get props => [channelId, title, content, type, data];
}

class LoadChannelHistoryEvent extends ChannelsEvent {
  final String channelId;
  final int page;
  final int pageSize;

  const LoadChannelHistoryEvent({
    required this.channelId,
    this.page = 1,
    this.pageSize = 20,
  });

  @override
  List<Object> get props => [channelId, page, pageSize];
}

class LoadUserChannelsEvent extends ChannelsEvent {
  final String userId;

  const LoadUserChannelsEvent(this.userId);

  @override
  List<Object> get props => [userId];
}

class UpdateUserSubscriptionsEvent extends ChannelsEvent {
  final String userId;
  final List<String>? channelsToAdd;
  final List<String>? channelsToRemove;

  const UpdateUserSubscriptionsEvent({
    required this.userId,
    this.channelsToAdd,
    this.channelsToRemove,
  });

  @override
  List<Object?> get props => [userId, channelsToAdd, channelsToRemove];
}

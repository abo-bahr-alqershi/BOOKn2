import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/notification_channel.dart';
import '../repositories/notification_channels_repository.dart';

class GetChannelsUseCase {
  final INotificationChannelsRepository repo;
  GetChannelsUseCase(this.repo);
  Future<Either<Failure, List<NotificationChannel>>> call({
    String? search,
    String? type,
    bool? isActive,
    int page = 1,
    int pageSize = 20,
  }) => repo.getChannels(search: search, type: type, isActive: isActive, page: page, pageSize: pageSize);
}

class GetChannelUseCase {
  final INotificationChannelsRepository repo;
  GetChannelUseCase(this.repo);
  Future<Either<Failure, NotificationChannel>> call(String id) => repo.getChannel(id);
}

class CreateChannelUseCase {
  final INotificationChannelsRepository repo;
  CreateChannelUseCase(this.repo);
  Future<Either<Failure, NotificationChannel>> call({
    required String name,
    required String identifier,
    String? description,
    String? type,
    String? icon,
    String? color,
  }) => repo.createChannel(name: name, identifier: identifier, description: description, type: type, icon: icon, color: color);
}

class UpdateChannelUseCase {
  final INotificationChannelsRepository repo;
  UpdateChannelUseCase(this.repo);
  Future<Either<Failure, NotificationChannel>> call(String id, {String? name, String? description, bool? isActive, String? icon, String? color})
    => repo.updateChannel(id, name: name, description: description, isActive: isActive, icon: icon, color: color);
}

class DeleteChannelUseCase {
  final INotificationChannelsRepository repo;
  DeleteChannelUseCase(this.repo);
  Future<Either<Failure, bool>> call(String id) => repo.deleteChannel(id);
}

class GetChannelSubscribersUseCase {
  final INotificationChannelsRepository repo;
  GetChannelSubscribersUseCase(this.repo);
  Future<Either<Failure, List<UserChannelSubscription>>> call(String channelId, {bool activeOnly = true})
    => repo.getChannelSubscribers(channelId, activeOnly: activeOnly);
}

class AddSubscribersUseCase {
  final INotificationChannelsRepository repo;
  AddSubscribersUseCase(this.repo);
  Future<Either<Failure, int>> call(String channelId, List<String> userIds) => repo.addSubscribers(channelId, userIds);
}

class RemoveSubscribersUseCase {
  final INotificationChannelsRepository repo;
  RemoveSubscribersUseCase(this.repo);
  Future<Either<Failure, int>> call(String channelId, List<String> userIds) => repo.removeSubscribers(channelId, userIds);
}

class SendChannelNotificationUseCase {
  final INotificationChannelsRepository repo;
  SendChannelNotificationUseCase(this.repo);
  Future<Either<Failure, ChannelNotificationHistory>> call(String channelId, {required String title, required String content, String? type, Map<String, String>? data})
    => repo.sendChannelNotification(channelId, title: title, content: content, type: type, data: data);
}

class GetChannelHistoryUseCase {
  final INotificationChannelsRepository repo;
  GetChannelHistoryUseCase(this.repo);
  Future<Either<Failure, List<ChannelNotificationHistory>>> call(String channelId, {int page = 1, int pageSize = 20})
    => repo.getChannelHistory(channelId, page: page, pageSize: pageSize);
}

class GetChannelsStatisticsUseCase {
  final INotificationChannelsRepository repo;
  GetChannelsStatisticsUseCase(this.repo);
  Future<Either<Failure, ChannelStatistics>> call() => repo.getStatistics();
}

class GetChannelStatisticsUseCase {
  final INotificationChannelsRepository repo;
  GetChannelStatisticsUseCase(this.repo);
  Future<Either<Failure, Map<String, dynamic>>> call(String channelId) => repo.getChannelStatistics(channelId);
}

class GetUserChannelsUseCase {
  final INotificationChannelsRepository repo;
  GetUserChannelsUseCase(this.repo);
  Future<Either<Failure, List<NotificationChannel>>> call(String userId) => repo.getUserChannels(userId);
}

class UpdateUserSubscriptionsUseCase {
  final INotificationChannelsRepository repo;
  UpdateUserSubscriptionsUseCase(this.repo);
  Future<Either<Failure, bool>> call(String userId, {List<String>? channelsToAdd, List<String>? channelsToRemove})
    => repo.updateUserSubscriptions(userId, channelsToAdd: channelsToAdd, channelsToRemove: channelsToRemove);
}

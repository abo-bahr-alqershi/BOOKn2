import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/notification_channel.dart';

abstract class INotificationChannelsRepository {
  Future<Either<Failure, List<NotificationChannel>>> getChannels({
    String? search,
    String? type,
    bool? isActive,
    int page = 1,
    int pageSize = 20,
  });

  Future<Either<Failure, NotificationChannel>> getChannel(String id);

  Future<Either<Failure, NotificationChannel>> createChannel({
    required String name,
    required String identifier,
    String? description,
    String? type,
    String? icon,
    String? color,
  });

  Future<Either<Failure, NotificationChannel>> updateChannel(
    String id, {
    String? name,
    String? description,
    bool? isActive,
    String? icon,
    String? color,
  });

  Future<Either<Failure, bool>> deleteChannel(String id);

  Future<Either<Failure, List<UserChannelSubscription>>> getChannelSubscribers(
    String channelId, {
    bool activeOnly = true,
  });

  Future<Either<Failure, int>> addSubscribers(
    String channelId,
    List<String> userIds,
  );

  Future<Either<Failure, int>> removeSubscribers(
    String channelId,
    List<String> userIds,
  );

  Future<Either<Failure, ChannelNotificationHistory>> sendChannelNotification(
    String channelId, {
    required String title,
    required String content,
    String? type,
    Map<String, String>? data,
  });

  Future<Either<Failure, List<ChannelNotificationHistory>>> getChannelHistory(
    String channelId, {
    int page = 1,
    int pageSize = 20,
  });

  Future<Either<Failure, ChannelStatistics>> getStatistics();

  Future<Either<Failure, Map<String, dynamic>>> getChannelStatistics(String channelId);

  Future<Either<Failure, List<NotificationChannel>>> getUserChannels(String userId);

  Future<Either<Failure, bool>> updateUserSubscriptions(
    String userId, {
    List<String>? channelsToAdd,
    List<String>? channelsToRemove,
  });
}

import 'package:dartz/dartz.dart';
import 'package:bookn_cp_app/core/error/failures.dart';
import '../../domain/entities/notification_channel.dart';
import '../../domain/repositories/notification_channels_repository.dart';
import '../datasources/notification_channels_remote_datasource.dart';

class NotificationChannelsRepositoryImpl implements INotificationChannelsRepository {
  final NotificationChannelsRemoteDataSource remote;
  NotificationChannelsRepositoryImpl({required this.remote});

  @override
  Future<Either<Failure, List<NotificationChannel>>> getChannels({
    String? search,
    String? type,
    bool? isActive,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final items = await remote.getChannels(
        search: search,
        type: type,
        isActive: isActive,
        page: page,
        pageSize: pageSize,
      );
      return Right(items);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, NotificationChannel>> getChannel(String id) async {
    try {
      final item = await remote.getChannel(id);
      return Right(item);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, NotificationChannel>> createChannel({
    required String name,
    required String identifier,
    String? description,
    String? type,
    String? icon,
    String? color,
  }) async {
    try {
      final item = await remote.createChannel(
        name: name,
        identifier: identifier,
        description: description,
        type: type,
        icon: icon,
        color: color,
      );
      return Right(item);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, NotificationChannel>> updateChannel(
    String id, {
    String? name,
    String? description,
    bool? isActive,
    String? icon,
    String? color,
  }) async {
    try {
      final item = await remote.updateChannel(
        id,
        name: name,
        description: description,
        isActive: isActive,
        icon: icon,
        color: color,
      );
      return Right(item);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteChannel(String id) async {
    try {
      final ok = await remote.deleteChannel(id);
      return Right(ok);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UserChannelSubscription>>> getChannelSubscribers(
    String channelId, {
    bool activeOnly = true,
  }) async {
    try {
      final items = await remote.getChannelSubscribers(channelId, activeOnly: activeOnly);
      return Right(items);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> addSubscribers(String channelId, List<String> userIds) async {
    try {
      final count = await remote.addSubscribers(channelId, userIds);
      return Right(count);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> removeSubscribers(String channelId, List<String> userIds) async {
    try {
      final count = await remote.removeSubscribers(channelId, userIds);
      return Right(count);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChannelNotificationHistory>> sendChannelNotification(
    String channelId, {
    required String title,
    required String content,
    String? type,
    Map<String, String>? data,
  }) async {
    try {
      final history = await remote.sendChannelNotification(
        channelId,
        title: title,
        content: content,
        type: type,
        data: data,
      );
      return Right(history);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ChannelNotificationHistory>>> getChannelHistory(
    String channelId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final items = await remote.getChannelHistory(channelId, page: page, pageSize: pageSize);
      return Right(items);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChannelStatistics>> getStatistics() async {
    try {
      final stats = await remote.getStatistics();
      return Right(stats);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getChannelStatistics(String channelId) async {
    try {
      final stats = await remote.getChannelStatistics(channelId);
      return Right(stats);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<NotificationChannel>>> getUserChannels(String userId) async {
    try {
      final items = await remote.getUserChannels(userId);
      return Right(items);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> updateUserSubscriptions(
    String userId, {
    List<String>? channelsToAdd,
    List<String>? channelsToRemove,
  }) async {
    try {
      final ok = await remote.updateUserSubscriptions(
        userId,
        channelsToAdd: channelsToAdd,
        channelsToRemove: channelsToRemove,
      );
      return Right(ok);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

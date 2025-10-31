import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/models/paginated_result.dart';
import '../../domain/entities/admin_notification.dart';
import '../../domain/repositories/admin_notifications_repository.dart';
import '../datasources/admin_notifications_remote_datasource.dart';

class AdminNotificationsRepositoryImpl implements AdminNotificationsRepository {
  final AdminNotificationsRemoteDataSource remote;
  final NetworkInfo networkInfo;
  AdminNotificationsRepositoryImpl(
      {required this.remote, required this.networkInfo});

  @override
  Future<Either<Failure, String>> create(
      {required String type,
      required String title,
      required String message,
      required String recipientId}) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final id = await remote.create(
          type: type, title: title, message: message, recipientId: recipientId);
      return Right(id);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> broadcast(
      {required String type,
      required String title,
      required String message,
      bool targetAll = false,
      List<String>? userIds,
      List<String>? roles,
      DateTime? scheduledFor,
      String? channelId}) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final count = await remote.broadcast(
        type: type,
        title: title,
        message: message,
        targetAll: targetAll,
        userIds: userIds,
        roles: roles,
        scheduledFor: scheduledFor,
        channelId: channelId,
      );
      return Right(count);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> delete(String notificationId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final ok = await remote.delete(notificationId);
      return Right(ok);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<AdminNotificationEntity>>> getSystem(
      {int page = 1, int pageSize = 20, String? type, String? status}) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final res = await remote.getSystem(
          page: page, pageSize: pageSize, type: type, status: status);
      return Right(res);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<AdminNotificationEntity>>> getUser(
      {required String userId,
      int page = 1,
      int pageSize = 20,
      bool? isRead}) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final res = await remote.getUser(
          userId: userId, page: page, pageSize: pageSize, isRead: isRead);
      return Right(res);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> resend(String notificationId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final ok = await remote.resend(notificationId);
      return Right(ok);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, int>>> getStats({DateTime? startDate, DateTime? endDate}) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final res = await remote.getStats(startDate: startDate, endDate: endDate);
      return Right(res);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

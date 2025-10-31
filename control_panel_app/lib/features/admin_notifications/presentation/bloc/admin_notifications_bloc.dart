import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_notification_usecase.dart';
import '../../domain/usecases/broadcast_notification_usecase.dart';
import '../../domain/usecases/delete_notification_usecase.dart';
import '../../domain/usecases/resend_notification_usecase.dart';
import '../../domain/usecases/get_system_notifications_usecase.dart';
import '../../domain/usecases/get_user_notifications_usecase.dart';
import '../../domain/usecases/get_notifications_stats_usecase.dart';
import 'admin_notifications_event.dart';
import 'admin_notifications_state.dart';

class AdminNotificationsBloc
    extends Bloc<AdminNotificationsEvent, AdminNotificationsState> {
  final CreateAdminNotificationUseCase createUseCase;
  final BroadcastAdminNotificationUseCase broadcastUseCase;
  final DeleteAdminNotificationUseCase deleteUseCase;
  final ResendAdminNotificationUseCase resendUseCase;
  final GetSystemAdminNotificationsUseCase getSystemUseCase;
  final GetUserAdminNotificationsUseCase getUserUseCase;
  final GetAdminNotificationsStatsUseCase getStatsUseCase;

  Map<String, int>? _cachedStats;
  String? _statsError;

  AdminNotificationsBloc({
    required this.createUseCase,
    required this.broadcastUseCase,
    required this.deleteUseCase,
    required this.resendUseCase,
    required this.getSystemUseCase,
    required this.getUserUseCase,
    required this.getStatsUseCase,
  }) : super(const AdminNotificationsInitial()) {
    on<LoadSystemNotificationsEvent>((event, emit) async {
      emit(AdminNotificationsLoading(
          stats: _cachedStats, statsError: _statsError));
      final res = await getSystemUseCase(
          page: event.page,
          pageSize: event.pageSize,
          type: event.type,
          status: event.status);
      res.fold(
        (l) => emit(AdminNotificationsError(
          l.message,
          stats: _cachedStats,
          statsError: _statsError,
        )),
        (r) => emit(AdminSystemNotificationsLoaded(
          items: r.items,
          totalCount: r.totalCount,
          stats: _cachedStats,
          statsError: _statsError,
        )),
      );
    });

    on<LoadUserNotificationsEvent>((event, emit) async {
      emit(AdminNotificationsLoading(
          stats: _cachedStats, statsError: _statsError));
      final res = await getUserUseCase(
          userId: event.userId,
          page: event.page,
          pageSize: event.pageSize,
          isRead: event.isRead);
      res.fold(
        (l) => emit(AdminNotificationsError(
          l.message,
          stats: _cachedStats,
          statsError: _statsError,
        )),
        (r) => emit(AdminUserNotificationsLoaded(
          items: r.items,
          totalCount: r.totalCount,
          stats: _cachedStats,
          statsError: _statsError,
        )),
      );
    });

    on<CreateAdminNotificationEvent>((event, emit) async {
      emit(AdminNotificationsSubmitting('create',
          stats: _cachedStats, statsError: _statsError));
      final res = await createUseCase(
          type: event.type,
          title: event.title,
          message: event.message,
          recipientId: event.recipientId);
      res.fold(
        (l) => emit(AdminNotificationsError(
          l.message,
          stats: _cachedStats,
          statsError: _statsError,
        )),
        (r) {
          emit(AdminNotificationsSuccess(
            'تم إنشام الإشعار',
            stats: _cachedStats,
            statsError: _statsError,
          ));
          // إعادة تحميل القائمة بعد النجاح
          add(const LoadSystemNotificationsEvent(page: 1, pageSize: 20));
        },
      );
    });

    on<BroadcastAdminNotificationEvent>((event, emit) async {
      emit(AdminNotificationsSubmitting('broadcast',
          stats: _cachedStats, statsError: _statsError));
      final res = await broadcastUseCase(
        type: event.type,
        title: event.title,
        message: event.message,
        targetAll: event.targetAll,
        userIds: event.userIds,
        roles: event.roles,
        scheduledFor: event.scheduledFor,
        channelId: event.channelId,
      );
      res.fold(
        (l) => emit(AdminNotificationsError(
          l.message,
          stats: _cachedStats,
          statsError: _statsError,
        )),
        (r) {
          emit(AdminNotificationsSuccess(
            'تم بث الإشعار لعدد $r مستخدم',
            stats: _cachedStats,
            statsError: _statsError,
          ));
          // إعادة تحميل القائمة بعد النجاح
          add(const LoadSystemNotificationsEvent(page: 1, pageSize: 20));
        },
      );
    });

    on<DeleteAdminNotificationEvent>((event, emit) async {
      emit(AdminNotificationsSubmitting('delete',
          stats: _cachedStats, statsError: _statsError));
      final res = await deleteUseCase(event.notificationId);
      res.fold(
        (l) => emit(AdminNotificationsError(
          l.message,
          stats: _cachedStats,
          statsError: _statsError,
        )),
        (r) => emit(AdminNotificationsSuccess(
          'تم حذف الإشعار',
          stats: _cachedStats,
          statsError: _statsError,
        )),
      );
    });

    on<ResendAdminNotificationEvent>((event, emit) async {
      emit(AdminNotificationsSubmitting('resend',
          stats: _cachedStats, statsError: _statsError));
      final res = await resendUseCase(event.notificationId);
      res.fold(
        (l) => emit(AdminNotificationsError(
          l.message,
          stats: _cachedStats,
          statsError: _statsError,
        )),
        (r) => emit(AdminNotificationsSuccess(
          'تمت إعادة الإرسال',
          stats: _cachedStats,
          statsError: _statsError,
        )),
      );
    });

    on<LoadAdminNotificationsStatsEvent>((event, emit) async {
      // Default last 30 days window similar to currencies
      final now = DateTime.now();
      final last30 = now.subtract(const Duration(days: 30));
      final res = await getStatsUseCase(startDate: last30, endDate: now);
      res.fold(
        (l) {
          _statsError = l.message;
          _cachedStats = null;
          emit(_cloneStateWithStats(state,
              stats: _cachedStats, statsError: _statsError));
        },
        (r) {
          _cachedStats = r;
          _statsError = null;
          emit(_cloneStateWithStats(state, stats: _cachedStats));
        },
      );
    });
  }

  AdminNotificationsState _cloneStateWithStats(
    AdminNotificationsState current, {
    required Map<String, int>? stats,
    String? statsError,
  }) {
    if (current is AdminSystemNotificationsLoaded) {
      return AdminSystemNotificationsLoaded(
        items: current.items,
        totalCount: current.totalCount,
        stats: stats ?? current.stats,
        statsError: statsError,
      );
    }

    if (current is AdminUserNotificationsLoaded) {
      return AdminUserNotificationsLoaded(
        items: current.items,
        totalCount: current.totalCount,
        stats: stats ?? current.stats,
        statsError: statsError,
      );
    }

    if (current is AdminNotificationsLoading) {
      return AdminNotificationsLoading(
        stats: stats ?? current.stats,
        statsError: statsError,
      );
    }

    if (current is AdminNotificationsSuccess) {
      return AdminNotificationsSuccess(
        current.message,
        stats: stats ?? current.stats,
        statsError: statsError,
      );
    }

    if (current is AdminNotificationsError) {
      return AdminNotificationsError(
        current.message,
        stats: stats ?? current.stats,
        statsError: statsError,
      );
    }

    return AdminNotificationsInitial(
      stats: stats ?? current.stats,
      statsError: statsError,
    );
  }
}

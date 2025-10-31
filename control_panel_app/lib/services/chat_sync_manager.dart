import 'dart:async';
import 'package:bookn_cp_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:bookn_cp_app/features/chat/data/datasources/chat_local_datasource.dart';
import 'package:bookn_cp_app/services/connectivity_service.dart';
import 'package:bookn_cp_app/services/websocket_service.dart';

class ChatSyncManager {
  final ChatRepository repository;
  final ChatLocalDataSource local;
  final ConnectivityService connectivity;
  final ChatWebSocketService ws;

  StreamSubscription<bool>? _connSub;
  bool _initialized = false;

  ChatSyncManager({
    required this.repository,
    required this.local,
    required this.connectivity,
    required this.ws,
  });

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _connSub = connectivity.connectionStatus.listen((connected) {
      if (connected) {
        // Flush queued messages when back online
        // Fire and forget
        // ignore: discarded_futures
        flushQueuedMessages();
        // Best-effort cache prune
        // ignore: discarded_futures
        local.pruneThumbnails(maxEntries: 300);
      }
    });

    if (connectivity.isConnected) {
      await flushQueuedMessages();
      await local.pruneThumbnails(maxEntries: 300);
    }
  }

  Future<void> flushQueuedMessages() async {
    try {
      final queued = await local.getQueuedMessages();
      for (final m in queued) {
        final id = (m['id'] ?? '').toString();
        final conversationId = (m['conversationId'] ?? '').toString();
        final messageType = (m['messageType'] ?? '').toString();
        final String? content = m['content']?.toString();
        final String? replyTo = m['replyToMessageId']?.toString();
        final List<String>? attachmentIds = (m['attachmentIds'] as List?)
            ?.map((e) => e.toString())
            .toList();

        final result = await repository.sendMessage(
          conversationId: conversationId,
          messageType: messageType,
          content: content,
          replyToMessageId: replyTo,
          location: null,
          attachmentIds: attachmentIds,
        );

        await result.fold(
          (_) async {},
          (msg) async {
            await local.removeQueuedMessage(id);
            ws.emitNewMessageById(
              conversationId: conversationId,
              messageId: msg.id,
            );
          },
        );
      }
      // Prune thumbnails after processing queue
      await local.pruneThumbnails(maxEntries: 300);
    } catch (_) {}
  }

  void dispose() {
    _connSub?.cancel();
  }
}

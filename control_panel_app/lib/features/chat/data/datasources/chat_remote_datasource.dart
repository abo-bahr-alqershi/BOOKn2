import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:bookn_cp_app/features/chat/data/models/chat_settings_model.dart';
import 'package:bookn_cp_app/features/chat/data/models/chat_user_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/error/exceptions.dart' hide ApiException;
import '../../../../core/utils/request_logger.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../models/attachment_model.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

abstract class ChatRemoteDataSource {
  Future<ConversationModel> createConversation({
    required List<String> participantIds,
    required String conversationType,
    String? title,
    String? description,
    String? propertyId,
  });

  Future<List<ConversationModel>> getConversations({
    required int pageNumber,
    required int pageSize,
  });

  Future<ConversationModel> getConversationById(String conversationId);

  Future<void> archiveConversation(String conversationId);

  Future<void> unarchiveConversation(String conversationId);

  Future<void> deleteConversation(String conversationId);

  Future<List<MessageModel>> getMessages({
    required String conversationId,
    required int pageNumber,
    required int pageSize,
    String? beforeMessageId,
  });

  Future<MessageModel> sendMessage({
    required String conversationId,
    required String messageType,
    String? content,
    Location? location,
    String? replyToMessageId,
    List<String>? attachmentIds,
  });

  Future<MessageModel> editMessage({
    required String messageId,
    required String content,
  });

  Future<void> deleteMessage(String messageId);

  Future<void> markAsRead({
    required String conversationId,
    required List<String> messageIds,
  });

  Future<void> addReaction({
    required String messageId,
    required String reactionType,
  });

  Future<void> removeReaction({
    required String messageId,
    required String reactionType,
  });

  Future<void> updateMessageStatus({
    required String messageId,
    required String status,
  });

  Future<AttachmentModel> uploadAttachment({
    required String conversationId,
    required String filePath,
    required String messageType,
    String? thumbnailPath,
    ProgressCallback? onSendProgress,
  });

  Future<SearchResult> searchChats({
    required String query,
    String? conversationId,
    String? messageType,
    String? senderId,
    DateTime? dateFrom,
    DateTime? dateTo,
    required int page,
    required int limit,
  });

  Future<List<ChatUserModel>> getAvailableUsers({
    String? userType,
    String? propertyId,
  });

  Future<List<ChatUserModel>> getAdminUsers();

  Future<void> updateUserStatus(String status);

  Future<ChatSettingsModel> getChatSettings();

  Future<ChatSettingsModel> updateChatSettings({
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? showReadReceipts,
    bool? showTypingIndicator,
    String? theme,
    String? fontSize,
    bool? autoDownloadMedia,
    bool? backupMessages,
  });
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final ApiClient apiClient;

  ChatRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<ConversationModel> createConversation({
    required List<String> participantIds,
    required String conversationType,
    String? title,
    String? description,
    String? propertyId,
  }) async {
    const requestName = 'chat.createConversation';

    // تنظيف المعرفات
    final cleanParticipantIds = participantIds
        .where((id) => id.isNotEmpty)
        .map((id) => id.trim())
        .toList();

    if (cleanParticipantIds.isEmpty) {
      throw const ServerException('قائمة المشاركين فارغة');
    }

    logRequestStart(requestName, details: {
      'participantIdsCount': cleanParticipantIds.length,
      'conversationType': conversationType,
      if (propertyId != null) 'propertyId': propertyId,
    });

    try {
      final response = await apiClient.post(
        '/api/common/chat/conversations',
        data: {
          'participantIds': cleanParticipantIds,
          'conversationType': conversationType,
          if (title != null && title.isNotEmpty) 'title': title,
          if (description != null && description.isNotEmpty)
            'description': description,
          if (propertyId != null && propertyId.isNotEmpty)
            'propertyId': propertyId,
        },
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.data['success'] == true && response.data['data'] != null) {
        return ConversationModel.fromJson(
            response.data['data'] as Map<String, dynamic>);
      }

      final errorMessage = response.data['message'] ?? 'فشل إنشاء المحادثة';
      throw ServerException(errorMessage);
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);

      // معالجة أفضل للأخطاء
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final data = e.response!.data;
        final message =
            data is Map ? (data['message'] ?? data['title'] ?? '') : '';

        if (statusCode == 400) {
          throw ServerException(
              message.isNotEmpty ? message : 'بيانات غير صحيحة');
        } else if (statusCode == 404) {
          throw const ServerException('المستخدم المطلوب غير موجود');
        } else if (statusCode == 500) {
          throw const ServerException('خطأ في الخادم، يرجى المحاولة لاحقاً');
        }
      }

      throw ApiException.fromDioError(e);
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<ConversationModel>> getConversations({
    required int pageNumber,
    required int pageSize,
  }) async {
    const requestName = 'chat.getConversations';
    logRequestStart(requestName, details: {
      'pageNumber': pageNumber,
      'pageSize': pageSize,
    });
    try {
      final response = await apiClient.get(
        '/api/common/chat/conversations',
        queryParameters: {
          'pageNumber': pageNumber,
          'pageSize': pageSize,
        },
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.data['conversations'] != null) {
        final list = (response.data['conversations'] as List)
            .map((json) => ConversationModel.fromJson(json))
            .toList();
        return list;
      }
      return [];
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ApiException.fromDioError(e);
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<ConversationModel> getConversationById(String conversationId) async {
    const requestName = 'chat.getConversationById';
    logRequestStart(requestName, details: {
      'conversationId': conversationId,
    });
    try {
      final response = await apiClient.get(
        '/api/common/chat/conversations/$conversationId',
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.data['success'] == true && response.data['data'] != null) {
        return ConversationModel.fromJson(response.data['data']);
      }
      throw ServerException(response.data['message'] ?? 'المحادثة غير موجودة');
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ApiException.fromDioError(e);
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> archiveConversation(String conversationId) async {
    const requestName = 'chat.archiveConversation';
    logRequestStart(requestName, details: {'conversationId': conversationId});
    try {
      final response = await apiClient.post(
        '/api/common/chat/conversations/$conversationId/archive',
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.data['success'] != true) {
        throw ServerException(response.data['message'] ?? 'فشل أرشفة المحادثة');
      }
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ApiException.fromDioError(e);
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> unarchiveConversation(String conversationId) async {
    const requestName = 'chat.unarchiveConversation';
    logRequestStart(requestName, details: {'conversationId': conversationId});
    try {
      final response = await apiClient.post(
        '/api/common/chat/conversations/$conversationId/unarchive',
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.data['success'] != true) {
        throw ServerException(
            response.data['message'] ?? 'فشل إلغاء أرشفة المحادثة');
      }
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ApiException.fromDioError(e);
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    const requestName = 'chat.deleteConversation';
    logRequestStart(requestName, details: {'conversationId': conversationId});
    try {
      final response = await apiClient.delete(
        '/api/common/chat/conversations/$conversationId',
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      // Some APIs may return 204 No Content or plain string. Accept those as success.
      final status = response.statusCode ?? 200;
      if (status == 204) return;

      final data = response.data;
      if (data == null) return;
      if (data is String) return; // treat plain string as OK
      if (data is Map && (data['success'] == true || data['isSuccess'] == true))
        return;

      if (data is Map) {
        throw ServerException(data['message'] ?? 'فشل حذف المحادثة');
      }
      // Fallback: assume success if we reached here without explicit failure
      return;
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ApiException.fromDioError(e);
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<MessageModel>> getMessages({
    required String conversationId,
    required int pageNumber,
    required int pageSize,
    String? beforeMessageId,
  }) async {
    const requestName = 'chat.getMessages';
    logRequestStart(requestName, details: {
      'conversationId': conversationId,
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      if (beforeMessageId != null) 'beforeMessageId': beforeMessageId,
    });
    try {
      final response = await apiClient.get(
        '/api/common/chat/conversations/$conversationId/messages',
        queryParameters: {
          'pageNumber': pageNumber,
          'pageSize': pageSize,
          if (beforeMessageId != null) 'beforeMessageId': beforeMessageId,
        },
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.data['messages'] != null) {
        return (response.data['messages'] as List)
            .map((json) => MessageModel.fromJson(json))
            .toList();
      }
      return [];
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ApiException.fromDioError(e);
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String messageType,
    String? content,
    Location? location,
    String? replyToMessageId,
    List<String>? attachmentIds,
  }) async {
    const requestName = 'chat.sendMessage';
    logRequestStart(requestName, details: {
      'conversationId': conversationId,
      'messageType': messageType,
    });

    try {
      // تحقق من صحة البيانات
      if (messageType == 'text' && (content == null || content.isEmpty)) {
        throw const ServerException('محتوى الرسالة مطلوب للرسائل النصية');
      }

      // استخدم FormData لأن الـ backend يتوقع [FromForm]
      final formData = FormData.fromMap({
        'conversationId': conversationId,
        'messageType': messageType,
        if (content != null && content.isNotEmpty) 'content': content,
        if (location != null)
          'locationJson': jsonEncode({
            'latitude': location.latitude,
            'longitude': location.longitude,
            if (location.address != null) 'address': location.address,
          }),
        if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
        if (attachmentIds != null && attachmentIds.isNotEmpty)
          for (int i = 0; i < attachmentIds.length; i++)
            'attachmentIds[$i]': attachmentIds[i],
      });

      final response = await apiClient.post(
        '/api/common/chat/conversations/$conversationId/messages',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.data != null && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;

        // تحويل message_id إلى id للتوافق مع MessageModel
        if (data.containsKey('message_id')) {
          data['id'] = data['message_id'];
        }

        // التحقق من البيانات المطلوبة
        if (data['messageType'] == null ||
            data['messageType'].toString().isEmpty) {
          data['messageType'] = messageType; // استخدم القيمة المرسلة
        }

        if (messageType == 'text' && data['content'] == null) {
          data['content'] = content; // استخدم القيمة المرسلة
        }

        // تعيين status إذا كان فارغاً
        if (data['status'] == null || data['status'].toString().isEmpty) {
          data['status'] = 'sent';
        }

        // إذا لم يُرجع الخادم قائمة المرفقات لكننا أرسلنا attachmentIds،
        // نقوم بإنشاء مصفوفة مرفقات مبسطة لعرض الصور مباشرة في الواجهة
        final hasNoAttachments = (data['attachments'] == null) ||
            ((data['attachments'] is List) && (data['attachments'] as List).isEmpty);
        if (hasNoAttachments && attachmentIds != null && attachmentIds.isNotEmpty) {
          data['attachments'] = attachmentIds
              .where((id) => id.isNotEmpty)
              .map((id) => {
                    'id': id,
                    'attachment_id': id,
                    // توفير مسار يمكن لـ ImageUtils.resolveUrl تحويله إلى رابط كامل
                    'file_url': '/api/common/chat/attachments/$id',
                  })
              .toList();
        }

        return MessageModel.fromJson(data);
      }

      throw const ServerException('صيغة الاستجابة غير صحيحة');
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);

      if (e.response?.statusCode == 400) {
        final message = e.response?.data?['message'] ?? 'بيانات غير صحيحة';
        throw ServerException(message);
      }

      throw ApiException.fromDioError(e);
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<MessageModel> editMessage({
    required String messageId,
    required String content,
  }) async {
    const requestName = 'chat.editMessage';
    logRequestStart(requestName, details: {'messageId': messageId});
    try {
      final response = await apiClient.put(
        '/api/common/chat/messages/$messageId',
        data: {
          'content': content,
        },
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.data['success'] == true && response.data['data'] != null) {
        return MessageModel.fromJson(response.data['data']);
      }
      throw ServerException(response.data['message'] ?? 'فشل تعديل الرسالة');
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ApiException.fromDioError(e);
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    const requestName = 'chat.deleteMessage';
    logRequestStart(requestName, details: {'messageId': messageId});
    try {
      final response = await apiClient.delete(
        '/api/common/chat/messages/$messageId',
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.data['success'] != true) {
        throw ServerException(response.data['message'] ?? 'فشل حذف الرسالة');
      }
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ApiException.fromDioError(e);
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> markAsRead({
    required String conversationId,
    required List<String> messageIds,
  }) async {
    const requestName = 'chat.markAsRead';
    logRequestStart(requestName, details: {
      'conversationId': conversationId,
      'messageIdsCount': messageIds.length,
    });
    try {
      for (final messageId in messageIds) {
        final response = await apiClient.put(
          '/api/common/chat/messages/$messageId/status',
          data: {
            'status': 'read',
          },
        );
        logRequestSuccess(requestName, statusCode: response.statusCode);
      }
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ApiException.fromDioError(e);
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> addReaction({
    required String messageId,
    required String reactionType,
  }) async {
    const requestName = 'chat.addReaction';
    logRequestStart(requestName, details: {
      'messageId': messageId,
      'reactionType': reactionType,
    });
    try {
      final response = await apiClient.post(
        '/api/common/chat/messages/$messageId/reactions',
        data: {
          'reactionType': reactionType,
        },
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.data['success'] != true) {
        throw ServerException(response.data['message'] ?? 'فشل إضافة التفاعل');
      }
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ApiException.fromDioError(e);
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> removeReaction({
    required String messageId,
    required String reactionType,
  }) async {
    const requestName = 'chat.removeReaction';
    logRequestStart(requestName, details: {
      'messageId': messageId,
      'reactionType': reactionType,
    });
    try {
      final response = await apiClient.delete(
        '/api/common/chat/messages/$messageId/reactions/$reactionType',
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.data['success'] != true) {
        throw ServerException(response.data['message'] ?? 'فشل إزالة التفاعل');
      }
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ApiException.fromDioError(e);
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateMessageStatus({
    required String messageId,
    required String status,
  }) async {
    const requestName = 'chat.updateMessageStatus';
    logRequestStart(requestName, details: {
      'messageId': messageId,
      'status': status,
    });
    try {
      final response = await apiClient.put(
        '/api/common/chat/messages/$messageId/status',
        data: {
          'status': status,
        },
      );
      logRequestSuccess(requestName, statusCode: response.statusCode);
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ApiException.fromDioError(e);
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ServerException(e.toString());
    }
  }

  @override
  Future<AttachmentModel> uploadAttachment({
    required String conversationId,
    required String filePath,
    required String messageType,
    String? thumbnailPath,
    ProgressCallback? onSendProgress,
  }) async {
    const requestName = 'chat.uploadAttachment';
    logRequestStart(requestName, details: {
      'conversationId': conversationId,
      'filePath': filePath,
      'messageType': messageType,
    });
    try {
      final file = File(filePath);
      final fileName = file.path.split('/').last;

      final formData = FormData();
      formData.fields
        ..add(MapEntry('messageType', messageType))
        ..add(MapEntry('conversationId', conversationId));
      formData.files.add(MapEntry(
        'file',
        await MultipartFile.fromFile(file.path, filename: fileName),
      ));
      if (thumbnailPath != null && thumbnailPath.isNotEmpty) {
        final thumbFile = File(thumbnailPath);
        if (thumbFile.existsSync()) {
          final thumbName = thumbFile.path.split('/').last;
          formData.files.add(MapEntry(
            'thumbnail',
            await MultipartFile.fromFile(thumbFile.path, filename: thumbName),
          ));
        }
      }

      final response = await apiClient.upload(
        '/api/common/chat/upload',
        formData: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
        onSendProgress: onSendProgress,
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        final dynamic payload = map['data'] ?? map['attachment'];
        if (payload != null) {
          return AttachmentModel.fromJson(payload as Map<String, dynamic>);
        }
      }
      throw ServerException(response.data['message'] ?? 'فشل رفع المرفق');
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ApiException.fromDioError(e);
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<SearchResult> searchChats({
    required String query,
    String? conversationId,
    String? messageType,
    String? senderId,
    DateTime? dateFrom,
    DateTime? dateTo,
    required int page,
    required int limit,
  }) async {
    const requestName = 'chat.searchChats';
    logRequestStart(requestName, details: {
      'query': query,
      if (conversationId != null) 'conversationId': conversationId,
      if (messageType != null) 'messageType': messageType,
      if (senderId != null) 'senderId': senderId,
      if (dateFrom != null) 'dateFrom': dateFrom.toIso8601String(),
      if (dateTo != null) 'dateTo': dateTo.toIso8601String(),
      'page': page,
      'limit': limit,
    });
    try {
      final response = await apiClient.get(
        '/api/common/chat/search',
        queryParameters: {
          'query': query,
          if (conversationId != null) 'conversationId': conversationId,
          if (messageType != null) 'messageType': messageType,
          if (senderId != null) 'senderId': senderId,
          if (dateFrom != null) 'dateFrom': dateFrom.toIso8601String(),
          if (dateTo != null) 'dateTo': dateTo.toIso8601String(),
          'page': page,
          'limit': limit,
        },
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      final data = response.data as Map<String, dynamic>;
      final messages = (data['messages'] as List? ?? const [])
          .map((j) => MessageModel.fromJson(j))
          .toList();
      final conversations = (data['conversations'] as List? ?? const [])
          .map((j) => ConversationModel.fromJson(j))
          .toList();
      final totalCount = (data['total'] ?? data['totalCount']) as int? ?? 0;
      final hasMore = (data['hasMore'] as bool?) ?? (data['nextPage'] != null);
      final nextPageNumber = data['nextPage'] ?? data['nextPageNumber'];

      return SearchResult(
        messages: messages,
        conversations: conversations,
        totalCount: totalCount,
        hasMore: hasMore,
        nextPageNumber: nextPageNumber as int?,
      );
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ApiException.fromDioError(e);
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<ChatUserModel>> getAvailableUsers({
    String? userType,
    String? propertyId,
  }) async {
    const requestName = 'chat.getAvailableUsers';
    logRequestStart(requestName, details: {
      if (userType != null) 'userType': userType,
      if (propertyId != null) 'propertyId': propertyId,
    });
    try {
      final response = await apiClient.get(
        '/api/common/chat/users/available',
        queryParameters: {
          if (userType != null) 'userType': userType,
          if (propertyId != null) 'propertyId': propertyId,
        },
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.data is Map<String, dynamic> &&
          response.data['users'] != null) {
        return (response.data['users'] as List)
            .map((json) => ChatUserModel.fromJson(json))
            .toList();
      }
      return [];
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ApiException.fromDioError(e);
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<ChatUserModel>> getAdminUsers() async {
    const requestName = 'chat.getAdminUsers';
    logRequestStart(requestName);
    try {
      final response = await apiClient.get(
        '/api/common/chat/users/admins',
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.data is Map<String, dynamic> &&
          response.data['users'] != null) {
        return (response.data['users'] as List)
            .map((json) => ChatUserModel.fromJson(json))
            .toList();
      }
      return [];
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ApiException.fromDioError(e);
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateUserStatus(String status) async {
    const requestName = 'chat.updateUserStatus';
    logRequestStart(requestName, details: {'status': status});
    try {
      final response = await apiClient.put(
        '/api/common/chat/users/status',
        data: {
          'status': status,
        },
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.data['success'] != true) {
        throw ServerException(response.data['message'] ?? 'فشل تحديث الحالة');
      }
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ApiException.fromDioError(e);
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<ChatSettingsModel> getChatSettings() async {
    const requestName = 'chat.getChatSettings';
    logRequestStart(requestName);
    try {
      final response = await apiClient.get('/api/common/chat/settings');

      logRequestSuccess(requestName, statusCode: response.statusCode);

      dynamic raw = response.data;
      // قد يأتي الرد مباشرة كجسم DTO أو داخل غلاف success/data
      Map<String, dynamic>? dataMap;
      if (raw is Map<String, dynamic>) {
        if (raw.containsKey('data')) {
          // شكل: { success: true, data: {...} }
          final successVal = raw['success'];
          final inner = raw['data'];
          if (successVal == true && inner is Map<String, dynamic>) {
            dataMap = inner;
          }
        }
        // شكل مباشرة: { id:..., userId:..., notificationsEnabled:... }
        if (dataMap == null &&
            (raw.containsKey('id') ||
                raw.containsKey('userId') ||
                raw.containsKey('user_id'))) {
          dataMap = raw;
        }
      }

      if (dataMap != null) {
        return ChatSettingsModel.fromJson(dataMap);
      }

      // إذا وصل الرد بدون بيانات صالحة نعيد الافتراضي بدل رمي خطأ
      return const ChatSettingsModel(id: '', userId: '');
    } on DioException catch (e, s) {
      // معالجة متوقعة في حالة عدم وجود إعدادات (أول مرة) => إعادة افتراضي بدون تسجيل كخطأ حرج
      final msg = e.response?.data is Map
          ? (e.response?.data['message']?.toString() ?? '')
          : '';
      final notFound = e.response?.statusCode == 404 || msg.contains('إعدادات');
      if (notFound) {
        logRequestSuccess('$requestName.not_found_fallback',
            statusCode: e.response?.statusCode);
        return const ChatSettingsModel(id: '', userId: '');
      }
      logRequestError(requestName, e, stackTrace: s);
      throw ApiException.fromDioError(e);
    } on ApiException catch (e, s) {
      final notFound = e.statusCode == 404 || e.message.contains('إعدادات');
      if (notFound) {
        logRequestSuccess('$requestName.not_found_fallback',
            statusCode: e.statusCode);
        return const ChatSettingsModel(id: '', userId: '');
      }
      logRequestError(requestName, e, stackTrace: s);
      rethrow;
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<ChatSettingsModel> updateChatSettings({
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? showReadReceipts,
    bool? showTypingIndicator,
    String? theme,
    String? fontSize,
    bool? autoDownloadMedia,
    bool? backupMessages,
  }) async {
    const requestName = 'chat.updateChatSettings';
    logRequestStart(requestName);
    try {
      final response = await apiClient.put(
        '/api/common/chat/settings',
        data: {
          if (notificationsEnabled != null)
            'notificationsEnabled': notificationsEnabled,
          if (soundEnabled != null) 'soundEnabled': soundEnabled,
          if (showReadReceipts != null) 'showReadReceipts': showReadReceipts,
          if (showTypingIndicator != null)
            'showTypingIndicator': showTypingIndicator,
          if (theme != null) 'theme': theme,
          if (fontSize != null) 'fontSize': fontSize,
          if (autoDownloadMedia != null) 'autoDownloadMedia': autoDownloadMedia,
          if (backupMessages != null) 'backupMessages': backupMessages,
        },
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      dynamic raw = response.data;
      Map<String, dynamic>? dataMap;
      if (raw is Map<String, dynamic>) {
        if (raw.containsKey('data')) {
          final successVal = raw['success'];
          final inner = raw['data'];
          if ((successVal == null || successVal == true) &&
              inner is Map<String, dynamic>) {
            dataMap = inner;
          }
        }
        if (dataMap == null &&
            (raw.containsKey('id') ||
                raw.containsKey('userId') ||
                raw.containsKey('user_id'))) {
          dataMap = raw;
        }
      }

      if (dataMap != null) {
        return ChatSettingsModel.fromJson(dataMap);
      }

      final errorMessage = (raw is Map<String, dynamic>)
          ? (raw['message']?.toString() ?? 'فشل تحديث إعدادات الدردشة')
          : 'فشل تحديث إعدادات الدردشة';
      throw ServerException(errorMessage);
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ApiException.fromDioError(e);
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }
}

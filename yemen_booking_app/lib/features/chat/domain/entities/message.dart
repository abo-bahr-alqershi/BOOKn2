import 'package:equatable/equatable.dart';
import 'attachment.dart';

class Message extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String? senderName;
  final String messageType;
  final String? content;
  final Location? location;
  final String? replyToMessageId;
  final List<MessageReaction> reactions;
  final List<Attachment> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status;
  final bool isEdited;
  final DateTime? editedAt;
  final DeliveryReceipt? deliveryReceipt;
  final bool isDeleted;
  final String? failureReason; // إضافة سبب الفشل

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.senderName,
    required this.messageType,
    this.content,
    this.location,
    this.replyToMessageId,
    this.reactions = const [],
    this.attachments = const [],
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    this.isEdited = false,
    this.editedAt,
    this.deliveryReceipt,
    this.isDeleted = false,
    this.failureReason,
  });

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderId,
        senderName,
        messageType,
        content,
        location,
        replyToMessageId,
        reactions,
        attachments,
        createdAt,
        updatedAt,
        status,
        isEdited,
        editedAt,
        deliveryReceipt,
        isDeleted,
        failureReason,
      ];
}

class Location extends Equatable {
  final double latitude;
  final double longitude;
  final String? address;

  const Location({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  @override
  List<Object?> get props => [latitude, longitude, address];
}

class MessageReaction extends Equatable {
  final String id;
  final String messageId;
  final String userId;
  final String reactionType; // "like", "love", "laugh", "sad", "angry", "wow"

  const MessageReaction({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.reactionType,
  });

  @override
  List<Object?> get props => [id, messageId, userId, reactionType];
}

class DeliveryReceipt extends Equatable {
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final List<String> readBy;

  const DeliveryReceipt({
    this.deliveredAt,
    this.readAt,
    this.readBy = const [],
  });

  @override
  List<Object?> get props => [deliveredAt, readAt, readBy];
}

extension LocationExtension on Location {
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      if (address != null) 'address': address,
    };
  }
}

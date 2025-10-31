import 'package:yemen_booking_app/features/chat/data/models/delivery_receipt_model.dart';
import 'message_reaction_model.dart';

import '../../domain/entities/message.dart';
import 'attachment_model.dart';

class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.conversationId,
    required super.senderId,
    required super.messageType,
    super.content,
    super.location,
    super.replyToMessageId,
    super.reactions,
    super.attachments,
    required super.createdAt,
    required super.updatedAt,
    required super.status,
    super.isEdited,
    super.editedAt,
    super.deliveryReceipt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? json['message_id'] ?? '',
      conversationId: json['conversationId'] ?? json['conversation_id'] ?? '',
      senderId: json['senderId'] ?? json['sender_id'] ?? '',
      messageType: json['messageType'] ?? json['message_type'] ?? 'text',
      content: json['content'],
      location: json['location'] != null
          ? LocationModel.fromJson(json['location'])
          : null,
      replyToMessageId: json['replyToMessageId'] ?? json['reply_to_message_id'],
      reactions: (json['reactions'] as List? ?? [])
          .map((r) => MessageReactionModel.fromJson(r))
          .toList(),
      attachments: (json['attachments'] as List? ?? [])
          .map((a) => AttachmentModel.fromJson(a))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at']),
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['updated_at']),
      status: json['status'] ?? 'sent',
      isEdited: json['isEdited'] ?? json['is_edited'] ?? false,
      editedAt: json['editedAt'] != null || json['edited_at'] != null
          ? DateTime.parse(json['editedAt'] ?? json['edited_at'])
          : null,
      deliveryReceipt:
          json['deliveryReceipt'] != null || json['delivery_receipt'] != null
              ? DeliveryReceiptModel.fromJson(
                  json['deliveryReceipt'] ?? json['delivery_receipt'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message_id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'message_type': messageType,
      if (content != null) 'content': content,
      if (location != null) 'location': (location as LocationModel).toJson(),
      if (replyToMessageId != null) 'reply_to_message_id': replyToMessageId,
      'reactions':
          reactions.map((r) => (r as MessageReactionModel).toJson()).toList(),
      'attachments':
          attachments.map((a) => (a as AttachmentModel).toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'status': status,
      'is_edited': isEdited,
      if (editedAt != null) 'edited_at': editedAt!.toIso8601String(),
      if (deliveryReceipt != null)
        'delivery_receipt': (deliveryReceipt as DeliveryReceiptModel).toJson(),
    };
  }

  factory MessageModel.fromEntity(Message message) {
    return MessageModel(
      id: message.id,
      conversationId: message.conversationId,
      senderId: message.senderId,
      messageType: message.messageType,
      content: message.content,
      location: message.location,
      replyToMessageId: message.replyToMessageId,
      reactions: message.reactions,
      attachments: message.attachments,
      createdAt: message.createdAt,
      updatedAt: message.updatedAt,
      status: message.status,
      isEdited: message.isEdited,
      editedAt: message.editedAt,
      deliveryReceipt: message.deliveryReceipt,
    );
  }
}

class LocationModel extends Location {
  const LocationModel({
    required super.latitude,
    required super.longitude,
    super.address,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      if (address != null) 'address': address,
    };
  }
}

import 'package:yemen_booking_app/features/chat/domain/entities/message.dart';


class MessageReactionModel extends MessageReaction {
  const MessageReactionModel({
    required super.id,
    required super.messageId,
    required super.userId,
    required super.reactionType,
  });

  factory MessageReactionModel.fromJson(Map<String, dynamic> json) {
    return MessageReactionModel(
      id: json['id'] ?? '',
      messageId: json['messageId'] ?? json['message_id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      reactionType: json['reactionType'] ?? json['reaction_type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message_id': messageId,
      'user_id': userId,
      'reaction_type': reactionType,
    };
  }
}

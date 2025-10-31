import '../../domain/entities/admin_notification.dart';

class AdminNotificationModel extends AdminNotificationEntity {
  AdminNotificationModel({
    required super.id,
    required super.type,
    required super.title,
    required super.message,
    required super.status,
    required super.priority,
    required super.recipientId,
    super.recipientName,
    super.recipientEmail,
    super.recipientPhone,
    required super.isRead,
    required super.createdAt,
    super.readAt,
  });

  factory AdminNotificationModel.fromJson(Map<String, dynamic> json) {
    return AdminNotificationModel(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
      recipientId: json['recipientId'] as String,
      recipientName: json['recipientName'] as String?,
      recipientEmail: json['recipientEmail'] as String?,
      recipientPhone: json['recipientPhone'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt'] as String) : null,
    );
  }
}


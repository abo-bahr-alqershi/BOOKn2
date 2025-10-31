class AdminNotificationEntity {
  final String id;
  final String type;
  final String title;
  final String message;
  final String status;
  final String priority;
  final String recipientId;
  final String? recipientName;
  final String? recipientEmail;
  final String? recipientPhone;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  AdminNotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.status,
    required this.priority,
    required this.recipientId,
    this.recipientName,
    this.recipientEmail,
    this.recipientPhone,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });
}


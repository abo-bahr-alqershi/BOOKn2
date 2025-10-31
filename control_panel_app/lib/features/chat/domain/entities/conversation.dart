import 'package:equatable/equatable.dart';
import 'package:bookn_cp_app/features/chat/domain/entities/message.dart';

class Conversation extends Equatable {
  final String id;
  final String conversationType; // "direct" or "group"
  final String? title;
  final String? description;
  final String? avatar;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Message? lastMessage;
  final int unreadCount;
  final bool isArchived;
  final bool isMuted;
  final String? propertyId;
  final List<ChatUser> participants;

  const Conversation({
    required this.id,
    required this.conversationType,
    this.title,
    this.description,
    this.avatar,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.unreadCount = 0,
    this.isArchived = false,
    this.isMuted = false,
    this.propertyId,
    required this.participants,
  });

  @override
  List<Object?> get props => [
    id,
    conversationType,
    title,
    description,
    avatar,
    createdAt,
    updatedAt,
    lastMessage,
    unreadCount,
    isArchived,
    isMuted,
    propertyId,
    participants,
  ];

  // Helper methods
  bool get isDirectChat => conversationType == 'direct';
  bool get isGroupChat => conversationType == 'group';
  bool get hasUnreadMessages => unreadCount > 0;
  
  // Get other participant in direct chat
  ChatUser? getOtherParticipant(String currentUserId) {
    if (!isDirectChat || participants.length != 2) return null;
    return participants.firstWhere((p) => p.id != currentUserId);
  }
}

class ChatUser extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? profileImage;
  final String userType; // "admin", "property_owner", "customer"
  final String status; // "online", "offline", "away", "busy"
  final DateTime? lastSeen;
  final String? propertyId;
  final bool isOnline;

  const ChatUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profileImage,
    required this.userType,
    required this.status,
    this.lastSeen,
    this.propertyId,
    required this.isOnline,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    phone,
    profileImage,
    userType,
    status,
    lastSeen,
    propertyId,
    isOnline,
  ];
}

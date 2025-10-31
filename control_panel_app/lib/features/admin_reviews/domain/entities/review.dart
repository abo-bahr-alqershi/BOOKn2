// lib/features/admin_reviews/domain/entities/review.dart

import 'package:equatable/equatable.dart';
import 'review_image.dart';

class Review extends Equatable {
  final String id;
  final String bookingId;
  final String propertyName;
  final String? unitName;
  final String userName;
  final double cleanliness;
  final double service;
  final double location;
  final double value;
  final String comment;
  final DateTime createdAt;
  final List<ReviewImage> images;
  final bool isApproved;
  final bool isPending;
  final String? responseText;
  final DateTime? responseDate;
  final String? respondedBy;
  // Optional enriched fields
  final String? propertyCity;
  final String? propertyAddress;
  final String? userEmail;
  final String? userPhone;
  final DateTime? bookingCheckIn;
  final DateTime? bookingCheckOut;
  final int? guestsCount;
  final String? bookingStatus;
  final String? bookingSource;
  
  const Review({
    required this.id,
    required this.bookingId,
    required this.propertyName,
    this.unitName,
    required this.userName,
    required this.cleanliness,
    required this.service,
    required this.location,
    required this.value,
    required this.comment,
    required this.createdAt,
    required this.images,
    this.isApproved = false,
    this.isPending = true,
    this.responseText,
    this.responseDate,
    this.respondedBy,
    this.propertyCity,
    this.propertyAddress,
    this.userEmail,
    this.userPhone,
    this.bookingCheckIn,
    this.bookingCheckOut,
    this.guestsCount,
    this.bookingStatus,
    this.bookingSource,
  });
  
  double get averageRating => (cleanliness + service + location + value) / 4;
  
  bool get hasResponse => responseText != null && responseText!.isNotEmpty;
  
  @override
  List<Object?> get props => [
    id, bookingId, propertyName, unitName, userName,
    cleanliness, service, location, value,
    comment, createdAt, images, isApproved,
    isPending, responseText, responseDate, respondedBy,
    propertyCity, propertyAddress, userEmail, userPhone,
    bookingCheckIn, bookingCheckOut, guestsCount, bookingStatus, bookingSource,
  ];
}
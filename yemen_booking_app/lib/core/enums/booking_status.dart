enum BookingStatus {
  confirmed,
  pending,
  cancelled,
  completed,
  checkedIn,
}

extension BookingStatusExtension on BookingStatus {
  String get displayName {
    switch (this) {
      case BookingStatus.confirmed:
        return 'مؤكد';
      case BookingStatus.pending:
        return 'معلق';
      case BookingStatus.cancelled:
        return 'ملغى';
      case BookingStatus.completed:
        return 'مكتمل';
      case BookingStatus.checkedIn:
        return 'تم تسجيل الوصول';
    }
  }

  String get displayNameEn {
    switch (this) {
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.checkedIn:
        return 'Checked In';
    }
  }
}
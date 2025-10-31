/// Helper functions for formatting time differences
class TimeAgoHelper {
  /// Returns a human-readable string representing how long ago a DateTime was
  /// in Arabic language
  static String getTimeAgoArabic(DateTime? dateTime) {
    if (dateTime == null) {
      return 'غير معروف';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'الآن';
    } else if (difference.inMinutes < 2) {
      return 'منذ دقيقة';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقائق';
    } else if (difference.inHours < 2) {
      return 'منذ ساعة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعات';
    } else if (difference.inDays < 2) {
      return 'منذ يوم';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? 'منذ أسبوع' : 'منذ $weeks أسابيع';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? 'منذ شهر' : 'منذ $months أشهر';
    } else {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? 'منذ سنة' : 'منذ $years سنوات';
    }
  }

  /// Returns a shorter version of time ago in Arabic
  static String getTimeAgoShortArabic(DateTime? dateTime) {
    if (dateTime == null) {
      return 'غير معروف';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}د';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}س';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}ي';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}ش';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}سنة';
    }
  }

  /// Check if user is online (last seen within 5 minutes)
  static bool isUserOnline(DateTime? lastSeen) {
    if (lastSeen == null) return false;
    final difference = DateTime.now().difference(lastSeen);
    return difference.inMinutes < 5;
  }

  /// Get online status text
  static String getOnlineStatusArabic(DateTime? lastSeen) {
    if (isUserOnline(lastSeen)) {
      return 'متصل الآن';
    } else if (lastSeen == null) {
      return 'غير معروف';
    } else {
      return getTimeAgoArabic(lastSeen);
    }
  }

  /// Get activity status: online, recently_active, away, offline
  static ActivityStatus getActivityStatus(DateTime? lastSeen) {
    if (lastSeen == null) return ActivityStatus.offline;
    
    final difference = DateTime.now().difference(lastSeen);
    
    if (difference.inMinutes < 5) {
      return ActivityStatus.online;
    } else if (difference.inMinutes < 30) {
      return ActivityStatus.recentlyActive;
    } else if (difference.inHours < 24) {
      return ActivityStatus.away;
    } else {
      return ActivityStatus.offline;
    }
  }
}

/// Enum for user activity status
enum ActivityStatus {
  online,
  recentlyActive,
  away,
  offline,
}

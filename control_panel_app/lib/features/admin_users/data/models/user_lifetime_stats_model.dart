import '../../domain/entities/user_lifetime_stats.dart';

class UserLifetimeStatsModel extends UserLifetimeStats {
  const UserLifetimeStatsModel({
    required int totalNightsStayed,
    required double totalMoneySpent,
    String? favoriteCity,
  }) : super(
          totalNightsStayed: totalNightsStayed,
          totalMoneySpent: totalMoneySpent,
          favoriteCity: favoriteCity,
        );

  factory UserLifetimeStatsModel.fromJson(Map<String, dynamic> json) {
    try {
    return UserLifetimeStatsModel(
        totalNightsStayed: json['totalNightsStayed'] as int? ?? 0,
        totalMoneySpent: (json['totalMoneySpent'] as num?)?.toDouble() ?? 0.0,
      favoriteCity: json['favoriteCity'] as String?,
    );
    } catch (e) {
      throw Exception('Failed to parse UserLifetimeStatsModel: ${e.toString()}');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'totalNightsStayed': totalNightsStayed,
      'totalMoneySpent': totalMoneySpent,
      'favoriteCity': favoriteCity,
    };
  }
}
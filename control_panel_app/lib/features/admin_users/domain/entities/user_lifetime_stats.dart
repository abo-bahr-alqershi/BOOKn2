import 'package:equatable/equatable.dart';

class UserLifetimeStats extends Equatable {
  final int totalNightsStayed;
  final double totalMoneySpent;
  final String? favoriteCity;

  const UserLifetimeStats({
    required this.totalNightsStayed,
    required this.totalMoneySpent,
    this.favoriteCity,
  });

  @override
  List<Object?> get props => [
        totalNightsStayed,
        totalMoneySpent,
        favoriteCity,
      ];
}
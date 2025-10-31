import 'package:equatable/equatable.dart';

class PropertyPolicy extends Equatable {
  final String id;
  final String policyType;
  final String policyContent;
  final bool isActive;
  final String type;
  final String description;
  final Map<String, dynamic> rules;

  const PropertyPolicy({
    required this.id,
    required this.policyType,
    required this.policyContent,
    required this.isActive,
    required this.type,
    required this.description,
    required this.rules,
  });

  @override
  List<Object?> get props => [
        id,
        policyType,
        policyContent,
        isActive,
        type,
        description,
        rules,
      ];
}
// lib/features/admin_financial/data/models/chart_of_account_model.dart

import '../../domain/entities/chart_of_account.dart';

/// 🏦 نموذج دليل الحسابات
class ChartOfAccountModel extends ChartOfAccount {
  const ChartOfAccountModel({
    required super.id,
    required super.accountNumber,
    required super.nameAr,
    required super.nameEn,
    required super.accountType,
    required super.category,
    required super.normalBalance,
    required super.level,
    super.description,
    super.balance,
    super.currency,
    super.isActive,
    super.isSystemAccount,
    super.canPost,
    super.parentAccountId,
    super.parentAccount,
    super.subAccounts,
    super.userId,
    super.propertyId,
    required super.createdAt,
    super.updatedAt,
  });

  factory ChartOfAccountModel.fromJson(Map<String, dynamic> json) {
    return ChartOfAccountModel(
      id: json['id']?.toString() ?? '',
      accountNumber: json['accountNumber'] ?? '',
      nameAr: json['nameAr'] ?? '',
      nameEn: json['nameEn'] ?? '',
      accountType: _parseAccountType(json['accountType']),
      category: _parseAccountCategory(json['category']),
      normalBalance: _parseAccountNature(json['normalBalance']),
      level: json['level'] ?? 1,
      description: json['description'],
      balance: (json['balance'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'YER',
      isActive: json['isActive'] ?? true,
      isSystemAccount: json['isSystemAccount'] ?? false,
      canPost: json['canPost'] ?? true,
      parentAccountId: json['parentAccountId']?.toString(),
      parentAccount: json['parentAccount'] != null
          ? ChartOfAccountModel.fromJson(json['parentAccount'])
          : null,
      subAccounts: json['subAccounts'] != null
          ? (json['subAccounts'] as List)
              .map((e) => ChartOfAccountModel.fromJson(e))
              .toList()
          : null,
      userId: json['userId']?.toString(),
      propertyId: json['propertyId']?.toString(),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accountNumber': accountNumber,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'accountType': accountType.index + 1, // Backend enums start at 1
      'category': category.index + 1, // Backend enums start at 1
      'normalBalance': normalBalance.index + 1, // Backend enums start at 1
      'level': level,
      'description': description,
      'balance': balance,
      'currency': currency,
      'isActive': isActive,
      'isSystemAccount': isSystemAccount,
      'canPost': canPost,
      'parentAccountId': parentAccountId,
      'userId': userId,
      'propertyId': propertyId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static AccountType _parseAccountType(dynamic value) {
    if (value == null) return AccountType.assets;
    
    // Handle integer values (backend enum indices start at 1)
    if (value is int) {
      final index = value - 1; // Backend starts at 1, Flutter at 0
      if (index >= 0 && index < AccountType.values.length) {
        return AccountType.values[index];
      }
    }
    
    // Handle string values
    if (value is String) {
      // Try to parse as number first
      final intValue = int.tryParse(value);
      if (intValue != null) {
        return _parseAccountType(intValue);
      }
      
      // Map backend string names to Flutter enum values
      final enumMap = <String, AccountType>{
        'Assets': AccountType.assets,
        'Liabilities': AccountType.liabilities,
        'Equity': AccountType.equity,
        'Revenue': AccountType.revenue,
        'Expenses': AccountType.expenses,
      };
      
      // Try exact match
      if (enumMap.containsKey(value)) {
        return enumMap[value]!;
      }
      
      // Try case-insensitive match
      final lowerValue = value.toLowerCase();
      for (final entry in enumMap.entries) {
        if (entry.key.toLowerCase() == lowerValue) {
          return entry.value;
        }
      }
    }
    
    return AccountType.assets;
  }

  static AccountCategory _parseAccountCategory(dynamic value) {
    if (value == null) return AccountCategory.main;
    
    // Handle integer values (backend enum indices start at 1)
    if (value is int) {
      final index = value - 1; // Backend starts at 1, Flutter at 0
      if (index >= 0 && index < AccountCategory.values.length) {
        return AccountCategory.values[index];
      }
    }
    
    // Handle string values
    if (value is String) {
      // Try to parse as number first
      final intValue = int.tryParse(value);
      if (intValue != null) {
        return _parseAccountCategory(intValue);
      }
      
      // Map backend string names to Flutter enum values
      final enumMap = <String, AccountCategory>{
        'Main': AccountCategory.main,
        'Sub': AccountCategory.sub,
      };
      
      // Try exact match
      if (enumMap.containsKey(value)) {
        return enumMap[value]!;
      }
      
      // Try case-insensitive match
      final lowerValue = value.toLowerCase();
      for (final entry in enumMap.entries) {
        if (entry.key.toLowerCase() == lowerValue) {
          return entry.value;
        }
      }
    }
    
    return AccountCategory.main;
  }

  static AccountNature _parseAccountNature(dynamic value) {
    if (value == null) return AccountNature.debit;
    
    // Handle integer values (backend enum indices start at 1)
    if (value is int) {
      final index = value - 1; // Backend starts at 1, Flutter at 0
      if (index >= 0 && index < AccountNature.values.length) {
        return AccountNature.values[index];
      }
    }
    
    // Handle string values
    if (value is String) {
      // Try to parse as number first
      final intValue = int.tryParse(value);
      if (intValue != null) {
        return _parseAccountNature(intValue);
      }
      
      // Map backend string names to Flutter enum values
      final enumMap = <String, AccountNature>{
        'Debit': AccountNature.debit,
        'Credit': AccountNature.credit,
      };
      
      // Try exact match
      if (enumMap.containsKey(value)) {
        return enumMap[value]!;
      }
      
      // Try case-insensitive match
      final lowerValue = value.toLowerCase();
      for (final entry in enumMap.entries) {
        if (entry.key.toLowerCase() == lowerValue) {
          return entry.value;
        }
      }
    }
    
    return AccountNature.debit;
  }
}

// lib/features/admin_financial/data/datasources/financial_remote_datasource.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/chart_of_account_model.dart';
import '../models/financial_transaction_model.dart';

/// 📡 مصدر البيانات البعيدة للعمليات المالية
abstract class FinancialRemoteDataSource {
  // Chart of Accounts
  Future<List<ChartOfAccountModel>> getChartOfAccounts();
  Future<ChartOfAccountModel> getAccountById(String accountId);
  Future<List<ChartOfAccountModel>> getAccountsByType(int accountType);
  Future<List<ChartOfAccountModel>> searchAccounts(String query);

  // Financial Transactions
  Future<List<FinancialTransactionModel>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    int? status,
    int? type,
    int? limit,
  });
  Future<FinancialTransactionModel> getTransactionById(String transactionId);
  Future<List<FinancialTransactionModel>> getTransactionsByBooking(
      String bookingId);
  Future<List<FinancialTransactionModel>> getTransactionsByProperty(
      String propertyId);
  Future<List<FinancialTransactionModel>> getTransactionsByUser(String userId);
  Future<List<FinancialTransactionModel>> searchTransactions(String query);
  Future<bool> postTransaction(String transactionId);
  Future<FinancialTransactionModel> reverseTransaction(
      String transactionId, String reason);
  Future<Map<String, dynamic>> postPendingTransactions();

  // Financial Reports
  Future<Map<String, dynamic>> getFinancialReport(
      DateTime startDate, DateTime endDate);
  Future<Map<String, dynamic>> getAccountStatement(
      String accountId, DateTime startDate, DateTime endDate);
  Future<Map<String, dynamic>> getAccountBalance(
      String accountId, DateTime? atDate);
  Future<Map<String, dynamic>> getTransactionSummaryByType(
      DateTime startDate, DateTime endDate);
  
  // Charts and Analytics
  Future<List<Map<String, dynamic>>> getRevenueChart(
      DateTime startDate, DateTime endDate);
  Future<List<Map<String, dynamic>>> getExpenseChart(
      DateTime startDate, DateTime endDate);
  Future<List<Map<String, dynamic>>> getCashFlowChart(
      DateTime startDate, DateTime endDate);
  Future<Map<String, dynamic>> getFinancialSummary();

  // Owner payouts
  Future<Map<String, dynamic>> processOwnerPayouts({
    List<String>? ownerIds,
    double? minimumAmountThreshold,
    bool includePendingTransactions = false,
    bool previewOnly = false,
    String? notes,
  });
}

/// 📡 تنفيذ مصدر البيانات البعيدة
class FinancialRemoteDataSourceImpl implements FinancialRemoteDataSource {
  final ApiClient apiClient;

  FinancialRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<ChartOfAccountModel>> getChartOfAccounts() async {
    try {
      final response = await apiClient.get(
        '${ApiConstants.adminBaseUrl}/financial-reports/chart-of-accounts',
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.map((json) => ChartOfAccountModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch chart of accounts');
      }
    } catch (e) {
      throw Exception('Error fetching chart of accounts: $e');
    }
  }

  @override
  Future<ChartOfAccountModel> getAccountById(String accountId) async {
    try {
      final response = await apiClient.get(
        '${ApiConstants.adminBaseUrl}/financial-reports/accounts/$accountId',
      );

      if (response.statusCode == 200) {
        return ChartOfAccountModel.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to fetch account');
      }
    } catch (e) {
      throw Exception('Error fetching account: $e');
    }
  }

  @override
  Future<List<ChartOfAccountModel>> getAccountsByType(int accountType) async {
    try {
      // تحويل index إلى اسم الـ enum
      // Convert index to enum name
      String accountTypeName = _getAccountTypeName(accountType);

      final response = await apiClient.get(
        '${ApiConstants.adminBaseUrl}/financial-reports/accounts',
        queryParameters: {'type': accountTypeName},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.map((json) => ChartOfAccountModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch accounts by type');
      }
    } catch (e) {
      throw Exception('Error fetching accounts by type: $e');
    }
  }

  /// تحويل index الـ enum إلى اسم الـ enum في الباك إند
  /// Convert enum index to backend enum name
  String _getAccountTypeName(int index) {
    switch (index) {
      case 0:
        return 'Assets';
      case 1:
        return 'Liabilities';
      case 2:
        return 'Equity';
      case 3:
        return 'Revenue';
      case 4:
        return 'Expenses';
      default:
        return 'Assets';
    }
  }

  @override
  Future<List<ChartOfAccountModel>> searchAccounts(String query) async {
    try {
      final response = await apiClient.get(
        '${ApiConstants.adminBaseUrl}/financial-reports/accounts/search',
        queryParameters: {'query': query},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.map((json) => ChartOfAccountModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search accounts');
      }
    } catch (e) {
      throw Exception('Error searching accounts: $e');
    }
  }

  @override
  Future<List<FinancialTransactionModel>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    int? status,
    int? type,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null)
        queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      if (status != null) queryParams['status'] = status;
      if (type != null) queryParams['type'] = type;
      if (limit != null) queryParams['limit'] = limit;

      final response = await apiClient.get(
        '${ApiConstants.adminBaseUrl}/financial-reports/transactions',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data
            .map((json) => FinancialTransactionModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to fetch transactions');
      }
    } catch (e) {
      throw Exception('Error fetching transactions: $e');
    }
  }

  @override
  Future<FinancialTransactionModel> getTransactionById(
      String transactionId) async {
    try {
      final response = await apiClient.get(
        '${ApiConstants.adminBaseUrl}/financial-reports/transactions/$transactionId',
      );

      if (response.statusCode == 200) {
        return FinancialTransactionModel.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to fetch transaction');
      }
    } catch (e) {
      throw Exception('Error fetching transaction: $e');
    }
  }

  @override
  Future<List<FinancialTransactionModel>> getTransactionsByBooking(
      String bookingId) async {
    try {
      final response = await apiClient.get(
        '${ApiConstants.adminBaseUrl}/financial-reports/transactions/booking/$bookingId',
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data
            .map((json) => FinancialTransactionModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to fetch booking transactions');
      }
    } catch (e) {
      throw Exception('Error fetching booking transactions: $e');
    }
  }

  @override
  Future<List<FinancialTransactionModel>> getTransactionsByProperty(
      String propertyId) async {
    try {
      final response = await apiClient.get(
        '${ApiConstants.adminBaseUrl}/financial-reports/transactions/property/$propertyId',
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data
            .map((json) => FinancialTransactionModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to fetch property transactions');
      }
    } catch (e) {
      throw Exception('Error fetching property transactions: $e');
    }
  }

  @override
  Future<List<FinancialTransactionModel>> getTransactionsByUser(
      String userId) async {
    try {
      final response = await apiClient.get(
        '${ApiConstants.adminBaseUrl}/financial-reports/transactions/user/$userId',
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data
            .map((json) => FinancialTransactionModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to fetch user transactions');
      }
    } catch (e) {
      throw Exception('Error fetching user transactions: $e');
    }
  }

  @override
  Future<List<FinancialTransactionModel>> searchTransactions(
      String query) async {
    try {
      final response = await apiClient.get(
        '${ApiConstants.adminBaseUrl}/financial-reports/transactions/search',
        queryParameters: {'searchTerm': query},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data
            .map((json) => FinancialTransactionModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to search transactions');
      }
    } catch (e) {
      throw Exception('Error searching transactions: $e');
    }
  }

  @override
  Future<bool> postTransaction(String transactionId) async {
    try {
      final response = await apiClient.post(
        '${ApiConstants.adminBaseUrl}/financial-reports/transactions/$transactionId/post',
      );

      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      throw Exception('Error posting transaction: $e');
    }
  }

  @override
  Future<FinancialTransactionModel> reverseTransaction(
      String transactionId, String reason) async {
    try {
      final response = await apiClient.post(
        '${ApiConstants.adminBaseUrl}/financial-reports/transactions/$transactionId/reverse',
        data: {'reason': reason},
      );

      if (response.statusCode == 200) {
        return FinancialTransactionModel.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to reverse transaction');
      }
    } catch (e) {
      throw Exception('Error reversing transaction: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> postPendingTransactions() async {
    try {
      final response = await apiClient.post(
        '${ApiConstants.adminBaseUrl}/financial-reports/post-pending',
      );

      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        throw Exception('Failed to post pending transactions');
      }
    } catch (e) {
      throw Exception('Error posting pending transactions: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getFinancialReport(
      DateTime startDate, DateTime endDate) async {
    try {
      final response = await apiClient.get(
        '${ApiConstants.adminBaseUrl}/financial-reports/report',
        queryParameters: {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        throw Exception('Failed to fetch financial report');
      }
    } catch (e) {
      throw Exception('Error fetching financial report: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getAccountStatement(
      String accountId, DateTime startDate, DateTime endDate) async {
    try {
      final response = await apiClient.get(
        '${ApiConstants.adminBaseUrl}/financial-reports/account-statement/$accountId',
        queryParameters: {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        throw Exception('Failed to fetch account statement');
      }
    } catch (e) {
      throw Exception('Error fetching account statement: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getAccountBalance(
      String accountId, DateTime? atDate) async {
    try {
      final queryParams = <String, dynamic>{};
      if (atDate != null) queryParams['atDate'] = atDate.toIso8601String();

      final response = await apiClient.get(
        '${ApiConstants.adminBaseUrl}/financial-reports/account-balance/$accountId',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        throw Exception('Failed to fetch account balance');
      }
    } catch (e) {
      throw Exception('Error fetching account balance: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getTransactionSummaryByType(
      DateTime startDate, DateTime endDate) async {
    try {
      final response = await apiClient.get(
        '${ApiConstants.adminBaseUrl}/financial-reports/summary-by-type',
        queryParameters: {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        throw Exception('Failed to fetch transaction summary');
      }
    } catch (e) {
      throw Exception('Error fetching transaction summary: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRevenueChart(
      DateTime startDate, DateTime endDate) async {
    try {
      final response = await apiClient.get(
        '${ApiConstants.adminBaseUrl}/financial-reports/charts/revenue',
        queryParameters: {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to fetch revenue chart');
      }
    } catch (e) {
      throw Exception('Error fetching revenue chart: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getExpenseChart(
      DateTime startDate, DateTime endDate) async {
    try {
      final response = await apiClient.get(
        '${ApiConstants.adminBaseUrl}/financial-reports/charts/expenses',
        queryParameters: {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to fetch expense chart');
      }
    } catch (e) {
      throw Exception('Error fetching expense chart: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCashFlowChart(
      DateTime startDate, DateTime endDate) async {
    try {
      final response = await apiClient.get(
        '${ApiConstants.adminBaseUrl}/financial-reports/charts/cash-flow',
        queryParameters: {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to fetch cash flow chart');
      }
    } catch (e) {
      throw Exception('Error fetching cash flow chart: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getFinancialSummary() async {
    try {
      final response = await apiClient.get(
        '${ApiConstants.adminBaseUrl}/financial-reports/financial-summary',
      );

      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        throw Exception('Failed to fetch financial summary');
      }
    } catch (e) {
      throw Exception('Error fetching financial summary: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> processOwnerPayouts({
    List<String>? ownerIds,
    double? minimumAmountThreshold,
    bool includePendingTransactions = false,
    bool previewOnly = false,
    String? notes,
  }) async {
    try {
      final payload = <String, dynamic>{
        if (ownerIds != null && ownerIds.isNotEmpty) 'ownerIds': ownerIds,
        if (minimumAmountThreshold != null)
          'minimumAmountThreshold': minimumAmountThreshold,
        'includePendingTransactions': includePendingTransactions,
        'previewOnly': previewOnly,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      final response = await apiClient.post(
        '${ApiConstants.adminBaseUrl}/accounting/owner-payouts/process',
        data: payload,
      );

      if (response.statusCode == 200) {
        // The backend returns a ResultDto envelope { success, message, data }
        // Return the whole payload to allow caller to read message/data.
        return response.data is Map<String, dynamic>
            ? (response.data as Map<String, dynamic>)
            : {'success': true, 'data': response.data};
      } else {
        throw Exception('Failed to process owner payouts');
      }
    } catch (e) {
      throw Exception('Error processing owner payouts: $e');
    }
  }
}

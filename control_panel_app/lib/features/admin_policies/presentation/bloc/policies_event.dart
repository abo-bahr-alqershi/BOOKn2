import 'package:equatable/equatable.dart';
import '../../domain/entities/policy.dart';

abstract class PoliciesEvent extends Equatable {
  const PoliciesEvent();

  @override
  List<Object?> get props => [];
}

/// تحميل السياسات
class LoadPoliciesEvent extends PoliciesEvent {
  final int pageNumber;
  final int pageSize;
  final String? searchTerm;
  final String? propertyId;
  final PolicyType? policyType;

  const LoadPoliciesEvent({
    this.pageNumber = 1,
    this.pageSize = 20,
    this.searchTerm,
    this.propertyId,
    this.policyType,
  });

  @override
  List<Object?> get props => [pageNumber, pageSize, searchTerm, propertyId, policyType];
}

/// إنشاء سياسة جديدة
class CreatePolicyEvent extends PoliciesEvent {
  final String propertyId;
  final PolicyType type;
  final String description;
  final String rules;
  final int cancellationWindowDays;
  final bool requireFullPaymentBeforeConfirmation;
  final double minimumDepositPercentage;
  final int minHoursBeforeCheckIn;

  const CreatePolicyEvent({
    required this.propertyId,
    required this.type,
    required this.description,
    required this.rules,
    this.cancellationWindowDays = 0,
    this.requireFullPaymentBeforeConfirmation = false,
    this.minimumDepositPercentage = 0.0,
    this.minHoursBeforeCheckIn = 0,
  });

  @override
  List<Object?> get props => [
        propertyId,
        type,
        description,
        rules,
        cancellationWindowDays,
        requireFullPaymentBeforeConfirmation,
        minimumDepositPercentage,
        minHoursBeforeCheckIn,
      ];
}

/// تحديث سياسة
class UpdatePolicyEvent extends PoliciesEvent {
  final String policyId;
  final PolicyType type;
  final String description;
  final String rules;
  final int? cancellationWindowDays;
  final bool? requireFullPaymentBeforeConfirmation;
  final double? minimumDepositPercentage;
  final int? minHoursBeforeCheckIn;

  const UpdatePolicyEvent({
    required this.policyId,
    required this.type,
    required this.description,
    required this.rules,
    this.cancellationWindowDays,
    this.requireFullPaymentBeforeConfirmation,
    this.minimumDepositPercentage,
    this.minHoursBeforeCheckIn,
  });

  @override
  List<Object?> get props => [
        policyId,
        type,
        description,
        rules,
        cancellationWindowDays,
        requireFullPaymentBeforeConfirmation,
        minimumDepositPercentage,
        minHoursBeforeCheckIn,
      ];
}

/// حذف سياسة
class DeletePolicyEvent extends PoliciesEvent {
  final String policyId;

  const DeletePolicyEvent({required this.policyId});

  @override
  List<Object?> get props => [policyId];
}

/// تفعيل/تعطيل سياسة
class TogglePolicyStatusEvent extends PoliciesEvent {
  final String policyId;

  const TogglePolicyStatusEvent({required this.policyId});

  @override
  List<Object?> get props => [policyId];
}

/// تحميل إحصائيات السياسات
class LoadPolicyStatsEvent extends PoliciesEvent {
  const LoadPolicyStatsEvent();
}

/// البحث عن السياسات
class SearchPoliciesEvent extends PoliciesEvent {
  final String searchTerm;
  final PolicyType? type;

  const SearchPoliciesEvent({
    required this.searchTerm,
    this.type,
  });

  @override
  List<Object?> get props => [searchTerm, type];
}

/// اختيار سياسة
class SelectPolicyEvent extends PoliciesEvent {
  final String policyId;

  const SelectPolicyEvent({required this.policyId});

  @override
  List<Object?> get props => [policyId];
}

/// إلغاء اختيار السياسة
class DeselectPolicyEvent extends PoliciesEvent {
  const DeselectPolicyEvent();
}

/// تحديث الصفحة
class RefreshPoliciesEvent extends PoliciesEvent {
  const RefreshPoliciesEvent();
}

/// تغيير الصفحة
class ChangePageEvent extends PoliciesEvent {
  final int pageNumber;

  const ChangePageEvent({required this.pageNumber});

  @override
  List<Object?> get props => [pageNumber];
}

/// تغيير حجم الصفحة
class ChangePageSizeEvent extends PoliciesEvent {
  final int pageSize;

  const ChangePageSizeEvent({required this.pageSize});

  @override
  List<Object?> get props => [pageSize];
}

/// تطبيق الفلاتر
class ApplyFiltersEvent extends PoliciesEvent {
  final String? propertyId;
  final PolicyType? policyType;

  const ApplyFiltersEvent({
    this.propertyId,
    this.policyType,
  });

  @override
  List<Object?> get props => [propertyId, policyType];
}

/// مسح الفلاتر
class ClearFiltersEvent extends PoliciesEvent {
  const ClearFiltersEvent();
}

/// تحميل سياسة بالمعرف
class LoadPolicyByIdEvent extends PoliciesEvent {
  final String policyId;

  const LoadPolicyByIdEvent({required this.policyId});

  @override
  List<Object?> get props => [policyId];
}

/// تحميل سياسات عقار معين
class LoadPoliciesByPropertyEvent extends PoliciesEvent {
  final String propertyId;

  const LoadPoliciesByPropertyEvent({required this.propertyId});

  @override
  List<Object?> get props => [propertyId];
}

/// تحميل سياسات حسب النوع
class LoadPoliciesByTypeEvent extends PoliciesEvent {
  final PolicyType type;
  final int pageNumber;
  final int pageSize;

  const LoadPoliciesByTypeEvent({
    required this.type,
    this.pageNumber = 1,
    this.pageSize = 20,
  });

  @override
  List<Object?> get props => [type, pageNumber, pageSize];
}

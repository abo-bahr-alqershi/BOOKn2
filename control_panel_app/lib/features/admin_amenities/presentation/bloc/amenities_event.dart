import 'package:equatable/equatable.dart';

abstract class AmenitiesEvent extends Equatable {
  const AmenitiesEvent();

  @override
  List<Object?> get props => [];
}

/// 📥 حدث تحميل المرافق
class LoadAmenitiesEvent extends AmenitiesEvent {
  final int pageNumber;
  final int pageSize;
  final String? searchTerm;
  final String? propertyId;
  final bool? isAssigned;
  final bool? isFree;
  final String? propertyTypeId;

  const LoadAmenitiesEvent({
    this.pageNumber = 1,
    this.pageSize = 10,
    this.searchTerm,
    this.propertyId,
    this.isAssigned,
    this.isFree,
    this.propertyTypeId,
  });

  @override
  List<Object?> get props => [
        pageNumber,
        pageSize,
        searchTerm,
        propertyId,
        isAssigned,
        isFree,
        propertyTypeId,
      ];
}

/// ➕ حدث إضافة مرفق
class CreateAmenityEvent extends AmenitiesEvent {
  final String name;
  final String description;
  final String icon;
  final String? propertyTypeId;
  final bool isDefaultForType;

  const CreateAmenityEvent({
    required this.name,
    required this.description,
    required this.icon,
    this.propertyTypeId,
    this.isDefaultForType = false,
  });

  @override
  List<Object?> get props => [name, description, icon, propertyTypeId, isDefaultForType];
}

/// ✏️ حدث تحديث مرفق
class UpdateAmenityEvent extends AmenitiesEvent {
  final String amenityId;
  final String? name;
  final String? description;
  final String? icon;

  const UpdateAmenityEvent({
    required this.amenityId,
    this.name,
    this.description,
    this.icon,
  });

  @override
  List<Object?> get props => [amenityId, name, description, icon];
}

/// 🗑️ حدث حذف مرفق
class DeleteAmenityEvent extends AmenitiesEvent {
  final String amenityId;

  const DeleteAmenityEvent({required this.amenityId});

  @override
  List<Object> get props => [amenityId];
}

/// 🔄 حدث تبديل حالة المرفق
class ToggleAmenityStatusEvent extends AmenitiesEvent {
  final String amenityId;

  const ToggleAmenityStatusEvent({required this.amenityId});

  @override
  List<Object> get props => [amenityId];
}

/// 🏢 حدث إسناد مرفق لعقار
class AssignAmenityToPropertyEvent extends AmenitiesEvent {
  final String amenityId;
  final String propertyId;
  final bool isAvailable;
  final double? extraCost;
  final String? description;

  const AssignAmenityToPropertyEvent({
    required this.amenityId,
    required this.propertyId,
    this.isAvailable = true,
    this.extraCost,
    this.description,
  });

  @override
  List<Object?> get props => [
        amenityId,
        propertyId,
        isAvailable,
        extraCost,
        description,
      ];
}

/// 🧩 حدث ربط مرفق بنوع عقار
class AssignAmenityToPropertyTypeEvent extends AmenitiesEvent {
  final String amenityId;
  final String propertyTypeId;
  final bool isDefault;

  const AssignAmenityToPropertyTypeEvent({
    required this.amenityId,
    required this.propertyTypeId,
    this.isDefault = false,
  });

  @override
  List<Object?> get props => [amenityId, propertyTypeId, isDefault];
}

/// 📊 حدث تحميل الإحصائيات
class LoadAmenityStatsEvent extends AmenitiesEvent {
  const LoadAmenityStatsEvent();
}

/// 🔍 حدث البحث عن المرافق
class SearchAmenitiesEvent extends AmenitiesEvent {
  final String searchTerm;

  const SearchAmenitiesEvent({required this.searchTerm});

  @override
  List<Object> get props => [searchTerm];
}

/// 🎯 حدث اختيار مرفق
class SelectAmenityEvent extends AmenitiesEvent {
  final String amenityId;

  const SelectAmenityEvent({required this.amenityId});

  @override
  List<Object> get props => [amenityId];
}

/// ❌ حدث إلغاء اختيار مرفق
class DeselectAmenityEvent extends AmenitiesEvent {
  const DeselectAmenityEvent();
}

/// 📈 حدث تحميل المرافق الشائعة
class LoadPopularAmenitiesEvent extends AmenitiesEvent {
  final int limit;

  const LoadPopularAmenitiesEvent({this.limit = 10});

  @override
  List<Object> get props => [limit];
}

/// 🔄 حدث تحديث الصفحة
class RefreshAmenitiesEvent extends AmenitiesEvent {
  const RefreshAmenitiesEvent();
}

/// 📑 حدث تغيير الصفحة
class ChangePageEvent extends AmenitiesEvent {
  final int pageNumber;

  const ChangePageEvent({required this.pageNumber});

  @override
  List<Object> get props => [pageNumber];
}

/// 🔢 حدث تغيير حجم الصفحة
class ChangePageSizeEvent extends AmenitiesEvent {
  final int pageSize;

  const ChangePageSizeEvent({required this.pageSize});

  @override
  List<Object> get props => [pageSize];
}

/// 🏷️ حدث تطبيق الفلاتر
class ApplyFiltersEvent extends AmenitiesEvent {
  final String? searchTerm;
  final bool? isAssigned;
  final bool? isFree;
  final String? propertyTypeId;

  const ApplyFiltersEvent({
    this.searchTerm,
    this.isAssigned,
    this.isFree,
    this.propertyTypeId,
  });

  @override
  List<Object?> get props => [searchTerm, isAssigned, isFree, propertyTypeId];
}

/// 🧹 حدث مسح الفلاتر
class ClearFiltersEvent extends AmenitiesEvent {
  const ClearFiltersEvent();
}
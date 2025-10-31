using MediatR;
using Microsoft.Extensions.Logging;
// using YemenBooking.Application.Features.UnitTypes; // غير موجود
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Features.Units.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.PropertyTypes.Queries.GetUnitTypes;

/// <summary>
/// معالج استعلام الحصول على أنواع الوحدات
/// Handler for get unit types query
/// </summary>
public class GetUnitTypesQueryHandler : IRequestHandler<GetUnitTypesQuery, ResultDto<List<UnitTypeDto>>>
{
    private readonly IUnitTypeRepository _unitTypeRepository;
    private readonly IPropertyTypeRepository _propertyTypeRepository;
    private readonly ILogger<GetUnitTypesQueryHandler> _logger;

    /// <summary>
    /// منشئ معالج استعلام أنواع الوحدات
    /// Constructor for get unit types query handler
    /// </summary>
    /// <param name="unitTypeRepository">مستودع أنواع الوحدات</param>
    /// <param name="propertyTypeRepository">مستودع أنواع العقارات</param>
    /// <param name="logger">مسجل الأحداث</param>
    public GetUnitTypesQueryHandler(
        IUnitTypeRepository unitTypeRepository,
        IPropertyTypeRepository propertyTypeRepository,
        ILogger<GetUnitTypesQueryHandler> logger)
    {
        _unitTypeRepository = unitTypeRepository;
        _propertyTypeRepository = propertyTypeRepository;
        _logger = logger;
    }

    /// <summary>
    /// معالجة استعلام الحصول على أنواع الوحدات
    /// Handle get unit types query
    /// </summary>
    /// <param name="request">طلب الاستعلام</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>قائمة أنواع الوحدات</returns>
    public async Task<ResultDto<List<UnitTypeDto>>> Handle(GetUnitTypesQuery request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء استعلام أنواع الوحدات. معرف نوع العقار: {PropertyTypeId}", request.PropertyTypeId);

            // التحقق من صحة البيانات المدخلة
            var validationResult = ValidateRequest(request);
            if (!validationResult.IsSuccess)
            {
                return validationResult;
            }

            // التحقق من وجود نوع العقار
            var propertyType = await _propertyTypeRepository.GetByIdAsync(request.PropertyTypeId, cancellationToken);
            if (propertyType == null)
            {
                _logger.LogWarning("لم يتم العثور على نوع العقار: {PropertyTypeId}", request.PropertyTypeId);
                return ResultDto<List<UnitTypeDto>>.Failed("نوع العقار غير موجود", "PROPERTY_TYPE_NOT_FOUND");
            }

            // الحصول على أنواع الوحدات المتاحة لهذا النوع من العقارات
            var unitTypes = await _unitTypeRepository.GetByPropertyTypeIdAsync(request.PropertyTypeId, cancellationToken);

            if (unitTypes == null || !unitTypes.Any())
            {
                _logger.LogInformation("لم يتم العثور على أنواع وحدات لنوع العقار: {PropertyTypeId}", request.PropertyTypeId);
                
                return ResultDto<List<UnitTypeDto>>.Ok(
                    new List<UnitTypeDto>(), 
                    "لا توجد أنواع وحدات متاحة لهذا النوع من العقارات"
                );
            }

            // تحويل البيانات إلى DTO
            var unitTypeDtos = unitTypes.Select(unitType => new UnitTypeDto
            {
                Id = unitType.Id,
                PropertyTypeId = unitType.PropertyTypeId,
                Name = unitType.Name ?? string.Empty,
                Description = unitType.Description ?? string.Empty,
                MaxCapacity = unitType.MaxCapacity,
                Icon = unitType.Icon ?? string.Empty,
                SystemCommissionRate = unitType.SystemCommissionRate,
                IsHasAdults = unitType.IsHasAdults,
                IsHasChildren = unitType.IsHasChildren,
                IsMultiDays = unitType.IsMultiDays,
                IsRequiredToDetermineTheHour = unitType.IsRequiredToDetermineTheHour,
                Fields = unitType.UnitTypeFields?.Select(f => new UnitTypeFieldDto
                {
                    FieldId = f.Id.ToString(),
                    UnitTypeId = unitType.Id.ToString(),
                    FieldTypeId = f.FieldTypeId,
                    FieldName = f.FieldName,
                    DisplayName = f.DisplayName,
                    Description = f.Description,
                    FieldOptions = new Dictionary<string, object>(),
                    ValidationRules = new Dictionary<string, object>(),
                    IsRequired = f.IsRequired,
                    IsSearchable = f.IsSearchable,
                    IsPublic = f.IsPublic,
                    SortOrder = f.SortOrder,
                    Category = f.Category,
                    GroupId = null,
                    IsForUnits = f.IsForUnits,
                    ShowInCards = f.ShowInCards,
                    IsPrimaryFilter = f.IsPrimaryFilter,
                    Priority = f.Priority
                }).ToList() ?? new List<UnitTypeFieldDto>()
            }).ToList();

            // ترتيب أنواع الوحدات حسب الأولوية والسعة
            unitTypeDtos = unitTypeDtos
                .OrderBy(ut => GetUnitTypeDisplayOrder(ut.Name))
                .ThenBy(ut => ut.MaxCapacity)
                .ThenBy(ut => ut.Name)
                .ToList();

            _logger.LogInformation("تم الحصول على {Count} نوع وحدة لنوع العقار {PropertyTypeId}", 
                unitTypeDtos.Count, request.PropertyTypeId);

            return ResultDto<List<UnitTypeDto>>.Ok(
                unitTypeDtos, 
                $"تم الحصول على {unitTypeDtos.Count} نوع وحدة"
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء الحصول على أنواع الوحدات. معرف نوع العقار: {PropertyTypeId}", request.PropertyTypeId);
            return ResultDto<List<UnitTypeDto>>.Failed(
                $"حدث خطأ أثناء الحصول على أنواع الوحدات: {ex.Message}", 
                "GET_UNIT_TYPES_ERROR"
            );
        }
    }

    /// <summary>
    /// التحقق من صحة البيانات المدخلة
    /// Validate request data
    /// </summary>
    /// <param name="request">طلب الاستعلام</param>
    /// <returns>نتيجة التحقق</returns>
    private ResultDto<List<UnitTypeDto>> ValidateRequest(GetUnitTypesQuery request)
    {
        if (request.PropertyTypeId == Guid.Empty)
        {
            _logger.LogWarning("معرف نوع العقار مطلوب");
            return ResultDto<List<UnitTypeDto>>.Failed("معرف نوع العقار مطلوب", "PROPERTY_TYPE_ID_REQUIRED");
        }

        return ResultDto<List<UnitTypeDto>>.Ok(null, "البيانات صحيحة");
    }

    /// <summary>
    /// الحصول على ترتيب عرض نوع الوحدة
    /// Get unit type display order
    /// </summary>
    /// <param name="unitTypeName">اسم نوع الوحدة</param>
    /// <returns>ترتيب العرض</returns>
    private int GetUnitTypeDisplayOrder(string unitTypeName)
    {
        return unitTypeName.ToLower() switch
        {
            // غرف الفنادق
            "غرفة مفردة" or "single room" => 1,
            "غرفة مزدوجة" or "double room" => 2,
            "غرفة ثلاثية" or "triple room" => 3,
            "غرفة عائلية" or "family room" => 4,
            "جناح" or "suite" => 5,
            "جناح ملكي" or "royal suite" => 6,

            // الشاليهات والفيلل
            "شاليه صغير" or "small chalet" => 10,
            "شاليه متوسط" or "medium chalet" => 11,
            "شاليه كبير" or "large chalet" => 12,
            "شاليه كامل" or "full chalet" => 13,
            "فيلا صغيرة" or "small villa" => 14,
            "فيلا متوسطة" or "medium villa" => 15,
            "فيلا كبيرة" or "large villa" => 16,
            "فيلا كاملة" or "full villa" => 17,

            // الشقق
            "استوديو" or "studio" => 20,
            "شقة غرفة واحدة" or "one bedroom apartment" => 21,
            "شقة غرفتين" or "two bedroom apartment" => 22,
            "شقة ثلاث غرف" or "three bedroom apartment" => 23,
            "شقة أربع غرف" or "four bedroom apartment" => 24,

            // الاستراحات والمخيمات
            "استراحة صغيرة" or "small rest house" => 30,
            "استراحة متوسطة" or "medium rest house" => 31,
            "استراحة كبيرة" or "large rest house" => 32,
            "خيمة" or "tent" => 35,
            "كرفان" or "caravan" => 36,

            _ => 999
        };
    }
}

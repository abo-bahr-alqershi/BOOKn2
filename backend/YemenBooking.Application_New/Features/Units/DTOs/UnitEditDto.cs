namespace YemenBooking.Application.Features.Units.DTOs;
using YemenBooking.Application.Features.DynamicFields.DTOs;

using System;
using System.Collections.Generic;

/// <summary>
/// بيانات نقل بيانات الوحدة للتحرير
/// DTO for unit edit form including dynamic values
/// </summary>
public class UnitEditDto
{
    public Guid UnitId { get; set; }
    public string Name { get; set; }
    public decimal BasePrice { get; set; }
    public Dictionary<string, object> CustomFeatures { get; set; }
    public List<FieldGroupWithValuesDto> DynamicFields { get; set; }
} 
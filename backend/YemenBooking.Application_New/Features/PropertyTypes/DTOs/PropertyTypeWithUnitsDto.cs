using System;
using System.Collections.Generic;
using YemenBooking.Application.Features.Units.DTOs;

namespace YemenBooking.Application.Features.PropertyTypes.DTOs
{
    /// <summary>
    /// نوع العقار مع أنواع الوحدات التابعة له
    /// Property type with its unit types
    /// </summary>
    public class PropertyTypeWithUnitsDto
    {
        public Guid Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public int PropertiesCount { get; set; }
        public string Icon { get; set; } = string.Empty;
        public List<string> DefaultAmenities { get; set; } = new();
        public List<UnitTypeDto> UnitTypes { get; set; } = new();
    }
}

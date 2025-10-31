namespace YemenBooking.Application.Features.Properties.DTOs;

using System;
using System.Collections.Generic;

/// <summary>
/// بيانات نقل بيانات الكيان للتحرير
/// DTO for property edit form including dynamic values
/// </summary>
public class PropertyEditDto
{
    public Guid PropertyId { get; set; }
    public string Name { get; set; }
    public string Address { get; set; }
    public string City { get; set; }
    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }
    public int? StarRating { get; set; }
    public string Description { get; set; }
    public Guid PropertyTypeId { get; set; }
} 
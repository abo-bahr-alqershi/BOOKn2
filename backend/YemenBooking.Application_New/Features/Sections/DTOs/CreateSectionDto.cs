using System;
using YemenBooking.Core.Enums;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Sections.DTOs {
    public class CreateSectionDto
    {
        public SectionType Type { get; set; }
        public ContentType ContentType { get; set; }
        public DisplayStyle DisplayStyle { get; set; }
        public string? Name { get; set; }
        public string? Title { get; set; }
        public string? Subtitle { get; set; }
        public string? Description { get; set; }
        public string? ShortDescription { get; set; }
        public int DisplayOrder { get; set; }
        public SectionTarget Target { get; set; }
        public bool IsActive { get; set; } = true;
        public int ColumnsCount { get; set; } = 2;
        public int ItemsToShow { get; set; } = 10;
        public string? Icon { get; set; }
        public string? ColorTheme { get; set; }
        public string? BackgroundImage { get; set; }
        public string? FilterCriteria { get; set; }
        public string? SortCriteria { get; set; }
        public string? CityName { get; set; }
        public Guid? PropertyTypeId { get; set; }
        public Guid? UnitTypeId { get; set; }
        public decimal? MinPrice { get; set; }
        public decimal? MaxPrice { get; set; }
        public decimal? MinRating { get; set; }
        public bool IsVisibleToGuests { get; set; } = true;
        public bool IsVisibleToRegistered { get; set; } = true;
        public string? RequiresPermission { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public string? Metadata { get; set; }
    }
}


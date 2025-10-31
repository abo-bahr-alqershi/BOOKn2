// LEGACY: To be removed after full migration to Features structure.
using System;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Sections;
using YemenBooking.Core.Enums;
using YemenBooking.Application.Features.Sections.DTOs;

namespace YemenBooking.Application.Features.Sections.Commands.ManageSections
{
	public class CreateSectionCommand : IRequest<ResultDto<SectionDto>>
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
		public string? TempKey { get; set; }
        public SectionClass? CategoryClass { get; set; }
        public int? HomeItemsCount { get; set; }
	}
}
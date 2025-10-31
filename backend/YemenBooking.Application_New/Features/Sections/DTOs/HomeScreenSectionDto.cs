using System;
using System.Collections.Generic;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Sections.DTOs {
    public class HomeScreenSectionDto
    {
        public Guid Id { get; set; }
        public Guid TemplateId { get; set; }
        public string Name { get; set; }
        public string Title { get; set; }
        public string Subtitle { get; set; }
        public int Order { get; set; }
        public bool IsVisible { get; set; }
        public string BackgroundColor { get; set; }
        public string BackgroundImage { get; set; }
        public string Padding { get; set; }
        public string Margin { get; set; }
        public int MinHeight { get; set; }
        public int MaxHeight { get; set; }
        public string CustomStyles { get; set; }
        public string Conditions { get; set; }
        public List<HomeScreenComponentDto> Components { get; set; }
    }
}
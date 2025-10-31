using System;
using System.Collections.Generic;

namespace YemenBooking.Application.Features.Reviews.DTOs {
    public class HomeScreenPreviewDto
    {
        public Guid TemplateId { get; set; }
        public string TemplateName { get; set; }
        public string Platform { get; set; }
        public string DeviceType { get; set; }
        public List<HomeScreenSectionPreviewDto> Sections { get; set; }
        public PreviewMetadata Metadata { get; set; }
    }

    public class HomeScreenSectionPreviewDto
    {
        public Guid Id { get; set; }
        public string Name { get; set; }
        public string Title { get; set; }
        public string Subtitle { get; set; }
        public int Order { get; set; }
        public bool IsVisible { get; set; }
        public Dictionary<string, string> Styles { get; set; }
        public List<HomeScreenComponentPreviewDto> Components { get; set; }
    }

    public class HomeScreenComponentPreviewDto
    {
        public Guid Id { get; set; }
        public string Type { get; set; }
        public string Name { get; set; }
        public int Order { get; set; }
        public int ColSpan { get; set; }
        public int RowSpan { get; set; }
        public string Alignment { get; set; }
        public Dictionary<string, object> PropertyDto { get; set; }
        public Dictionary<string, string> Styles { get; set; }
        public object Data { get; set; }
        public AnimationConfig Animation { get; set; }
    }

    public class AnimationConfig
    {
        public string Type { get; set; }
        public int Duration { get; set; }
        public int Delay { get; set; }
        public string Easing { get; set; }
    }

    public class PreviewMetadata
    {
        public DateTime GeneratedAt { get; set; }
        public int TotalSections { get; set; }
        public int TotalComponents { get; set; }
        public int EstimatedLoadTime { get; set; }
        public bool UsedMockData { get; set; }
    }
}
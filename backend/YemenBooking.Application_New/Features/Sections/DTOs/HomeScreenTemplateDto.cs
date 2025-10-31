using System;
using System.Collections.Generic;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Sections.DTOs {
    public class HomeScreenTemplateDto
    {
        public Guid Id { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public string Version { get; set; }
        public bool IsActive { get; set; }
        public bool IsDefault { get; set; }
        public DateTime? PublishedAt { get; set; }
        public Guid? PublishedBy { get; set; }
        public string PublishedByName { get; set; }
        public string Platform { get; set; }
        public string TargetAudience { get; set; }
        public string MetaData { get; set; }
        public string CustomizationData { get; set; }
        public string UserPreferences { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public List<HomeScreenSectionDto> Sections { get; set; }
    }
}
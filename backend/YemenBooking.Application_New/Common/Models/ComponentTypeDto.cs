using System.Collections.Generic;

namespace YemenBooking.Application.Common.Models
{
    public class ComponentTypeDto
    {
        public string Type { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public string Icon { get; set; }
        public string Category { get; set; }
        public int DefaultColSpan { get; set; }
        public int DefaultRowSpan { get; set; }
        public bool AllowResize { get; set; }
        public List<ComponentPropertyMetadata> PropertyDto { get; set; }
        public List<string> SupportedPlatforms { get; set; }
        public Dictionary<string, object> DefaultStyles { get; set; }
    }

    public class ComponentPropertyMetadata
    {
        public string Key { get; set; }
        public string Name { get; set; }
        public string Type { get; set; }
        public bool IsRequired { get; set; }
        public string DefaultValue { get; set; }
        public string[] Options { get; set; }
        public string Description { get; set; }
        public string ValidationPattern { get; set; }
    }
}
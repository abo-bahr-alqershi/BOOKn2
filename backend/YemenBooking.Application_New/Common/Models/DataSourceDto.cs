using System.Collections.Generic;

namespace YemenBooking.Application.Common.Models
{
    public class DataSourceDto
    {
        public string Id { get; set; }
        public string Name { get; set; }
        public string Type { get; set; }
        public string Description { get; set; }
        public string Endpoint { get; set; }
        public bool IsAvailable { get; set; }
        public bool RequiresAuth { get; set; }
        public string[] SupportedComponents { get; set; }
        public List<DataSourceParameter> Parameters { get; set; }
        public int? CacheDuration { get; set; }
    }

    public class DataSourceParameter
    {
        public string Key { get; set; }
        public string Name { get; set; }
        public string Type { get; set; }
        public string DefaultValue { get; set; }
        public bool IsRequired { get; set; }
        public string Description { get; set; }
        public string[] Options { get; set; }
    }
}
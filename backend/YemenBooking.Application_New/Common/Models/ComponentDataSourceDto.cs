using System;

namespace YemenBooking.Application.Common.Models
{
    public class ComponentDataSourceDto
    {
        public Guid Id { get; set; }
        public string SourceType { get; set; }
        public string DataEndpoint { get; set; }
        public string HttpMethod { get; set; }
        public string Headers { get; set; }
        public string QueryParams { get; set; }
        public string RequestBody { get; set; }
        public string DataMapping { get; set; }
        public string CacheKey { get; set; }
        public int CacheDuration { get; set; }
        public string RefreshTrigger { get; set; }
        public int RefreshInterval { get; set; }
        public string ErrorHandling { get; set; }
        public string MockData { get; set; }
        public bool UseMockInDev { get; set; }
    }
}
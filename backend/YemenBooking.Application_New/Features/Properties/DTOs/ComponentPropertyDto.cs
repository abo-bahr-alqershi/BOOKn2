using System;

namespace YemenBooking.Application.Features.Properties.DTOs
{
    public class ComponentPropertyDto
    {
        public Guid Id { get; set; }
        public string PropertyKey { get; set; }
        public string PropertyName { get; set; }
        public string PropertyType { get; set; }
        public string Value { get; set; }
        public string DefaultValue { get; set; }
        public bool IsRequired { get; set; }
        public string ValidationRules { get; set; }
        public string Options { get; set; }
        public string HelpText { get; set; }
        public int Order { get; set; }
    }
}
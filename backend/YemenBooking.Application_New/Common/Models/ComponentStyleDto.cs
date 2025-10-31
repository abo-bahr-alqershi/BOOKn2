using System;

namespace YemenBooking.Application.Common.Models
{
    public class ComponentStyleDto
    {
        public Guid Id { get; set; }
        public string StyleKey { get; set; }
        public string StyleValue { get; set; }
        public string Unit { get; set; }
        public bool IsImportant { get; set; }
        public string MediaQuery { get; set; }
        public string State { get; set; }
        public string Platform { get; set; }
    }
}
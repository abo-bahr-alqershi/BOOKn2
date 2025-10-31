using System;

namespace YemenBooking.Application.Common.Models
{
    public class ComponentActionDto
    {
        public Guid Id { get; set; }
        public string ActionType { get; set; }
        public string ActionTrigger { get; set; }
        public string ActionTarget { get; set; }
        public string ActionParams { get; set; }
        public string Conditions { get; set; }
        public bool RequiresAuth { get; set; }
        public string AnimationType { get; set; }
        public int Priority { get; set; }
    }
}
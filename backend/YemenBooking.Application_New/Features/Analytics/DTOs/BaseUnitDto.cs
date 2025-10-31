using YemenBooking.Application.Features.Units.DTOs;

namespace YemenBooking.Application.Features.Analytics.DTOs {
    public class BaseUnitDto
    {
        public string UnitId { get; set; }
        public string PropertyId { get; set; }
        public string UnitName { get; set; }
        public string UnitType { get; set; }
        public int Capacity { get; set; }
        public decimal BasePrice { get; set; }
        public bool IsActive { get; set; }
    }
} 
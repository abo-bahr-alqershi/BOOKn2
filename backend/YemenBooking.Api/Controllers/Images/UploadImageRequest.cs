using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace YemenBooking.Api.Controllers.Images
{
    /// <summary>
    /// طلب رفع صورة يجمع كل الحقول ضمن نموذج واحد
    /// DTO to wrap form data for image upload
    /// </summary>
    public class UploadImageRequest
    {
        [FromForm(Name = "file")]
        public IFormFile File { get; set; } = null!;

        /// <summary>
        /// صورة مصغرة للفيديو يرسلها العميل (اختياري)
        /// Optional client-provided video thumbnail image
        /// </summary>
        [FromForm(Name = "videoThumbnail")]
        public IFormFile? VideoThumbnail { get; set; }

        [FromForm(Name = "tempKey")]
        public string? TempKey { get; set; }

        [FromForm(Name = "category")]
        public string Category { get; set; } = string.Empty;

        [FromForm(Name = "propertyId")]
        public string? PropertyId { get; set; }

        [FromForm(Name = "unitId")]
        public string? UnitId { get; set; }

        /// <summary>
        /// للربط مع كيان القسم مباشرة (صور الخلفية/الغلاف)
        /// </summary>
        [FromForm(Name = "sectionId")]
        public string? SectionId { get; set; }

        /// <summary>
        /// ربط الصور الإضافية بسجل عقار في قسم
        /// </summary>
        [FromForm(Name = "propertyInSectionId")]
        public string? PropertyInSectionId { get; set; }

        /// <summary>
        /// ربط الصور الإضافية بسجل وحدة في قسم
        /// </summary>
        [FromForm(Name = "unitInSectionId")]
        public string? UnitInSectionId { get; set; }

        [FromForm(Name = "cityName")]
        public string? CityName { get; set; }

        /// <summary>
        /// Alias to accept cityId from app; mapped to CityName for backend
        /// </summary>
        [FromForm(Name = "cityId")]
        public string? CityId { get; set; }

        [FromForm(Name = "alt")]
        public string? Alt { get; set; }

        /// <summary>
        /// سياق الحفظ: section | property-in-section | unit-in-section | property
        /// </summary>
        [FromForm(Name = "context")]
        public string? Context { get; set; }

        [FromForm(Name = "isPrimary")]
        public bool? IsPrimary { get; set; }

        [FromForm(Name = "order")]
        public int? Order { get; set; }

        [FromForm(Name = "tags")]
        public string? Tags { get; set; }
    }
} 
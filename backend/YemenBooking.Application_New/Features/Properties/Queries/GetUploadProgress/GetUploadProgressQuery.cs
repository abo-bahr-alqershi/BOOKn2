using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Properties.Queries.GetUploadProgress
{
    /// <summary>
    /// استعلام لتتبع تقدم رفع الصورة بواسطة معرف المهمة
    /// Query to track image upload progress by task ID
    /// </summary>
    public class GetUploadProgressQuery : IRequest<ResultDto<UploadProgressDto>>
    {
        /// <summary>
        /// معرف المهمة لتتبع التقدم
        /// Task ID for progress tracking
        /// </summary>
        public string TaskId { get; set; } = string.Empty;
    }
} 
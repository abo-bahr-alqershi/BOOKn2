using System.Collections.Generic;
using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Properties.Commands.ManageImages
{
    /// <summary>
    /// أمر لحذف صور متعددة (مؤقت أو دائم)
    /// Command to bulk delete images (soft or permanent)
    /// </summary>
    public class DeleteImagesCommand : IRequest<ResultDto<bool>>
    {
        /// <summary>
        /// قائمة معرفات الصور المراد حذفها
        /// List of image IDs to delete
        /// </summary>
        public List<Guid> ImageIds { get; set; } = new List<Guid>();

        /// <summary>
        /// حذف دائم بدل الحذف المؤقت لجميع الصور
        /// Permanent deletion flag for all images
        /// </summary>
        public bool Permanent { get; set; } = false;
    }

    /// <summary>
    /// أمر لحذف الصور وفق مفتاح مؤقت
    /// Command to delete images by temporary key
    /// </summary>
    public class DeleteImagesByTempKeyCommand : IRequest<ResultDto<bool>>
    {
        public string TempKey { get; set; } = string.Empty;
        public bool Permanent { get; set; } = true;
    }
} 
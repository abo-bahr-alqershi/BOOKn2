using System;
using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Properties.Commands.ManageImages
{
    /// <summary>
    /// أمر لحذف صورة واحدة (مؤقت أو دائم)
    /// Command to delete a single image (soft or permanent)
    /// </summary>
    public class DeleteImageCommand : IRequest<ResultDto<bool>>
    {
        /// <summary>
        /// معرف الصورة المراد حذفها
        /// Identifier of the image to delete
        /// </summary>
        public Guid ImageId { get; set; }

        /// <summary>
        /// حذف دائم بدل الحذف المؤقت
        /// Permanent deletion flag (true for permanent)
        /// </summary>
        public bool Permanent { get; set; } = false;
    }
} 
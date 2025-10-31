using System;
using System.Collections.Generic;
using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Properties.Commands.ManageImages
{
    /// <summary>
    /// أمر لإعادة ترتيب الصور
    /// Command to reorder images with specified display orders
    /// </summary>
    public class ReorderImagesCommand : IRequest<ResultDto<bool>>
    {
        /// <summary>
        /// قائمة التعيينات: معرف الصورة وترتيب العرض الجديد
        /// List of assignments: image ID and new display order
        /// </summary>
        public List<ImageOrderAssignment> Assignments { get; set; } = new List<ImageOrderAssignment>();
    }

    /// <summary>
    /// تفاصيل تعيين ترتيب صورة
    /// Image order assignment details
    /// </summary>
    public class ImageOrderAssignment
    {
        /// <summary>
        /// معرف الصورة
        /// Image unique identifier
        /// </summary>
        public Guid ImageId { get; set; }

        /// <summary>
        /// ترتيب العرض الجديد
        /// New display order
        /// </summary>
        public int DisplayOrder { get; set; }
    }
} 
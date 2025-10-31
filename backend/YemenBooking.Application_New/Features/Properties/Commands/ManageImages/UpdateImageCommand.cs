using System;
using System.Collections.Generic;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Enums;
using YemenBooking.Application.Features.Properties.DTOs;

namespace YemenBooking.Application.Features.Properties.Commands.ManageImages
{
    /// <summary>
    /// أمر لتحديث بيانات صورة (alt النص، الترتيب، العلامات، الفئة، الصورة الرئيسية)
    /// Command to update image metadata (alt text, order, tags, category, primary flag)
    /// </summary>
    public class UpdateImageCommand : IRequest<ResultDto<ImageDto>>
    {
        /// <summary>
        /// معرف الصورة
        /// Image unique identifier
        /// </summary>
        public Guid ImageId { get; set; }

        /// <summary>
        /// النص البديل للصورة
        /// Alt text for the image
        /// </summary>
        public string? Alt { get; set; }

        /// <summary>
        /// تعيين الصورة كصورة رئيسية
        /// Flag indicating whether this image is primary
        /// </summary>
        public bool? IsPrimary { get; set; }

        /// <summary>
        /// ترتيب العرض للصورة
        /// Display order for the image
        /// </summary>
        public int? Order { get; set; }

        /// <summary>
        /// وسوم الصورة
        /// Tags associated with the image
        /// </summary>
        public List<string>? Tags { get; set; }

        /// <summary>
        /// فئة الصورة
        /// Category of the image
        /// </summary>
        public ImageCategory? Category { get; set; }
    }
} 
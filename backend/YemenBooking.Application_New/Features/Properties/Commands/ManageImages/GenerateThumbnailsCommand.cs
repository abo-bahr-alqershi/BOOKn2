using System;
using System.Collections.Generic;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Properties.DTOs;

namespace YemenBooking.Application.Features.Properties.Commands.ManageImages
{
    /// <summary>
    /// أمر لإنشاء مصغرات إضافية للصورة
    /// Command to generate additional thumbnails for an image
    /// </summary>
    public class GenerateThumbnailsCommand : IRequest<ResultDto<ImageDto>>
    {
        /// <summary>
        /// معرف الصورة
        /// Image unique identifier
        /// </summary>
        public Guid ImageId { get; set; }

        /// <summary>
        /// قائمة الأحجام المطلوبة (مثل small, medium, large, hd)
        /// List of sizes to generate (e.g., small, medium, large, hd)
        /// </summary>
        public List<string> Sizes { get; set; } = new List<string>();
    }
} 
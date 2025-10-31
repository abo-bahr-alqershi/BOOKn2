using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Application.Features.Properties;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using System.Collections.Generic;
using YemenBooking.Application.Features.Properties.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Properties.Queries.GetImageStatistics
{
    /// <summary>
    /// معالج استعلام الحصول على إحصائيات الصور
    /// Handler for GetImageStatisticsQuery to compute image statistics
    /// </summary>
    public class GetImageStatisticsQueryHandler : IRequestHandler<GetImageStatisticsQuery, ResultDto<ImageStatisticsDto>>
    {
        private readonly IPropertyImageRepository _imageRepository;

        public GetImageStatisticsQueryHandler(IPropertyImageRepository imageRepository)
        {
            _imageRepository = imageRepository;
        }

        public async Task<ResultDto<ImageStatisticsDto>> Handle(GetImageStatisticsQuery request, CancellationToken cancellationToken)
        {
            // بناء الاستعلام مع فلاتر اختيارية
            var query = _imageRepository.GetQueryable().AsNoTracking();
            if (request.PropertyId.HasValue)
                query = query.Where(i => i.PropertyId == request.PropertyId.Value);
            if (request.UnitId.HasValue)
                query = query.Where(i => i.UnitId == request.UnitId.Value);

            // جلب قائمة الصور
            var images = await query.ToListAsync(cancellationToken);

            // حساب الإحصائيات
            var totalImages = images.Count;
            var totalSize = images.Sum(i => i.SizeBytes);
            var byCategory = images
                .GroupBy(i => i.Category)
                .ToDictionary(g => g.Key, g => g.Count());
            var byStatus = images
                .GroupBy(i => i.Status)
                .ToDictionary(g => g.Key.ToString(), g => g.Count());
            var averageSize = totalImages > 0 ? images.Average(i => i.SizeBytes) : 0;
            var primaryImages = images.Count(i => i.IsMain);

            // تجميع DTO
            var dto = new ImageStatisticsDto
            {
                TotalImages = totalImages,
                TotalSize = totalSize,
                ByCategory = byCategory,
                ByStatus = byStatus,
                AverageSize = averageSize,
                PrimaryImages = primaryImages
            };

            return ResultDto<ImageStatisticsDto>.Ok(dto);
        }
    }
} 
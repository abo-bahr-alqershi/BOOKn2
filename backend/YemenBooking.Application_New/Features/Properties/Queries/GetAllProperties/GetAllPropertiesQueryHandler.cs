using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Properties;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features;
using YemenBooking.Application.Features.Properties.DTOs;
using YemenBooking.Application.Features.Properties.DTOs;

namespace YemenBooking.Application.Features.Properties.Queries.GetAllProperties
{
    /// <summary>
    /// معالج استعلام الحصول على جميع الكيانات مع الفلترة والصفحات
    /// Get all properties with filtering and pagination query handler
    /// </summary>
    public class GetAllPropertiesQueryHandler : IRequestHandler<GetAllPropertiesQuery, PaginatedResult<YemenBooking.Application.Features.Properties.DTOs.PropertyDto>>
    {
        #region Dependencies
        private readonly IPropertyRepository _propertyRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<GetAllPropertiesQueryHandler> _logger;
        #endregion

        #region Constructor
        public GetAllPropertiesQueryHandler(
            IPropertyRepository propertyRepository,
            ICurrentUserService currentUserService,
            ILogger<GetAllPropertiesQueryHandler> logger)
        {
            _propertyRepository = propertyRepository;
            _currentUserService = currentUserService;
            _logger = logger;
        }
        #endregion

        #region Handler Implementation
        public async Task<PaginatedResult<YemenBooking.Application.Features.Properties.DTOs.PropertyDto>> Handle(GetAllPropertiesQuery request, CancellationToken cancellationToken)
        {
            try
            {
                _logger.LogInformation("بدء معالجة استعلام الحصول على جميع الكيانات - الصفحة: {PageNumber}، الحجم: {PageSize}", request.PageNumber, request.PageSize);

                // 1. التحقق من صحة المدخلات
                ValidateInputParameters(request);

                // 2. بناء الاستعلام الأساسي مع التحسينات الأمنية والأداء
                var query = await BuildBaseQueryAsync(cancellationToken);

                // 3. تطبيق الفلاتر
                query = ApplyFilters(query, request);

                // 4. تطبيق البحث النصي إذا وُجد مصطلح بحث
                if (!string.IsNullOrWhiteSpace(request.SearchTerm))
                    query = ApplyTextSearch(query, request.SearchTerm);

                // 5. تطبيق الترتيب
                query = ApplySorting(query, request.SortBy, request.IsAscending);

                // 6. تنفيذ الاستعلام مع الصفحات
                var result = await ExecutePaginatedQueryAsync(query, request.PageNumber, request.PageSize, cancellationToken);

                // Attach stats metadata on first page
                if (request.PageNumber == 1)
                {
                    var total = result.TotalCount;
                    var activeCount = await query.CountAsync(p => p.IsApproved, cancellationToken);
                    var pendingCount = await query.CountAsync(p => !p.IsApproved, cancellationToken);
                    result.Metadata = new
                    {
                        totalProperties = total,
                        activeProperties = activeCount,
                        pendingProperties = pendingCount
                    };
                }

                _logger.LogInformation("تم الحصول على {Count} كيان من إجمالي {Total} كيان", result.Items.Count(), result.TotalCount);
                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في معالجة استعلام الحصول على جميع الكيانات");
                throw;
            }
        }
        #endregion

        #region Private Methods
        private void ValidateInputParameters(GetAllPropertiesQuery request)
        {
            if (request.PageNumber < 1)
                throw new ArgumentException("رقم الصفحة يجب أن يكون أكبر من صفر", nameof(request.PageNumber));

            if (request.PageSize < 1 || request.PageSize > 100)
                throw new ArgumentException("حجم الصفحة يجب أن يكون بين 1 و 100", nameof(request.PageSize));
        }

        private async Task<IQueryable<Property>> BuildBaseQueryAsync(CancellationToken cancellationToken)
        {
            // استعلام أساسي مع التضمينات الضرورية للتصفية والتعيين
            var query = _propertyRepository.GetQueryable()
                .AsNoTracking()
                .Include(p => p.PropertyType)
                .Include(p => p.Owner)
                .Include(p => p.Amenities).ThenInclude(a => a.PropertyTypeAmenity)
                .Include(p => p.Units).ThenInclude(u => u.Bookings)
                // Include all non-deleted images for listing (so edit modal can show existing images)
                .Include(p => p.Images.Where(i => !i.IsDeleted))
                .Where(p => !p.IsDeleted);
            // تطبيق مرشحات الأمان استنادًا إلى دور المستخدم
            var currentUserId = _currentUserService.UserId;
            var role = _currentUserService.Role;
            if (!string.Equals(role, "Admin", StringComparison.OrdinalIgnoreCase))
            {
                if (string.Equals(role, "Owner", StringComparison.OrdinalIgnoreCase))
                {
                    // تطبيق مرشحات الأمان استنادًا إلى دور المستخدم
                    query = query.Where(p => p.IsApproved || p.OwnerId == currentUserId);
                }
                else
                {
                    // يمكن للضيوف والأدوار الأخرى رؤية الكيانات المعتمدة فقط
                    query = query.Where(p => p.IsApproved);
                }
            }
            return await Task.FromResult(query);
        }

        private IQueryable<Property> ApplyFilters(IQueryable<Property> query, GetAllPropertiesQuery request)
        {
            // نوع الكيان
            if (request.PropertyTypeId.HasValue)
                query = query.Where(p => p.TypeId == request.PropertyTypeId.Value);
            // السعر
            if (request.MinPrice.HasValue)
                query = query.Where(p => p.Units.Any(u => u.BasePrice.Amount >= request.MinPrice.Value));
            if (request.MaxPrice.HasValue)
                query = query.Where(p => p.Units.Any(u => u.BasePrice.Amount <= request.MaxPrice.Value));
            // المرافق
            if (request.AmenityIds != null && request.AmenityIds.Any())
                query = query.Where(p => request.AmenityIds.All(id => p.Amenities.Any(a => a.PropertyTypeAmenity.AmenityId == id && a.IsAvailable)));
            // تصنيف النجوم
            if (request.StarRatings != null && request.StarRatings.Any())
                query = query.Where(p => request.StarRatings.Contains(p.StarRating));
            // متوسط التقييم
            if (request.MinAverageRating.HasValue)
                query = query.Where(p => p.Reviews.Any()
                    && p.Reviews.Average(r => (r.Cleanliness + r.Service + r.Location + r.Value) / 4.0) >= request.MinAverageRating.Value);
            // حالة الموافقة
            if (request.IsApproved.HasValue)
                query = query.Where(p => p.IsApproved == request.IsApproved.Value);
            // حجوزات نشطة (باستخدام BookingCount)
            if (request.HasActiveBookings.HasValue)
                query = request.HasActiveBookings.Value
                    ? query.Where(p => p.BookingCount > 0)
                    : query.Where(p => p.BookingCount == 0);
            return query;
        }

        private IQueryable<Property> ApplyTextSearch(IQueryable<Property> query, string searchTerm)
        {
            var term = searchTerm.Trim().ToLower();
            return query.Where(p =>
                p.Name.ToLower().Contains(term) ||
                p.Description.ToLower().Contains(term) ||
                p.Address.ToLower().Contains(term) ||
                p.City.ToLower().Contains(term));
        }

        private IQueryable<Property> ApplySorting(IQueryable<Property> query, string? sortBy, bool isAscending)
        {
            if (string.IsNullOrWhiteSpace(sortBy))
                return query.OrderByDescending(p => p.CreatedAt);
            var key = sortBy.Trim().ToLower();
            return key switch
            {
                "name" => isAscending ? query.OrderBy(p => p.Name) : query.OrderByDescending(p => p.Name),
                "price" => isAscending
                    ? query.OrderBy(p => p.Units.Min(u => u.BasePrice.Amount))
                    : query.OrderByDescending(p => p.Units.Min(u => u.BasePrice.Amount)),
                "starrating" => isAscending ? query.OrderBy(p => p.StarRating) : query.OrderByDescending(p => p.StarRating),
                "rating" => isAscending
                    ? query.OrderBy(p => p.Reviews.Average(r => (r.Cleanliness + r.Service + r.Location + r.Value) / 4.0))
                    : query.OrderByDescending(p => p.Reviews.Average(r => (r.Cleanliness + r.Service + r.Location + r.Value) / 4.0)),
                "createdat" or "date" => isAscending ? query.OrderBy(p => p.CreatedAt) : query.OrderByDescending(p => p.CreatedAt),
                _ => query.OrderByDescending(p => p.CreatedAt)
            };
        }

        private async Task<PaginatedResult<YemenBooking.Application.Features.Properties.DTOs.PropertyDto>> ExecutePaginatedQueryAsync(
            IQueryable<Property> query,
            int pageNumber,
            int pageSize,
            CancellationToken cancellationToken)
        {
            var totalCount = await query.CountAsync(cancellationToken);
            var properties = await query
                .Skip((pageNumber - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync(cancellationToken);

            var propertyDtos = properties.Select(MapToDto).ToList();

            // Localize date fields for client
            for (int i = 0; i < propertyDtos.Count; i++)
            {
                propertyDtos[i].CreatedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(propertyDtos[i].CreatedAt);
                if (propertyDtos[i].Images != null)
                {
                    foreach (var image in propertyDtos[i].Images)
                    {
                        image.UploadedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(image.UploadedAt);
                    }
                }
            }

            return new PaginatedResult<YemenBooking.Application.Features.Properties.DTOs.PropertyDto>
            {
                Items = propertyDtos,
                PageNumber = pageNumber,
                PageSize = pageSize,
                TotalCount = totalCount
            };
        }

        private YemenBooking.Application.Features.Properties.DTOs.PropertyDto MapToDto(Property property)
        {
            return new YemenBooking.Application.Features.Properties.DTOs.PropertyDto
            {
                Id = property.Id,
                OwnerId = property.OwnerId,
                TypeId = property.TypeId,
                Name = property.Name,
                Address = property.Address,
                City = property.City,
                Latitude = property.Latitude,
                Longitude = property.Longitude,
                StarRating = property.StarRating,
                Description = property.Description,
                IsApproved = property.IsApproved,
                CreatedAt = property.CreatedAt,
                OwnerName = property.Owner.Name,
                TypeName = property.PropertyType.Name,
                Images = property.Images.Select(i => new PropertyImageDto
                {
                    Id = i.Id,
                    PropertyId = i.PropertyId,
                    UnitId = i.UnitId,
                    Name = i.Name,
                    Url = i.Url,
                    SizeBytes = i.SizeBytes,
                    Type = i.Type,
                    Category = i.Category,
                    Caption = i.Caption,
                    AltText = i.AltText,
                    Tags = i.Tags,
                    Sizes = i.Sizes,
                    IsMain = i.IsMain,
                    DisplayOrder = i.DisplayOrder,
                    UploadedAt = i.UploadedAt,
                    Status = i.Status,
                    AssociationType = i.PropertyId != null ? "Property" : "Unit"
                }).ToList()
            };
        }
        #endregion
    }
} 
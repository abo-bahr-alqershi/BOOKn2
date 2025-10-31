using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Services;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Features.Services.DTOs;
using YemenBooking.Application.Common.Interfaces;

namespace YemenBooking.Application.Features.Services.Queries.GetServiceById
{
    /// <summary>
    /// معالج استعلام الحصول على تفاصيل الخدمة بواسطة المعرف
    /// Query handler for GetServiceByIdQuery
    /// </summary>
    public class GetServiceByIdQueryHandler : IRequestHandler<GetServiceByIdQuery, ResultDto<ServiceDetailsDto>>
    {
        private readonly IPropertyServiceRepository _serviceRepository;
        private readonly ILogger<GetServiceByIdQueryHandler> _logger;
        private readonly ICurrentUserService _currentUserService;

        public GetServiceByIdQueryHandler(
            IPropertyServiceRepository serviceRepository,
            ILogger<GetServiceByIdQueryHandler> logger,
            ICurrentUserService currentUserService)
        {
            _serviceRepository = serviceRepository;
            _logger = logger;
            _currentUserService = currentUserService;
        }

        public async Task<ResultDto<ServiceDetailsDto>> Handle(GetServiceByIdQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("جاري معالجة استعلام تفاصيل الخدمة: {ServiceId}", request.ServiceId);

            var service = await _serviceRepository.GetQueryable()
                .AsNoTracking()
                .Include(s => s.Property)
                .FirstOrDefaultAsync(s => s.Id == request.ServiceId, cancellationToken);

            if (service == null)
            {
                return ResultDto<ServiceDetailsDto>.Failure("الخدمة غير موجودة");
            }

            var isAdmin = string.Equals(_currentUserService.Role, "Admin", StringComparison.OrdinalIgnoreCase)
                || string.Equals(_currentUserService.AccountRole, "Admin", StringComparison.OrdinalIgnoreCase)
                || (_currentUserService.UserRoles?.Any(r => string.Equals(r, "Admin", StringComparison.OrdinalIgnoreCase)) ?? false);
            if (!isAdmin)
            {
                if (_currentUserService.PropertyId.HasValue && _currentUserService.PropertyId.Value != service.PropertyId)
                {
                    return ResultDto<ServiceDetailsDto>.Failure("غير مصرح لك بعرض هذه الخدمة");
                }
                if (service.Property?.OwnerId != _currentUserService.UserId)
                {
                    return ResultDto<ServiceDetailsDto>.Failure("غير مصرح لك بعرض هذه الخدمة");
                }
            }

            var dto = new ServiceDetailsDto
            {
                Id = service.Id,
                PropertyId = service.PropertyId,
                PropertyName = service.Property?.Name ?? string.Empty,
                Name = service.Name,
                Icon = service.Icon,
                Description = service.Description,
                Price = new MoneyDto
                {
                    Amount = service.Price.Amount,
                    Currency = service.Price.Currency
                },
                PricingModel = service.PricingModel
            };

            return ResultDto<ServiceDetailsDto>.Ok(dto, "تم جلب بيانات الخدمة بنجاح");
        }
    }
} 
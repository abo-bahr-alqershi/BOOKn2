using System;
using System.Linq;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Services;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Features.Services.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Services.Queries.GetServicesByType
{
    /// <summary>
    /// معالج استعلام الحصول على الخدمات حسب النوع
    /// Query handler for GetServicesByTypeQuery
    /// </summary>
    public class GetServicesByTypeQueryHandler : IRequestHandler<GetServicesByTypeQuery, PaginatedResult<ServiceDto>>
    {
        private readonly IPropertyServiceRepository _serviceRepository;
        private readonly ILogger<GetServicesByTypeQueryHandler> _logger;

        public GetServicesByTypeQueryHandler(
            IPropertyServiceRepository serviceRepository,
            ILogger<GetServicesByTypeQueryHandler> logger)
        {
            _serviceRepository = serviceRepository;
            _logger = logger;
        }

        public async Task<PaginatedResult<ServiceDto>> Handle(GetServicesByTypeQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("جاري معالجة استعلام الخدمات حسب النوع: {ServiceType}", request.ServiceType);

            var services = (await _serviceRepository.GetServicesByTypeAsync(request.ServiceType, cancellationToken))
                .ToList();

            var dtos = services.Select(s => new ServiceDto
            {
                Id = s.Id,
                PropertyId = s.PropertyId,
                PropertyName = s.Property?.Name ?? string.Empty,
                Name = s.Name,
                Icon = s.Icon,
                Description = s.Description,
                Price = new MoneyDto
                {
                    Amount = s.Price.Amount,
                    Currency = s.Price.Currency
                },
                PricingModel = s.PricingModel
            }).ToList();

            var totalCount = dtos.Count;
            var items = dtos
                .Skip((request.PageNumber - 1) * request.PageSize)
                .Take(request.PageSize)
                .ToList();

            var page = new PaginatedResult<ServiceDto>
            {
                Items = items,
                PageNumber = request.PageNumber,
                PageSize = request.PageSize,
                TotalCount = totalCount
            };
            if (request.PageNumber == 1)
            {
                var paidServices = services.Count(s => s.Price.Amount > 0);
                page.Metadata = new
                {
                    totalServices = services.Count,
                    paidServices
                };
            }
            return page;
        }
    }
} 
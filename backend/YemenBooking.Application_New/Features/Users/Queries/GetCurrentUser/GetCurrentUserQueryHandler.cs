using System;
using System.Threading;
using System.Threading.Tasks;
using AutoMapper;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Users;
using YemenBooking.Application.Features.Users;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Users.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Users.Queries.GetCurrentUser
{
    /// <summary>
    /// معالج استعلام الحصول على بيانات المستخدم الحالي
    /// Query handler for GetCurrentUserQuery
    /// </summary>
    public class GetCurrentUserQueryHandler : IRequestHandler<GetCurrentUserQuery, ResultDto<UserDto>>
    {
        private readonly ICurrentUserService _currentUserService;
        private readonly IMapper _mapper;
        private readonly ILogger<GetCurrentUserQueryHandler> _logger;

        public GetCurrentUserQueryHandler(
            ICurrentUserService currentUserService,
            IMapper mapper,
            ILogger<GetCurrentUserQueryHandler> logger)
        {
            _currentUserService = currentUserService;
            _mapper = mapper;
            _logger = logger;
        }

        public async Task<ResultDto<UserDto>> Handle(GetCurrentUserQuery request, CancellationToken cancellationToken)
        {
            try
            {
                _logger.LogInformation("جاري معالجة استعلام بيانات المستخدم الحالي: {UserId}", _currentUserService.UserId);

                if (_currentUserService.UserId == Guid.Empty)
                {
                    _logger.LogWarning("طلب غير مصادق عليه لبيانات المستخدم الحالي");
                    return ResultDto<UserDto>.Failure("يجب تسجيل الدخول للوصول إلى بيانات المستخدم");
                }

                var user = await _currentUserService.GetCurrentUserAsync(cancellationToken);
                if (user == null)
                {
                    _logger.LogWarning("تعذر العثور على المستخدم: {UserId}", _currentUserService.UserId);
                    return ResultDto<UserDto>.Failure($"المستخدم بالمعرف {_currentUserService.UserId} غير موجود");
                }

                var userDto = _mapper.Map<UserDto>(user);
                // enrich with claims-based context
                userDto.AccountRole = _currentUserService.AccountRole;
                if (_currentUserService.PropertyId.HasValue)
                {
                    userDto.PropertyId = _currentUserService.PropertyId;
                    userDto.PropertyName = _currentUserService.PropertyName;
                    userDto.PropertyCurrency = _currentUserService.PropertyCurrency;
                }

                _logger.LogInformation("تم جلب بيانات المستخدم الحالي بنجاح: {UserId}", userDto.Id);
                return ResultDto<UserDto>.Ok(userDto, "تم جلب بيانات المستخدم بنجاح");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في معالجة استعلام بيانات المستخدم الحالي");
                return ResultDto<UserDto>.Failure("حدث خطأ أثناء جلب بيانات المستخدم");
            }
        }
    }
} 
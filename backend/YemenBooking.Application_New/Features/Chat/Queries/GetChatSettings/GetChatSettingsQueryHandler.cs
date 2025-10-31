using System.Threading;
using System.Threading.Tasks;
using MediatR;
using AutoMapper;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Chat;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Chat.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Chat.Queries.GetChatSettings
{
    /// <summary>
    /// معالج استعلام جلب إعدادات الشات الخاصة بالمستخدم
    /// </summary>
    public class GetChatSettingsQueryHandler : IRequestHandler<GetChatSettingsQuery, ResultDto<ChatSettingsDto>>
    {
        private readonly IChatSettingsRepository _settingsRepo;
        private readonly ICurrentUserService _currentUserService;
        private readonly IMapper _mapper;
        private readonly ILogger<GetChatSettingsQueryHandler> _logger;

        public GetChatSettingsQueryHandler(
            IChatSettingsRepository settingsRepo,
            ICurrentUserService currentUserService,
            IMapper mapper,
            ILogger<GetChatSettingsQueryHandler> logger)
        {
            _settingsRepo = settingsRepo;
            _currentUserService = currentUserService;
            _mapper = mapper;
            _logger = logger;
        }

        public async Task<ResultDto<ChatSettingsDto>> Handle(GetChatSettingsQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("جلب إعدادات الشات للمستخدم {UserId}", _currentUserService.UserId);
            var userId = _currentUserService.UserId;
            var settings = await _settingsRepo.GetByUserIdAsync(userId, cancellationToken);
            if (settings == null)
                return ResultDto<ChatSettingsDto>.Failure("لم يتم العثور على إعدادات الشات", errorCode: "not_found");

            var dto = _mapper.Map<ChatSettingsDto>(settings);
            return ResultDto<ChatSettingsDto>.Ok(dto);
        }
    }
} 
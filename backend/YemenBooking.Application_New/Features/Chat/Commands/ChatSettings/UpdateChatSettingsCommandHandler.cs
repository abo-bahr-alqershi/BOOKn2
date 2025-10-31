using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using AutoMapper;
using YemenBooking.Application.Features.Chat;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Interfaces;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Chat.DTOs;

namespace YemenBooking.Application.Features.Chat.Commands.ChatSettings
{
    /// <summary>
    /// معالج أمر تحديث إعدادات الشات الخاصة بالمستخدم
    /// </summary>
    public class UpdateChatSettingsCommandHandler : IRequestHandler<UpdateChatSettingsCommand, ResultDto<ChatSettingsDto>>
    {
        private readonly IChatSettingsRepository _settingsRepo;
        private readonly IUnitOfWork _unitOfWork;
        private readonly ICurrentUserService _currentUserService;
        private readonly IMapper _mapper;
        private readonly ILogger<UpdateChatSettingsCommandHandler> _logger;

        public UpdateChatSettingsCommandHandler(
            IChatSettingsRepository settingsRepo,
            IUnitOfWork unitOfWork,
            ICurrentUserService currentUserService,
            IMapper mapper,
            ILogger<UpdateChatSettingsCommandHandler> logger)
        {
            _settingsRepo = settingsRepo;
            _unitOfWork = unitOfWork;
            _currentUserService = currentUserService;
            _mapper = mapper;
            _logger = logger;
        }

        public async Task<ResultDto<ChatSettingsDto>> Handle(UpdateChatSettingsCommand request, CancellationToken cancellationToken)
        {
            try
            {
                var userId = _currentUserService.UserId;
                _logger.LogInformation("تحديث إعدادات الشات للمستخدم {UserId}", userId);

                var settings = await _settingsRepo.GetByUserIdAsync(userId, cancellationToken)
                    ?? new YemenBooking.Core.Entities.ChatSettings { UserId = userId, CreatedAt = DateTime.UtcNow, UpdatedAt = DateTime.UtcNow };

                if (request.NotificationsEnabled.HasValue)
                    settings.NotificationsEnabled = request.NotificationsEnabled!.Value;
                if (request.SoundEnabled.HasValue)
                    settings.SoundEnabled = request.SoundEnabled!.Value;
                if (request.ShowReadReceipts.HasValue)
                    settings.ShowReadReceipts = request.ShowReadReceipts!.Value;
                if (request.ShowTypingIndicator.HasValue)
                    settings.ShowTypingIndicator = request.ShowTypingIndicator!.Value;
                if (!string.IsNullOrWhiteSpace(request.Theme))
                    settings.Theme = request.Theme!;
                if (!string.IsNullOrWhiteSpace(request.FontSize))
                    settings.FontSize = request.FontSize!;
                if (request.AutoDownloadMedia.HasValue)
                    settings.AutoDownloadMedia = request.AutoDownloadMedia!.Value;
                if (request.BackupMessages.HasValue)
                    settings.BackupMessages = request.BackupMessages!.Value;
                settings.UpdatedAt = DateTime.UtcNow;

                if (settings.Id == default)
                {
                    await _unitOfWork.Repository<YemenBooking.Core.Entities.ChatSettings>().AddAsync(settings, cancellationToken);
                }
                else
                {
                    _unitOfWork.Repository<YemenBooking.Core.Entities.ChatSettings>().UpdateAsync(settings, cancellationToken).GetAwaiter().GetResult();
                }

                await _unitOfWork.SaveChangesAsync(cancellationToken);

                var dto = _mapper.Map<ChatSettingsDto>(settings);
                return ResultDto<ChatSettingsDto>.Ok(dto, "تم تحديث إعدادات الشات بنجاح");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ أثناء تحديث إعدادات الشات");
                return ResultDto<ChatSettingsDto>.Failed("حدث خطأ أثناء تحديث الإعدادات");
            }
        }
    }
} 
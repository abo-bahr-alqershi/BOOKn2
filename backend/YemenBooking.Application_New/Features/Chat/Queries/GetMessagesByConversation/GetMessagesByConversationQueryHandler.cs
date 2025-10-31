using System;
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

namespace YemenBooking.Application.Features.Chat.Queries.GetMessagesByConversation
{
    /// <summary>
    /// معالج استعلام جلب الرسائل في محادثة محددة
    /// </summary>
    public class GetMessagesByConversationQueryHandler : IRequestHandler<GetMessagesByConversationQuery, PaginatedResult<ChatMessageDto>>
    {
        private readonly IChatMessageRepository _messageRepo;
        private readonly IMapper _mapper;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<GetMessagesByConversationQueryHandler> _logger;

        public GetMessagesByConversationQueryHandler(
            IChatMessageRepository messageRepo,
            IMapper mapper,
            ILogger<GetMessagesByConversationQueryHandler> logger,
            ICurrentUserService currentUserService)
        {
            _messageRepo = messageRepo;
            _mapper = mapper;
            _logger = logger;
            _currentUserService = currentUserService;
        }

        public async Task<PaginatedResult<ChatMessageDto>> Handle(GetMessagesByConversationQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("جلب الرسائل للمحادثة {ConversationId}", request.ConversationId);
            var beforeId = request.BeforeMessageId?.ToString();
            var (items, total) = await _messageRepo.GetMessagesByConversationAsync(request.ConversationId, request.PageNumber, request.PageSize, beforeId, cancellationToken);
            var dtos = _mapper.Map<IEnumerable<ChatMessageDto>>(items).ToList();
            for (int i = 0; i < dtos.Count; i++)
            {
                dtos[i].CreatedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(dtos[i].CreatedAt);
                dtos[i].UpdatedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(dtos[i].UpdatedAt);
                if (dtos[i].EditedAt.HasValue)
                    dtos[i].EditedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(dtos[i].EditedAt.Value);
                if (dtos[i].DeliveryReceipt != null)
                {
                    if (dtos[i].DeliveryReceipt.DeliveredAt.HasValue)
                        dtos[i].DeliveryReceipt.DeliveredAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(dtos[i].DeliveryReceipt.DeliveredAt.Value);
                    if (dtos[i].DeliveryReceipt.ReadAt.HasValue)
                        dtos[i].DeliveryReceipt.ReadAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(dtos[i].DeliveryReceipt.ReadAt.Value);
                }
            }
            return PaginatedResult<ChatMessageDto>.Create(dtos, request.PageNumber, request.PageSize, total);
        }
    }
} 
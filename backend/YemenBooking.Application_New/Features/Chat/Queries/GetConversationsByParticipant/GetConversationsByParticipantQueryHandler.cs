using System.Threading;
using System.Threading.Tasks;
using MediatR;
using AutoMapper;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Chat;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Interfaces;
using YemenBooking.Application.Infrastructure.Services; // Added for ICurrentUserService
using System.Linq;
using System.Collections.Generic;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Chat.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Chat.Queries.GetConversationsByParticipant
{
    /// <summary>
    /// معالج استعلام جلب المحادثات الخاصة بالمستخدم
    /// </summary>
    public class GetConversationsByParticipantQueryHandler : IRequestHandler<GetConversationsByParticipantQuery, PaginatedResult<ChatConversationDto>>
    {
        private readonly IChatConversationRepository _conversationRepo;
        private readonly ICurrentUserService _currentUserService;
        private readonly IMapper _mapper;
        private readonly ILogger<GetConversationsByParticipantQueryHandler> _logger;

        public GetConversationsByParticipantQueryHandler(
            IChatConversationRepository conversationRepo,
            ICurrentUserService currentUserService,
            IMapper mapper,
            ILogger<GetConversationsByParticipantQueryHandler> logger)
        {
            _conversationRepo = conversationRepo;
            _currentUserService = currentUserService;
            _mapper = mapper;
            _logger = logger;
        }

        public async Task<PaginatedResult<ChatConversationDto>> Handle(GetConversationsByParticipantQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("جلب المحادثات للمستخدم {UserId}", _currentUserService.UserId);
            var userId = _currentUserService.UserId;
            var (items, total) = await _conversationRepo.GetConversationsByParticipantAsync(userId, request.PageNumber, request.PageSize, cancellationToken);
            var itemList = items?.ToList() ?? new List<Core.Entities.ChatConversation>();
            var dtos = _mapper.Map<List<ChatConversationDto>>(itemList);
            for (int i = 0; i < dtos.Count; i++)
            {
                dtos[i].CreatedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(dtos[i].CreatedAt);
                dtos[i].UpdatedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(dtos[i].UpdatedAt);
                if (dtos[i].LastMessageTime.HasValue)
                    dtos[i].LastMessageTime = await _currentUserService.ConvertFromUtcToUserLocalAsync(dtos[i].LastMessageTime.Value);
            }

            // Compute unread count per conversation for the current user
            for (int i = 0; i < dtos.Count; i++)
            {
                var conv = itemList[i];
                var unread = conv.Messages
                    .Where(m => m.SenderId != userId)
                    .Count(m => !string.Equals(m.Status, "read", System.StringComparison.OrdinalIgnoreCase));
                dtos[i].UnreadCount = unread;
            }

            return PaginatedResult<ChatConversationDto>.Create(dtos, request.PageNumber, request.PageSize, total);
        }
    }
} 
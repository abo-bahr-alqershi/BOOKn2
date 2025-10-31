using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Chat.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Chat.Queries.SearchChats
{
    using System;
    using System.Linq;
    using System.Threading;
    using System.Threading.Tasks;
    using AutoMapper;
    using global::YemenBooking.Application.Common.Models;
    using global::YemenBooking.Core.Interfaces.Repositories;
    using MediatR;
    using Microsoft.EntityFrameworkCore;

    /// <summary>
    /// معالج استعلام البحث في المحادثات والرسائل
    /// Handler for SearchChatsQuery
    /// </summary>
    public class SearchChatsQueryHandler : IRequestHandler<SearchChatsQuery, ResultDto<SearchChatsResultDto>>
    {
        private readonly IChatMessageRepository _messageRepo;
        private readonly IChatConversationRepository _conversationRepo;
        private readonly IMapper _mapper;
        private readonly ICurrentUserService _currentUserService;

        public SearchChatsQueryHandler(
            IChatMessageRepository messageRepo,
            IChatConversationRepository conversationRepo,
            IMapper mapper,
            ICurrentUserService currentUserService)
        {
            _messageRepo = messageRepo;
            _conversationRepo = conversationRepo;
            _mapper = mapper;
            _currentUserService = currentUserService;
        }

        public async Task<ResultDto<SearchChatsResultDto>> Handle(SearchChatsQuery request, CancellationToken cancellationToken)
        {
            var msgQuery = _messageRepo.GetQueryable()
                .Where(m => m.Content.Contains(request.Query));

            if (request.ConversationId.HasValue)
                msgQuery = msgQuery.Where(m => m.ConversationId == request.ConversationId);

            if (!string.IsNullOrEmpty(request.MessageType))
                msgQuery = msgQuery.Where(m => m.MessageType == request.MessageType);

            if (request.SenderId.HasValue)
                msgQuery = msgQuery.Where(m => m.SenderId == request.SenderId);

            if (request.DateFrom.HasValue)
            {
                var fromUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.DateFrom.Value);
                msgQuery = msgQuery.Where(m => m.CreatedAt >= fromUtc);
            }

            if (request.DateTo.HasValue)
            {
                var toUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.DateTo.Value);
                msgQuery = msgQuery.Where(m => m.CreatedAt <= toUtc);
            }

            var totalMessages = await msgQuery.CountAsync(cancellationToken);
            var messages = await msgQuery
                .OrderByDescending(m => m.CreatedAt)
                .Skip((request.Page - 1) * request.Limit)
                .Take(request.Limit)
                .ToListAsync(cancellationToken);

            var convQuery = _conversationRepo.GetQueryable()
                .Where(c => c.Title.Contains(request.Query) || c.Participants.Any(p => p.Id.ToString().Contains(request.Query)));

            if (request.ConversationId.HasValue)
                convQuery = convQuery.Where(c => c.Id == request.ConversationId);

            var totalConversations = await convQuery.CountAsync(cancellationToken);
            var conversations = await convQuery
                .OrderByDescending(c => c.UpdatedAt)
                .Skip((request.Page - 1) * request.Limit)
                .Take(request.Limit)
                .ToListAsync(cancellationToken);

            var resultDto = new SearchChatsResultDto
            {
                Messages = _mapper.Map<IEnumerable<ChatMessageDto>>(messages).Select(async m => {
                    m.CreatedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(m.CreatedAt);
                    m.UpdatedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(m.UpdatedAt);
                    if (m.EditedAt.HasValue) m.EditedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(m.EditedAt.Value);
                    if (m.DeliveryReceipt != null)
                    {
                        if (m.DeliveryReceipt.DeliveredAt.HasValue) m.DeliveryReceipt.DeliveredAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(m.DeliveryReceipt.DeliveredAt.Value);
                        if (m.DeliveryReceipt.ReadAt.HasValue) m.DeliveryReceipt.ReadAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(m.DeliveryReceipt.ReadAt.Value);
                    }
                    return m;
                }).Select(t => t.Result).ToList(),
                Conversations = _mapper.Map<IEnumerable<ChatConversationDto>>(conversations).Select(async c => {
                    c.CreatedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(c.CreatedAt);
                    c.UpdatedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(c.UpdatedAt);
                    if (c.LastMessage != null)
                    {
                        c.LastMessage.CreatedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(c.LastMessage.CreatedAt);
                        c.LastMessage.UpdatedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(c.LastMessage.UpdatedAt);
                        if (c.LastMessage.EditedAt.HasValue) c.LastMessage.EditedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(c.LastMessage.EditedAt.Value);
                        if (c.LastMessage.DeliveryReceipt != null)
                        {
                            if (c.LastMessage.DeliveryReceipt.DeliveredAt.HasValue) c.LastMessage.DeliveryReceipt.DeliveredAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(c.LastMessage.DeliveryReceipt.DeliveredAt.Value);
                            if (c.LastMessage.DeliveryReceipt.ReadAt.HasValue) c.LastMessage.DeliveryReceipt.ReadAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(c.LastMessage.DeliveryReceipt.ReadAt.Value);
                        }
                    }
                    if (c.LastMessageTime.HasValue) c.LastMessageTime = await _currentUserService.ConvertFromUtcToUserLocalAsync(c.LastMessageTime.Value);
                    return c;
                }).Select(t => t.Result).ToList(),
                TotalCount = totalMessages + totalConversations,
                HasMore = (request.Page * request.Limit) < (totalMessages + totalConversations),
                NextPageNumber = ((request.Page * request.Limit) < (totalMessages + totalConversations)) ? request.Page + 1 : (int?)null
            };

            return ResultDto<SearchChatsResultDto>.Ok(resultDto);
        }
    }
} 
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using AutoMapper;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Chat;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Chat.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Chat.Queries.GetConversationById
{
    /// <summary>
    /// معالج استعلام جلب محادثة واحدة بناءً على المعرف
    /// Handler for GetConversationByIdQuery
    /// </summary>
    public class GetConversationByIdQueryHandler : IRequestHandler<GetConversationByIdQuery, ResultDto<ChatConversationDto>>
    {
        private readonly IChatConversationRepository _repository;
        private readonly IMapper _mapper;
        private readonly ICurrentUserService _currentUserService;

        public GetConversationByIdQueryHandler(IChatConversationRepository repository, IMapper mapper, ICurrentUserService currentUserService)
        {
            _repository = repository;
            _mapper = mapper;
            _currentUserService = currentUserService;
        }

        public async Task<ResultDto<ChatConversationDto>> Handle(GetConversationByIdQuery request, CancellationToken cancellationToken)
        {
            // Load with details to include participants and messages for accurate lastMessage/updatedAt
            var conv = await _repository.GetByIdWithDetailsAsync(request.ConversationId, cancellationToken);
            if (conv == null)
                return ResultDto<ChatConversationDto>.Failure("المحادثة غير موجودة");

            var dto = _mapper.Map<ChatConversationDto>(conv);
            dto.CreatedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(dto.CreatedAt);
            dto.UpdatedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(dto.UpdatedAt);
            if (dto.LastMessage != null)
            {
                dto.LastMessage.CreatedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(dto.LastMessage.CreatedAt);
                dto.LastMessage.UpdatedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(dto.LastMessage.UpdatedAt);
                if (dto.LastMessage.EditedAt.HasValue)
                    dto.LastMessage.EditedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(dto.LastMessage.EditedAt.Value);
                if (dto.LastMessage.DeliveryReceipt != null)
                {
                    if (dto.LastMessage.DeliveryReceipt.DeliveredAt.HasValue)
                        dto.LastMessage.DeliveryReceipt.DeliveredAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(dto.LastMessage.DeliveryReceipt.DeliveredAt.Value);
                    if (dto.LastMessage.DeliveryReceipt.ReadAt.HasValue)
                        dto.LastMessage.DeliveryReceipt.ReadAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(dto.LastMessage.DeliveryReceipt.ReadAt.Value);
                }
            }
            if (dto.LastMessageTime.HasValue)
                dto.LastMessageTime = await _currentUserService.ConvertFromUtcToUserLocalAsync(dto.LastMessageTime.Value);
            return ResultDto<ChatConversationDto>.Ok(dto);
        }
    }
} 
using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Chat;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Interfaces;
using YemenBooking.Application.Infrastructure.Services;
using AutoMapper;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Chat.DTOs;

namespace YemenBooking.Application.Features.Chat.Commands.Conversation
{
    public class CreateConversationCommandHandler : IRequestHandler<CreateConversationCommand, ResultDto<ChatConversationDto>>
    {
        private readonly IChatConversationRepository _conversationRepository;
        private readonly IUnitOfWork _unitOfWork;
        private readonly ICurrentUserService _currentUserService;
        private readonly IMapper _mapper;
        private readonly IFirebaseService _firebaseService;
        private readonly ILogger<CreateConversationCommandHandler> _logger;
        private readonly IRepository<User> _userRepository; // إضافة مستودع المستخدمين

        public CreateConversationCommandHandler(
            IChatConversationRepository conversationRepository,
            IUnitOfWork unitOfWork,
            ICurrentUserService currentUserService,
            IMapper mapper,
            IFirebaseService firebaseService,
            ILogger<CreateConversationCommandHandler> logger)
        {
            _conversationRepository = conversationRepository;
            _unitOfWork = unitOfWork;
            _currentUserService = currentUserService;
            _mapper = mapper;
            _firebaseService = firebaseService;
            _logger = logger;
            _userRepository = unitOfWork.Repository<User>(); // الحصول على مستودع المستخدمين
        }

        public async Task<ResultDto<ChatConversationDto>> Handle(CreateConversationCommand request, CancellationToken cancellationToken)
        {
            try
            {
                _logger.LogInformation("إنشاء محادثة جديدة للمستخدم {UserId}", _currentUserService.UserId);

                // تحقق من صحة البيانات الأساسية
                if (request.ParticipantIds == null || request.ParticipantIds.Count == 0)
                {
                    return ResultDto<ChatConversationDto>.Failed("قائمة المشاركين مطلوبة");
                }
                if (string.IsNullOrWhiteSpace(request.ConversationType))
                {
                    return ResultDto<ChatConversationDto>.Failed("نوع المحادثة مطلوب");
                }

                // السماح فقط بالمحادثات الثنائية المباشرة
                if (!string.Equals(request.ConversationType, "direct", StringComparison.OrdinalIgnoreCase))
                {
                    return ResultDto<ChatConversationDto>.Failed("يُسمح فقط بالمحادثات الثنائية المباشرة", errorCode: "direct_only");
                }

                var conversation = new ChatConversation
                {
                    Id = Guid.NewGuid(),
                    ConversationType = request.ConversationType,
                    Title = request.Title,
                    Description = request.Description,
                    PropertyId = request.PropertyId,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow,
                    IsArchived = false,
                    IsMuted = false
                };

                // إضافة المشاركين
                var currentUserId = _currentUserService.UserId;
                var participantIds = request.ParticipantIds.Contains(currentUserId)
                    ? request.ParticipantIds
                    : request.ParticipantIds.Append(currentUserId).ToList();

                // يجب أن تكون المحادثة بين مستخدمين فقط (بما فيهم المستخدم الحالي)
                var distinctParticipants = participantIds.Distinct().ToList();
                if (distinctParticipants.Count != 2)
                {
                    return ResultDto<ChatConversationDto>.Failed("يجب أن تكون المحادثة بين مستخدمين فقط", errorCode: "invalid_participants_count");
                }

                // للمحادثات الفردية: تحقق إن كانت موجودة مسبقًا
                if (string.Equals(request.ConversationType, "direct", StringComparison.OrdinalIgnoreCase) && participantIds.Count == 2)
                {
                    var existing = await _conversationRepository.GetDirectConversationAsync(participantIds[0], participantIds[1], cancellationToken);
                    if (existing != null)
                    {
                        // أعد المحادثة الحالية بكامل تفاصيلها
                        var dtoExisting = _mapper.Map<ChatConversationDto>(existing);
                        return ResultDto<ChatConversationDto>.Ok(dtoExisting, "المحادثة موجودة بالفعل");
                    }
                }

                // قيود الأدوار:
                // - Admin: يمكنه بدء محادثة مع أي مستخدم
                // - Owner/Staff: يستخدمون حساب العقار فقط، ويستطيعون مراسلة Admins أو العملاء الذين سبق لهم مراسلة العقار
                // - Client: يستطيع مراسلة Admins أو العقارات. ولا تظهر العقارات لديه إلا إذا سبق مراسلتها
                var roles = (_currentUserService.UserRoles ?? Enumerable.Empty<string>()).Select(r => (r ?? string.Empty).ToLowerInvariant()).ToList();
                var accountRole = (_currentUserService.AccountRole ?? string.Empty).ToLowerInvariant();
                var isAdmin = roles.Contains("admin") || roles.Contains("super_admin") || accountRole == "admin";
                var isOwner = roles.Contains("owner") || roles.Contains("hotel_owner") || accountRole == "owner";
                var isStaff = roles.Contains("staff") || roles.Contains("hotel_manager") || roles.Contains("receptionist") || accountRole == "staff";
                var isClient = roles.Contains("client") || roles.Contains("customer") || accountRole == "client";

                if (isOwner || isStaff)
                {
                    if (!conversation.PropertyId.HasValue || !_currentUserService.PropertyId.HasValue || conversation.PropertyId.Value != _currentUserService.PropertyId!.Value)
                    {
                        return ResultDto<ChatConversationDto>.Failed("حساب المراسلة لمالك/موظف يجب أن يرتبط بالعقار الخاص به", errorCode: "property_required");
                    }

                    // التحقق أن الطرف الآخر Admin أو عميل سبق مراسلة العقار
                    var otherIds = participantIds.Where(id => id != currentUserId).ToList();
                    if (otherIds.Count != 1)
                    {
                        return ResultDto<ChatConversationDto>.Failed("لا يُسمح بمحادثات جماعية لمالك/موظف في هذا السياق");
                    }
                    var otherUserId = otherIds[0];

                    // جلب المستخدم الآخر لمعرفة دوره
                    var otherUser = await _userRepository.GetByIdAsync(otherUserId, cancellationToken);
                    if (otherUser == null)
                        return ResultDto<ChatConversationDto>.Failed("المستخدم الآخر غير موجود");

                    var otherRoles = (otherUser.UserRoles ?? new List<UserRole>()).Select(ur => ur.Role?.Name?.ToLowerInvariant() ?? string.Empty).ToList();
                    var otherIsAdmin = otherRoles.Contains("admin") || otherRoles.Contains("super_admin");
                    var otherIsClient = otherRoles.Contains("client") || otherRoles.Contains("customer");

                    if (!otherIsAdmin)
                    {
                        if (!(otherIsClient && await _conversationRepository.ExistsConversationBetweenClientAndPropertyAsync(otherUserId, conversation.PropertyId.Value, cancellationToken)))
                        {
                            return ResultDto<ChatConversationDto>.Failed("لا يمكنك مراسلة هذا المستخدم لعدم وجود محادثة سابقة مع العقار", errorCode: "no_prior_client_property_chat");
                        }
                    }
                }
                else if (isClient)
                {
                    // عميل: يمكنه مراسلة Admin أو العقارات
                    // إذا كان الطرف الآخر عقار (من خلال PropertyId)، يجب السماح بإنشاء أول محادثة لبدء التواصل مع العقار
                    // وإذا كان الطرف الآخر Admin، لا قيود إضافية
                    // ملاحظة: لعرض قائمة العقارات في جهات الاتصال، يتم التحكم من جهة الاستعلام وليس هنا
                }

                // *** الحل: جلب المستخدمين الفعليين من قاعدة البيانات ***
                var users = await _userRepository.GetQueryable()
                    .Where(u => participantIds.Contains(u.Id))
                    .ToListAsync(cancellationToken);

                // التحقق من وجود جميع المستخدمين
                if (users.Count != participantIds.Count)
                {
                    var missingIds = participantIds.Except(users.Select(u => u.Id));
                    _logger.LogError("بعض المستخدمين غير موجودين: {MissingIds}", string.Join(", ", missingIds));
                    return ResultDto<ChatConversationDto>.Failed("بعض المستخدمين المحددين غير موجودين");
                }

                // فرض النوع direct دائمًا
                conversation.ConversationType = "direct";

                // إضافة المستخدمين الفعليين للمحادثة
                foreach (var user in users)
                {
                    conversation.Participants.Add(user);
                }

                // حفظ المحادثة
                await _conversationRepository.AddAsync(conversation, cancellationToken);
                await _unitOfWork.SaveChangesAsync(cancellationToken);

                // إرسال الإشعارات
                foreach (var participant in users.Where(u => u.Id != currentUserId))
                {
                    try
                    {
                        await _firebaseService.SendNotificationAsync(
                            $"user_{participant.Id}", 
                            "محادثة جديدة", 
                            conversation.Title ?? $"محادثة مع {users.FirstOrDefault(u => u.Id == currentUserId)?.Name ?? "مستخدم"}", 
                            new System.Collections.Generic.Dictionary<string, string>
                            {
                                { "type", "conversation_created" },
                                { "conversation_id", conversation.Id.ToString() }
                            }, 
                            cancellationToken);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogWarning(ex, "فشل إرسال إشعار للمستخدم {UserId}", participant.Id);
                    }
                }

                // تحميل المحادثة بتفاصيلها الكاملة
                var created = await _conversationRepository.GetByIdWithDetailsAsync(conversation.Id, cancellationToken);
                if (created == null)
                {
                    return ResultDto<ChatConversationDto>.Failed("تعذر تحميل بيانات المحادثة بعد إنشائها");
                }
                
                var dto = _mapper.Map<ChatConversationDto>(created);
                // Convert timestamps to user's local time for client
                dto.CreatedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(dto.CreatedAt);
                dto.UpdatedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(dto.UpdatedAt);
                if (dto.LastMessageTime.HasValue)
                {
                    dto.LastMessageTime = await _currentUserService.ConvertFromUtcToUserLocalAsync(dto.LastMessageTime.Value);
                }
                return ResultDto<ChatConversationDto>.Ok(dto, "تم إنشاء المحادثة بنجاح");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ أثناء إنشاء المحادثة");
                return ResultDto<ChatConversationDto>.Failed($"حدث خطأ أثناء إنشاء المحادثة: {ex.Message}");
            }
        }
    }
}
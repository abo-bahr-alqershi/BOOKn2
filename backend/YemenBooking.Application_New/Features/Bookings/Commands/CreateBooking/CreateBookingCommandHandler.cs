using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Bookings;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;
using YemenBooking.Core.Interfaces;
using YemenBooking.Core.Interfaces.Events;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Features.Pricing.Services;
using YemenBooking.Core.ValueObjects;
using YemenBooking.Application.Features.AuditLog.Services;
using System.Linq;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Core.Notifications;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Features.Accounting.Services;
using YemenBooking.Application.Features.Notifications.Services;
using YemenBooking.Application.Features.Pricing;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Application.Features.Units.Services;
using YemenBooking.Application.Features.Bookings.Commands.CreateBooking;
using System.Text.Json;

namespace YemenBooking.Application.Features.Bookings.Commands.CreateBooking;

/// <summary>
/// معالج أمر إنشاء حجز جديد
/// Create booking command handler
/// </summary>
public class CreateBookingCommandHandler : IRequestHandler<CreateBookingCommand, ResultDto<CreateBookingResponse>>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICurrentUserService _currentUserService;
    private readonly IAvailabilityService _availabilityService;
    private readonly IUnitAvailabilityRepository _availabilityRepository;
    private readonly IPricingService _pricingService;
    private readonly IValidationService _validationService;
    private readonly IAuditService _auditService;
    private readonly IEventPublisher _eventPublisher;
    private readonly ILogger<CreateBookingCommandHandler> _logger;
    private readonly INotificationService _notificationService;
    private readonly IBookingRepository _bookingRepository;
    private readonly IUnitRepository _unitRepository;
    private readonly IPropertyRepository _propertyRepository;
    private readonly IPropertyServiceRepository _propertyServiceRepository;
    private readonly IPolicyRepository _policyRepository;
    private readonly IMediator _mediator;
    private readonly IIndexingService _indexingService;
    private readonly IFinancialAccountingService _financialAccountingService;
    private readonly ICurrencySettingsService _currencySettingsService;

    public CreateBookingCommandHandler(
        IBookingRepository bookingRepository,
        IUnitRepository unitRepository,
        IPropertyRepository propertyRepository,
        IPropertyServiceRepository propertyServiceRepository,
        IPolicyRepository policyRepository,
        IUnitOfWork unitOfWork,
        ICurrentUserService currentUserService,
        IAvailabilityService availabilityService,
        IUnitAvailabilityRepository availabilityRepository,
        IPricingService pricingService,
        IValidationService validationService,
        IAuditService auditService,
        IEventPublisher eventPublisher,
        ILogger<CreateBookingCommandHandler> logger,
        INotificationService notificationService,
        IMediator mediator,
        IIndexingService indexingService,
        IFinancialAccountingService financialAccountingService,
        ICurrencySettingsService currencySettingsService)
    {
        _bookingRepository = bookingRepository;
        _unitRepository = unitRepository;
        _propertyRepository = propertyRepository;
        _propertyServiceRepository = propertyServiceRepository;
        _policyRepository = policyRepository;
        _unitOfWork = unitOfWork;
        _currentUserService = currentUserService;
        _availabilityService = availabilityService;
        _availabilityRepository = availabilityRepository;
        _pricingService = pricingService;
        _validationService = validationService;
        _auditService = auditService;
        _eventPublisher = eventPublisher;
        _logger = logger;
        _notificationService = notificationService;
        _mediator = mediator;
        _indexingService = indexingService;
        _financialAccountingService = financialAccountingService;
        _currencySettingsService = currencySettingsService;
    }

    public async Task<ResultDto<CreateBookingResponse>> Handle(CreateBookingCommand request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء معالجة أمر إنشاء حجز جديد للمستخدم {UserId} والوحدة {UnitId}", 
                request.UserId, request.UnitId);

            // Normalize incoming dates from user-local to UTC
            request.CheckIn = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.CheckIn);
            request.CheckOut = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.CheckOut);

            // التحقق من صحة المدخلات
            var validationResult = await ValidateInputAsync(request, cancellationToken);
            if (!validationResult.IsSuccess)
            {
                return validationResult;
            }

            // التحقق من وجود المستخدم والوحدة
            var existenceValidation = await ValidateExistenceAsync(request, cancellationToken);
            if (!existenceValidation.IsSuccess)
            {
                return existenceValidation;
            }

            // التحقق من الصلاحيات
            var authorizationValidation = await ValidateAuthorizationAsync(request, cancellationToken);
            if (!authorizationValidation.IsSuccess)
            {
                return authorizationValidation;
            }

            // التحقق من قواعد العمل
            var businessRulesValidation = await ValidateBusinessRulesAsync(request, cancellationToken);
            if (!businessRulesValidation.IsSuccess)
            {
                return businessRulesValidation;
            }

            // التحقق من توافر الوحدة للفترة المطلوبة
            var isAvailable = await _availabilityService.CheckAvailabilityAsync(
                request.UnitId,
                request.CheckIn,
                request.CheckOut);
            if (!isAvailable)
            {
                return ResultDto<CreateBookingResponse>.Failed("لا يمكن إنشاء الحجز؛ الوحدة غير متاحة للفترة المحددة");
            }

            // حساب السعر الإجمالي
            var priceAmount = await _pricingService.CalculatePriceAsync(
                request.UnitId,
                request.CheckIn,
                request.CheckOut);
            
            // الحصول على الوحدة والعقار لتحديد العملة الصحيحة
            var unit = await _unitRepository.GetByIdAsync(request.UnitId, cancellationToken);
            var property = await _propertyRepository.GetByIdAsync(unit.PropertyId, cancellationToken);
            
            // استخدام عملة العقار أو العملة الافتراضية للوحدة
            var currency = property?.Currency ?? unit?.BasePrice?.Currency ?? "YER";

            // تحقق من دعم العملة في إعدادات النظام
            var currencies = await _currencySettingsService.GetCurrenciesAsync(cancellationToken);
            var isSupported = currencies.Any(c => string.Equals(c.Code, currency, StringComparison.OrdinalIgnoreCase));
            if (!isSupported)
            {
                return ResultDto<CreateBookingResponse>.Failed($"العملة المحددة للحجز غير مدعومة: {currency}");
            }

            // ضمان عدم تجاوز منازل عشرية للسعر عن رقمين
            var roundedPrice = decimal.Round(priceAmount, 2);
            var totalPrice = new Money(roundedPrice, currency);

            // إنشاء كيان الحجز
            var booking = new Booking
            {
                Id = Guid.NewGuid(),
                UserId = request.UserId,
                UnitId = request.UnitId,
                CheckIn = request.CheckIn,
                CheckOut = request.CheckOut,
                GuestsCount = request.GuestsCount,
                TotalPrice = totalPrice,
                Status = BookingStatus.Pending,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow,
                IsActive = true
            };

            try
            {
                var currentPolicies = await _policyRepository.GetPropertyPoliciesAsync(property.Id, cancellationToken);
                var policySnapshotObj = new
                {
                    PropertyId = property.Id,
                    UnitId = unit.Id,
                    CapturedAt = DateTime.UtcNow,
                    UnitOverrides = new
                    {
                        AllowsCancellation = unit.AllowsCancellation,
                        CancellationWindowDays = unit.CancellationWindowDays
                    },
                    Policies = currentPolicies.Select(p => new
                    {
                        p.Id,
                        Type = p.Type.ToString(),
                        p.Description,
                        p.Rules,
                        p.CancellationWindowDays,
                        p.RequireFullPaymentBeforeConfirmation,
                        p.MinimumDepositPercentage,
                        p.MinHoursBeforeCheckIn
                    }).ToList()
                };
                booking.PolicySnapshot = JsonSerializer.Serialize(policySnapshotObj);
                booking.PolicySnapshotAt = DateTime.UtcNow;
            }
            catch
            {
                booking.PolicySnapshot = null;
                booking.PolicySnapshotAt = null;
            }

            UnitAvailability availability = null!;

            // تنفيذ إنشاء الحجز وقفل الإتاحة وتسجيل القيد المالي ضمن ترانزاكشن واحدة
            await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                // حفظ الحجز
                await _unitOfWork.Repository<Booking>().AddAsync(booking, cancellationToken);

                // إنشاء سجل توافر لحجز الوحدة
                availability = new UnitAvailability
                {
                    Id = Guid.NewGuid(),
                    UnitId = booking.UnitId,
                    StartDate = booking.CheckIn,
                    EndDate = booking.CheckOut,
                    Status = YemenBooking.Core.Enums.AvailabilityStatus.Booked,
                    Reason = "Customer Booking",
                    Notes = $"Block for booking {booking.Id}",
                    BookingId = booking.Id
                };
                await _unitOfWork.Repository<UnitAvailability>().AddAsync(availability, cancellationToken);

                // حفظ كل التغييرات قبل القيود المالية
                await _unitOfWork.SaveChangesAsync(cancellationToken);

                // تسجيل القيد المحاسبي للحجز الجديد (توزيع 95%/5%)
                var tx = await _financialAccountingService.RecordBookingTransactionAsync(booking.Id, _currentUserService.UserId);
                if (tx == null)
                    throw new InvalidOperationException("FAILED_TO_RECORD_BOOKING_TRANSACTION");
            }, cancellationToken);

            // تسجيل تنفيذ كتلة الإتاحة في سجل التدقيق
            await _auditService.LogAuditAsync(
                entityType: nameof(UnitAvailability),
                entityId: availability.Id,
                action: AuditAction.CREATE,
                oldValues: null,
                newValues: System.Text.Json.JsonSerializer.Serialize(new { booking.UnitId, booking.Id, availability.StartDate, availability.EndDate }),
                performedBy: _currentUserService.UserId,
                notes: $"تم حجز الوحدة {booking.UnitId} للحجز {booking.Id} بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})",
                cancellationToken: cancellationToken);

            // تحديث مباشر لفهرس الإتاحة
            try
            {
                var from = DateTime.UtcNow.Date;
                var to = from.AddMonths(6);
                var periods = await _availabilityRepository.GetByDateRangeAsync(booking.UnitId, from, to);
                var availableRanges = periods
                    .Where(p => p.Status == "Available")
                    .Select(p => (p.StartDate, p.EndDate))
                    .ToList();

                var bookingUnit = await _unitRepository.GetByIdAsync(booking.UnitId, cancellationToken);
                var propertyId = bookingUnit?.PropertyId ?? Guid.Empty;

                await _indexingService.OnAvailabilityChangedAsync(booking.UnitId, propertyId, availableRanges, cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "تعذرت الفهرسة المباشرة للإتاحة بعد إنشاء الحجز {BookingId}", booking.Id);
            }

            // تسجيل العملية في سجل التدقيق
            await _auditService.LogAuditAsync(
                entityType: nameof(Booking),
                entityId: booking.Id,
                action: AuditAction.CREATE,
                oldValues: null,
                newValues: System.Text.Json.JsonSerializer.Serialize(new { booking.UserId, booking.UnitId, booking.CheckIn, booking.CheckOut, booking.GuestsCount, booking.TotalPrice }),
                performedBy: _currentUserService.UserId,
                notes: $"تم إنشاء حجز جديد للمستخدم {request.UserId} بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})",
                cancellationToken: cancellationToken);

            // إرسال حدث إنشاء الحجز
            await _eventPublisher.PublishAsync(new BookingCreatedEvent
            {
                BookingId = booking.Id,
                UserId = request.UserId,
                UnitId = request.UnitId,
                CheckIn = request.CheckIn,
                CheckOut = request.CheckOut,
                TotalPrice = totalPrice,
                GuestsCount = request.GuestsCount,
                Status = booking.Status.ToString(),
                BookedAt = booking.CreatedAt
            }, cancellationToken);

            // إرسال إشعار للضيف بتأكيد الحجز المبدئي
            await _notificationService.SendAsync(new NotificationRequest
            {
                UserId = request.UserId,
                Type = NotificationType.BookingCreated,
                Title = "تم إنشاء حجزك / Your booking has been created",
                Message = $"تم إنشاء حجزك رقم {booking.Id} بنجاح / Your booking {booking.Id} has been created successfully",
                Data = new { BookingId = booking.Id }
            }, cancellationToken);

            _logger.LogInformation("تم إنشاء الحجز بنجاح بالمعرف {BookingId}", booking.Id);

            var response = new CreateBookingResponse
            {
                BookingId = booking.Id,
                Message = "تم إنشاء الحجز بنجاح"
            };
            return ResultDto<CreateBookingResponse>.Succeeded(response, "تم إنشاء الحجز بنجاح");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في إنشاء الحجز للمستخدم {UserId}", request.UserId);
            return ResultDto<CreateBookingResponse>.Failed("حدث خطأ أثناء إنشاء الحجز");
        }
    }

    /// <summary>
    /// التحقق من صحة المدخلات
    /// Input validation
    /// </summary>
    private async Task<ResultDto<CreateBookingResponse>> ValidateInputAsync(CreateBookingCommand request, CancellationToken cancellationToken)
    {
        var errors = new List<string>();

        // التحقق من صحة المعرفات
        if (request.UserId == Guid.Empty)
            errors.Add("معرف المستخدم مطلوب");

        if (request.UnitId == Guid.Empty)
            errors.Add("معرف الوحدة مطلوب");

        // التحقق من صحة التواريخ
        if (request.CheckIn >= request.CheckOut)
            errors.Add("تاريخ المغادرة يجب أن يكون بعد تاريخ الوصول");

        var userToday = (await _currentUserService.ConvertFromUtcToUserLocalAsync(DateTime.UtcNow)).Date;
        var checkInLocal = (await _currentUserService.ConvertFromUtcToUserLocalAsync(request.CheckIn)).Date;
        if (checkInLocal < userToday)
            errors.Add("تاريخ الوصول يجب أن يكون في المستقبل");

        // التحقق من عدد الضيوف
        if (request.GuestsCount <= 0)
            errors.Add("عدد الضيوف يجب أن يكون أكبر من صفر");

        // التحقق من صحة الطلب
        var validationResult = await _validationService.ValidateAsync(request, cancellationToken);
        if (!validationResult.IsValid)
        {
            errors.AddRange(validationResult.Errors.Select(e => e.Message));
        }

        if (errors.Any())
        {
            return ResultDto<CreateBookingResponse>.Failed(errors, "بيانات غير صحيحة");
        }

        return ResultDto<CreateBookingResponse>.Succeeded(new CreateBookingResponse { BookingId = Guid.Empty });
    }

    /// <summary>
    /// التحقق من وجود الكيانات
    /// Existence validation
    /// </summary>
    private async Task<ResultDto<CreateBookingResponse>> ValidateExistenceAsync(CreateBookingCommand request, CancellationToken cancellationToken)
    {
        // التحقق من وجود المستخدم
        var user = await _unitOfWork.Repository<User>().GetByIdAsync(request.UserId, cancellationToken);
        if (user == null || !user.IsActive)
        {
            return ResultDto<CreateBookingResponse>.Failed("المستخدم غير موجود أو غير نشط");
        }

        // التحقق من وجود الوحدة
        var unit = await _unitOfWork.Repository<YemenBooking.Core.Entities.Unit>().GetByIdAsync(request.UnitId, cancellationToken);
        if (unit == null || !unit.IsActive)
        {
            return ResultDto<CreateBookingResponse>.Failed("الوحدة غير موجودة أو غير نشطة");
        }

        return ResultDto<CreateBookingResponse>.Succeeded(new CreateBookingResponse { BookingId = Guid.Empty });
    }

    /// <summary>
    /// التحقق من الصلاحيات
    /// Authorization validation
    /// </summary>
    private async Task<ResultDto<CreateBookingResponse>> ValidateAuthorizationAsync(CreateBookingCommand request, CancellationToken cancellationToken)
    {
        var currentUserId = _currentUserService.UserId;
        // العثور على الوحدة للتحقق من الصلاحيات
        var unit = await _unitRepository.GetByIdAsync(request.UnitId, cancellationToken);

        // التحقق من الصلاحيات: حجز بنفسه أو مسؤول أو موظف
            if (currentUserId != request.UserId)
            {
                if (_currentUserService.Role != "Admin" && _currentUserService.Role != "Staff" && _currentUserService.UserId != request.UserId)
                {
                    return ResultDto<CreateBookingResponse>.Failed("ليس لديك الصلاحية لإنشاء حجز لمستخدم آخر");
                }
            }

        // التحقق من أن المستخدم هو موظف في الكيان إذا لم يكن المالك أو المسؤول
        if (_currentUserService.Role != "Admin" && _currentUserService.Role != "Staff" && unit != null && !_currentUserService.IsStaffInProperty(unit.PropertyId))
        {
            return ResultDto<CreateBookingResponse>.Failed("لست موظفًا في هذا الكيان");
        }

        return ResultDto<CreateBookingResponse>.Succeeded(new CreateBookingResponse { BookingId = Guid.Empty });
    }

    /// <summary>
    /// التحقق من قواعد العمل
    /// Business rules validation
    /// </summary>
    private async Task<ResultDto<CreateBookingResponse>> ValidateBusinessRulesAsync(CreateBookingCommand request, CancellationToken cancellationToken)
    {
        // التحقق من سعة الوحدة
        var unit = await _unitOfWork.Repository<YemenBooking.Core.Entities.Unit>().GetByIdAsync(request.UnitId, cancellationToken);
        if (request.GuestsCount > unit.MaxCapacity)
        {
            return ResultDto<CreateBookingResponse>.Failed($"عدد الضيوف يتجاوز السعة القصوى للوحدة ({unit.MaxCapacity})");
        }

        // التحقق من عدم وجود حجز متداخل للمستخدم
        var overlappingBookings = await _unitOfWork.Repository<Booking>().FindAsync(
            b => b.UserId == request.UserId && b.CheckIn < request.CheckOut && b.CheckOut > request.CheckIn,
            cancellationToken);
        if (overlappingBookings.Any())
        {
            return ResultDto<CreateBookingResponse>.Failed("لديك حجز آخر في نفس الفترة الزمنية");
        }

        if (request.Services != null && request.Services.Any())
        {
            var unitEntity = await _unitRepository.GetByIdAsync(request.UnitId, cancellationToken);
            if (unitEntity != null)
            {
                var propertyServices = await _propertyServiceRepository.GetPropertyServicesAsync(unitEntity.PropertyId, cancellationToken);
                var availableServiceIds = propertyServices.Select(ps => ps.Id);
                var requestedServiceIds = request.Services.Select(s => s.ServiceId);
                var invalidServiceIds = requestedServiceIds.Except(availableServiceIds).ToList();
                if (invalidServiceIds.Any())
                {
                    _logger.LogWarning("Invalid services requested: {InvalidServiceIds}", invalidServiceIds);
                    return ResultDto<CreateBookingResponse>.Failure($"Invalid services requested: {string.Join(", ", invalidServiceIds)}");
                }
            }
        }

        return ResultDto<CreateBookingResponse>.Succeeded(new CreateBookingResponse { BookingId = Guid.Empty });
    }
}

/// <summary>
/// حدث إنشاء الحجز
/// Booking created event
/// </summary>
public class BookingCreatedEvent : IBookingCreatedEvent
{
    public Guid BookingId { get; set; }
    public Guid? UserId { get; set; }
    public Guid UnitId { get; set; }
    public DateTime CheckIn { get; set; }
    public DateTime CheckOut { get; set; }
    public Money TotalPrice { get; set; }
    public DateTime OccurredAt { get; set; } = DateTime.UtcNow;
    public Guid EventId { get; set; } = Guid.NewGuid();
    public DateTime OccurredOn { get; set; } = DateTime.UtcNow;
    public string EventType { get; set; } = nameof(BookingCreatedEvent);
    public int Version { get; set; } = 1;
    public string CorrelationId { get; set; }
    public int GuestsCount { get; set; }
    public string Status { get; set; }
    public DateTime BookedAt { get; set; }
}

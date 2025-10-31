using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Authentication;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Authentication;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using System.Text.Json;
using System.Text.RegularExpressions;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Application.Features.Authentication.DTOs;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Authentication.Commands.UpdateUser;

/// <summary>
/// معالج أمر تحديث ملف المستخدم الشخصي
/// Handler for update user profile command
/// </summary>
public class UpdateUserProfileCommandHandler : IRequestHandler<UpdateUserProfileCommand, ResultDto<UpdateUserProfileResponse>>
{
    private readonly IUserRepository _userRepository;
    private readonly IFileUploadService _fileUploadService;
    private readonly ILogger<UpdateUserProfileCommandHandler> _logger;
    private readonly IAuditService _auditService;
    private readonly ICurrentUserService _currentUserService;
    private readonly IPropertyRepository _propertyRepository;

    /// <summary>
    /// منشئ معالج أمر تحديث ملف المستخدم الشخصي
    /// Constructor for update user profile command handler
    /// </summary>
    /// <param name="userRepository">مستودع المستخدمين</param>
    /// <param name="fileUploadService">خدمة رفع الملفات</param>
    /// <param name="logger">مسجل الأحداث</param>
    public UpdateUserProfileCommandHandler(
        IUserRepository userRepository,
        IFileUploadService fileUploadService,
        ILogger<UpdateUserProfileCommandHandler> logger,
        IAuditService auditService,
        ICurrentUserService currentUserService,
        IPropertyRepository propertyRepository)
    {
        _userRepository = userRepository;
        _fileUploadService = fileUploadService;
        _logger = logger;
        _auditService = auditService;
        _currentUserService = currentUserService;
        _propertyRepository = propertyRepository;
    }

    /// <summary>
    /// معالجة أمر تحديث ملف المستخدم الشخصي
    /// Handle update user profile command
    /// </summary>
    /// <param name="request">طلب تحديث الملف الشخصي</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>نتيجة العملية</returns>
    public async Task<ResultDto<UpdateUserProfileResponse>> Handle(UpdateUserProfileCommand request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء عملية تحديث ملف المستخدم الشخصي: {UserId}", request.UserId);

            // التحقق من صحة البيانات المدخلة
            if (request.UserId == Guid.Empty)
            {
                _logger.LogWarning("محاولة تحديث ملف شخصي بمعرف مستخدم غير صالح");
                return ResultDto<UpdateUserProfileResponse>.Failed("معرف المستخدم غير صالح", "INVALID_USER_ID");
            }

            // البحث عن المستخدم
            var user = await _userRepository.GetByIdAsync(request.UserId, cancellationToken);
            if (user == null)
            {
                _logger.LogWarning("لم يتم العثور على المستخدم: {UserId}", request.UserId);
                return ResultDto<UpdateUserProfileResponse>.Failed("المستخدم غير موجود", "USER_NOT_FOUND");
            }

            bool hasChanges = false;
            string? newProfileImageUrl = null;

            // تحديث الاسم إذا تم توفيره
            if (!string.IsNullOrWhiteSpace(request.Name) && request.Name != user.Name)
            {
                // التحقق من صحة الاسم
                if (request.Name.Length < 2 || request.Name.Length > 100)
                {
                    return ResultDto<UpdateUserProfileResponse>.Failed("الاسم يجب أن يكون بين 2 و 100 حرف", "INVALID_NAME_LENGTH");
                }

                // التحقق من عدم احتواء الاسم على أحرف غير مسموحة
                if (!Regex.IsMatch(request.Name, @"^[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFFa-zA-Z\s]+$"))
                {
                    return ResultDto<UpdateUserProfileResponse>.Failed("الاسم يحتوي على أحرف غير مسموحة", "INVALID_NAME_CHARACTERS");
                }

                user.Name = request.Name.Trim();
                hasChanges = true;
                _logger.LogInformation("تحديث اسم المستخدم: {UserId} إلى {NewName}", request.UserId, request.Name);
            }

            // تحديث رقم الهاتف إذا تم توفيره
            if (!string.IsNullOrWhiteSpace(request.Phone) && request.Phone != user.Phone)
            {
                // التحقق من صحة تنسيق رقم الهاتف
                var phoneRegex = new Regex(@"^(\+967|967|0)?[1-9]\d{7,8}$");
                if (!phoneRegex.IsMatch(request.Phone))
                {
                    return ResultDto<UpdateUserProfileResponse>.Failed("تنسيق رقم الهاتف غير صحيح", "INVALID_PHONE_FORMAT");
                }

                // التحقق من عدم استخدام رقم الهاتف من قبل مستخدم آخر
                var existingPhoneUser = await _userRepository.GetByPhoneAsync(request.Phone, cancellationToken);
                if (existingPhoneUser != null && existingPhoneUser.Id != request.UserId)
                {
                    _logger.LogWarning("محاولة تحديث رقم هاتف مستخدم من قبل مستخدم آخر: {Phone}", request.Phone);
                    return ResultDto<UpdateUserProfileResponse>.Failed("رقم الهاتف مستخدم من قبل مستخدم آخر", "PHONE_ALREADY_EXISTS");
                }

                user.Phone = request.Phone;
                hasChanges = true;
                _logger.LogInformation("تحديث رقم هاتف المستخدم: {UserId} إلى {NewPhone}", request.UserId, request.Phone);
            }

            // تحديث صورة الملف الشخصي إذا تم توفيرها
            if (!string.IsNullOrWhiteSpace(request.ProfileImageBase64))
            {
                try
                {
                    // التحقق من صحة تنسيق Base64
                    var imageBytes = Convert.FromBase64String(request.ProfileImageBase64);
                    
                    // التحقق من حجم الصورة (حد أقصى 5 ميجابايت)
                    if (imageBytes.Length > 5 * 1024 * 1024)
                    {
                        return ResultDto<UpdateUserProfileResponse>.Failed("حجم الصورة يجب أن يكون أقل من 5 ميجابايت", "IMAGE_TOO_LARGE");
                    }

                    // رفع الصورة
                    using var imageStream = new MemoryStream(imageBytes);
                    var uploadResult = await _fileUploadService.UploadImageAsync(
                        imageStream, 
                        $"profile_{request.UserId}", 
                        1024 * 1024); // حد أقصى 1MB

                    if (!string.IsNullOrWhiteSpace(uploadResult))
                    {
                        // حذف الصورة القديمة إذا كانت موجودة
                        if (!string.IsNullOrWhiteSpace(user.ProfileImageUrl))
                        {
                            try
                            {
                                await _fileUploadService.DeleteFileAsync(user.ProfileImageUrl);
                            }
                            catch (Exception deleteEx)
                            {
                                _logger.LogWarning(deleteEx, "فشل في حذف الصورة القديمة للمستخدم: {UserId}", request.UserId);
                            }
                        }

                        user.ProfileImageUrl = uploadResult;
                        newProfileImageUrl = uploadResult;
                        hasChanges = true;
                        _logger.LogInformation("تحديث صورة الملف الشخصي للمستخدم: {UserId}", request.UserId);
                    }
                    else
                    {
                        _logger.LogError("فشل في رفع صورة الملف الشخصي للمستخدم: {UserId}", request.UserId);
                        return ResultDto<UpdateUserProfileResponse>.Failed("فشل في رفع الصورة", "IMAGE_UPLOAD_FAILED");
                    }
                }
                catch (FormatException)
                {
                    return ResultDto<UpdateUserProfileResponse>.Failed("تنسيق الصورة غير صحيح", "INVALID_IMAGE_FORMAT");
                }
                catch (Exception imageEx)
                {
                    _logger.LogError(imageEx, "خطأ في معالجة صورة الملف الشخصي للمستخدم: {UserId}", request.UserId);
                    return ResultDto<UpdateUserProfileResponse>.Failed("خطأ في معالجة الصورة", "IMAGE_PROCESSING_ERROR");
                }
            }

            // إذا كانت هناك حقول عقار مرافقة ويملك المستخدم صلاحية المالك، نفّذ تحديث العقار ضمن نفس الطلب
            if ((_currentUserService.Role == "Admin" || _currentUserService.UserRoles.Contains("Owner"))
                 && (request.PropertyId.HasValue || !string.IsNullOrWhiteSpace(request.PropertyName) || !string.IsNullOrWhiteSpace(request.PropertyAddress)
                     || !string.IsNullOrWhiteSpace(request.PropertyCity) || !string.IsNullOrWhiteSpace(request.PropertyDescription)
                     || !string.IsNullOrWhiteSpace(request.PropertyShortDescription) || request.PropertyStarRating.HasValue
                     || !string.IsNullOrWhiteSpace(request.PropertyCurrency) || request.PropertyLatitude.HasValue || request.PropertyLongitude.HasValue))
            {
                var propertyId = request.PropertyId ?? _currentUserService.PropertyId;
                if (!propertyId.HasValue || propertyId.Value == Guid.Empty)
                {
                    _logger.LogWarning("لم يتم توفير PropertyId لطلب تحديث العقار المصاحب");
                }
                else
                {
                    var property = await _propertyRepository.GetPropertyByIdAsync(propertyId.Value, cancellationToken);
                    if (property == null)
                    {
                        _logger.LogWarning("العقار غير موجود: {PropertyId}", propertyId);
                    }
                    else if (_currentUserService.Role == "Admin" || property.OwnerId == _currentUserService.UserId)
                    {
                        if (!string.IsNullOrWhiteSpace(request.PropertyName)) property.Name = request.PropertyName!.Trim();
                        if (!string.IsNullOrWhiteSpace(request.PropertyAddress)) property.Address = request.PropertyAddress!.Trim();
                        if (!string.IsNullOrWhiteSpace(request.PropertyCity)) property.City = request.PropertyCity!.Trim();
                        if (!string.IsNullOrWhiteSpace(request.PropertyDescription)) property.Description = request.PropertyDescription!.Trim();
                        if (!string.IsNullOrWhiteSpace(request.PropertyShortDescription)) property.ShortDescription = request.PropertyShortDescription!.Trim();
                        if (!string.IsNullOrWhiteSpace(request.PropertyCurrency)) property.Currency = request.PropertyCurrency!.Trim().ToUpperInvariant();
                        if (request.PropertyStarRating.HasValue) property.StarRating = request.PropertyStarRating.Value;
                        if (request.PropertyLatitude.HasValue) property.Latitude = (decimal)request.PropertyLatitude.Value;
                        if (request.PropertyLongitude.HasValue) property.Longitude = (decimal)request.PropertyLongitude.Value;

                        property.IsApproved = false; // أي تعديل من المالك يلغي الموافقة حتى يراجع المشرف
                        property.UpdatedAt = DateTime.UtcNow;
                        property.UpdatedBy = _currentUserService.UserId;
                        await _propertyRepository.UpdatePropertyAsync(property, cancellationToken);
                        hasChanges = true;
                        _logger.LogInformation("تم تحديث بيانات العقار ضمن تحديث الملف الشخصي: {PropertyId}", property.Id);
                    }
                }
            }

            // حفظ التغييرات إذا كانت موجودة
            if (hasChanges)
            {
                user.UpdatedAt = DateTime.UtcNow;
                await _userRepository.UpdateUserAsync(user, cancellationToken);
                
                _logger.LogInformation("تم حفظ تحديثات الملف الشخصي بنجاح للمستخدم: {UserId}", request.UserId);

                // تدقيق يدوي: تحديث الملف الشخصي
                var performerName = _currentUserService.Username;
                var performerId = _currentUserService.UserId;
                var notes = $"تم تحديث الملف الشخصي للمستخدم {request.UserId} بواسطة {performerName} (ID={performerId})";
                await _auditService.LogAuditAsync(
                    entityType: "User",
                    entityId: request.UserId,
                    action: YemenBooking.Core.Entities.AuditAction.UPDATE,
                    oldValues: null,
                    newValues: JsonSerializer.Serialize(new { user.Name, user.Phone, user.ProfileImageUrl }),
                    performedBy: performerId,
                    notes: notes,
                    cancellationToken: cancellationToken);

                var response = new UpdateUserProfileResponse
                {
                    Success = true,
                    Message = "تم تحديث الملف الشخصي بنجاح",
                    NewProfileImageUrl = newProfileImageUrl
                };

                return ResultDto<UpdateUserProfileResponse>.Ok(response);
            }
            else
            {
                _logger.LogInformation("لا توجد تغييرات لحفظها في الملف الشخصي للمستخدم: {UserId}", request.UserId);

                var noChangesResponse = new UpdateUserProfileResponse
                {
                    Success = true,
                    Message = "لا توجد تغييرات للحفظ"
                };

                return ResultDto<UpdateUserProfileResponse>.Ok(noChangesResponse);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء تحديث الملف الشخصي للمستخدم: {UserId}", request.UserId);
            return ResultDto<UpdateUserProfileResponse>.Failed($"حدث خطأ أثناء تحديث الملف الشخصي: {ex.Message}", "UPDATE_PROFILE_ERROR");
        }
    }
}

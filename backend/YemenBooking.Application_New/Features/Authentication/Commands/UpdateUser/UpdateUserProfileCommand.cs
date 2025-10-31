using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Authentication;
using System;
using System.ComponentModel.DataAnnotations;
using YemenBooking.Application.Features.Authentication.DTOs;

namespace YemenBooking.Application.Features.Authentication.Commands.UpdateUser
{
    /// <summary>
    /// أمر تحديث ملف المستخدم الشخصي
    /// Command to update user profile
    /// </summary>
    public class UpdateUserProfileCommand : IRequest<ResultDto<UpdateUserProfileResponse>>
{
    /// <summary>
    /// معرف المستخدم
    /// </summary>
    public Guid UserId { get; set; }
    
    /// <summary>
    /// الاسم الجديد (اختياري)
    /// </summary>
    public string? Name { get; set; }
    
    /// <summary>
    /// رقم الهاتف الجديد (اختياري)
    /// </summary>
    public string? Phone { get; set; }
    
    /// <summary>
    /// صورة الملف الشخصي المحدثة (Base64)
    /// </summary>
    public string? ProfileImageBase64 { get; set; }

    // Optional property fields (for Owners)
    public Guid? PropertyId { get; set; }
    public string? PropertyName { get; set; }
    public string? PropertyAddress { get; set; }
    public string? PropertyCity { get; set; }
    public string? PropertyShortDescription { get; set; }
    public string? PropertyDescription { get; set; }
    public string? PropertyCurrency { get; set; }
    public int? PropertyStarRating { get; set; }
    public double? PropertyLatitude { get; set; }
    public double? PropertyLongitude { get; set; }
    }
}
using MediatR;
using YemenBooking.Application.Common.Models;
using System;

namespace YemenBooking.Application.Features.Authentication.Commands.UpdateProfile
{
    /// <summary>
    /// أمر رفع صورة الملف الشخصي للمستخدم
    /// Command to upload user profile image
    /// </summary>
    public class UploadUserProfileImageCommand : IRequest<ResultDto<UploadUserProfileImageResponse>>
    {
        /// <summary>معرف المستخدم</summary>
        public Guid UserId { get; set; }

        /// <summary>اسم الملف الأصلي</summary>
        public string FileName { get; set; } = string.Empty;

        /// <summary>نوع المحتوى</summary>
        public string ContentType { get; set; } = "application/octet-stream";

        /// <summary>محتوى الملف كـ بايت</summary>
        public byte[] FileBytes { get; set; } = Array.Empty<byte>();
    }

    /// <summary>
    /// استجابة رفع صورة الملف الشخصي
    /// </summary>
    public class UploadUserProfileImageResponse
    {
        public Guid UserId { get; set; }
        public string ProfileImageUrl { get; set; } = string.Empty;
        public DateTime UpdatedAt { get; set; }
    }
}
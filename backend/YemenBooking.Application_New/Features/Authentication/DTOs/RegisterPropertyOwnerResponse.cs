using System;

namespace YemenBooking.Application.Features.Authentication.DTOs {
    /// <summary>
    /// استجابة تسجيل مالك عقار مع إنشاء العقار
    /// Response for registering property owner with created property
    /// </summary>
    public class RegisterPropertyOwnerResponse
    {
        public Guid UserId { get; set; }
        public Guid PropertyId { get; set; }
        public string UserName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string PropertyName { get; set; } = string.Empty;
        public string AccountRole { get; set; } = "Owner";
        public string Message { get; set; } = string.Empty;

        // Tokens
        public string AccessToken { get; set; } = string.Empty;
        public string RefreshToken { get; set; } = string.Empty;
        public DateTime AccessTokenExpiry { get; set; }

        // Optional property enrichments
        public string? PropertyCurrency { get; set; }
    }
}


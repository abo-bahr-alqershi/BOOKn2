using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Features.Authentication.Services;
using YemenBooking.Core.DTOs.Common;
using System.IdentityModel.Tokens.Jwt;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using System.Security.Claims;
using System.Text;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Infrastructure.Settings;
using System.Collections.Generic;
using System.Linq;

namespace YemenBooking.Infrastructure.Services
{
    /// <summary>
    /// تنفيذ خدمة المصادقة وإدارة الجلسة
    /// Authentication and session management service implementation
    /// </summary>
    public class AuthenticationService : IAuthenticationService
    {
        // إضافة حقن مستودعات المستخدم والأدوار والخصائص والموظفين وإعدادات JWT
        private readonly IPasswordHashingService _passwordHashingService;
        private readonly IUserRepository _userRepository;
        private readonly IUserRoleRepository _userRoleRepository;
        private readonly IRoleRepository _roleRepository;
        private readonly IPropertyRepository _propertyRepository;
        private readonly IStaffRepository _staffRepository;
        private readonly JwtSettings _jwtSettings;
        private readonly ICurrencyEnsureService _currencyEnsureService;
        private readonly ILogger<AuthenticationService> _logger;

        /// <summary>
        /// المُنشئ مع حقن التبعيات اللازمة
        /// Constructor with required dependencies
        /// </summary>
        public AuthenticationService(
            IPasswordHashingService passwordHashingService,
            IUserRepository userRepository,
            IUserRoleRepository userRoleRepository,
            IRoleRepository roleRepository,
            IPropertyRepository propertyRepository,
            IStaffRepository staffRepository,
            IOptions<JwtSettings> jwtOptions,
            ICurrencyEnsureService currencyEnsureService,
            ILogger<AuthenticationService> logger)
        {
            _passwordHashingService = passwordHashingService;
            _userRepository = userRepository;
            _userRoleRepository = userRoleRepository;
            _roleRepository = roleRepository;
            _propertyRepository = propertyRepository;
            _staffRepository = staffRepository;
            _jwtSettings = jwtOptions.Value;
            _currencyEnsureService = currencyEnsureService;
            _logger = logger;
        }

        /// <inheritdoc />
        public async Task<AuthResultDto> IssueTokensForUserAsync(Guid userId, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("Issuing tokens for existing user: {UserId}", userId);
            var user = await _userRepository.GetUserByIdAsync(userId, cancellationToken);
            if (user == null)
            {
                throw new Exception("المستخدم غير موجود");
            }

            var userRoles = await _userRoleRepository.GetUserRolesAsync(user.Id, cancellationToken);
            var roleNames = new List<string>();
            foreach (var ur in userRoles)
            {
                var role = await _roleRepository.GetRoleByIdAsync(ur.RoleId, cancellationToken);
                if (role != null) roleNames.Add(role.Name);
            }

            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new Claim(ClaimTypes.Name, user.Name),
                new Claim(ClaimTypes.Email, user.Email),
                new Claim("correlationId", Guid.NewGuid().ToString()),
            };
            foreach (var rn in roleNames)
                claims.Add(new Claim(ClaimTypes.Role, rn));

            if (roleNames.Contains("Staff"))
            {
                var staff = await _staffRepository.GetStaffByUserAsync(user.Id, cancellationToken);
                if (staff != null)
                {
                    var perms = System.Text.Json.JsonSerializer.Deserialize<string[]>(staff.Permissions);
                    if (perms != null)
                        foreach (var p in perms)
                            claims.Add(new Claim("permission", p));
                    claims.Add(new Claim("propertyId", staff.PropertyId.ToString()));
                    var prop = await _propertyRepository.GetPropertyByIdAsync(staff.PropertyId, cancellationToken);
                    if (prop != null)
                    {
                        claims.Add(new Claim("propertyName", prop.Name));
                        var currencyCode = (prop.Currency ?? string.Empty).ToUpperInvariant();
                        if (!string.IsNullOrWhiteSpace(currencyCode))
                        {
                            await _currencyEnsureService.EnsureCurrencyExistsAsync(currencyCode, cancellationToken);
                            claims.Add(new Claim("propertyCurrency", currencyCode));
                        }
                    }
                    claims.Add(new Claim("staffId", staff.Id.ToString()));
                }
            }
            if (roleNames.Contains("Owner") || roleNames.Contains("HOTEL_OWNER") || roleNames.Contains("HOTEL_MANAGER"))
            {
                var props = await _propertyRepository.GetPropertiesByOwnerAsync(user.Id, cancellationToken);
                var firstProp = props.FirstOrDefault();
                if (firstProp != null)
                {
                    claims.Add(new Claim("propertyId", firstProp.Id.ToString()));
                    claims.Add(new Claim("propertyName", firstProp.Name));
                    var currencyCode = (firstProp.Currency ?? string.Empty).ToUpperInvariant();
                    if (!string.IsNullOrWhiteSpace(currencyCode))
                    {
                        await _currencyEnsureService.EnsureCurrencyExistsAsync(currencyCode, cancellationToken);
                        claims.Add(new Claim("propertyCurrency", currencyCode));
                    }
                }
            }

            var accountRole = NormalizeAccountRole(roleNames);
            if (!string.IsNullOrWhiteSpace(accountRole))
                claims.Add(new Claim("accountRole", accountRole));

            var tokens = GenerateTokens(claims);

            return new AuthResultDto
            {
                AccessToken = tokens.AccessToken,
                RefreshToken = tokens.RefreshToken,
                ExpiresAt = tokens.AccessTokenExpiresAt,
                UserId = user.Id,
                UserName = user.Name,
                Email = user.Email,
                Role = roleNames.FirstOrDefault() ?? string.Empty,
                AccountRole = accountRole,
                ProfileImage = user.ProfileImage ?? string.Empty,
                PropertyName = claims.FirstOrDefault(c => c.Type == "propertyName")?.Value,
                PropertyId = claims.FirstOrDefault(c => c.Type == "propertyId")?.Value,
                StaffId = claims.FirstOrDefault(c => c.Type == "staffId")?.Value,
                PropertyCurrency = claims.FirstOrDefault(c => c.Type == "propertyCurrency")?.Value
            };
        }

        /// <inheritdoc />
        public async Task<AuthResultDto> LoginAsync(string email, string password, CancellationToken cancellationToken = default)
        {
            // Treat the first parameter as an identifier (email or phone)
            var identifier = (email ?? string.Empty).Trim();
            _logger.LogInformation("بدء عملية المصادقة للمستخدم: {Identifier}", identifier);

            // Try email first (case-insensitive), then phone (normalized)
            var user = await _userRepository.GetUserByEmailAsync(identifier, cancellationToken);
            if (user == null)
            {
                var normalizedPhone = new string(identifier.Where(char.IsDigit).ToArray());
                if (!string.IsNullOrEmpty(normalizedPhone))
                {
                    user = await _userRepository.GetByPhoneAsync(normalizedPhone, cancellationToken);
                }
            }

            if (user == null)
            {
                _logger.LogWarning("فشل تسجيل الدخول: المستخدم غير موجود. Identifier={Identifier}", identifier);
                throw new Exception("المستخدم غير موجود");
            }
            // التحقق من كلمة المرور
            var valid = await _passwordHashingService.VerifyPasswordAsync(password, user.Password!, cancellationToken);
            if (!valid) throw new Exception("بيانات الاعتماد غير صحيحة");

            // جلب الأدوار
            var userRoles = await _userRoleRepository.GetUserRolesAsync(user.Id, cancellationToken);
            var roleNames = new List<string>();
            foreach (var ur in userRoles)
            {
                var role = await _roleRepository.GetRoleByIdAsync(ur.RoleId, cancellationToken);
                if (role != null) roleNames.Add(role.Name);
            }

            // إنشاء مجلد المطالبات
            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new Claim(ClaimTypes.Name, user.Name),
                new Claim(ClaimTypes.Email, user.Email),
                new Claim("correlationId", Guid.NewGuid().ToString()),
            };
            foreach (var rn in roleNames)
                claims.Add(new Claim(ClaimTypes.Role, rn));

            // إضافة صلاحيات لموظفي الكيان
            if (roleNames.Contains("Staff"))
            {
                var staff = await _staffRepository.GetStaffByUserAsync(user.Id, cancellationToken);
                if (staff != null)
                {
                    // صلاحيات من JSON
                    var perms = System.Text.Json.JsonSerializer.Deserialize<string[]>(staff.Permissions);
                    if (perms != null)
                        foreach (var p in perms)
                            claims.Add(new Claim("permission", p));
                    // إضافة معلومات الكيان
                    claims.Add(new Claim("propertyId", staff.PropertyId.ToString()));
                    var prop = await _propertyRepository.GetPropertyByIdAsync(staff.PropertyId, cancellationToken);
                    if (prop != null)
                    {
                        claims.Add(new Claim("propertyName", prop.Name));
                        var currencyCode = (prop.Currency ?? string.Empty).ToUpperInvariant();
                        if (!string.IsNullOrWhiteSpace(currencyCode))
                        {
                            await _currencyEnsureService.EnsureCurrencyExistsAsync(currencyCode, cancellationToken);
                            claims.Add(new Claim("propertyCurrency", currencyCode));
                        }
                    }
                    claims.Add(new Claim("staffId", staff.Id.ToString()));
                }
            }
            // إضافة معلومات الكيان لمالكي الكيان
            if (roleNames.Contains("Owner") || roleNames.Contains("HOTEL_OWNER") || roleNames.Contains("HOTEL_MANAGER"))
            {
                var props = await _propertyRepository.GetPropertiesByOwnerAsync(user.Id, cancellationToken);
                var firstProp = props.FirstOrDefault();
                if (firstProp != null)
                {
                    claims.Add(new Claim("propertyId", firstProp.Id.ToString()));
                    claims.Add(new Claim("propertyName", firstProp.Name));
                    var currencyCode = (firstProp.Currency ?? string.Empty).ToUpperInvariant();
                    if (!string.IsNullOrWhiteSpace(currencyCode))
                    {
                        await _currencyEnsureService.EnsureCurrencyExistsAsync(currencyCode, cancellationToken);
                        claims.Add(new Claim("propertyCurrency", currencyCode));
                    }
                }
            }

            // إضافة نوع حساب موحّد
            var accountRole = NormalizeAccountRole(roleNames);
            if (!string.IsNullOrWhiteSpace(accountRole))
                claims.Add(new Claim("accountRole", accountRole));

            var tokens = GenerateTokens(claims);

            return new AuthResultDto
            {
                AccessToken = tokens.AccessToken,
                RefreshToken = tokens.RefreshToken,
                ExpiresAt = tokens.AccessTokenExpiresAt,
                UserId = user.Id,
                UserName = user.Name,
                Email = user.Email,
                Role = roleNames.FirstOrDefault() ?? string.Empty,
                AccountRole = accountRole,
                ProfileImage = user.ProfileImage ?? string.Empty,
                PropertyName = claims.FirstOrDefault(c => c.Type == "propertyName")?.Value,
                PropertyId = claims.FirstOrDefault(c => c.Type == "propertyId")?.Value,
                StaffId = claims.FirstOrDefault(c => c.Type == "staffId")?.Value,
                PropertyCurrency = claims.FirstOrDefault(c => c.Type == "propertyCurrency")?.Value
            };
        }

        /// <inheritdoc />
        public async Task<AuthResultDto> RefreshTokenAsync(string refreshToken, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("بدء تجديد رمز المصادقة");
            var tokenHandler = new JwtSecurityTokenHandler();
            var issuer = ResolveIssuer();
            var audience = ResolveAudience();
            var secret = ResolveSecret();

            var validateIssuer = !string.IsNullOrWhiteSpace(issuer);
            var validateAudience = !string.IsNullOrWhiteSpace(audience);

            ClaimsPrincipal principal;
            try
            {
                var validationParameters = new TokenValidationParameters
                {
                    // Accept known issuers; keep issuer validation on when value provided
                    ValidateIssuer = validateIssuer,
                    ValidIssuer = issuer,
                    ValidIssuers = new[] { issuer, DefaultIssuer, "YourIssuer" },

                    // Do NOT require audience for refresh tokens to avoid env drift
                    ValidateAudience = false,

                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secret)),

                    // Enforce token lifetime with a small clock skew
                    ValidateLifetime = true,
                    ClockSkew = TimeSpan.FromMinutes(1)
                };

                principal = tokenHandler.ValidateToken(refreshToken, validationParameters, out _);
            }
            catch (SecurityTokenException ex)
            {
                _logger.LogWarning(ex, "رمز التحديث غير صالح. Issuer={Issuer} Audience={Audience}", issuer, audience);
                throw;
            }

            // التحقق من نوع التوكن
            if (principal.FindFirst("tokenType")?.Value != "refresh")
            {
                throw new SecurityTokenException("رمز التحديث غير صالح");
            }

            var userIdClaim = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrWhiteSpace(userIdClaim) || !Guid.TryParse(userIdClaim, out var userId))
            {
                throw new SecurityTokenException("تعذر تحديد المستخدم من رمز التحديث");
            }

            var user = await _userRepository.GetUserByIdAsync(userId, cancellationToken);
            if (user == null)
            {
                throw new SecurityTokenException("المستخدم غير موجود");
            }

            // إعادة بناء نفس المطالبات المعتمدة في تسجيل الدخول
            var userRoles = await _userRoleRepository.GetUserRolesAsync(user.Id, cancellationToken);
            var roleNames = new List<string>();
            foreach (var ur in userRoles)
            {
                var role = await _roleRepository.GetRoleByIdAsync(ur.RoleId, cancellationToken);
                if (role != null) roleNames.Add(role.Name);
            }

            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new Claim(ClaimTypes.Name, user.Name),
                new Claim(ClaimTypes.Email, user.Email),
                new Claim("correlationId", Guid.NewGuid().ToString()),
            };
            foreach (var rn in roleNames)
                claims.Add(new Claim(ClaimTypes.Role, rn));

            if (roleNames.Contains("Staff"))
            {
                var staff = await _staffRepository.GetStaffByUserAsync(user.Id, cancellationToken);
                if (staff != null)
                {
                    var perms = System.Text.Json.JsonSerializer.Deserialize<string[]>(staff.Permissions);
                    if (perms != null)
                        foreach (var p in perms)
                            claims.Add(new Claim("permission", p));
                    claims.Add(new Claim("propertyId", staff.PropertyId.ToString()));
                    var prop = await _propertyRepository.GetPropertyByIdAsync(staff.PropertyId, cancellationToken);
                    if (prop != null)
                    {
                        claims.Add(new Claim("propertyName", prop.Name));
                        var currencyCode = (prop.Currency ?? string.Empty).ToUpperInvariant();
                        if (!string.IsNullOrWhiteSpace(currencyCode))
                        {
                            await _currencyEnsureService.EnsureCurrencyExistsAsync(currencyCode, cancellationToken);
                            claims.Add(new Claim("propertyCurrency", currencyCode));
                        }
                    }
                    claims.Add(new Claim("staffId", staff.Id.ToString()));
                }
            }
            if (roleNames.Contains("Owner") || roleNames.Contains("HOTEL_OWNER") || roleNames.Contains("HOTEL_MANAGER"))
            {
                var props = await _propertyRepository.GetPropertiesByOwnerAsync(user.Id, cancellationToken);
                var firstProp = props.FirstOrDefault();
                if (firstProp != null)
                {
                    claims.Add(new Claim("propertyId", firstProp.Id.ToString()));
                    claims.Add(new Claim("propertyName", firstProp.Name));
                    var currencyCode = (firstProp.Currency ?? string.Empty).ToUpperInvariant();
                    if (!string.IsNullOrWhiteSpace(currencyCode))
                    {
                        await _currencyEnsureService.EnsureCurrencyExistsAsync(currencyCode, cancellationToken);
                        claims.Add(new Claim("propertyCurrency", currencyCode));
                    }
                }
            }

            var accountRole = NormalizeAccountRole(roleNames);
            if (!string.IsNullOrWhiteSpace(accountRole))
                claims.Add(new Claim("accountRole", accountRole));

            var tokens = GenerateTokens(claims);

            return new AuthResultDto
            {
                AccessToken = tokens.AccessToken,
                RefreshToken = tokens.RefreshToken,
                ExpiresAt = tokens.AccessTokenExpiresAt,
                UserId = user.Id,
                UserName = user.Name,
                Email = user.Email,
                Role = roleNames.FirstOrDefault() ?? string.Empty,
                AccountRole = accountRole,
                ProfileImage = user.ProfileImage ?? string.Empty,
                PropertyName = claims.FirstOrDefault(c => c.Type == "propertyName")?.Value,
                PropertyId = claims.FirstOrDefault(c => c.Type == "propertyId")?.Value,
                StaffId = claims.FirstOrDefault(c => c.Type == "staffId")?.Value,
                PropertyCurrency = claims.FirstOrDefault(c => c.Type == "propertyCurrency")?.Value
            };
        }

        /// <inheritdoc />
        public async Task<bool> ChangePasswordAsync(Guid userId, string currentPassword, string newPassword, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("بدء عملية تغيير كلمة المرور للمستخدم: {UserId}", userId);
            try
            {
                if (userId == Guid.Empty) return false;
                if (string.IsNullOrWhiteSpace(currentPassword) || string.IsNullOrWhiteSpace(newPassword)) return false;

                var user = await _userRepository.GetUserByIdAsync(userId, cancellationToken);
                if (user == null)
                {
                    _logger.LogWarning("لم يتم العثور على المستخدم: {UserId}", userId);
                    return false;
                }

                // تحقق كلمة المرور الحالية
                var isCurrentValid = await _passwordHashingService.VerifyPasswordAsync(currentPassword, user.Password, cancellationToken);
                if (!isCurrentValid)
                {
                    _logger.LogWarning("كلمة المرور الحالية غير صحيحة للمستخدم: {UserId}", userId);
                    return false;
                }

                // منع استخدام نفس كلمة المرور
                var isSameAsCurrent = await _passwordHashingService.VerifyPasswordAsync(newPassword, user.Password, cancellationToken);
                if (isSameAsCurrent)
                {
                    _logger.LogWarning("كلمة المرور الجديدة مطابقة للحالية للمستخدم: {UserId}", userId);
                    return false;
                }

                // تشفير كلمة المرور الجديدة
                var hashedNew = await _passwordHashingService.HashPasswordAsync(newPassword, cancellationToken);
                user.Password = hashedNew;
                user.UpdatedAt = DateTime.UtcNow;

                await _userRepository.UpdateUserAsync(user, cancellationToken);
                _logger.LogInformation("تم تحديث كلمة المرور بنجاح للمستخدم: {UserId}", userId);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "فشل تغيير كلمة المرور للمستخدم: {UserId}", userId);
                return false;
            }
        }

        /// <inheritdoc />
        public Task<bool> ForgotPasswordAsync(string email, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("طلب إعادة تعيين كلمة المرور للمستخدم: {Email}", email);
            throw new NotImplementedException();
        }

        /// <inheritdoc />
        public Task<bool> ResetPasswordAsync(string token, string newPassword, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("إعادة تعيين كلمة المرور باستخدام التوكن");
            throw new NotImplementedException();
        }

        /// <inheritdoc />
        public Task<bool> VerifyEmailAsync(string token, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("تأكيد البريد الإلكتروني باستخدام التوكن");
            throw new NotImplementedException();
        }

        /// <inheritdoc />
        public Task<bool> ActivateUserAsync(Guid userId, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("تفعيل المستخدم بعد التحقق: {UserId}", userId);
            throw new NotImplementedException();
        }


        private const string DefaultIssuer = "YemenBooking";
        private const string DefaultAudience = "YemenBookingUsers";

        private string ResolveIssuer() => string.IsNullOrWhiteSpace(_jwtSettings.Issuer)
            ? DefaultIssuer
            : _jwtSettings.Issuer;

        private string ResolveAudience() => string.IsNullOrWhiteSpace(_jwtSettings.Audience)
            ? DefaultAudience
            : _jwtSettings.Audience;

        private string ResolveSecret() => string.IsNullOrWhiteSpace(_jwtSettings.Secret)
            ? "fallback-development-secret-change-in-production-please-32+chars"
            : _jwtSettings.Secret;

        private (string AccessToken, string RefreshToken, DateTime AccessTokenExpiresAt, DateTime RefreshTokenExpiresAt) GenerateTokens(IEnumerable<Claim> claims)
        {
            // إعداد التوكن
            var secret = ResolveSecret();
            var issuer = ResolveIssuer();
            var audience = ResolveAudience();

            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secret));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
            var now = DateTime.UtcNow;

            var accessExpiryMinutes = _jwtSettings.AccessTokenExpirationMinutes > 0
                ? _jwtSettings.AccessTokenExpirationMinutes
                : 60;
            var accessTokenExpires = now.AddMinutes(accessExpiryMinutes);
            var accessTokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(claims),
                Expires = accessTokenExpires,
                Issuer = issuer,
                Audience = audience,
                SigningCredentials = creds
            };
            var tokenHandler = new JwtSecurityTokenHandler();
            var accessToken = tokenHandler.WriteToken(tokenHandler.CreateToken(accessTokenDescriptor));

            var refreshExpiryDays = _jwtSettings.RefreshTokenExpirationDays > 0
                ? _jwtSettings.RefreshTokenExpirationDays
                : 7;
            var refreshTokenExpires = now.AddDays(refreshExpiryDays);
            var refreshClaims = new List<Claim>(claims) { new Claim("tokenType", "refresh") };
            var refreshDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(refreshClaims),
                Expires = refreshTokenExpires,
                Issuer = issuer,
                Audience = audience,
                SigningCredentials = creds
            };
            var refreshToken = tokenHandler.WriteToken(tokenHandler.CreateToken(refreshDescriptor));

            return (accessToken, refreshToken, accessTokenExpires, refreshTokenExpires);
        }

        private static string NormalizeAccountRole(IEnumerable<string> roleNames)
        {
            var normalized = roleNames.Select(r => r?.Trim().Replace(" ", "").Replace("-", "").ToLowerInvariant() ?? string.Empty).ToList();
            if (normalized.Any(r => r.Contains("admin"))) return "Admin";
            if (normalized.Any(r => r.Contains("owner"))) return "Owner";
            if (normalized.Any(r => r.Contains("receptionist") || r.Contains("manager") || r.Contains("staff"))) return "Staff";
            return "Client";
        }
    }
}
using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Infrastructure.Services;

namespace YemenBooking.Api.Controllers.Common
{
    [Route("api/common/system-settings")]
    [ApiController]
    [Authorize(Roles = "Admin")]
    public class SystemSettingsController : ControllerBase
    {
        private readonly ISystemSettingsService _settingsService;
        private readonly ICurrencySettingsService _currencySettingsService;
        private readonly ICitySettingsService _citySettingsService;

        public SystemSettingsController(ISystemSettingsService settingsService, ICurrencySettingsService currencySettingsService, ICitySettingsService citySettingsService)
        {
            _settingsService = settingsService;
            _currencySettingsService = currencySettingsService;
            _citySettingsService = citySettingsService;
        }

        /// <summary>
        /// جلب إعدادات النظام
        /// Get system settings
        /// </summary>
        [HttpGet]
        public async Task<ActionResult<ResultDto<Dictionary<string, string>>>> GetSettingsAsync(CancellationToken cancellationToken)
        {
            var settings = await _settingsService.GetSettingsAsync(cancellationToken);
            return Ok(ResultDto<Dictionary<string, string>>.Succeeded(settings));
        }

        /// <summary>
        /// جلب قائمة العملات
        /// Get currency settings
        /// </summary>
        [AllowAnonymous]
        [HttpGet("currencies")]
        public async Task<ActionResult<ResultDto<List<CurrencyDto>>>> GetCurrenciesAsync(CancellationToken cancellationToken)
        {
            var currencies = await _currencySettingsService.GetCurrenciesAsync(cancellationToken);
            return Ok(ResultDto<List<CurrencyDto>>.Succeeded(currencies));
        }

        /// <summary>
        /// جلب قائمة المدن
        /// Get city settings
        /// </summary>
        [AllowAnonymous]
        [HttpGet("cities")]
        public async Task<ActionResult<ResultDto<List<CityDto>>>> GetCitiesAsync(CancellationToken cancellationToken)
        {
            var cities = await _citySettingsService.GetCitiesAsync(cancellationToken);
            var baseUrl = $"{Request.Scheme}://{Request.Host}";
            foreach (var c in cities)
            {
                for (int i = 0; i < c.Images.Count; i++)
                {
                    var url = c.Images[i] ?? string.Empty;
                    if (!string.IsNullOrWhiteSpace(url) && !url.StartsWith("http", StringComparison.OrdinalIgnoreCase))
                    {
                        c.Images[i] = baseUrl + (url.StartsWith("/") ? url : "/" + url);
                    }
                }
            }
            return Ok(ResultDto<List<CityDto>>.Succeeded(cities));
        }
    }
} 
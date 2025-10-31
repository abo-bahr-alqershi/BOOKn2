using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Common.Models;
using System;
using System.Linq;
using System.Collections.Generic;
using YemenBooking.Infrastructure.Services;
using YemenBooking.Application.Infrastructure.Services;

namespace YemenBooking.Api.Controllers.Admin
{
    [Route("api/admin/system-settings")]
    [ApiController]
    [Authorize(Roles = "Admin")]
    public class SystemSettingsController : ControllerBase
    {
        private readonly ISystemSettingsService _settingsService;
        private readonly ICurrencySettingsService _currencySettingsService;
        private readonly ICitySettingsService _citySettingsService;
        private static double? Trend(double current, double previous)
        {
            if (previous == 0)
                return current == 0 ? 0.0 : (double?)null;
            var pct = ((current - previous) / previous) * 100.0;
            return Math.Round(pct, 1);
        }

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
        /// حفظ أو تحديث إعدادات النظام
        /// Save or update system settings
        /// </summary>
        [HttpPut]
        public async Task<ActionResult<ResultDto<bool>>> SaveSettingsAsync([FromBody] Dictionary<string, string> settings, CancellationToken cancellationToken)
        {
            await _settingsService.SaveSettingsAsync(settings, cancellationToken);
            return Ok(ResultDto<bool>.Succeeded(true));
        }

        /// <summary>
        /// جلب قائمة العملات
        /// Get currency settings
        /// </summary>
        [AllowAnonymous]
        [HttpGet("currencies")]
        public async Task<ActionResult<ResultDto<List<Application.Common.Models.CurrencyDto>>>> GetCurrenciesAsync(CancellationToken cancellationToken)
        {
            var currencies = await _currencySettingsService.GetCurrenciesAsync(cancellationToken);
            return Ok(ResultDto<List<Application.Common.Models.CurrencyDto>>.Succeeded(currencies));
        }

        /// <summary>
        /// Get currency statistics with optional last-30-days trends
        /// </summary>
        [HttpGet("currencies/stats")]
        public async Task<ActionResult<ResultDto<CurrencyStatsDto>>> GetCurrenciesStatsAsync([FromQuery] DateTime? startDate = null, [FromQuery] DateTime? endDate = null, CancellationToken cancellationToken = default)
        {
            var list = await _currencySettingsService.GetCurrenciesAsync(cancellationToken);
            var total = list.Count;
            var def = list.FirstOrDefault(c => c.IsDefault)?.Code;
            var withRate = list.Count(c => c.ExchangeRate.HasValue);
            var avgRate = withRate > 0 ? list.Where(c => c.ExchangeRate.HasValue).Average(c => (double)c.ExchangeRate!.Value) : 0.0;
            DateTime? lastUpdated = null;
            foreach (var c in list)
            {
                if (c.LastUpdated.HasValue)
                {
                    if (!lastUpdated.HasValue || c.LastUpdated.Value > lastUpdated.Value)
                        lastUpdated = c.LastUpdated.Value;
                }
            }

            var dto = new CurrencyStatsDto
            {
                TotalCurrencies = total,
                DefaultCurrencyCode = def,
                CurrenciesWithExchangeRate = withRate,
                AverageExchangeRate = Math.Round(avgRate, 4),
                LastUpdated = lastUpdated,
                UpdatesCount = 0,
                UpdatesTrendPct = null,
                AverageUpdatedRate = null,
                AverageUpdatedRateTrendPct = null
            };

            if (startDate.HasValue && endDate.HasValue && endDate > startDate)
            {
                var currentStart = startDate.Value;
                var currentEnd = endDate.Value;
                var period = currentEnd - currentStart;
                var previousStart = currentStart - period;
                var previousEnd = currentStart;

                var currentUpdated = list.Where(c => c.LastUpdated.HasValue && c.LastUpdated.Value >= currentStart && c.LastUpdated.Value <= currentEnd).ToList();
                var previousUpdated = list.Where(c => c.LastUpdated.HasValue && c.LastUpdated.Value >= previousStart && c.LastUpdated.Value <= previousEnd).ToList();

                var currUpdates = currentUpdated.Count;
                var prevUpdates = previousUpdated.Count;
                var currAvgUpdatedRate = currentUpdated.Count > 0 ? currentUpdated.Where(c => c.ExchangeRate.HasValue).Average(c => (double)c.ExchangeRate!.Value) : 0.0;
                var prevAvgUpdatedRate = previousUpdated.Count > 0 ? previousUpdated.Where(c => c.ExchangeRate.HasValue).Average(c => (double)c.ExchangeRate!.Value) : 0.0;

                dto.UpdatesCount = currUpdates;
                dto.UpdatesTrendPct = Trend(currUpdates, prevUpdates);
                dto.AverageUpdatedRate = Math.Round(currAvgUpdatedRate, 4);
                dto.AverageUpdatedRateTrendPct = Trend(currAvgUpdatedRate, prevAvgUpdatedRate);
            }

            return Ok(ResultDto<CurrencyStatsDto>.Succeeded(dto));
        }

        /// <summary>
        /// Get city statistics with optional last-30-days trends
        /// </summary>
        [HttpGet("cities/stats")]
        public async Task<ActionResult<ResultDto<CityStatsDto>>> GetCitiesStatsAsync([FromQuery] DateTime? startDate = null, [FromQuery] DateTime? endDate = null, CancellationToken cancellationToken = default)
        {
            var cities = await _citySettingsService.GetCitiesAsync(cancellationToken);
            var total = cities.Count;
            var active = cities.Count(c => c.IsActive != false);
            var totalImages = cities.Sum(c => c.Images?.Count ?? 0);
            var byCountry = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
            foreach (var c in cities)
            {
                var country = c.Country ?? string.Empty;
                byCountry[country] = byCountry.TryGetValue(country, out var v) ? v + 1 : 1;
            }

            var dto = new CityStatsDto
            {
                TotalCities = total,
                ActiveCities = active,
                ByCountry = byCountry,
                TotalImages = totalImages,
                ImagesTrend = null,
                UpdatesCount = 0,
                UpdatesTrendPct = null
            };

            // Trend based on cities added/changed in the period: since CityDto has no LastUpdated, we approximate by change in count per period (using settings snapshot).
            if (startDate.HasValue && endDate.HasValue && endDate > startDate)
            {
                // Without historical audit here, expose trend as null when no baseline is available
                dto.UpdatesCount = 0;
                dto.UpdatesTrendPct = null;
            }

            return Ok(ResultDto<CityStatsDto>.Succeeded(dto));
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
            // Ensure image URLs are absolute for frontend cards, leverage same behavior as ImagesController
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

        /// <summary>
        /// حفظ أو تحديث قائمة العملات
        /// Save or update currency settings
        /// </summary>
        [HttpPut("currencies")]
        public async Task<ActionResult<ResultDto<bool>>> SaveCurrenciesAsync([FromBody] List<CurrencyDto> currencies, CancellationToken cancellationToken)
        {
            await _currencySettingsService.SaveCurrenciesAsync(currencies, cancellationToken);
            return Ok(ResultDto<bool>.Succeeded(true));
        }

        /// <summary>
        /// حذف عملة نهائياً بعد التحقق من الارتباطات
        /// Permanently delete a currency after verifying references
        /// </summary>
        [HttpDelete("currencies/{code}")]
        public async Task<ActionResult<ResultDto>> DeleteCurrencyAsync([FromRoute] string code, CancellationToken cancellationToken)
        {
            try
            {
                await _currencySettingsService.DeleteCurrencyAsync(code, cancellationToken);
                return Ok(ResultDto.Ok("تم حذف العملة بنجاح"));
            }
            catch (InvalidOperationException ex)
            {
                return Conflict(ResultDto.Failure(ex.Message, errorCode: "CURRENCY_DELETE_CONFLICT"));
            }
            catch (ArgumentException ex)
            {
                return BadRequest(ResultDto.Failure(ex.Message, errorCode: "INVALID_CURRENCY_CODE"));
            }
        }

        /// <summary>
        /// حفظ أو تحديث قائمة المدن
        /// Save or update city settings
        /// </summary>
        [HttpPut("cities")]
        public async Task<ActionResult<ResultDto<bool>>> SaveCitiesAsync([FromBody] List<CityDto> cities, CancellationToken cancellationToken)
        {
            // Normalize URLs to server-relative paths to keep DB clean
            var origin = $"{Request.Scheme}://{Request.Host}";
            foreach (var c in cities)
            {
                for (int i = 0; i < c.Images.Count; i++)
                {
                    var url = c.Images[i] ?? string.Empty;
                    if (!string.IsNullOrWhiteSpace(url) && url.StartsWith(origin, StringComparison.OrdinalIgnoreCase))
                    {
                        c.Images[i] = url.Substring(origin.Length);
                    }
                }
            }
            await _citySettingsService.SaveCitiesAsync(cities, cancellationToken);
            return Ok(ResultDto<bool>.Succeeded(true));
        }

        /// <summary>
        /// حذف مدينة مع التحقق من الارتباطات
        /// Delete city after validating dependent references
        /// </summary>
        [HttpDelete("cities/{name}")]
        public async Task<ActionResult<ResultDto>> DeleteCityAsync([FromRoute] string name, CancellationToken cancellationToken)
        {
            try
            {
                await _citySettingsService.DeleteCityAsync(name, cancellationToken);
                return Ok(ResultDto.Ok("تم حذف المدينة بنجاح"));
            }
            catch (InvalidOperationException ex)
            {
                return Conflict(ResultDto.Failure(ex.Message, errorCode: "CITY_DELETE_CONFLICT"));
            }
            catch (ArgumentException ex)
            {
                return BadRequest(ResultDto.Failure(ex.Message, errorCode: "INVALID_CITY_NAME"));
            }
        }
    }
} 
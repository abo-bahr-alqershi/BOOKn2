// RedisSearchService.cs
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using StackExchange.Redis;
using MessagePack;
using YemenBooking.Core.Indexing.Models;
using YemenBooking.Infrastructure.Indexing.Models;
using YemenBooking.Application.Infrastructure.Services;

using YemenBooking.Application.Features.SearchAndFilters.Services;

namespace YemenBooking.Infrastructure.Services
{
    public class RedisSearchService : IPropertySearchService
    {
        private readonly IRedisConnectionManager _redisManager;
        private readonly ILogger<RedisSearchService> _logger;
        private readonly IDatabase _db;

        public RedisSearchService(
            IRedisConnectionManager redisManager,
            ILogger<RedisSearchService> logger)
        {
            _redisManager = redisManager;
            _logger = logger;
            _db = _redisManager.GetDatabase();
        }

        public async Task<PropertySearchResult> SearchAsync(
            PropertySearchRequest request,
            CancellationToken cancellationToken = default)
        {
            try
            {
                // محاولة استخدام RediSearch إذا كان متاحاً
                if (await IsRediSearchAvailable())
                {
                    _logger.LogDebug("Using RediSearch for property search");
                    return await SearchWithRediSearchAsync(request, cancellationToken);
                }

                // استخدام البحث اليدوي
                _logger.LogDebug("RediSearch not available, using manual search");
                return await ManualSearchAsync(request, cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في البحث في Redis");
                // في حالة فشل Redis، نعيد نتائج فارغة
                return new PropertySearchResult
                {
                    Properties = new List<PropertySearchItem>(),
                    TotalCount = 0,
                    PageNumber = request.PageNumber,
                    PageSize = request.PageSize,
                    TotalPages = 0
                };
            }
        }

        private async Task<bool> IsRediSearchAvailable()
        {
            try
            {
                var marker = await _db.StringGetAsync("search:module:available");
                if (marker == "0") return false;
                if (marker == "1") return true;
                // Safely check command existence without invoking FT.* directly
                var cmdInfo = await _db.ExecuteAsync("COMMAND", "INFO", "FT.SEARCH");
                return !cmdInfo.IsNull;
            }
            catch (Exception ex)
            {
                _logger.LogDebug("RediSearch not available: {Message}", ex.Message);
                return false;
            }
        }

        private async Task<PropertySearchResult> SearchWithRediSearchAsync(
            PropertySearchRequest request,
            CancellationToken cancellationToken)
        {
            // إذا تم تمرير تواريخ، نفذ فلترة الإتاحة والسعة ونوع الوحدة داخل Redis (Lua)
            if (request.CheckIn.HasValue && request.CheckOut.HasValue)
            {
                return await SearchWithRediSearchWithServerAvailabilityAsync(request, cancellationToken);
            }

            var query = BuildRediSearchQuery(request);
            var offset = (request.PageNumber - 1) * request.PageSize;

            var args = new List<object> { "idx:properties", query };
            var sortBy = request.SortBy?.ToLower();
            if (sortBy == "price_asc") { args.AddRange(new object[] { "SORTBY", "min_price", "ASC" }); }
            else if (sortBy == "price_desc") { args.AddRange(new object[] { "SORTBY", "min_price", "DESC" }); }
            else if (sortBy == "rating") { args.AddRange(new object[] { "SORTBY", "average_rating", "DESC" }); }
            else if (sortBy == "newest") { args.AddRange(new object[] { "SORTBY", "created_at", "DESC" }); }
            else if (sortBy == "popularity") { args.AddRange(new object[] { "SORTBY", "booking_count", "DESC" }); }

            // استخدام باجنيشن مباشر من RediSearch
            args.AddRange(new object[] { "LIMIT", offset.ToString(), request.PageSize.ToString() });

            var result = await _db.ExecuteAsync("FT.SEARCH", args.ToArray());
            return await ParseRediSearchResultsAsync(result, request, cancellationToken);
        }

        private async Task<PropertySearchResult> SearchWithRediSearchWithServerAvailabilityAsync(
            PropertySearchRequest request,
            CancellationToken cancellationToken)
        {
            var query = BuildRediSearchQuery(request);
            var offset = (request.PageNumber - 1) * request.PageSize;
            var pageSize = request.PageSize;
            var step = Math.Max(pageSize, 100);

            string sortField = string.Empty;
            string sortDir = string.Empty;
            var s = request.SortBy?.ToLower();
            if (s == "price_asc") { sortField = "min_price"; sortDir = "ASC"; }
            else if (s == "price_desc") { sortField = "min_price"; sortDir = "DESC"; }
            else if (s == "rating") { sortField = "average_rating"; sortDir = "DESC"; }
            else if (s == "newest") { sortField = "created_at"; sortDir = "DESC"; }
            else if (s == "popularity") { sortField = "booking_count"; sortDir = "DESC"; }

            var script = @"
local query = ARGV[1]
local offset = tonumber(ARGV[2])
local pageSize = tonumber(ARGV[3])
local step = tonumber(ARGV[4])
local checkIn = tonumber(ARGV[5])
local checkOut = tonumber(ARGV[6])
local guests = tonumber(ARGV[7])
local unitTypeId = ARGV[8]
local sortField = ARGV[9]
local sortDir = ARGV[10]
local propTypeId = ARGV[11]
local dfCount = tonumber(ARGV[12])

local df = {}
if (dfCount and dfCount > 0) then
  local idx = 13
  for i=1,dfCount do
    local k = ARGV[idx]; local v = ARGV[idx+1]
    df[k] = v
    idx = idx + 2
  end
end

local function hasAvailableUnit(propId)
  local unitsKey = 'property:units:' .. propId
  local unitIds = redis.call('SMEMBERS', unitsKey)
  for _, uid in ipairs(unitIds) do
    local ukey = 'unit:' .. uid
    local maxCap = tonumber(redis.call('HGET', ukey, 'max_capacity') or '0')
    if (guests == nil or guests <= 0 or maxCap >= guests) then
      local utid = redis.call('HGET', ukey, 'unit_type_id')
      if (unitTypeId == nil or unitTypeId == '' or utid == unitTypeId) then
        local akey = 'availability:' .. uid
        if (redis.call('EXISTS', akey) == 1) then
          local ranges = redis.call('ZRANGEBYSCORE', akey, 0, checkOut)
          for _, r in ipairs(ranges) do
            local sep = string.find(r, ':')
            if sep then
              local s = tonumber(string.sub(r, 1, sep-1))
              local e = tonumber(string.sub(r, sep+1))
              if s <= checkIn and e >= checkOut then
                return 1
              end
            end
          end
        end
      end
    end
  end
  return 0
end

local accepted = {}
local totalFiltered = 0
local cursor = offset
local idx = 'idx:properties'

while true do
  local args = {'FT.SEARCH', idx, query}
  if (sortField ~= nil and sortField ~= '') then
    table.insert(args, 'SORTBY'); table.insert(args, sortField); table.insert(args, sortDir)
  end
  table.insert(args, 'LIMIT'); table.insert(args, tostring(cursor)); table.insert(args, tostring(step))

  local res = redis.call(unpack(args))
  if (not res or #res == 0) then break end
  local total = tonumber(res[1]) or 0
  if (#res <= 1) then break end

  for i = 2, #res, 2 do
    local key = res[i]
    if (string.sub(key, 1, 9) == 'property:') then
      key = string.sub(key, 10)
    end
    if (propTypeId ~= nil and propTypeId ~= '') then
      local pt = redis.call('HGET', 'property:' .. key, 'property_type_id') or ''
      if (pt ~= propTypeId) then goto continue end
    end
    if (dfCount and dfCount > 0) then
      for k, v in pairs(df) do
        local fv = redis.call('HGET', 'property:' .. key, 'df_' .. k) or ''
        if (fv ~= v) then goto continue end
      end
    end
    if (hasAvailableUnit(key) == 1) then
      totalFiltered = totalFiltered + 1
      if (#accepted < pageSize) then table.insert(accepted, key) end
    end
    ::continue::
  end

  cursor = cursor + step
  if (cursor >= total) then break end
end

local out = { tostring(totalFiltered) }
for _, v in ipairs(accepted) do table.insert(out, v) end
return out
";

            var valuesList = new List<RedisValue>
            {
                query,
                offset,
                pageSize,
                step,
                request.CheckIn!.Value.Ticks,
                request.CheckOut!.Value.Ticks,
                request.GuestsCount ?? -1,
                request.UnitTypeId ?? string.Empty,
                sortField,
                sortDir,
                // تمرير نوع العقار كـ GUID إذا كان كذلك، وإلا اتركه فارغاً
                (Guid.TryParse(request.PropertyType, out var g) ? (RedisValue)g.ToString() : string.Empty)
            };

            var dfCount = request.DynamicFieldFilters?.Count ?? 0;
            valuesList.Add(dfCount);
            if (dfCount > 0)
            {
                foreach (var kv in request.DynamicFieldFilters!)
                {
                    valuesList.Add(kv.Key);
                    valuesList.Add(kv.Value);
                }
            }

            var values = valuesList.ToArray();

            var eval = await _db.ScriptEvaluateAsync(script, values: values);
            var arr = (RedisResult[])eval;
            int totalFiltered = 0;
            var ids = new List<string>();
            if (arr != null && arr.Length > 0)
            {
                int.TryParse(arr[0].ToString(), out totalFiltered);
                for (int i = 1; i < arr.Length; i++)
                {
                    ids.Add(arr[i].ToString());
                }
            }

            // بناء العناصر من Redis
            var items = new List<PropertySearchItem>();
            if (ids.Count > 0)
            {
                var tasks = ids.Select(async id =>
                {
                    var model = await GetPropertyDetails(id);
                    if (model == null) return null;
                    return new PropertySearchItem
                    {
                        Id = model.Id,
                        Name = model.Name,
                        City = model.City,
                        PropertyType = model.PropertyType,
                        MinPrice = model.MinPrice,
                        Currency = model.Currency,
                        AverageRating = model.AverageRating,
                        StarRating = model.StarRating,
                        ImageUrls = model.ImageUrls,
                        MaxCapacity = model.MaxCapacity,
                        UnitsCount = model.UnitsCount,
                        DynamicFields = model.DynamicFields,
                        Latitude = model.Latitude,
                        Longitude = model.Longitude
                    };
                });
                var res = await Task.WhenAll(tasks);
                items = res.Where(x => x != null).ToList();
            }

            return new PropertySearchResult
            {
                Properties = items,
                TotalCount = totalFiltered,
                PageNumber = request.PageNumber,
                PageSize = request.PageSize,
                TotalPages = (int)Math.Ceiling((double)totalFiltered / Math.Max(1, request.PageSize))
            };
        }

        private async Task<PropertySearchResult> ManualSearchAsync(
            PropertySearchRequest request,
            CancellationToken cancellationToken)
        {
            // تنفيذ فلترة وباجنيشن كاملين داخل Redis عبر Lua بدون RediSearch
            var sortKey = "properties:by_rating";
            var sortDir = "DESC";
            var s = request.SortBy?.ToLower();
            if (s == "price_asc") { sortKey = "properties:by_price"; sortDir = "ASC"; }
            else if (s == "price_desc") { sortKey = "properties:by_price"; sortDir = "DESC"; }
            else if (s == "rating") { sortKey = "properties:by_rating"; sortDir = "DESC"; }
            else if (s == "newest") { sortKey = "properties:by_created"; sortDir = "DESC"; }
            else if (s == "popularity") { sortKey = "properties:by_bookings"; sortDir = "DESC"; }

            var useGeo = request.Latitude.HasValue && request.Longitude.HasValue && request.RadiusKm.HasValue;

            var script = @"
local sortKey = ARGV[1]
local sortDir = ARGV[2]
local offset = tonumber(ARGV[3])
local pageSize = tonumber(ARGV[4])
local step = tonumber(ARGV[5])
local useGeo = ARGV[6] == '1'
local lat = tonumber(ARGV[7])
local lon = tonumber(ARGV[8])
local radiusKm = tonumber(ARGV[9])
local city = ARGV[10]
local propType = ARGV[11]
local minPrice = ARGV[12]
local maxPrice = ARGV[13]
local minRating = ARGV[14]
local guests = tonumber(ARGV[15])
local unitTypeId = ARGV[16]
local checkIn = tonumber(ARGV[17])
local checkOut = tonumber(ARGV[18])
local dfCount = tonumber(ARGV[19])
local amenCount = tonumber(ARGV[20])
local svcCount = tonumber(ARGV[21])

local idx = 22
local df = {}
for i=1,dfCount do
  local k = ARGV[idx]; local v = ARGV[idx+1]
  df[k] = v
  idx = idx + 2
end
local amens = {}
for i=1,amenCount do
  amens[i] = ARGV[idx]; idx = idx + 1
end
local svcs = {}
for i=1,svcCount do
  svcs[i] = ARGV[idx]; idx = idx + 1
end

local function prop_passes(pid)
  local pkey = 'property:' .. pid
  if (redis.call('HEXISTS', pkey, 'is_approved') == 1) then
    local appr = redis.call('HGET', pkey, 'is_approved')
    if (appr ~= 'True') then return 0 end
  end
  if (city ~= nil and city ~= '' and redis.call('HGET', pkey, 'city') ~= city) then return 0 end
  if (propType ~= nil and propType ~= '') then
    if (string.len(propType) == 36) then -- GUID
      if (redis.call('HGET', pkey, 'property_type_id') ~= propType) then return 0 end
    else
      if (redis.call('HGET', pkey, 'property_type') ~= propType) then return 0 end
    end
  end
  if (minPrice ~= nil and minPrice ~= '' and tonumber(redis.call('HGET', pkey, 'min_price') or '0') < tonumber(minPrice)) then return 0 end
  if (maxPrice ~= nil and maxPrice ~= '' and tonumber(redis.call('HGET', pkey, 'min_price') or '0') > tonumber(maxPrice)) then return 0 end
  if (minRating ~= nil and minRating ~= '' and tonumber(redis.call('HGET', pkey, 'average_rating') or '0') < tonumber(minRating)) then return 0 end
  if (guests ~= nil and guests > 0 and tonumber(redis.call('HGET', pkey, 'max_capacity') or '0') < guests) then return 0 end
  -- dynamic fields
  for k,v in pairs(df) do
    local fv = redis.call('HGET', pkey, 'df_' .. k) or ''
    if (fv ~= v) then return 0 end
  end
  -- amenities
  for i=1,#amens do
    local akey = 'amenity:' .. amens[i]
    if (redis.call('SISMEMBER', akey, pid) ~= 1) then return 0 end
  end
  -- services
  for i=1,#svcs do
    local skey = 'service:' .. svcs[i]
    if (redis.call('SISMEMBER', skey, pid) ~= 1) then return 0 end
  end
  -- availability check (if dates provided)
  if (checkIn ~= nil and checkIn > 0 and checkOut ~= nil and checkOut > 0) then
    local uSet = 'property:units:' .. pid
    local uids = redis.call('SMEMBERS', uSet)
    local found = 0
    for _, uid in ipairs(uids) do
      local ukey = 'unit:' .. uid
      local cap = tonumber(redis.call('HGET', ukey, 'max_capacity') or '0')
      if (guests == nil or guests <= 0 or cap >= guests) then
        local utid = redis.call('HGET', ukey, 'unit_type_id') or ''
        if (unitTypeId == nil or unitTypeId == '' or utid == unitTypeId) then
          local akey = 'availability:' .. uid
          if (redis.call('EXISTS', akey) == 1) then
            local ranges = redis.call('ZRANGEBYSCORE', akey, 0, checkOut)
            for _, r in ipairs(ranges) do
              local sep = string.find(r, ':')
              if sep then
                local s = tonumber(string.sub(r, 1, sep-1))
                local e = tonumber(string.sub(r, sep+1))
                if (s <= checkIn and e >= checkOut) then found = 1; break end
              end
            end
            if (found == 1) then break end
          end
        end
      end
    end
    if (found == 0) then return 0 end
  end
  return 1
end

local accepted = {}
local totalFiltered = 0
local scanned = 0

if (useGeo) then
  local candidates = redis.call('GEOSEARCH', 'properties:geo', 'FROMLONLAT', tostring(lon), tostring(lat), 'BYRADIUS', tostring(radiusKm), 'km')
  for i=1,#candidates do
    local pid = candidates[i]
    if (prop_passes(pid) == 1) then
      totalFiltered = totalFiltered + 1
      if (totalFiltered > offset and #accepted < pageSize) then table.insert(accepted, pid) end
    end
  end
else
  local total = redis.call('ZCARD', sortKey)
  local cursor = 0
  if (total > 0) then
    while cursor < total do
      local stop = math.min(cursor + step - 1, total - 1)
      local chunk = {}
      if (sortDir == 'ASC') then
        chunk = redis.call('ZRANGE', sortKey, cursor, stop)
      else
        chunk = redis.call('ZREVRANGE', sortKey, cursor, stop)
      end
      for _, pid in ipairs(chunk) do
        if (prop_passes(pid) == 1) then
          totalFiltered = totalFiltered + 1
          if (totalFiltered > offset and #accepted < pageSize) then table.insert(accepted, pid) end
        end
      end
      cursor = cursor + step
      if (#accepted >= pageSize) then break end
    end
  else
    -- fallback: iterate all approved properties when sorted set is empty
    local all = redis.call('SMEMBERS', 'properties:all')
    for _, pid in ipairs(all) do
      if (prop_passes(pid) == 1) then
        totalFiltered = totalFiltered + 1
        if (totalFiltered > offset and #accepted < pageSize) then table.insert(accepted, pid) end
      end
      if (#accepted >= pageSize) then break end
    end
  end
end

local out = { tostring(totalFiltered) }
for _, v in ipairs(accepted) do table.insert(out, v) end
return out
";

            var offset = (request.PageNumber - 1) * request.PageSize;
            var step = Math.Max(request.PageSize, 200);

            var values = new List<RedisValue>
            {
                sortKey,
                sortDir,
                offset,
                request.PageSize,
                step,
                useGeo ? "1" : "0",
                request.Latitude ?? 0,
                request.Longitude ?? 0,
                request.RadiusKm ?? 0,
                request.City ?? string.Empty,
                request.PropertyType ?? string.Empty,
                request.MinPrice?.ToString() ?? string.Empty,
                request.MaxPrice?.ToString() ?? string.Empty,
                request.MinRating?.ToString() ?? string.Empty,
                request.GuestsCount ?? -1,
                request.UnitTypeId ?? string.Empty,
                request.CheckIn?.Ticks ?? -1,
                request.CheckOut?.Ticks ?? -1,
                request.DynamicFieldFilters?.Count ?? 0,
                request.RequiredAmenityIds?.Count ?? 0,
                request.ServiceIds?.Count ?? 0
            };

            if (request.DynamicFieldFilters?.Any() == true)
            {
                foreach (var kv in request.DynamicFieldFilters)
                {
                    values.Add(kv.Key);
                    values.Add(kv.Value);
                }
            }
            if (request.RequiredAmenityIds?.Any() == true)
            {
                foreach (var a in request.RequiredAmenityIds)
                    values.Add(a);
            }
            if (request.ServiceIds?.Any() == true)
            {
                foreach (var sId in request.ServiceIds)
                    values.Add(sId);
            }

            var eval = await _db.ScriptEvaluateAsync(script, values: values.ToArray());
            var arr = (RedisResult[])eval;
            int totalFiltered = 0;
            var ids = new List<string>();
            if (arr != null && arr.Length > 0)
            {
                int.TryParse(arr[0].ToString(), out totalFiltered);
                for (int i = 1; i < arr.Length; i++) ids.Add(arr[i].ToString());
            }

            var items = new List<PropertySearchItem>();
            if (ids.Count > 0)
            {
                var tasks = ids.Select(async id =>
                {
                    var model = await GetPropertyDetails(id);
                    if (model == null) return null;
                    return new PropertySearchItem
                    {
                        Id = model.Id,
                        Name = model.Name,
                        City = model.City,
                        PropertyType = model.PropertyType,
                        MinPrice = model.MinPrice,
                        Currency = model.Currency,
                        AverageRating = model.AverageRating,
                        StarRating = model.StarRating,
                        ImageUrls = model.ImageUrls,
                        MaxCapacity = model.MaxCapacity,
                        UnitsCount = model.UnitsCount,
                        DynamicFields = model.DynamicFields,
                        Latitude = model.Latitude,
                        Longitude = model.Longitude
                    };
                });
                var res = await Task.WhenAll(tasks);
                items = res.Where(x => x != null).ToList();
            }

            return new PropertySearchResult
            {
                Properties = items,
                TotalCount = totalFiltered,
                PageNumber = request.PageNumber,
                PageSize = request.PageSize,
                TotalPages = (int)Math.Ceiling((double)totalFiltered / Math.Max(1, request.PageSize))
            };
        }

        private async Task<List<string>> GetApprovedProperties()
        {
            var approvedProperties = new List<string>();
            
            try
            {
                var allPropertyIds = await _db.SetMembersAsync("properties:all");

                if (allPropertyIds != null && allPropertyIds.Length > 0)
                {
                    _logger.LogDebug("Found {Count} properties in Redis index", allPropertyIds.Length);
                    foreach (var propertyId in allPropertyIds)
                    {
                        var isApproved = await _db.HashGetAsync($"property:{propertyId}", "is_approved");
                        if (isApproved == "True")
                        {
                            approvedProperties.Add(propertyId.ToString());
                        }
                    }
                    return approvedProperties;
                }

                _logger.LogDebug("No properties found in Redis index, attempting key scan");
                // Fallback: scan keys when index set is missing/empty
                var server = _redisManager.GetServer();
                foreach (var key in server.Keys(pattern: "property:*"))
                {
                    var keyStr = key.ToString();
                    if (keyStr.StartsWith("property:units:")) continue;
                    if (keyStr.EndsWith(":bin")) continue;
                    if (keyStr.StartsWith("property:"))
                    {
                        var id = keyStr.Substring("property:".Length);
                        var isApproved = await _db.HashGetAsync(keyStr, "is_approved");
                        if (isApproved.IsNullOrEmpty || isApproved == "True")
                        {
                            approvedProperties.Add(id);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting approved properties from Redis");
            }

            _logger.LogDebug("Found {Count} approved properties", approvedProperties.Count);
            return approvedProperties.Distinct().ToList();
        }

        private async Task<PropertyIndexModel> GetPropertyDetails(string propertyId)
        {
            // محاولة جلب البيانات المسلسلة أولاً (أسرع)
            var serializedData = await _db.StringGetAsync($"property:{propertyId}:bin");
            
            if (!serializedData.IsNullOrEmpty)
            {
                return MessagePackSerializer.Deserialize<PropertyIndexModel>(serializedData);
            }

            // جلب من Hash
            var hashData = await _db.HashGetAllAsync($"property:{propertyId}");
            
            if (hashData.Length > 0)
            {
                var model = PropertyIndexModel.FromHashEntries(hashData);
                
                // جلب القوائم المرتبطة
                model.UnitIds = (await _db.SetMembersAsync($"property:units:{propertyId}"))
                    .Select(x => x.ToString()).ToList();
                
                // جلب الحقول الديناميكية
                var dynamicFields = hashData
                    .Where(x => x.Name.ToString().StartsWith("df_"))
                    .ToDictionary(
                        x => x.Name.ToString().Substring(3),
                        x => x.Value.ToString());
                
                model.DynamicFields = dynamicFields;
                
                return model;
            }

            return null;
        }

        private async Task<bool> HasAvailableUnit(string propertyId, DateTime checkIn, DateTime checkOut, int? guests, string? unitTypeId)
        {
            var unitIds = await _db.SetMembersAsync($"property:units:{propertyId}");
            if (unitIds == null || unitIds.Length == 0) return false;

            foreach (var unitId in unitIds)
            {
                var unitHash = await _db.HashGetAllAsync($"unit:{unitId}");
                if (unitHash == null || unitHash.Length == 0) continue;

                int maxCap = 0;
                string? utid = null;
                foreach (var he in unitHash)
                {
                    if (he.Name == "max_capacity") int.TryParse(he.Value.ToString(), out maxCap);
                    else if (he.Name == "unit_type_id") utid = he.Value.ToString();
                }

                if (guests.HasValue && maxCap < guests.Value) continue;
                if (!string.IsNullOrWhiteSpace(unitTypeId) && !string.Equals(utid, unitTypeId, StringComparison.OrdinalIgnoreCase)) continue;

                var availabilityKey = $"availability:{unitId}";
                if (!await _db.KeyExistsAsync(availabilityKey))
                {
                    continue; // بيانات إتاحة غير موجودة => غير متاح
                }

                var ranges = await _db.SortedSetRangeByScoreAsync(
                    availabilityKey,
                    0,
                    checkOut.Ticks);

                foreach (var range in ranges)
                {
                    var parts = range.ToString().Split(':');
                    if (parts.Length == 2)
                    {
                        var start = new DateTime(long.Parse(parts[0]));
                        var end = new DateTime(long.Parse(parts[1]));

                        if (start <= checkIn && end >= checkOut)
                        {
                            return true;
                        }
                    }
                }
            }

            return false;
        }

        private List<PropertyIndexModel> ApplySorting(
            List<PropertyIndexModel> properties,
            string? sortBy,
            double? lat,
            double? lon)
        {
            return sortBy?.ToLower() switch
            {
                "price_asc" => properties.OrderBy(p => p.MinPrice).ToList(),
                "price_desc" => properties.OrderByDescending(p => p.MinPrice).ToList(),
                "rating" => properties.OrderByDescending(p => p.AverageRating)
                    .ThenByDescending(p => p.ReviewsCount).ToList(),
                "newest" => properties.OrderByDescending(p => p.CreatedAt).ToList(),
                "popularity" => properties.OrderByDescending(p => p.BookingCount)
                    .ThenByDescending(p => p.ViewCount).ToList(),
                "distance" => (lat.HasValue && lon.HasValue)
                    ? properties.OrderBy(p => CalculateDistance(lat.Value, lon.Value, p.Latitude, p.Longitude))
                        .ToList()
                    : properties,
                _ => properties.OrderByDescending(p => p.AverageRating)
                    .ThenByDescending(p => p.ReviewsCount).ToList()
            };
        }

        private double CalculateDistance(double lat1, double lon1, double lat2, double lon2)
        {
            const double R = 6371; // كيلومتر
            var dLat = ToRadians(lat2 - lat1);
            var dLon = ToRadians(lon2 - lon1);
            var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                    Math.Cos(ToRadians(lat1)) * Math.Cos(ToRadians(lat2)) *
                    Math.Sin(dLon / 2) * Math.Sin(dLon / 2);
            var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
            return R * c;
        }

        private double ToRadians(double degrees) => degrees * Math.PI / 180;

        private string BuildRediSearchQuery(PropertySearchRequest request)
        {
            var queryParts = new List<string>();

            if (!string.IsNullOrWhiteSpace(request.SearchText))
            {
                var q = Sanitize(request.SearchText);
                queryParts.Add($"(@name:{q}* | @description:{q}*)");
            }

            if (!string.IsNullOrWhiteSpace(request.City))
            {
                var c = Sanitize(request.City);
                queryParts.Add($"@city:{{{c}}}");
            }

            if (!string.IsNullOrWhiteSpace(request.PropertyType))
            {
                // إذا كانت القيمة GUID فلا نضيفها في استعلام FT (قد لا يكون الحقل مفهرساً)، سنفلتر بعد الجلب
                if (!Guid.TryParse(request.PropertyType, out _))
                {
                    var t = Sanitize(request.PropertyType);
                    queryParts.Add($"@property_type:{{{t}}}");
                }
            }

            if (request.MinPrice.HasValue || request.MaxPrice.HasValue)
            {
                var min = request.MinPrice ?? 0;
                var max = request.MaxPrice ?? decimal.MaxValue;
                queryParts.Add($"@min_price:[{min} {max}]");
            }

            if (request.MinRating.HasValue)
            {
                queryParts.Add($"@average_rating:[{request.MinRating.Value} inf]");
            }

            if (request.GuestsCount.HasValue)
            {
                queryParts.Add($"@max_capacity:[{request.GuestsCount.Value} inf]");
            }

            queryParts.Add("@is_approved:{True}");

            return queryParts.Any() ? string.Join(" ", queryParts) : "*";
        }

        private static string Sanitize(string input)
        {
            var s = input.Trim();
            var chars = new[] { '"', '\'', ';', '\\', '|', '(', ')', '[', ']', '{', '}', '@', ':' };
            foreach (var c in chars) s = s.Replace(c.ToString(), " ");
            return s;
        }

        private string GetSortByClause(string? sortBy)
        {
            return sortBy?.ToLower() switch
            {
                "price_asc" => "SORTBY min_price ASC",
                "price_desc" => "SORTBY min_price DESC",
                "rating" => "SORTBY average_rating DESC",
                "newest" => "SORTBY created_at DESC",
                "popularity" => "SORTBY booking_count DESC",
                _ => "SORTBY average_rating DESC"
            };
        }

        private async Task<PropertySearchResult> ParseRediSearchResultsAsync(
            RedisResult result,
            PropertySearchRequest request,
            CancellationToken cancellationToken)
        {
            var properties = new List<PropertySearchItem>();
            var ids = new List<string>();
            var total = 0;

            try
            {
                var arr = (RedisResult[])result;
                if (arr != null && arr.Length > 0)
                {
                    // First element is total count
                    if (int.TryParse(arr[0].ToString(), out var t)) total = t; else total = 0;
                    // Remaining are pairs: key, fields
                    for (int i = 1; i < arr.Length; i += 2)
                    {
                        var key = arr[i].ToString();
                        if (string.IsNullOrWhiteSpace(key)) continue;
                        if (key.StartsWith("property:")) key = key.Substring("property:".Length);
                        ids.Add(key);
                    }
                }
            }
            catch
            {
                // fallback: return empty
            }

            if (ids.Count > 0)
            {
                var tasks = ids.Select(async id =>
                {
                    var model = await GetPropertyDetails(id);
                    if (model == null) return null;

                    // Property type filter: support GUID or textual type
                    if (!string.IsNullOrWhiteSpace(request.PropertyType))
                    {
                        if (Guid.TryParse(request.PropertyType, out var ptid))
                        {
                            if (model.PropertyTypeId != ptid) return null;
                        }
                        else if (!string.Equals(model.PropertyType, request.PropertyType, StringComparison.OrdinalIgnoreCase))
                        {
                            return null;
                        }
                    }

                    // Dynamic fields filter (property-level)
                    if (request.DynamicFieldFilters?.Any() == true)
                    {
                        foreach (var filter in request.DynamicFieldFilters)
                        {
                            if (!model.DynamicFields.ContainsKey(filter.Key) || model.DynamicFields[filter.Key] != filter.Value)
                                return null;
                        }
                    }

                    // Date availability + capacity + unitType filter (unit-level in Redis)
                    if (request.CheckIn.HasValue && request.CheckOut.HasValue)
                    {
                        var ok = await HasAvailableUnit(
                            id,
                            request.CheckIn.Value,
                            request.CheckOut.Value,
                            request.GuestsCount,
                            request.UnitTypeId);
                        if (!ok) return null;
                    }

                    return new PropertySearchItem
                    {
                        Id = model.Id,
                        Name = model.Name,
                        City = model.City,
                        PropertyType = model.PropertyType,
                        MinPrice = model.MinPrice,
                        Currency = model.Currency,
                        AverageRating = model.AverageRating,
                        StarRating = model.StarRating,
                        ImageUrls = model.ImageUrls,
                        MaxCapacity = model.MaxCapacity,
                        UnitsCount = model.UnitsCount,
                        DynamicFields = model.DynamicFields,
                        Latitude = model.Latitude,
                        Longitude = model.Longitude
                    };
                });

                var results = await Task.WhenAll(tasks);
                properties = results.Where(x => x != null).ToList();
            }

            // إعادة التصفح بعد الفلترة
            var offset = (request.PageNumber - 1) * request.PageSize;
            var filteredCount = properties.Count;
            var paged = properties.Skip(offset).Take(request.PageSize).ToList();

            return new PropertySearchResult
            {
                Properties = paged,
                TotalCount = filteredCount,
                PageNumber = request.PageNumber,
                PageSize = request.PageSize,
                TotalPages = (int)Math.Ceiling((double)filteredCount / request.PageSize)
            };
        }
    }
}
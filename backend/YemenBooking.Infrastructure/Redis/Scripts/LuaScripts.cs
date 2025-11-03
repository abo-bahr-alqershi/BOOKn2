using System;
using System.Collections.Generic;

namespace YemenBooking.Infrastructure.Redis.Scripts
{
    /// <summary>
    /// مجموعة Lua Scripts المحسنة للنظام
    /// توفر معالجة فعالة على جانب الخادم
    /// </summary>
    public static class LuaScripts
    {
        /// <summary>
        /// سكريبت البحث والفلترة المعقد
        /// يقوم بالبحث والفلترة والترتيب على جانب Redis
        /// </summary>
        public const string COMPLEX_SEARCH_SCRIPT = @"
-- معاملات الإدخال
local search_pattern = ARGV[1]
local city = ARGV[2]
local property_type = ARGV[3]
local min_price = tonumber(ARGV[4]) or 0
local max_price = tonumber(ARGV[5]) or 999999999
local min_rating = tonumber(ARGV[6]) or 0
local guests_count = tonumber(ARGV[7]) or 0
local check_in = tonumber(ARGV[8])
local check_out = tonumber(ARGV[9])
local sort_by = ARGV[10] or 'popularity'
local page_number = tonumber(ARGV[11]) or 1
local page_size = tonumber(ARGV[12]) or 20
local amenity_ids = cjson.decode(ARGV[13] or '[]')
local preferred_currency = ARGV[14] or ''

-- متغيرات محلية
local results = {}
local property_scores = {}
local total_count = 0

-- دالة تحويل العملة (تقريبية)
local function convert_currency(amount, from_currency, to_currency)
    if to_currency == '' or from_currency == '' or from_currency == to_currency then
        return amount
    end
    local fx_key = 'cache:fx:' .. from_currency .. ':' .. to_currency
    local rate = redis.call('GET', fx_key)
    if rate then
        local r = tonumber(rate)
        if r and r > 0 then
            return amount * r
        end
    end
    return amount -- fallback بدون تحويل
end

-- دالة فحص الإتاحة
local function check_availability(property_id)
    if not check_in or not check_out then
        return true -- إذا لم يتم تحديد تواريخ، اعتبر متاح
    end
    
    local units_key = 'property:units:' .. property_id
    local unit_ids = redis.call('SMEMBERS', units_key)
    
    for _, unit_id in ipairs(unit_ids) do
        -- فحص السعة
        local unit_key = 'unit:' .. unit_id
        local unit_data = redis.call('HMGET', unit_key, 'max_capacity','base_price','currency','is_active','is_available')
        local max_capacity = tonumber(unit_data[1] or 0)
        local base_price = tonumber(unit_data[2] or 0)
        local unit_currency = unit_data[3] or 'YER'
        local is_active = unit_data[4] == '1'
        local is_available_flag = unit_data[5] == '1'
        if is_active and is_available_flag and max_capacity >= guests_count then
            -- فحص الإتاحة
            local avail_key = 'avail:unit:' .. unit_id
            local ranges = redis.call('ZRANGEBYSCORE', avail_key, 0, check_out)
            
            for _, range in ipairs(ranges) do
                local parts = {}
                for part in string.gmatch(range, '([^:]+)') do
                    table.insert(parts, part)
                end
                
                if #parts == 2 then
                    local start_date = tonumber(parts[1])
                    local end_date = tonumber(parts[2])
                    
                    if start_date <= check_in and end_date >= check_out then
                        -- فحص التسعير
                        local passes_price = true
                        if min_price > 0 or max_price < 999999999 then
                            local price_key = 'price:unit:' .. unit_id
                            local price_ranges = redis.call('ZRANGEBYSCORE', price_key, 0, check_out)
                            local found_cover = false
                            local price_nightly = base_price
                            local price_currency = unit_currency
                            for _, pr in ipairs(price_ranges) do
                                local p = {}
                                for x in string.gmatch(pr, '([^:]+)') do table.insert(p, x) end
                                if #p >= 4 then
                                    local p_start = tonumber(p[1])
                                    local p_end = tonumber(p[2])
                                    local p_price = tonumber(p[3]) or 0
                                    local p_curr = p[4]
                                    if p_start <= check_in and p_end >= check_out then
                                        found_cover = true
                                        price_nightly = p_price
                                        price_currency = p_curr
                                        break
                                    end
                                end
                            end
                            -- تحويل العملة إذا لزم
                            local price_eval = convert_currency(price_nightly, price_currency, preferred_currency)
                            if price_eval < min_price or price_eval > max_price then
                                passes_price = false
                            end
                        end
                        if passes_price then
                            return true -- وحدة متاحة وتحقق السعر
                        end
                    end
                end
            end
        end
    end
    
    return false -- لا توجد وحدات متاحة
end

-- دالة حساب النقاط للترتيب
local function calculate_score(property_data, sort_by)
    if sort_by == 'price_asc' or sort_by == 'price_desc' then
        return tonumber(property_data['min_price'] or 0)
    elseif sort_by == 'rating' then
        return tonumber(property_data['average_rating'] or 0) * 
               tonumber(property_data['reviews_count'] or 0)
    elseif sort_by == 'newest' then
        return tonumber(property_data['created_at'] or 0)
    elseif sort_by == 'bookings' then
        return tonumber(property_data['booking_count'] or 0)
    else -- popularity
        local rating = tonumber(property_data['average_rating'] or 0)
        local reviews = tonumber(property_data['reviews_count'] or 0)
        local bookings = tonumber(property_data['booking_count'] or 0)
        local views = tonumber(property_data['views_count'] or 0)
        
        return (rating * reviews * 0.3) + (bookings * 0.3) + (views * 0.1)
    end
end

-- دالة فحص المرافق
local function has_required_amenities(property_id, required_amenities)
    if #required_amenities == 0 then
        return true
    end
    
    for _, amenity_id in ipairs(required_amenities) do
        local amenity_key = 'tag:amenity:' .. amenity_id
        local has_amenity = redis.call('SISMEMBER', amenity_key, property_id)
        if has_amenity == 0 then
            return false
        end
    end
    
    return true
end

-- جلب جميع العقارات المحتملة
local base_set = 'properties:all'
local property_ids = {}

if city ~= '' then
    base_set = 'tag:city:' .. string.lower(city)
end

property_ids = redis.call('SMEMBERS', base_set)

-- فلترة العقارات
for _, property_id in ipairs(property_ids) do
    local property_key = 'property:' .. property_id
    local property_data = redis.call('HGETALL', property_key)
    
    if #property_data > 0 then
        -- تحويل إلى جدول
        local prop = {}
        for i = 1, #property_data, 2 do
            prop[property_data[i]] = property_data[i+1]
        end
        
        -- فحص الفلاتر
        local passes_filters = true
        
        -- فحص النشاط والاعتماد
        if prop['is_active'] ~= '1' or prop['is_approved'] ~= '1' then
            passes_filters = false
        end
        
        -- فحص نوع العقار
        if passes_filters and property_type ~= '' then
            if prop['property_type_id'] ~= property_type then
                passes_filters = false
            end
        end
        
        -- فحص السعر (الحد الأدنى/الأقصى) سيتم التحقق بشكل أدق داخل فحص الإتاحة/التسعير للوحدات
        -- تم نقله داخل check_availability بالاعتماد على فترات التسعير للوحدات
        
        -- فحص التقييم
        if passes_filters then
            local rating = tonumber(prop['average_rating'] or 0)
            if rating < min_rating then
                passes_filters = false
            end
        end
        
        -- فحص السعة
        if passes_filters and guests_count > 0 then
            local capacity = tonumber(prop['max_capacity'] or 0)
            if capacity < guests_count then
                passes_filters = false
            end
        end
        
        -- فحص المرافق
        if passes_filters then
            passes_filters = has_required_amenities(property_id, amenity_ids)
        end
        
        -- فحص الإتاحة
        if passes_filters and check_in and check_out then
            passes_filters = check_availability(property_id)
        end
        
        -- فحص النص البحثي
        if passes_filters and search_pattern ~= '' then
            local search_lower = string.lower(search_pattern)
            local name_lower = string.lower(prop['name'] or '')
            local desc_lower = string.lower(prop['description'] or '')
            
            if not string.find(name_lower, search_lower) and 
               not string.find(desc_lower, search_lower) then
                passes_filters = false
            end
        end
        
        -- إضافة إلى النتائج
        if passes_filters then
            total_count = total_count + 1
            local score = calculate_score(prop, sort_by)
            table.insert(results, {property_id, score, prop})
        end
    end
end

-- ترتيب النتائج
if sort_by == 'price_asc' then
    table.sort(results, function(a, b) return a[2] < b[2] end)
elseif sort_by == 'price_desc' or sort_by == 'rating' or 
       sort_by == 'newest' or sort_by == 'bookings' or sort_by == 'popularity' then
    table.sort(results, function(a, b) return a[2] > b[2] end)
end

-- تطبيق التقسيم
local start_index = (page_number - 1) * page_size + 1
local end_index = math.min(start_index + page_size - 1, total_count)
local paged_results = {}

for i = start_index, end_index do
    if results[i] then
        table.insert(paged_results, results[i])
    end
end

-- إرجاع النتائج
return cjson.encode({
    total_count = total_count,
    page_number = page_number,
    page_size = page_size,
    results = paged_results
})
";

        /// <summary>
        /// سكريبت فحص الإتاحة المحسن
        /// يفحص إتاحة عدة وحدات بكفاءة
        /// </summary>
        public const string CHECK_AVAILABILITY_SCRIPT = @"
local property_id = KEYS[1]
local check_in = tonumber(ARGV[1])
local check_out = tonumber(ARGV[2])
local guests_count = tonumber(ARGV[3]) or 0
local unit_type_id = ARGV[4]

local available_units = {}
local units_key = 'property:units:' .. property_id
local unit_ids = redis.call('SMEMBERS', units_key)

for _, unit_id in ipairs(unit_ids) do
    local unit_key = 'unit:' .. unit_id
    local unit_data = redis.call('HMGET', unit_key, 
        'id', 'name', 'unit_type_id', 'max_capacity', 
        'base_price', 'currency', 'is_active', 'is_available')
    
    -- فحص الحالة والسعة ونوع الوحدة
    if unit_data[7] == '1' and unit_data[8] == '1' then
        local max_capacity = tonumber(unit_data[4] or 0)
        
        if max_capacity >= guests_count then
            if unit_type_id == '' or unit_data[3] == unit_type_id then
                -- فحص الإتاحة
                local avail_key = 'avail:unit:' .. unit_id
                local ranges = redis.call('ZRANGEBYSCORE', avail_key, 0, check_out)
                
                local is_available = false
                for _, range in ipairs(ranges) do
                    local parts = {}
                    for part in string.gmatch(range, '([^:]+)') do
                        table.insert(parts, part)
                    end
                    
                    if #parts == 2 then
                        local start_date = tonumber(parts[1])
                        local end_date = tonumber(parts[2])
                        
                        if start_date <= check_in and end_date >= check_out then
                            is_available = true
                            break
                        end
                    end
                end
                
                if is_available then
                    -- حساب السعر (مبسط)
                    local nights = math.ceil((check_out - check_in) / 86400000000)
                    local base_price = tonumber(unit_data[5] or 0)
                    local total_price = base_price * nights
                    
                    table.insert(available_units, {
                        unit_id = unit_id,
                        name = unit_data[2],
                        unit_type_id = unit_data[3],
                        max_capacity = max_capacity,
                        base_price = base_price,
                        total_price = total_price,
                        currency = unit_data[6],
                        nights = nights
                    })
                end
            end
        end
    end
end

return cjson.encode({
    property_id = property_id,
    check_in = check_in,
    check_out = check_out,
    available_units = available_units,
    total_available = #available_units
})
";

        /// <summary>
        /// سكريبت تحديث الإحصائيات الذري
        /// يحدث عدة إحصائيات في عملية واحدة
        /// </summary>
        public const string UPDATE_STATISTICS_SCRIPT = @"
local operation_name = KEYS[1]
local success = ARGV[1] == '1'
local latency_ms = tonumber(ARGV[2])
local error_type = ARGV[3]

-- تحديث عداد الطلبات الكلي
redis.call('INCR', 'stats:total_requests')

if success then
    -- تحديث عداد النجاح
    redis.call('INCR', 'stats:success:' .. operation_name)
    redis.call('SET', 'stats:last_success:' .. operation_name, redis.call('TIME')[1])
    
    -- تحديث زمن الاستجابة
    redis.call('ZADD', 'stats:latencies', latency_ms, operation_name)
    
    -- تحديث المتوسط المتحرك
    local count = redis.call('INCR', 'stats:request_count')
    local current_avg = redis.call('GET', 'stats:avg_latency')
    local new_avg = latency_ms
    
    if current_avg then
        current_avg = tonumber(current_avg)
        new_avg = ((current_avg * (count - 1)) + latency_ms) / count
    end
    
    redis.call('SET', 'stats:avg_latency', new_avg)
    
    -- تحديث P95 و P99 (تقريبي)
    local all_latencies = redis.call('ZRANGE', 'stats:latencies', 0, -1, 'WITHSCORES')
    local latency_values = {}
    for i = 2, #all_latencies, 2 do
        table.insert(latency_values, tonumber(all_latencies[i]))
    end
    
    if #latency_values > 0 then
        table.sort(latency_values)
        local p95_index = math.ceil(#latency_values * 0.95)
        local p99_index = math.ceil(#latency_values * 0.99)
        
        redis.call('SET', 'stats:p95_latency', latency_values[p95_index] or latency_ms)
        redis.call('SET', 'stats:p99_latency', latency_values[p99_index] or latency_ms)
    end
else
    -- تحديث عداد الفشل
    redis.call('INCR', 'stats:failure:' .. operation_name)
    redis.call('SET', 'stats:last_failure:' .. operation_name, redis.call('TIME')[1])
    
    if error_type ~= '' then
        redis.call('INCR', 'stats:error:' .. error_type)
        redis.call('ZINCRBY', 'stats:error_counts', 1, error_type)
    end
end

-- تحديث معدل النجاح
local total = tonumber(redis.call('GET', 'stats:total_requests') or 0)
local successes = tonumber(redis.call('GET', 'stats:success:' .. operation_name) or 0)
local success_rate = 0

if total > 0 then
    success_rate = (successes / total) * 100
end

redis.call('SET', 'stats:success_rate:' .. operation_name, success_rate)

-- إضافة إلى قائمة العمليات البطيئة إذا لزم
if latency_ms > 1000 then
    redis.call('ZADD', 'stats:slow_operations', latency_ms, operation_name)
    -- الاحتفاظ بأبطأ 100 عملية فقط
    redis.call('ZREMRANGEBYRANK', 'stats:slow_operations', 0, -101)
end

return success_rate
";

        /// <summary>
        /// سكريبت إعادة بناء الفهرس الكامل
        /// يعيد بناء جميع الفهارس من البيانات الموجودة
        /// </summary>
        public const string REBUILD_INDEX_SCRIPT = @"
local property_ids = redis.call('SMEMBERS', 'properties:all')
local processed = 0
local failed = 0

for _, property_id in ipairs(property_ids) do
    local property_key = 'property:' .. property_id
    local property_data = redis.call('HGETALL', property_key)
    
    if #property_data > 0 then
        -- تحويل إلى جدول
        local prop = {}
        for i = 1, #property_data, 2 do
            prop[property_data[i]] = property_data[i+1]
        end
        
        -- إعادة بناء الفهارس
        local success = true
        
        -- فهرس المدينة
        if prop['city'] then
            redis.call('SADD', 'tag:city:' .. string.lower(prop['city']), property_id)
        end
        
        -- فهرس النوع
        if prop['property_type_id'] then
            redis.call('SADD', 'tag:type:' .. prop['property_type_id'], property_id)
        end
        
        -- فهرس السعر
        if prop['min_price'] then
            redis.call('ZADD', 'idx:price', tonumber(prop['min_price']), property_id)
        end
        
        -- فهرس التقييم
        if prop['average_rating'] then
            redis.call('ZADD', 'idx:rating', tonumber(prop['average_rating']), property_id)
        end
        
        -- فهرس تاريخ الإنشاء
        if prop['created_at'] then
            redis.call('ZADD', 'idx:created', tonumber(prop['created_at']), property_id)
        end
        
        -- فهرس الحجوزات
        if prop['booking_count'] then
            redis.call('ZADD', 'idx:bookings', tonumber(prop['booking_count']), property_id)
        end
        
        -- فهرس الشعبية
        local popularity = 0
        if prop['average_rating'] and prop['reviews_count'] and prop['booking_count'] then
            local rating = tonumber(prop['average_rating']) or 0
            local reviews = tonumber(prop['reviews_count']) or 0
            local bookings = tonumber(prop['booking_count']) or 0
            popularity = (rating * reviews * 0.3) + (bookings * 0.3)
        end
        redis.call('ZADD', 'idx:popularity', popularity, property_id)
        
        -- الفهرس الجغرافي
        if prop['latitude'] and prop['longitude'] then
            redis.call('GEOADD', 'geo:properties', 
                tonumber(prop['longitude']), 
                tonumber(prop['latitude']), 
                property_id)
            
            if prop['city'] then
                redis.call('GEOADD', 'geo:cities:' .. string.lower(prop['city']), 
                    tonumber(prop['longitude']), 
                    tonumber(prop['latitude']), 
                    property_id)
            end
        end
        
        if success then
            processed = processed + 1
        else
            failed = failed + 1
        end
    else
        failed = failed + 1
    end
end

return cjson.encode({
    total = #property_ids,
    processed = processed,
    failed = failed,
    success_rate = processed / math.max(#property_ids, 1) * 100
})
";

        /// <summary>
        /// سكريبت تنظيف البيانات القديمة
        /// يحذف البيانات القديمة والمفاتيح المنتهية
        /// </summary>
        public const string CLEANUP_OLD_DATA_SCRIPT = @"
local cutoff_date = tonumber(ARGV[1]) -- تاريخ القطع بالتكات
local max_keys_to_process = tonumber(ARGV[2]) or 1000
local deleted_count = 0

-- تنظيف مفاتيح الإتاحة القديمة
local avail_keys = redis.call('KEYS', 'avail:unit:*')
for i = 1, math.min(#avail_keys, max_keys_to_process) do
    local key = avail_keys[i]
    local removed = redis.call('ZREMRANGEBYSCORE', key, 0, cutoff_date)
    deleted_count = deleted_count + removed
    
    -- حذف المفتاح إذا أصبح فارغاً
    if redis.call('ZCARD', key) == 0 then
        redis.call('DEL', key)
    end
end

-- تنظيف مفاتيح التاريخ القديمة
local date_keys = redis.call('KEYS', 'avail:date:*')
for i = 1, math.min(#date_keys, max_keys_to_process) do
    local key = date_keys[i]
    -- استخراج التاريخ من اسم المفتاح
    local date_str = string.match(key, 'avail:date:(%d+)')
    if date_str then
        local key_date = tonumber(date_str)
        if key_date and key_date < cutoff_date then
            redis.call('DEL', key)
            deleted_count = deleted_count + 1
        end
    end
end

-- تنظيف المفاتيح المؤقتة
local temp_keys = redis.call('KEYS', 'temp:*')
for i = 1, math.min(#temp_keys, 100) do
    redis.call('DEL', temp_keys[i])
    deleted_count = deleted_count + 1
end

-- تنظيف الكاش القديم
local cache_keys = redis.call('KEYS', 'cache:*')
local current_time = redis.call('TIME')[1]
for i = 1, math.min(#cache_keys, max_keys_to_process) do
    local ttl = redis.call('TTL', cache_keys[i])
    -- حذف المفاتيح بدون TTL أو المنتهية
    if ttl == -1 or ttl == -2 then
        redis.call('DEL', cache_keys[i])
        deleted_count = deleted_count + 1
    end
end

-- تنظيف قوائم الإحصائيات القديمة
redis.call('LTRIM', 'stats:circuit_breaker_trips', -100, -1)
redis.call('LTRIM', 'alerts:info', -1000, -1)
redis.call('LTRIM', 'alerts:warning', -500, -1)
redis.call('LTRIM', 'alerts:error', -200, -1)
redis.call('LTRIM', 'alerts:critical', -100, -1)

return deleted_count
";

        /// <summary>
        /// الحصول على SHA1 للسكريبت
        /// </summary>
        public static string GetScriptSha1(string script)
        {
            using (var sha1 = System.Security.Cryptography.SHA1.Create())
            {
                var bytes = System.Text.Encoding.UTF8.GetBytes(script);
                var hash = sha1.ComputeHash(bytes);
                return BitConverter.ToString(hash).Replace("-", "").ToLower();
            }
        }

        /// <summary>
        /// قاموس SHA1 للسكريبتات
        /// </summary>
        public static readonly Dictionary<string, string> ScriptSha1Map = new()
        {
            ["ComplexSearch"] = GetScriptSha1(COMPLEX_SEARCH_SCRIPT),
            ["CheckAvailability"] = GetScriptSha1(CHECK_AVAILABILITY_SCRIPT),
            ["UpdateStatistics"] = GetScriptSha1(UPDATE_STATISTICS_SCRIPT),
            ["RebuildIndex"] = GetScriptSha1(REBUILD_INDEX_SCRIPT),
            ["CleanupOldData"] = GetScriptSha1(CLEANUP_OLD_DATA_SCRIPT)
        };
    }
}

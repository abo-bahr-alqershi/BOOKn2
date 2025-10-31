#!/bin/bash

# سكريبت شامل للتحقق من Redis
# Redis Comprehensive Verification Script

set -e

echo "=========================================="
echo "🔍 فحص Redis الشامل"
echo "Redis Comprehensive Check"
echo "=========================================="
echo ""

# الألوان
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. فحص تشغيل Redis
echo "1️⃣  فحص تشغيل خدمة Redis..."
if systemctl is-active --quiet redis-server 2>/dev/null || systemctl is-active --quiet redis 2>/dev/null; then
    echo -e "${GREEN}✓ Redis يعمل${NC}"
else
    echo -e "${YELLOW}⚠ Redis قد لا يكون يعمل كخدمة نظام${NC}"
    if pgrep -x redis-server > /dev/null; then
        echo -e "${GREEN}✓ لكن عملية redis-server نشطة${NC}"
    else
        echo -e "${RED}✗ Redis غير نشط${NC}"
        exit 1
    fi
fi
echo ""

# 2. فحص الاتصال
echo "2️⃣  فحص الاتصال بـ Redis..."
if redis-cli ping > /dev/null 2>&1; then
    RESPONSE=$(redis-cli ping)
    echo -e "${GREEN}✓ الاتصال ناجح: $RESPONSE${NC}"
else
    echo -e "${RED}✗ فشل الاتصال بـ Redis${NC}"
    exit 1
fi
echo ""

# 3. فحص المعلومات الأساسية
echo "3️⃣  معلومات Redis الأساسية:"
echo "   الإصدار:"
redis-cli INFO server | grep redis_version
echo "   وضع التشغيل:"
redis-cli INFO server | grep redis_mode
echo "   المنفذ:"
redis-cli CONFIG GET port | tail -n 1
echo "   قاعدة البيانات الافتراضية: 0"
echo ""

# 4. فحص الذاكرة
echo "4️⃣  حالة الذاكرة:"
redis-cli INFO memory | grep -E "used_memory_human|used_memory_peak_human|mem_fragmentation_ratio"
echo ""

# 5. فحص عدد المفاتيح
echo "5️⃣  إحصائيات المفاتيح:"
TOTAL_KEYS=$(redis-cli DBSIZE | grep -oE '[0-9]+' || echo "0")
echo "   إجمالي المفاتيح: $TOTAL_KEYS"

if [ "$TOTAL_KEYS" -gt 0 ] 2>/dev/null; then
    echo ""
    echo "   توزيع المفاتيح حسب النوع:"
    
    # عد مفاتيح العقارات
    PROPERTY_KEYS=$(redis-cli KEYS "property:*" | wc -l)
    echo "   - property:* → $PROPERTY_KEYS"
    
    # عد مفاتيح الوحدات
    UNIT_KEYS=$(redis-cli KEYS "unit:*" | wc -l)
    echo "   - unit:* → $UNIT_KEYS"
    
    # عد مفاتيح المدن
    CITY_KEYS=$(redis-cli KEYS "city:*" | wc -l)
    echo "   - city:* → $CITY_KEYS"
    
    # عد مفاتيح الأنواع
    TYPE_KEYS=$(redis-cli KEYS "type:*" | wc -l)
    echo "   - type:* → $TYPE_KEYS"
    
    # عد مفاتيح المرافق
    AMENITY_KEYS=$(redis-cli KEYS "amenity:*" | wc -l)
    echo "   - amenity:* → $AMENITY_KEYS"
    
    # عد مفاتيح الإتاحة
    AVAIL_KEYS=$(redis-cli KEYS "availability:*" | wc -l)
    echo "   - availability:* → $AVAIL_KEYS"
    
    # عد مفاتيح التسعير
    PRICING_KEYS=$(redis-cli KEYS "pricing:*" | wc -l)
    echo "   - pricing:* → $PRICING_KEYS"
fi
echo ""

# 6. فحص المجموعات الرئيسية
echo "6️⃣  المجموعات الرئيسية:"
if redis-cli EXISTS "properties:all" | grep -q 1; then
    PROP_COUNT=$(redis-cli SCARD "properties:all")
    echo -e "   ${GREEN}✓ properties:all → $PROP_COUNT عقار${NC}"
else
    echo -e "   ${YELLOW}⚠ properties:all غير موجود${NC}"
fi

# فحص الفهارس المرتبة
for INDEX in "properties:by_price" "properties:by_rating" "properties:by_created" "properties:by_bookings"; do
    if redis-cli EXISTS "$INDEX" | grep -q 1; then
        COUNT=$(redis-cli ZCARD "$INDEX")
        echo -e "   ${GREEN}✓ $INDEX → $COUNT${NC}"
    else
        echo -e "   ${YELLOW}⚠ $INDEX غير موجود${NC}"
    fi
done

# فحص الفهرس الجغرافي
if redis-cli EXISTS "properties:geo" | grep -q 1; then
    GEO_COUNT=$(redis-cli ZCARD "properties:geo")
    echo -e "   ${GREEN}✓ properties:geo → $GEO_COUNT موقع${NC}"
else
    echo -e "   ${YELLOW}⚠ properties:geo غير موجود${NC}"
fi
echo ""

# 7. فحص RediSearch
echo "7️⃣  فحص RediSearch Module:"
if redis-cli MODULE LIST | grep -q search; then
    echo -e "   ${GREEN}✓ RediSearch مثبت${NC}"
    
    # فحص الفهرس
    if redis-cli FT.INFO "idx:properties" > /dev/null 2>&1; then
        echo -e "   ${GREEN}✓ فهرس idx:properties موجود${NC}"
        redis-cli FT.INFO "idx:properties" | grep -E "num_docs|num_terms"
    else
        echo -e "   ${YELLOW}⚠ فهرس idx:properties غير موجود${NC}"
    fi
else
    echo -e "   ${YELLOW}⚠ RediSearch غير مثبت (سيتم استخدام البحث اليدوي)${NC}"
fi
echo ""

# 8. فحص الأداء
echo "8️⃣  اختبار الأداء:"
echo "   اختبار سرعة الكتابة/القراءة..."

# كتابة
START=$(date +%s%N)
redis-cli SET "test:performance" "benchmark_value" > /dev/null
END=$(date +%s%N)
WRITE_TIME=$(( ($END - $START) / 1000000 ))
echo "   - زمن الكتابة: ${WRITE_TIME}ms"

# قراءة
START=$(date +%s%N)
redis-cli GET "test:performance" > /dev/null
END=$(date +%s%N)
READ_TIME=$(( ($END - $START) / 1000000 ))
echo "   - زمن القراءة: ${READ_TIME}ms"

# تنظيف
redis-cli DEL "test:performance" > /dev/null

if [ $WRITE_TIME -lt 10 ] && [ $READ_TIME -lt 10 ]; then
    echo -e "   ${GREEN}✓ الأداء ممتاز${NC}"
elif [ $WRITE_TIME -lt 50 ] && [ $READ_TIME -lt 50 ]; then
    echo -e "   ${GREEN}✓ الأداء جيد${NC}"
else
    echo -e "   ${YELLOW}⚠ الأداء بطيء نسبياً${NC}"
fi
echo ""

# 9. فحص الاتصالات
echo "9️⃣  حالة الاتصالات:"
redis-cli INFO clients | grep -E "connected_clients|blocked_clients"
echo ""

# 10. فحص الإحصائيات
echo "🔟 إحصائيات العمليات:"
redis-cli INFO stats | grep -E "total_commands_processed|instantaneous_ops_per_sec|keyspace_hits|keyspace_misses"

# حساب نسبة الإصابة
HITS=$(redis-cli INFO stats | grep keyspace_hits | cut -d: -f2 | tr -d '\r')
MISSES=$(redis-cli INFO stats | grep keyspace_misses | cut -d: -f2 | tr -d '\r')
if [ "$HITS" -gt 0 ] || [ "$MISSES" -gt 0 ]; then
    TOTAL=$((HITS + MISSES))
    HIT_RATE=$(awk "BEGIN {printf \"%.2f\", ($HITS / $TOTAL) * 100}")
    echo "   نسبة إصابة الكاش: ${HIT_RATE}%"
    if [ $(echo "$HIT_RATE > 80" | awk '{print ($1 > 80)}') -eq 1 ]; then
        echo -e "   ${GREEN}✓ نسبة إصابة ممتازة${NC}"
    elif [ $(echo "$HIT_RATE > 50" | awk '{print ($1 > 50)}') -eq 1 ]; then
        echo -e "   ${YELLOW}⚠ نسبة إصابة متوسطة${NC}"
    else
        echo -e "   ${YELLOW}⚠ نسبة إصابة منخفضة${NC}"
    fi
fi
echo ""

# 11. فحص الثبات (Persistence)
echo "1️⃣1️⃣  إعدادات الثبات:"
redis-cli CONFIG GET save
redis-cli CONFIG GET appendonly
LAST_SAVE=$(redis-cli LASTSAVE)
echo "   آخر حفظ: $LAST_SAVE"
echo ""

# 12. عينة من البيانات
echo "1️⃣2️⃣  عينة من البيانات المخزنة:"
if [ "$TOTAL_KEYS" -gt 0 ] 2>/dev/null; then
    echo "   أول 5 مفاتيح عقارات:"
    redis-cli KEYS "property:*" | head -n 5 | while read key; do
        if [ ! -z "$key" ]; then
            NAME=$(redis-cli HGET "$key" "name" 2>/dev/null || echo "N/A")
            CITY=$(redis-cli HGET "$key" "city" 2>/dev/null || echo "N/A")
            echo "   - $key → $NAME ($CITY)"
        fi
    done
    
    echo ""
    echo "   المدن المتاحة:"
    redis-cli KEYS "city:*" | head -n 10 | sed 's/city:/   - /'
else
    echo -e "   ${YELLOW}⚠ لا توجد بيانات في Redis بعد${NC}"
    echo "   💡 قم بتشغيل التطبيق لإعادة بناء الفهارس"
fi
echo ""

# النتيجة النهائية
echo "=========================================="
if [ "$TOTAL_KEYS" -gt 0 ]; then
    echo -e "${GREEN}✅ Redis يعمل بشكل صحيح وجاهز للاستخدام${NC}"
else
    echo -e "${YELLOW}⚠️  Redis يعمل لكن لا توجد بيانات بعد${NC}"
    echo "   قم بتشغيل YemenBooking.Api لإعادة بناء الفهارس"
fi
echo "=========================================="

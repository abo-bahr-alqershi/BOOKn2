#!/bin/bash

# سكريبت التحقق السريع من حالة Redis
# Redis Quick Status Check Script

echo "=================================================="
echo "🔍 التحقق من حالة Redis / Redis Status Check"
echo "=================================================="
echo ""

# التحقق من الاتصال
echo "1️⃣ اختبار الاتصال / Connection Test:"
if redis-cli ping > /dev/null 2>&1; then
    echo "   ✅ Redis متصل ويعمل"
    echo "   ✅ Redis is connected and working"
else
    echo "   ❌ Redis غير متصل"
    echo "   ❌ Redis is not connected"
    exit 1
fi
echo ""

# معلومات الإصدار
echo "2️⃣ معلومات الإصدار / Version Info:"
REDIS_VERSION=$(redis-cli INFO server | grep "redis_version" | cut -d':' -f2 | tr -d '\r')
echo "   📦 الإصدار / Version: $REDIS_VERSION"
echo ""

# الإعدادات الأساسية
echo "3️⃣ الإعدادات / Configuration:"
PORT=$(redis-cli CONFIG GET port | tail -1)
BIND=$(redis-cli CONFIG GET bind | tail -1)
echo "   🔌 المنفذ / Port: $PORT"
echo "   🌐 الربط / Bind: $BIND"
echo ""

# الذاكرة
echo "4️⃣ استهلاك الذاكرة / Memory Usage:"
USED_MEMORY=$(redis-cli INFO memory | grep "used_memory_human:" | cut -d':' -f2 | tr -d '\r')
PEAK_MEMORY=$(redis-cli INFO memory | grep "used_memory_peak_human:" | cut -d':' -f2 | tr -d '\r')
echo "   💾 الاستهلاك الحالي / Current: $USED_MEMORY"
echo "   📈 ذروة الاستهلاك / Peak: $PEAK_MEMORY"
echo ""

# المفاتيح
echo "5️⃣ إحصائيات المفاتيح / Keys Statistics:"
KEYS_COUNT=$(redis-cli DBSIZE)
echo "   🔑 إجمالي المفاتيح / Total Keys: $KEYS_COUNT"
echo ""

# الفهارس المحملة
echo "6️⃣ الفهارس المحملة / Loaded Indexes:"
INDEX_COUNT=$(redis-cli KEYS "index:*" | wc -l)
echo "   📚 عدد الفهارس / Indexes Count: $INDEX_COUNT"
if [ $INDEX_COUNT -gt 0 ]; then
    echo "   📋 قائمة الفهارس / Indexes List:"
    redis-cli KEYS "index:*" | while read key; do
        echo "      ✅ $key"
    done
else
    echo "   ⚠️  لا توجد فهارس محملة"
    echo "   ⚠️  No indexes loaded"
    echo "   💡 قم بتشغيل: ./load_indexes_to_redis.sh"
fi
echo ""

# معلومات الأداء
echo "7️⃣ معلومات الأداء / Performance Info:"
TOTAL_COMMANDS=$(redis-cli INFO stats | grep "total_commands_processed:" | cut -d':' -f2 | tr -d '\r')
CONNECTED_CLIENTS=$(redis-cli INFO clients | grep "connected_clients:" | cut -d':' -f2 | tr -d '\r')
echo "   ⚡ الأوامر المنفذة / Commands Processed: $TOTAL_COMMANDS"
echo "   👥 العملاء المتصلين / Connected Clients: $CONNECTED_CLIENTS"
echo ""

# الوقت
echo "8️⃣ وقت التشغيل / Uptime:"
UPTIME_DAYS=$(redis-cli INFO server | grep "uptime_in_days:" | cut -d':' -f2 | tr -d '\r')
echo "   ⏰ أيام التشغيل / Uptime Days: $UPTIME_DAYS"
echo ""

echo "=================================================="
echo "✅ تم الانتهاء من الفحص / Check Completed"
echo "=================================================="

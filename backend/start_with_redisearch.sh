#!/bin/bash

echo "=========================================="
echo "🚀 تشغيل التطبيق مع RediSearch"
echo "=========================================="

# 1. التحقق من Redis Stack
echo ""
echo "1️⃣  التحقق من Redis Stack..."
if docker ps | grep -q redis-stack; then
    echo "✅ Redis Stack يعمل"
else
    echo "⚠️  Redis Stack لا يعمل - جاري التشغيل..."
    docker start redis-stack 2>/dev/null || docker run -d --name redis-stack -p 6379:6379 -p 8001:8001 redis/redis-stack:latest
    sleep 3
fi

# 2. التحقق من RediSearch
echo ""
echo "2️⃣  التحقق من RediSearch..."
if redis-cli COMMAND INFO FT.SEARCH >/dev/null 2>&1; then
    echo "✅ RediSearch متاح"
else
    echo "❌ RediSearch غير متاح!"
    exit 1
fi

# 3. إيقاف العمليات القديمة
echo ""
echo "3️⃣  إيقاف العمليات القديمة..."
sudo lsof -ti:5000 | xargs sudo kill -9 2>/dev/null
sudo pkill -9 -f "dotnet.*YemenBooking" 2>/dev/null
sleep 2
echo "✅ تم إيقاف العمليات القديمة"

# 4. تشغيل التطبيق
echo ""
echo "4️⃣  تشغيل التطبيق..."
cd YemenBooking.Api
nohup dotnet run > /tmp/yemenbooking-redisearch.log 2>&1 &
APP_PID=$!
echo "✅ التطبيق يعمل (PID: $APP_PID)"

# 5. انتظار بدء التطبيق
echo ""
echo "5️⃣  انتظار بدء التطبيق..."
for i in {1..60}; do
    if grep -q "Application started" /tmp/yemenbooking-redisearch.log 2>/dev/null; then
        echo "✅ التطبيق بدأ بنجاح!"
        break
    fi
    echo -n "."
    sleep 1
done
echo ""

# 6. التحقق من الفهرس
echo ""
echo "6️⃣  التحقق من فهرس RediSearch..."
sleep 2
if redis-cli FT.INFO idx:properties >/dev/null 2>&1; then
    echo "✅ فهرس idx:properties تم إنشاؤه بنجاح"
    redis-cli FT.INFO idx:properties | grep -E "index_name|num_docs"
else
    echo "⚠️  الفهرس لم يُنشأ بعد - تحقق من السجلات"
fi

# 7. عرض الملخص
echo ""
echo "=========================================="
echo "✅ الملخص"
echo "=========================================="
echo "🔹 Redis Stack: http://localhost:8001 (Redis Insight)"
echo "🔹 API: http://localhost:5000"
echo "🔹 السجلات: tail -f /tmp/yemenbooking-redisearch.log"
echo "🔹 اختبار البحث:"
echo "   curl 'http://localhost:5000/api/client/properties/search?PageNumber=1&PageSize=5'"
echo ""
echo "=========================================="

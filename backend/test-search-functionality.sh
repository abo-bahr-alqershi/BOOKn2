#!/bin/bash

echo "🔍 اختبار وظائف البحث"
echo "===================================="

# بدء التطبيق
echo -e "\n📦 بدء التطبيق..."
cd /home/ameen/Desktop/BOOKIN/BOOKIN/backend
dotnet run --project YemenBooking.Api > /tmp/app-test.log 2>&1 &
APP_PID=$!

# انتظار حتى يبدأ التطبيق
echo "⏳ انتظار بدء التطبيق (20 ثانية)..."
sleep 20

# اختبار endpoint الصحة
echo -e "\n🏥 فحص صحة النظام:"
curl -s http://localhost:5224/api/admin/redis/health 2>/dev/null | head -1 || echo "API غير متاح بعد"

# اختبار معلومات النظام
echo -e "\n📊 معلومات النظام:"
curl -s http://localhost:5224/api/admin/redis/info 2>/dev/null | jq -r '.system, .version, .features.search' 2>/dev/null || echo "API غير متاح"

# اختبار البحث الأساسي
echo -e "\n🔎 اختبار البحث:"
curl -s -X POST http://localhost:5224/api/admin/redis/search/test \
  -H "Content-Type: application/json" \
  -d '{"PageNumber": 1, "PageSize": 5}' 2>/dev/null | jq -r '.result.totalCount' 2>/dev/null || echo "البحث غير متاح"

# فحص الأخطاء الحرجة
echo -e "\n❌ فحص الأخطاء الحرجة:"
CRITICAL_ERRORS=$(grep -c "System.InvalidOperationException\|System.NotImplementedException" /tmp/app-test.log)
echo "عدد الأخطاء الحرجة: $CRITICAL_ERRORS"

if [ $CRITICAL_ERRORS -eq 0 ]; then
    echo "✅ لا توجد أخطاء حرجة!"
else
    echo "⚠️ توجد أخطاء حرجة:"
    grep "System.InvalidOperationException\|System.NotImplementedException" /tmp/app-test.log | head -3
fi

# إيقاف التطبيق
kill $APP_PID 2>/dev/null

echo -e "\n===================================="
echo "✨ اكتمل الاختبار!"

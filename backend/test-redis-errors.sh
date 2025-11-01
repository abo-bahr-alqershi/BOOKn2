#!/bin/bash

echo "🔍 اختبار نظام Redis وفحص الأخطاء"
echo "===================================="

# تشغيل المشروع في الخلفية
echo -e "\n📦 بدء تشغيل المشروع..."
cd /home/ameen/Desktop/BOOKIN/BOOKIN/backend
dotnet run --project YemenBooking.Api > /tmp/app.log 2>&1 &
APP_PID=$!

# انتظار قليل حتى يبدأ التطبيق
echo "⏳ انتظار بدء التطبيق..."
sleep 15

# فحص السجل للأخطاء
echo -e "\n📋 فحص السجل للأخطاء..."
echo "--------------------------------"

# عد الأخطاء
ERROR_COUNT=$(grep -c "fail:\|error:\|exception:" /tmp/app.log)
echo "عدد الأخطاء الكلي: $ERROR_COUNT"

if [ $ERROR_COUNT -gt 0 ]; then
    echo -e "\n❌ تم العثور على أخطاء:"
    grep -E "fail:|error:|exception:" /tmp/app.log | head -10
else
    echo -e "\n✅ لا توجد أخطاء!"
fi

# فحص نجاح الفهرسة
echo -e "\n📊 فحص عمليات الفهرسة:"
echo "--------------------------------"
SUCCESS_COUNT=$(grep -c "✅ تمت فهرسة العقار بنجاح\|✅ اكتملت إعادة بناء الفهرس" /tmp/app.log)
echo "عمليات الفهرسة الناجحة: $SUCCESS_COUNT"

# فحص Redis
echo -e "\n🔄 فحص Redis:"
echo "--------------------------------"
REDIS_KEYS=$(redis-cli DBSIZE | cut -d' ' -f2)
echo "عدد المفاتيح في Redis: $REDIS_KEYS"

# فحص مفاتيح العقارات
PROPERTY_KEYS=$(redis-cli --scan --pattern "property:*" | wc -l)
echo "عدد مفاتيح العقارات: $PROPERTY_KEYS"

# إيقاف التطبيق
echo -e "\n🛑 إيقاف التطبيق..."
kill $APP_PID 2>/dev/null

echo -e "\n===================================="
if [ $ERROR_COUNT -eq 0 ] && [ $SUCCESS_COUNT -gt 0 ]; then
    echo "✨ النظام يعمل بنجاح!"
else
    echo "⚠️ يحتاج النظام إلى مراجعة"
fi

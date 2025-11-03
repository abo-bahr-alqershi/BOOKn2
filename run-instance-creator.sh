#!/bin/bash

# سكريبت للتشغيل الدائم - محاولة إنشاء A1.Flex
# يعمل باستمرار حتى ينجح

cd /home/ameen/Desktop/BOOKIN/BOOKIN/oci-arm-host-capacity

echo "=================================="
echo " مراقب إنشاء خادم Oracle A1.Flex"
echo " بدأ في: $(date)"
echo "=================================="
echo ""

while true; do
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] محاولة إنشاء الخادم..."
    
    # تشغيل السكريبت
    OUTPUT=$(php index.php 2>&1)
    
    # التحقق من النجاح
    if echo "$OUTPUT" | grep -q '"id".*"ocid1.instance'; then
        echo ""
        echo "🎉🎉🎉 نجح! تم إنشاء الخادم!"
        echo "=================================="
        echo "$OUTPUT"
        echo "=================================="
        
        # إرسال إشعار (اختياري)
        notify-send "Oracle Cloud" "تم إنشاء خادم A1.Flex بنجاح!" 2>/dev/null || true
        
        # التوقف بعد النجاح
        exit 0
    elif echo "$OUTPUT" | grep -q "Out of host capacity"; then
        echo "   ⚠️  نفاد السعة - سأحاول مرة أخرى بعد دقيقة"
    elif echo "$OUTPUT" | grep -q "TooManyRequests"; then
        echo "   ⚠️  الكثير من الطلبات - انتظار 10 دقائق"
        sleep 600
        continue
    else
        echo "   ❓ استجابة غير متوقعة:"
        echo "$OUTPUT" | head -5
    fi
    
    # انتظار دقيقة واحدة قبل المحاولة التالية
    sleep 60
done

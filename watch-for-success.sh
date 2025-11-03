#!/bin/bash

# سكريبت مراقبة مستمر - يرسل إشعار عند النجاح

LOG_FILE="$HOME/Desktop/BOOKIN/BOOKIN/instance-creator.log"
CHECK_INTERVAL=60  # فحص كل 60 ثانية

echo "=================================="
echo " مراقب النجاح"
echo " بدأ في: $(date)"
echo "=================================="
echo ""
echo "⏳ أراقب السجل... سأخبرك عند النجاح!"
echo ""

while true; do
    if grep -q "نجح" "$LOG_FILE" 2>/dev/null; then
        echo ""
        echo "=================================="
        echo "🎉🎉🎉 مبروك! نجح الإنشاء!"
        echo "=================================="
        echo ""
        
        # إرسال إشعار على سطح المكتب
        notify-send -u critical "Oracle Cloud" "🎉 تم إنشاء خادم A1.Flex بنجاح!" 2>/dev/null || true
        
        # تشغيل صوت (إذا كان متاحاً)
        paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null || true
        
        # عرض التفاصيل
        echo "تفاصيل الخادم:"
        tail -30 "$LOG_FILE" | grep -A 25 "نجح"
        
        echo ""
        echo "=================================="
        echo "الخطوات التالية:"
        echo "=================================="
        echo "1. افتح Oracle Cloud Console"
        echo "2. Menu → Compute → Instances"
        echo "3. انسخ Public IP من الخادم الجديد"
        echo "4. اتصل: ssh -i ~/.oci/oci_api_key.pem ubuntu@<PUBLIC_IP>"
        echo ""
        
        # إرسال بريد إلكتروني (اختياري - يحتاج تكوين)
        # echo "نجح إنشاء خادم Oracle Cloud!" | mail -s "Oracle Cloud Success" your@email.com
        
        exit 0
    fi
    
    # عرض تحديث كل 10 دقائق
    CURRENT_TIME=$(date +%s)
    if [ $((CURRENT_TIME % 600)) -eq 0 ]; then
        ATTEMPTS=$(grep -c "محاولة إنشاء" "$LOG_FILE" 2>/dev/null || echo "0")
        echo "[$(date '+%H:%M:%S')] لا يزال يحاول... (المحاولات: $ATTEMPTS)"
    fi
    
    sleep $CHECK_INTERVAL
done

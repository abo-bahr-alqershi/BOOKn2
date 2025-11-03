#!/bin/bash

# ملف الأوامر السريعة لإدارة سكريبت Oracle Instance Creator

echo "=================================="
echo " أوامر سريعة لإدارة السكريبت"
echo "=================================="
echo ""
echo "اختر عملية:"
echo "1) تشغيل السكريبت"
echo "2) إيقاف السكريبت"
echo "3) إعادة تشغيل السكريبت"
echo "4) التحقق من الحالة"
echo "5) مشاهدة السجل (آخر 30 سطر)"
echo "6) مشاهدة السجل المباشر"
echo "7) عد عدد المحاولات"
echo "8) البحث عن رسالة النجاح"
echo "9) مسح السجل"
echo "0) خروج"
echo ""
read -p "اختيارك: " choice

case $choice in
    1)
        echo "🚀 تشغيل السكريبت..."
        cd ~/Desktop/BOOKIN/BOOKIN
        nohup ./run-instance-creator.sh > instance-creator.log 2>&1 &
        echo "✅ تم! PID: $!"
        ;;
    2)
        echo "⛔ إيقاف السكريبت..."
        pkill -f run-instance-creator.sh
        echo "✅ تم الإيقاف"
        ;;
    3)
        echo "🔄 إعادة تشغيل السكريبت..."
        pkill -f run-instance-creator.sh
        sleep 2
        cd ~/Desktop/BOOKIN/BOOKIN
        nohup ./run-instance-creator.sh > instance-creator.log 2>&1 &
        echo "✅ تم! PID: $!"
        ;;
    4)
        echo "🔍 حالة السكريبت:"
        if ps aux | grep -v grep | grep -q run-instance-creator; then
            echo "✅ السكريبت يعمل"
            ps aux | grep -v grep | grep run-instance-creator | head -2
        else
            echo "❌ السكريبت متوقف"
        fi
        ;;
    5)
        echo "📊 آخر 30 سطر من السجل:"
        tail -30 ~/Desktop/BOOKIN/BOOKIN/instance-creator.log
        ;;
    6)
        echo "👀 مشاهدة السجل المباشر (Ctrl+C للخروج):"
        tail -f ~/Desktop/BOOKIN/BOOKIN/instance-creator.log
        ;;
    7)
        ATTEMPTS=$(grep -c "محاولة إنشاء" ~/Desktop/BOOKIN/BOOKIN/instance-creator.log)
        echo "📈 عدد المحاولات حتى الآن: $ATTEMPTS"
        ;;
    8)
        echo "🔍 البحث عن رسالة النجاح..."
        if grep -q "نجح" ~/Desktop/BOOKIN/BOOKIN/instance-creator.log; then
            echo "🎉 وُجدت رسالة نجاح!"
            grep -A 10 "نجح" ~/Desktop/BOOKIN/BOOKIN/instance-creator.log
        else
            echo "⏳ لم ينجح بعد - السكريبت لا يزال يحاول"
        fi
        ;;
    9)
        read -p "⚠️  هل أنت متأكد من مسح السجل؟ (y/n): " confirm
        if [ "$confirm" = "y" ]; then
            > ~/Desktop/BOOKIN/BOOKIN/instance-creator.log
            echo "✅ تم مسح السجل"
        else
            echo "❌ تم الإلغاء"
        fi
        ;;
    0)
        echo "👋 وداعاً!"
        exit 0
        ;;
    *)
        echo "❌ اختيار غير صحيح"
        ;;
esac

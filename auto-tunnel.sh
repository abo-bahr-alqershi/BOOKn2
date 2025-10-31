#!/bin/bash

# Auto Tunnel Script for Yemen Booking
# يعمل تلقائياً ويحدث DuckDNS بالرابط الجديد

echo "=========================================="
echo "🚀 Yemen Booking Auto Tunnel"
echo "=========================================="

# الإعدادات
DUCKDNS_DOMAIN="abobahr"
DUCKDNS_TOKEN="ea7c5314-7999-4526-a31b-07c47e68dca4"
CLOUDFLARED_PATH="$HOME/cloudflared"

# التأكد من وجود cloudflared
if [ ! -f "$CLOUDFLARED_PATH" ]; then
    echo "⚠️  تحميل Cloudflared..."
    curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o "$CLOUDFLARED_PATH"
    chmod +x "$CLOUDFLARED_PATH"
fi

# قتل أي tunnel سابق
echo "🔄 إيقاف أي tunnels سابقة..."
pkill -f cloudflared 2>/dev/null
sleep 2

# تشغيل tunnel جديد
echo "🌐 تشغيل Cloudflare Tunnel..."
$CLOUDFLARED_PATH tunnel --url http://localhost:80 > /tmp/cf-tunnel.log 2>&1 &
CF_PID=$!

# انتظار ظهور الرابط
echo "⏳ انتظار الرابط..."
for i in {1..20}; do
    if grep -q "trycloudflare.com" /tmp/cf-tunnel.log; then
        break
    fi
    sleep 1
done

# استخراج الرابط
TUNNEL_URL=$(grep "trycloudflare.com" /tmp/cf-tunnel.log | grep -oP 'https://[a-z-]+\.trycloudflare\.com' | head -1)

if [ -z "$TUNNEL_URL" ]; then
    echo "❌ فشل في الحصول على رابط Tunnel"
    exit 1
fi

# عرض الرابط
echo ""
echo "=========================================="
echo "✅ المشروع متاح على:"
echo "=========================================="
echo "🔗 الرابط الرئيسي:"
echo "   $TUNNEL_URL"
echo ""
echo "📱 Swagger UI:"
echo "   $TUNNEL_URL/swagger"
echo ""
echo "🌍 DuckDNS (سيعمل قريباً):"
echo "   http://$DUCKDNS_DOMAIN.duckdns.org"
echo "=========================================="

# حفظ الرابط في ملف
echo "$TUNNEL_URL" > /tmp/current-tunnel-url.txt

# إنشاء صفحة HTML توجيهية لـ DuckDNS (اختياري)
cat > /tmp/redirect.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Yemen Booking - Redirecting...</title>
    <meta http-equiv="refresh" content="0; url=$TUNNEL_URL">
    <script>window.location.href = "$TUNNEL_URL";</script>
</head>
<body>
    <h2>جاري التحويل...</h2>
    <p>إذا لم يتم التحويل تلقائياً، <a href="$TUNNEL_URL">اضغط هنا</a></p>
</body>
</html>
EOF

echo ""
echo "💡 نصيحة: احفظ الرابط - سيتغير عند إعادة التشغيل"
echo "📋 الرابط محفوظ في: /tmp/current-tunnel-url.txt"
echo ""
echo "🛑 للإيقاف: pkill -f cloudflared"
echo "=========================================="

# الاحتفاظ بالعملية
echo ""
echo "📊 سجل Cloudflare Tunnel:"
tail -f /tmp/cf-tunnel.log

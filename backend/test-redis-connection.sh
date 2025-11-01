#!/bin/bash

echo "🔍 اختبار اتصال Redis والنظام الجديد"
echo "===================================="

# اختبار اتصال Redis
echo -e "\n1. فحص اتصال Redis:"
redis-cli ping
if [ $? -eq 0 ]; then
    echo "✅ Redis متصل ويعمل"
else
    echo "❌ Redis غير متصل"
    exit 1
fi

# فحص المعلومات
echo -e "\n2. معلومات Redis:"
redis-cli INFO server | head -5

# عد المفاتيح الموجودة
echo -e "\n3. عدد المفاتيح في Redis:"
KEYS_COUNT=$(redis-cli DBSIZE | cut -d' ' -f2)
echo "   المفاتيح الموجودة: $KEYS_COUNT"

# البحث عن مفاتيح النظام الجديد
echo -e "\n4. البحث عن مفاتيح النظام الجديد:"
echo "   - مفاتيح العقارات:"
redis-cli --scan --pattern "property:*" | head -5

echo "   - مفاتيح الفهارس:"
redis-cli --scan --pattern "idx:*" | head -5

echo "   - مفاتيح الكاش:"
redis-cli --scan --pattern "cache:*" | head -5

echo -e "\n===================================="
echo "✨ اكتمل اختبار Redis بنجاح!"

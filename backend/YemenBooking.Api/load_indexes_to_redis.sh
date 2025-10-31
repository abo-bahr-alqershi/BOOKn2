#!/bin/bash

# سكريبت لتحميل الفهارس إلى Redis
# Load indexes to Redis script

echo "🔄 بدء تحميل الفهارس إلى Redis..."
echo "Starting to load indexes to Redis..."

# التحقق من أن Redis يعمل
if ! redis-cli ping > /dev/null 2>&1; then
    echo "❌ خطأ: Redis غير متصل"
    echo "Error: Redis is not running"
    exit 1
fi

echo "✅ Redis متصل"
echo "Redis is connected"

# الملفات المطلوب تحميلها
INDEX_FILES=(
    "property_index.json"
    "unit_index.json"
    "city_index.json"
    "amenity_index.json"
    "availability_index.json"
    "pricing_index.json"
)

# عد الملفات الموجودة
LOADED_COUNT=0
FAILED_COUNT=0

# تحميل كل ملف
for file in "${INDEX_FILES[@]}"; do
    if [ -f "$file" ]; then
        INDEX_NAME="${file%.json}"
        echo "📂 تحميل $file..."
        
        # قراءة محتوى الملف وتخزينه في Redis
        CONTENT=$(cat "$file")
        
        # تخزين في Redis بمفتاح index:filename
        redis-cli SET "index:$INDEX_NAME" "$CONTENT" > /dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            echo "✅ تم تحميل $file إلى Redis بنجاح"
            ((LOADED_COUNT++))
        else
            echo "❌ فشل تحميل $file"
            ((FAILED_COUNT++))
        fi
    else
        echo "⚠️  الملف $file غير موجود"
        ((FAILED_COUNT++))
    fi
done

echo ""
echo "📊 النتائج:"
echo "Results:"
echo "   - تم التحميل: $LOADED_COUNT"
echo "   - Loaded: $LOADED_COUNT"
echo "   - فشل: $FAILED_COUNT"
echo "   - Failed: $FAILED_COUNT"

# عرض المفاتيح المحملة في Redis
echo ""
echo "🔍 المفاتيح المحملة في Redis:"
echo "Loaded keys in Redis:"
redis-cli KEYS "index:*"

echo ""
echo "✅ تم الانتهاء من تحميل الفهارس"
echo "Indexes loading completed"

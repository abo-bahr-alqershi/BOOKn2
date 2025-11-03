#!/bin/bash

# سكريبت للاتصال بخادم Oracle Cloud عبر VNC
# يتم تشغيله على جهازك المحلي

set -e

echo "================================================"
echo "   الاتصال بخادم Oracle Cloud عبر VNC"
echo "================================================"
echo ""

# التحقق من وجود المفتاح الخاص
KEY_FILE="$HOME/.oci/oci_api_key.pem"
if [ ! -f "$KEY_FILE" ]; then
    echo "❌ خطأ: لم يتم العثور على المفتاح الخاص"
    echo "   المسار المتوقع: $KEY_FILE"
    exit 1
fi

# طلب عنوان IP
echo "📝 أدخل عنوان IP العام للخادم:"
read -p "IP Address: " SERVER_IP

if [ -z "$SERVER_IP" ]; then
    echo "❌ خطأ: يجب إدخال عنوان IP"
    exit 1
fi

# طلب اسم المستخدم
echo ""
echo "📝 أدخل اسم المستخدم (اضغط Enter للاستخدام الافتراضي: opc):"
read -p "Username [opc]: " USERNAME
USERNAME=${USERNAME:-opc}

# التحقق من تثبيت VNC Viewer
echo ""
echo "🔍 التحقق من تثبيت VNC Viewer..."
if ! command -v vncviewer &> /dev/null; then
    echo "⚠️  VNC Viewer غير مثبت"
    echo "   تثبيت الآن؟ (y/n)"
    read -p "> " INSTALL_VNC
    
    if [[ "$INSTALL_VNC" == "y" ]] || [[ "$INSTALL_VNC" == "Y" ]]; then
        echo "📦 تثبيت TigerVNC Viewer..."
        if command -v apt &> /dev/null; then
            sudo apt update
            sudo apt install -y tigervnc-viewer
        elif command -v yum &> /dev/null; then
            sudo yum install -y tigervnc
        else
            echo "❌ لا يمكن تثبيت VNC Viewer تلقائياً"
            echo "   الرجاء تثبيته يدوياً"
            exit 1
        fi
    else
        echo "❌ لا يمكن المتابعة بدون VNC Viewer"
        exit 1
    fi
fi

# اختيار طريقة الاتصال
echo ""
echo "🔒 اختر طريقة الاتصال:"
echo "   1) SSH Tunnel (آمن - موصى به)"
echo "   2) مباشر (غير آمن - استخدم فقط للاختبار)"
read -p "اختيارك [1]: " METHOD
METHOD=${METHOD:-1}

if [ "$METHOD" == "1" ]; then
    echo ""
    echo "🔐 إنشاء نفق SSH..."
    echo "   الأمر: ssh -i $KEY_FILE -L 5901:localhost:5901 $USERNAME@$SERVER_IP"
    echo ""
    echo "📌 سيتم فتح اتصال SSH. اتركه مفتوحاً."
    echo "   في نافذة أخرى، سيتم فتح VNC Viewer تلقائياً."
    echo ""
    echo "اضغط Enter للمتابعة..."
    read
    
    # إنشاء سكريبت مؤقت لفتح VNC Viewer
    TEMP_SCRIPT=$(mktemp)
    cat > "$TEMP_SCRIPT" << 'EOF'
#!/bin/bash
sleep 5
vncviewer localhost:5901
EOF
    chmod +x "$TEMP_SCRIPT"
    
    # تشغيل VNC Viewer في الخلفية
    gnome-terminal -- bash -c "$TEMP_SCRIPT" 2>/dev/null || \
    xterm -e "$TEMP_SCRIPT" 2>/dev/null || \
    konsole -e "$TEMP_SCRIPT" 2>/dev/null || \
    (sleep 5 && vncviewer localhost:5901) &
    
    # فتح SSH Tunnel
    ssh -i "$KEY_FILE" -L 5901:localhost:5901 "$USERNAME@$SERVER_IP"
    
    # حذف السكريبت المؤقت
    rm -f "$TEMP_SCRIPT"
    
elif [ "$METHOD" == "2" ]; then
    echo ""
    echo "⚠️  تحذير: الاتصال المباشر غير آمن!"
    echo "   حركة المرور ستكون غير مشفرة."
    echo ""
    echo "🔗 الاتصال بـ $SERVER_IP:5901..."
    vncviewer "$SERVER_IP:5901"
else
    echo "❌ خيار غير صحيح"
    exit 1
fi

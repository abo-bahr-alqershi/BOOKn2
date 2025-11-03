#!/bin/bash

# سكريبت تثبيت واجهة سطح المكتب وVNC على Oracle Cloud
# يتم تشغيله على الخادم بعد الاتصال عبر SSH

set -e

echo "================================================"
echo "   إعداد واجهة سطح المكتب وVNC"
echo "================================================"
echo ""

# التحقق من نظام التشغيل
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "❌ لا يمكن التعرف على نظام التشغيل"
    exit 1
fi

echo "📋 نظام التشغيل المكتشف: $OS"
echo ""

# تحديث النظام
echo "🔄 تحديث النظام..."
if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
    sudo apt update && sudo apt upgrade -y
elif [[ "$OS" == "ol" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "centos" ]]; then
    sudo yum update -y
fi

# تثبيت البيئة الرسومية
echo ""
echo "🖥️  تثبيت البيئة الرسومية XFCE..."
if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
    sudo apt install -y xfce4 xfce4-goodies
elif [[ "$OS" == "ol" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "centos" ]]; then
    sudo yum install -y epel-release
    sudo yum groupinstall -y xfce
fi

# تثبيت VNC Server
echo ""
echo "🔌 تثبيت TigerVNC Server..."
if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
    sudo apt install -y tigervnc-standalone-server tigervnc-common
elif [[ "$OS" == "ol" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "centos" ]]; then
    sudo yum install -y tigervnc-server
fi

# إعداد VNC
echo ""
echo "⚙️  إعداد VNC..."
mkdir -p ~/.vnc

# إنشاء ملف xstartup
cat > ~/.vnc/xstartup << 'EOF'
#!/bin/bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XKL_XMODMAP_DISABLE=1
export XDG_CURRENT_DESKTOP="XFCE"
export XDG_SESSION_DESKTOP="xfce"

xrdb $HOME/.Xresources
startxfce4 &
EOF

chmod +x ~/.vnc/xstartup

# طلب كلمة مرور VNC
echo ""
echo "🔐 الآن، قم بتعيين كلمة مرور VNC:"
echo "   (يجب أن تكون 6-8 أحرف على الأقل)"
vncpasswd

# فتح المنفذ في جدار الحماية
echo ""
echo "🔥 فتح المنفذ 5901 في جدار الحماية..."
if command -v ufw &> /dev/null; then
    sudo ufw allow 5901/tcp
    sudo ufw --force enable
    echo "✅ تم فتح المنفذ في UFW"
elif command -v firewall-cmd &> /dev/null; then
    sudo firewall-cmd --permanent --add-port=5901/tcp
    sudo firewall-cmd --reload
    echo "✅ تم فتح المنفذ في firewalld"
fi

# تعطيل SELinux إذا كان موجوداً (للأنظمة القائمة على RHEL)
if command -v setenforce &> /dev/null; then
    sudo setenforce 0
    sudo sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config 2>/dev/null || true
fi

# بدء VNC Server
echo ""
echo "🚀 بدء VNC Server..."
vncserver :1 -geometry 1920x1080 -depth 24

# الحصول على IP العام
PUBLIC_IP=$(curl -s ifconfig.me)

echo ""
echo "================================================"
echo "   ✅ تم الإعداد بنجاح!"
echo "================================================"
echo ""
echo "📝 معلومات الاتصال:"
echo "   - عنوان IP العام: $PUBLIC_IP"
echo "   - منفذ VNC: 5901"
echo "   - شاشة VNC: :1"
echo ""
echo "🔗 للاتصال من جهازك:"
echo ""
echo "   الطريقة الآمنة (SSH Tunnel):"
echo "   1. ssh -i ~/.oci/oci_api_key.pem -L 5901:localhost:5901 $(whoami)@$PUBLIC_IP"
echo "   2. vncviewer localhost:5901"
echo ""
echo "   الطريقة المباشرة:"
echo "   vncviewer $PUBLIC_IP:5901"
echo ""
echo "⚠️  تذكير: لا تنسى فتح المنفذ 5901 في Oracle Cloud Security Lists!"
echo ""
echo "📚 أوامر مفيدة:"
echo "   - إيقاف VNC: vncserver -kill :1"
echo "   - بدء VNC: vncserver :1 -geometry 1920x1080 -depth 24"
echo "   - عرض الشاشات النشطة: vncserver -list"
echo ""
echo "================================================"

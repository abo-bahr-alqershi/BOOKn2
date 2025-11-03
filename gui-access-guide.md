# دليل الوصول إلى واجهة نظام التشغيل (GUI) على Oracle Cloud

## الوضع الحالي
لا توجد خوادم (instances) نشطة في حسابك حالياً.

## الخطوات المطلوبة

### 1️⃣ إنشاء خادم (Compute Instance)

يمكنك إنشاء خادم بطريقتين:

#### أ) من خلال واجهة الويب (الأسهل)
1. افتح [Oracle Cloud Console](https://cloud.oracle.com/)
2. سجل الدخول بحسابك
3. اذهب إلى: **Menu → Compute → Instances**
4. اضغط **Create Instance**
5. اختر:
   - **Name:** أي اسم تريده
   - **Image:** Ubuntu 22.04 أو Oracle Linux
   - **Shape:** اختر Always Free Eligible (مجاني)
   - **Network:** استخدم الشبكة الافتراضية
   - **SSH Keys:** ارفع المفتاح العام: `hafidhafeed4@gmail.com-2025-11-02T21 55 28.901Z_public.pem`

#### ب) من خلال سطر الأوامر (متقدم)
```bash
# قائمة الصور المتاحة
oci compute image list --compartment-id ocid1.tenancy.oc1..aaaaaaaay7in5ik5o23vpicjf4ec6ihgmear32t6lttkrjxvrrx7buylw3qq --output table

# قائمة الأشكال (Shapes) المتاحة
oci compute shape list --compartment-id ocid1.tenancy.oc1..aaaaaaaay7in5ik5o23vpicjf4ec6ihgmear32t6lttkrjxvrrx7buylw3qq --output table
```

---

### 2️⃣ الحصول على عنوان IP العام للخادم

بعد إنشاء الخادم:
```bash
# عرض معلومات الخادم
oci compute instance list --compartment-id ocid1.tenancy.oc1..aaaaaaaay7in5ik5o23vpicjf4ec6ihgmear32t6lttkrjxvrrx7buylw3qq --output table

# الحصول على IP العام
oci network public-ip list --scope REGION --compartment-id ocid1.tenancy.oc1..aaaaaaaay7in5ik5o23vpicjf4ec6ihgmear32t6lttkrjxvrrx7buylw3qq --output table
```

---

### 3️⃣ الاتصال بالخادم عبر SSH

```bash
# استبدل <PUBLIC_IP> بعنوان IP الخاص بخادمك
ssh -i ~/.oci/oci_api_key.pem opc@<PUBLIC_IP>
# أو إذا كنت تستخدم Ubuntu:
ssh -i ~/.oci/oci_api_key.pem ubuntu@<PUBLIC_IP>
```

---

### 4️⃣ تثبيت واجهة سطح المكتب (Desktop Environment)

بعد الاتصال بالخادم:

#### للأنظمة المبنية على Ubuntu/Debian:
```bash
# تحديث النظام
sudo apt update && sudo apt upgrade -y

# تثبيت XFCE (واجهة خفيفة وسريعة)
sudo apt install -y xfce4 xfce4-goodies

# أو تثبيت GNOME (واجهة كاملة)
sudo apt install -y ubuntu-desktop

# أو تثبيت LXDE (واجهة خفيفة جداً)
sudo apt install -y lxde
```

#### للأنظمة المبنية على Oracle Linux/RHEL:
```bash
# تحديث النظام
sudo yum update -y

# تثبيت GNOME
sudo yum groupinstall -y "Server with GUI"

# أو تثبيت XFCE
sudo yum install -y epel-release
sudo yum groupinstall -y xfce
```

---

### 5️⃣ تثبيت وإعداد VNC Server

VNC يسمح لك بالوصول للواجهة الرسومية عن بعد:

```bash
# تثبيت TigerVNC Server
sudo apt install -y tigervnc-standalone-server tigervnc-common
# أو على Oracle Linux:
sudo yum install -y tigervnc-server

# تعيين كلمة مرور VNC
vncpasswd
# ستُطلب منك إدخال كلمة مرور (6-8 أحرف على الأقل)

# إنشاء ملف تكوين VNC
mkdir -p ~/.vnc
cat > ~/.vnc/xstartup << 'EOF'
#!/bin/bash
xrdb $HOME/.Xresources
startxfce4 &
EOF

# جعل الملف قابل للتنفيذ
chmod +x ~/.vnc/xstartup

# بدء خادم VNC
vncserver :1 -geometry 1920x1080 -depth 24
```

---

### 6️⃣ فتح المنافذ في Oracle Cloud

يجب فتح منفذ VNC (5901) في قواعد الأمان:

#### من خلال واجهة الويب:
1. اذهب إلى: **Menu → Networking → Virtual Cloud Networks**
2. اختر الشبكة الافتراضية (VCN)
3. اذهب إلى **Security Lists**
4. اختر **Default Security List**
5. اضغط **Add Ingress Rules**
6. أضف:
   - **Source CIDR:** `0.0.0.0/0` (أو عنوان IP جهازك فقط للأمان)
   - **IP Protocol:** TCP
   - **Destination Port Range:** `5901`
   - **Description:** VNC Access

#### من خلال سطر الأوامر:
```bash
# عرض قوائم الأمان
oci network security-list list --compartment-id ocid1.tenancy.oc1..aaaaaaaay7in5ik5o23vpicjf4ec6ihgmear32t6lttkrjxvrrx7buylw3qq --output table
```

---

### 7️⃣ فتح المنفذ في جدار الحماية على الخادم

```bash
# على Ubuntu/Debian:
sudo ufw allow 5901/tcp
sudo ufw enable
sudo ufw status

# على Oracle Linux/RHEL:
sudo firewall-cmd --permanent --add-port=5901/tcp
sudo firewall-cmd --reload
sudo firewall-cmd --list-all
```

---

### 8️⃣ الاتصال من جهازك

#### الطريقة الأولى: استخدام عميل VNC

على جهازك المحلي (Linux):

```bash
# تثبيت عميل VNC
sudo apt install -y tigervnc-viewer
# أو
sudo apt install -y remmina remmina-plugin-vnc

# الاتصال
vncviewer <PUBLIC_IP>:5901
# أو افتح Remmina واختر بروتوكول VNC
```

#### الطريقة الثانية: استخدام SSH Tunnel (أكثر أماناً)

على جهازك المحلي:

```bash
# إنشاء نفق SSH
ssh -i ~/.oci/oci_api_key.pem -L 5901:localhost:5901 opc@<PUBLIC_IP>

# بعد ذلك، في نافذة جديدة:
vncviewer localhost:5901
```

هذه الطريقة أكثر أماناً لأن حركة المرور مشفرة عبر SSH.

---

### 9️⃣ بدائل أخرى

#### استخدام RDP (Remote Desktop Protocol)

```bash
# تثبيت XRDP (يعمل مع عملاء Windows RDP)
sudo apt install -y xrdp
sudo systemctl enable xrdp
sudo systemctl start xrdp

# فتح المنفذ
sudo ufw allow 3389/tcp
```

ثم استخدم:
- **Windows:** Remote Desktop Connection
- **Linux:** Remmina أو rdesktop
- **Mac:** Microsoft Remote Desktop

#### استخدام NoMachine (أداء أفضل)

```bash
# تحميل وتثبيت NoMachine
wget https://download.nomachine.com/download/8.11/Linux/nomachine_8.11.3_1_amd64.deb
sudo dpkg -i nomachine_8.11.3_1_amd64.deb

# فتح المنفذ (4000)
sudo ufw allow 4000/tcp
```

---

## ملخص الأوامر السريعة

### على الخادم:
```bash
# 1. تثبيت البيئة الرسومية
sudo apt update && sudo apt install -y xfce4 xfce4-goodies

# 2. تثبيت VNC
sudo apt install -y tigervnc-standalone-server tigervnc-common

# 3. إعداد VNC
vncpasswd
mkdir -p ~/.vnc
echo '#!/bin/bash
xrdb $HOME/.Xresources
startxfce4 &' > ~/.vnc/xstartup
chmod +x ~/.vnc/xstartup

# 4. بدء VNC
vncserver :1 -geometry 1920x1080 -depth 24

# 5. فتح المنفذ
sudo ufw allow 5901/tcp
sudo ufw enable
```

### على جهازك المحلي:
```bash
# تثبيت العميل
sudo apt install -y tigervnc-viewer

# الاتصال (طريقة آمنة)
ssh -i ~/.oci/oci_api_key.pem -L 5901:localhost:5901 opc@<PUBLIC_IP>
# في نافذة أخرى:
vncviewer localhost:5901
```

---

## نصائح أمنية

1. **لا تفتح المنفذ 5901 للعالم** - استخدم SSH Tunnel بدلاً من ذلك
2. **استخدم كلمة مرور قوية** لـ VNC
3. **قم بإيقاف VNC** عندما لا تحتاجه:
   ```bash
   vncserver -kill :1
   ```
4. **احتفظ بنسخة احتياطية** من التكوينات المهمة

---

## استكشاف الأخطاء

### لا يمكن الاتصال بـ VNC:
- تأكد من أن VNC يعمل: `ps aux | grep vnc`
- تأكد من فتح المنفذ: `sudo ufw status`
- تحقق من قواعد الأمان في Oracle Cloud Console

### شاشة سوداء بعد الاتصال:
- تحقق من ملف `~/.vnc/xstartup`
- جرب إعادة تشغيل VNC: `vncserver -kill :1 && vncserver :1`

### بطء الأداء:
- قلل الدقة: `vncserver :1 -geometry 1280x720`
- استخدم NoMachine بدلاً من VNC
- أوقف الخدمات غير الضرورية

---

## الخطوات التالية

1. ✅ إنشاء خادم على Oracle Cloud
2. ✅ الاتصال بالخادم عبر SSH
3. ✅ تثبيت البيئة الرسومية
4. ✅ إعداد VNC
5. ✅ فتح المنافذ
6. ✅ الاتصال من جهازك

بالتوفيق! 🚀

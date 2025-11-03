# 🚀 دليل البدء السريع - Oracle Cloud GUI

## ما تحتاجه الآن

### ✅ ما تم إنجازه:
- ✅ تكوين Oracle Cloud CLI
- ✅ مفاتيح API جاهزة
- ✅ سكريبتات جاهزة للاستخدام

### ⏳ ما تحتاج إلى فعله:
1. إنشاء خادم (Instance)
2. تثبيت واجهة سطح المكتب
3. الاتصال من جهازك

---

## الخطوات البسيطة

### 1️⃣ إنشاء خادم

اذهب إلى [Oracle Cloud Console](https://cloud.oracle.com/) وقم بإنشاء خادم:

1. **تسجيل الدخول** → hafidhafeed4@gmail.com
2. **Menu** → **Compute** → **Instances**
3. **Create Instance**
4. **اختر الإعدادات:**
   - **Name:** أي اسم (مثلاً: MyDesktop)
   - **Image:** Ubuntu 22.04
   - **Shape:** VM.Standard.E2.1.Micro (مجاني)
   - **SSH Keys:** ارفع الملف:
     ```
     hafidhafeed4@gmail.com-2025-11-02T21 55 28.901Z_public.pem
     ```
5. **Create**
6. **انسخ عنوان IP العام** من صفحة تفاصيل الخادم

---

### 2️⃣ فتح المنافذ المطلوبة

في نفس الصفحة:

1. اذهب إلى **Primary VNIC** → **Subnet** → **Security Lists**
2. اختر **Default Security List**
3. **Add Ingress Rules:**
   - **Source CIDR:** `0.0.0.0/0`
   - **IP Protocol:** TCP
   - **Destination Port:** `5901`
   - **Description:** VNC Access
4. **Save**

---

### 3️⃣ الاتصال بالخادم وتثبيت الواجهة

في الطرفية على جهازك:

```bash
# استبدل <IP> بعنوان IP العام للخادم
ssh -i ~/.oci/oci_api_key.pem opc@<IP>
```

بعد الاتصال، على الخادم:

```bash
# حمّل السكريبت (إذا لم يكن موجوداً)
wget https://raw.githubusercontent.com/your-repo/setup-desktop-gui.sh
# أو انسخه من جهازك:
# من جهازك المحلي:
# scp -i ~/.oci/oci_api_key.pem setup-desktop-gui.sh opc@<IP>:~/

# شغّل السكريبت
chmod +x setup-desktop-gui.sh
./setup-desktop-gui.sh
```

أو قم بالتثبيت اليدوي:

```bash
# تحديث النظام
sudo apt update && sudo apt upgrade -y

# تثبيت XFCE
sudo apt install -y xfce4 xfce4-goodies

# تثبيت VNC
sudo apt install -y tigervnc-standalone-server tigervnc-common

# إعداد VNC
vncpasswd  # أدخل كلمة مرور
mkdir -p ~/.vnc
echo '#!/bin/bash
xrdb $HOME/.Xresources
startxfce4 &' > ~/.vnc/xstartup
chmod +x ~/.vnc/xstartup

# فتح المنفذ
sudo ufw allow 5901/tcp
sudo ufw enable

# بدء VNC
vncserver :1 -geometry 1920x1080 -depth 24
```

---

### 4️⃣ الاتصال من جهازك

#### الطريقة الأولى: استخدام السكريبت الجاهز

```bash
cd ~/Desktop/BOOKIN/BOOKIN
./connect-to-server.sh
```

#### الطريقة الثانية: يدوياً

```bash
# تثبيت VNC Viewer (إذا لم يكن مثبتاً)
sudo apt install -y tigervnc-viewer

# الاتصال (طريقة آمنة)
# في طرفية أولى:
ssh -i ~/.oci/oci_api_key.pem -L 5901:localhost:5901 opc@<IP>

# في طرفية ثانية:
vncviewer localhost:5901
```

---

## 🎉 النتيجة النهائية

بعد اتباع الخطوات أعلاه، ستحصل على:

- ✅ خادم Ubuntu يعمل على Oracle Cloud
- ✅ واجهة سطح مكتب XFCE كاملة
- ✅ الوصول عن بعد من جهازك
- ✅ اتصال آمن عبر SSH Tunnel

---

## 📝 أوامر مفيدة

### على الخادم:

```bash
# إيقاف VNC
vncserver -kill :1

# بدء VNC
vncserver :1 -geometry 1920x1080 -depth 24

# تغيير كلمة مرور VNC
vncpasswd

# عرض الشاشات النشطة
vncserver -list

# إعادة تشغيل الخادم
sudo reboot
```

### من جهازك المحلي:

```bash
# الاتصال عبر SSH فقط
ssh -i ~/.oci/oci_api_key.pem opc@<IP>

# نسخ ملفات إلى الخادم
scp -i ~/.oci/oci_api_key.pem file.txt opc@<IP>:~/

# نسخ ملفات من الخادم
scp -i ~/.oci/oci_api_key.pem opc@<IP>:~/file.txt ./

# عرض معلومات الخادم
oci compute instance list --compartment-id ocid1.tenancy.oc1..aaaaaaaay7in5ik5o23vpicjf4ec6ihgmear32t6lttkrjxvrrx7buylw3qq --output table
```

---

## ⚠️ نصائح مهمة

1. **كلمة مرور VNC:**
   - استخدم كلمة مرور قوية
   - لا تشاركها مع أحد

2. **الأمان:**
   - استخدم SSH Tunnel دائماً
   - لا تفتح المنفذ 5901 للعالم (إلا للاختبار)

3. **الأداء:**
   - إذا كان الاتصال بطيئاً، قلل الدقة:
     ```bash
     vncserver :1 -geometry 1280x720 -depth 16
     ```

4. **التكلفة:**
   - الخادم المجاني (E2.1.Micro) محدود الموارد
   - راقب استهلاكك من [Usage Reports](https://cloud.oracle.com/usage)

---

## 🆘 استكشاف الأخطاء

### لا يمكن الاتصال بـ SSH:
```bash
# تحقق من أن الخادم يعمل
oci compute instance get --instance-id <INSTANCE_OCID>

# تحقق من IP العام
oci network public-ip list --scope REGION --compartment-id ocid1.tenancy.oc1..aaaaaaaay7in5ik5o23vpicjf4ec6ihgmear32t6lttkrjxvrrx7buylw3qq
```

### لا يمكن الاتصال بـ VNC:
```bash
# على الخادم، تحقق من أن VNC يعمل
ps aux | grep vnc

# تحقق من المنفذ
sudo netstat -tlnp | grep 5901

# تحقق من جدار الحماية
sudo ufw status
```

### شاشة سوداء في VNC:
```bash
# أعد تشغيل VNC
vncserver -kill :1
vncserver :1 -geometry 1920x1080 -depth 24

# تحقق من ملف xstartup
cat ~/.vnc/xstartup
```

---

## 📚 الملفات المرجعية

- **الدليل الكامل:** `gui-access-guide.md`
- **مرجع OCI:** `oci-quick-reference.md`
- **سكريبت التثبيت:** `setup-desktop-gui.sh`
- **سكريبت الاتصال:** `connect-to-server.sh`

---

## 🎯 الخطوة التالية

**الآن، اذهب إلى Oracle Cloud Console وأنشئ خادمك الأول!**

[🔗 افتح Oracle Cloud Console](https://cloud.oracle.com/)

بالتوفيق! 🚀

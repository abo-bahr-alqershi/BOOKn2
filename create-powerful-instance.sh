#!/bin/bash

# سكريبت لإنشاء خادم A1.Flex (الأقوى المجاني) تلقائياً
# يحاول في جميع مناطق التوفر حتى ينجح

set -e

COMPARTMENT_ID="ocid1.tenancy.oc1..aaaaaaaay7in5ik5o23vpicjf4ec6ihgmear32t6lttkrjxvrrx7buylw3qq"
SSH_KEY_FILE="/home/ameen/Desktop/BOOKIN/BOOKIN/oracle_ssh_key.pub"

echo "================================================"
echo "  محاولة إنشاء خادم A1.Flex (4 OCPU + 24 GB)"
echo "================================================"
echo ""

# التحقق من وجود المفتاح العام
if [ ! -f "$SSH_KEY_FILE" ]; then
    echo "❌ خطأ: لم يتم العثور على المفتاح العام"
    echo "   المسار: $SSH_KEY_FILE"
    exit 1
fi

SSH_KEY=$(cat "$SSH_KEY_FILE")

# الحصول على الشبكة الافتراضية (أو إنشاء واحدة)
echo "🔍 البحث عن الشبكة الافتراضية..."
VCN_ID=$(oci network vcn list --compartment-id "$COMPARTMENT_ID" --query 'data[0].id' --raw-output 2>/dev/null || echo "")

if [ -z "$VCN_ID" ]; then
    echo "📝 إنشاء شبكة افتراضية جديدة..."
    VCN_ID=$(oci network vcn create \
        --compartment-id "$COMPARTMENT_ID" \
        --cidr-block "10.0.0.0/16" \
        --display-name "vcn-main" \
        --dns-label "vcnmain" \
        --wait-for-state AVAILABLE \
        --query 'data.id' \
        --raw-output)
    
    # إنشاء Internet Gateway
    IGW_ID=$(oci network internet-gateway create \
        --compartment-id "$COMPARTMENT_ID" \
        --vcn-id "$VCN_ID" \
        --is-enabled true \
        --display-name "igw-main" \
        --wait-for-state AVAILABLE \
        --query 'data.id' \
        --raw-output)
    
    # الحصول على Route Table الافتراضية
    RT_ID=$(oci network route-table list \
        --compartment-id "$COMPARTMENT_ID" \
        --vcn-id "$VCN_ID" \
        --query 'data[0].id' \
        --raw-output)
    
    # إضافة قاعدة للإنترنت
    oci network route-table update \
        --rt-id "$RT_ID" \
        --route-rules "[{\"destination\": \"0.0.0.0/0\", \"networkEntityId\": \"$IGW_ID\"}]" \
        --force
    
    echo "✅ تم إنشاء الشبكة بنجاح"
fi

echo "✅ الشبكة الافتراضية: $VCN_ID"

# الحصول على Subnet (أو إنشاء واحدة)
echo ""
echo "🔍 البحث عن Subnet..."
SUBNET_ID=$(oci network subnet list \
    --compartment-id "$COMPARTMENT_ID" \
    --vcn-id "$VCN_ID" \
    --query 'data[0].id' \
    --raw-output 2>/dev/null || echo "")

if [ -z "$SUBNET_ID" ]; then
    echo "📝 إنشاء Subnet جديدة..."
    
    # الحصول على أول availability domain
    AD=$(oci iam availability-domain list \
        --compartment-id "$COMPARTMENT_ID" \
        --query 'data[0].name' \
        --raw-output)
    
    SUBNET_ID=$(oci network subnet create \
        --compartment-id "$COMPARTMENT_ID" \
        --vcn-id "$VCN_ID" \
        --cidr-block "10.0.0.0/24" \
        --display-name "subnet-public" \
        --dns-label "subnetpublic" \
        --wait-for-state AVAILABLE \
        --query 'data.id' \
        --raw-output)
    
    echo "✅ تم إنشاء Subnet بنجاح"
fi

echo "✅ Subnet: $SUBNET_ID"

# الحصول على قائمة availability domains
echo ""
echo "🔍 الحصول على مناطق التوفر..."
ADS=($(oci iam availability-domain list \
    --compartment-id "$COMPARTMENT_ID" \
    --query 'data[*].name' \
    --raw-output | tr '\t' '\n'))

echo "✅ تم العثور على ${#ADS[@]} مناطق توفر"

# الحصول على آخر image لـ Ubuntu
echo ""
echo "🔍 البحث عن صورة Ubuntu..."
IMAGE_ID=$(oci compute image list \
    --compartment-id "$COMPARTMENT_ID" \
    --operating-system "Canonical Ubuntu" \
    --operating-system-version "22.04" \
    --shape "VM.Standard.A1.Flex" \
    --sort-by TIMECREATED \
    --sort-order DESC \
    --limit 1 \
    --query 'data[0].id' \
    --raw-output)

echo "✅ Image ID: $IMAGE_ID"

# محاولة إنشاء الخادم في كل AD
echo ""
echo "================================================"
echo "  بدء المحاولات..."
echo "================================================"
echo ""

SUCCESS=0
ATTEMPT=1
MAX_ATTEMPTS=50  # عدد المحاولات الإجمالي

while [ $ATTEMPT -le $MAX_ATTEMPTS ] && [ $SUCCESS -eq 0 ]; do
    # اختيار AD عشوائي
    AD_INDEX=$((RANDOM % ${#ADS[@]}))
    AD="${ADS[$AD_INDEX]}"
    
    echo "[$ATTEMPT/$MAX_ATTEMPTS] محاولة إنشاء خادم في: $AD"
    
    # محاولة إنشاء الخادم
    RESULT=$(oci compute instance launch \
        --compartment-id "$COMPARTMENT_ID" \
        --availability-domain "$AD" \
        --shape "VM.Standard.A1.Flex" \
        --shape-config '{"ocpus": 4, "memoryInGBs": 24}' \
        --image-id "$IMAGE_ID" \
        --subnet-id "$SUBNET_ID" \
        --display-name "ubuntu-desktop-powerful" \
        --assign-public-ip true \
        --ssh-authorized-keys-file "$SSH_KEY_FILE" \
        --wait-for-state RUNNING 2>&1 || echo "FAILED")
    
    if [[ "$RESULT" == *"FAILED"* ]] || [[ "$RESULT" == *"Out of capacity"* ]] || [[ "$RESULT" == *"Out of host capacity"* ]]; then
        echo "   ❌ فشل - نفاد السعة"
        echo "   ⏳ انتظار 5 ثوان..."
        sleep 5
    else
        echo ""
        echo "================================================"
        echo "   🎉 نجح! تم إنشاء الخادم!"
        echo "================================================"
        echo ""
        
        # استخراج معلومات الخادم
        INSTANCE_ID=$(echo "$RESULT" | grep '"id":' | head -1 | cut -d'"' -f4)
        
        echo "📋 معلومات الخادم:"
        echo "   - Instance ID: $INSTANCE_ID"
        echo "   - Availability Domain: $AD"
        echo "   - Shape: VM.Standard.A1.Flex"
        echo "   - OCPUs: 4"
        echo "   - Memory: 24 GB"
        echo ""
        
        # الحصول على IP العام
        echo "🔍 الحصول على IP العام..."
        sleep 5
        
        PUBLIC_IP=$(oci compute instance list-vnics \
            --instance-id "$INSTANCE_ID" \
            --query 'data[0]."public-ip"' \
            --raw-output 2>/dev/null || echo "")
        
        if [ -n "$PUBLIC_IP" ]; then
            echo "✅ Public IP: $PUBLIC_IP"
            echo ""
            echo "🔗 للاتصال بالخادم:"
            echo "   ssh -i ~/.oci/oci_api_key.pem ubuntu@$PUBLIC_IP"
        fi
        
        SUCCESS=1
    fi
    
    ATTEMPT=$((ATTEMPT + 1))
done

if [ $SUCCESS -eq 0 ]; then
    echo ""
    echo "================================================"
    echo "   ❌ فشلت جميع المحاولات"
    echo "================================================"
    echo ""
    echo "💡 جرّب:"
    echo "   1. تشغيل السكريبت مرة أخرى"
    echo "   2. المحاولة في وقت لاحق (الليل أفضل)"
    echo "   3. استخدام E2.1.Micro بدلاً من ذلك"
    exit 1
fi

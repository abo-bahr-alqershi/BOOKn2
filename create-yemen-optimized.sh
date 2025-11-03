#!/bin/bash

# سكريبت إنشاء خادم ARM Ampere A1.Flex محسّن لليمن
# 4 OCPUs + 24 GB RAM في أقرب منطقة

set -e

echo "================================================"
echo "  إنشاء خادم محسّن لليمن"
echo "  ARM Ampere A1.Flex: 4 OCPUs + 24 GB"
echo "================================================"
echo ""

# اختيار المنطقة
echo "🌍 اختر المنطقة الأقرب:"
echo "   1) me-jeddah-1 (جدة، السعودية) - الأقرب ⭐⭐⭐⭐⭐"
echo "   2) me-dubai-1 (دبي، الإمارات) ⭐⭐⭐⭐⭐"
echo "   3) me-abudhabi-1 (أبوظبي، الإمارات) ⭐⭐⭐⭐⭐"
echo "   4) eu-frankfurt-1 (ألمانيا) ⭐⭐⭐⭐"
echo "   5) us-chicago-1 (شيكاغو، أمريكا) - الحالي ⭐⭐⭐"
echo ""
read -p "اختيارك [1]: " REGION_CHOICE
REGION_CHOICE=${REGION_CHOICE:-1}

case $REGION_CHOICE in
    1) REGION="me-jeddah-1" ;;
    2) REGION="me-dubai-1" ;;
    3) REGION="me-abudhabi-1" ;;
    4) REGION="eu-frankfurt-1" ;;
    5) REGION="us-chicago-1" ;;
    *) REGION="me-jeddah-1" ;;
esac

echo "✅ المنطقة المختارة: $REGION"
echo ""

# تحديث التكوين للمنطقة المختارة
echo "⚙️  تحديث التكوين..."
oci setup repair-file-permissions --file ~/.oci/config
export OCI_CLI_PROFILE=DEFAULT

# تعيين المنطقة
oci setup config --region "$REGION" 2>/dev/null || true

echo "📋 التكوين الحالي:"
echo "   Region: $REGION"
echo ""

COMPARTMENT_ID="ocid1.tenancy.oc1..aaaaaaaay7in5ik5o23vpicjf4ec6ihgmear32t6lttkrjxvrrx7buylw3qq"
SSH_KEY_FILE="/home/ameen/Desktop/BOOKIN/BOOKIN/oracle_ssh_key.pub"

if [ ! -f "$SSH_KEY_FILE" ]; then
    echo "❌ خطأ: المفتاح العام غير موجود: $SSH_KEY_FILE"
    exit 1
fi

echo "🔍 التحقق من الشبكة الافتراضية..."

# محاولة الحصول على VCN موجودة أو إنشاء واحدة
VCN_ID=$(oci network vcn list \
    --region "$REGION" \
    --compartment-id "$COMPARTMENT_ID" \
    --query 'data[0].id' \
    --raw-output 2>/dev/null || echo "")

if [ -z "$VCN_ID" ]; then
    echo "📝 إنشاء شبكة افتراضية جديدة..."
    VCN_ID=$(oci network vcn create \
        --region "$REGION" \
        --compartment-id "$COMPARTMENT_ID" \
        --cidr-block "10.0.0.0/16" \
        --display-name "vcn-main" \
        --dns-label "vcnmain" \
        --wait-for-state AVAILABLE \
        --query 'data.id' \
        --raw-output)
    
    # إنشاء Internet Gateway
    IGW_ID=$(oci network internet-gateway create \
        --region "$REGION" \
        --compartment-id "$COMPARTMENT_ID" \
        --vcn-id "$VCN_ID" \
        --is-enabled true \
        --display-name "igw-main" \
        --wait-for-state AVAILABLE \
        --query 'data.id' \
        --raw-output)
    
    # تحديث Route Table
    RT_ID=$(oci network route-table list \
        --region "$REGION" \
        --compartment-id "$COMPARTMENT_ID" \
        --vcn-id "$VCN_ID" \
        --query 'data[0].id' \
        --raw-output)
    
    oci network route-table update \
        --region "$REGION" \
        --rt-id "$RT_ID" \
        --route-rules "[{\"destination\": \"0.0.0.0/0\", \"networkEntityId\": \"$IGW_ID\"}]" \
        --force
fi

echo "✅ VCN ID: $VCN_ID"

# الحصول على Subnet
SUBNET_ID=$(oci network subnet list \
    --region "$REGION" \
    --compartment-id "$COMPARTMENT_ID" \
    --vcn-id "$VCN_ID" \
    --query 'data[0].id' \
    --raw-output 2>/dev/null || echo "")

if [ -z "$SUBNET_ID" ]; then
    echo "📝 إنشاء Subnet..."
    SUBNET_ID=$(oci network subnet create \
        --region "$REGION" \
        --compartment-id "$COMPARTMENT_ID" \
        --vcn-id "$VCN_ID" \
        --cidr-block "10.0.0.0/24" \
        --display-name "subnet-public" \
        --dns-label "subnetpublic" \
        --wait-for-state AVAILABLE \
        --query 'data.id' \
        --raw-output)
fi

echo "✅ Subnet ID: $SUBNET_ID"

# الحصول على availability domains
echo ""
echo "🔍 الحصول على مناطق التوفر..."
ADS=($(oci iam availability-domain list \
    --region "$REGION" \
    --compartment-id "$COMPARTMENT_ID" \
    --query 'data[*].name' \
    --raw-output | tr '\t' '\n'))

echo "✅ مناطق التوفر: ${#ADS[@]}"

# الحصول على صورة Ubuntu
echo "🔍 البحث عن صورة Ubuntu 22.04..."
IMAGE_ID=$(oci compute image list \
    --region "$REGION" \
    --compartment-id "$COMPARTMENT_ID" \
    --operating-system "Canonical Ubuntu" \
    --operating-system-version "22.04" \
    --shape "VM.Standard.A1.Flex" \
    --sort-by TIMECREATED \
    --sort-order DESC \
    --limit 1 \
    --query 'data[0].id' \
    --raw-output 2>/dev/null || echo "")

if [ -z "$IMAGE_ID" ]; then
    echo "❌ لم يتم العثور على صورة Ubuntu متوافقة مع A1.Flex في هذه المنطقة"
    echo "   جرّب منطقة أخرى أو استخدم E2.1.Micro"
    exit 1
fi

echo "✅ Image ID: $IMAGE_ID"

# بدء المحاولات
echo ""
echo "================================================"
echo "  محاولة إنشاء خادم A1.Flex (4 OCPU + 24 GB)"
echo "================================================"
echo ""

SUCCESS=0
ATTEMPT=1
MAX_ATTEMPTS=100

while [ $ATTEMPT -le $MAX_ATTEMPTS ] && [ $SUCCESS -eq 0 ]; do
    AD_INDEX=$((RANDOM % ${#ADS[@]}))
    AD="${ADS[$AD_INDEX]}"
    
    echo "[$ATTEMPT/$MAX_ATTEMPTS] المحاولة في: $AD"
    
    RESULT=$(oci compute instance launch \
        --region "$REGION" \
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
        echo "   ❌ فشل - انتظار 3 ثوان..."
        sleep 3
    else
        echo ""
        echo "================================================"
        echo "   🎉🎉🎉 نجح! تم إنشاء الخادم!"
        echo "================================================"
        echo ""
        
        INSTANCE_ID=$(echo "$RESULT" | grep -o 'ocid1.instance[^"]*' | head -1)
        
        echo "📋 معلومات الخادم:"
        echo "   - Region: $REGION"
        echo "   - AD: $AD"
        echo "   - Shape: VM.Standard.A1.Flex"
        echo "   - OCPUs: 4"
        echo "   - Memory: 24 GB"
        echo "   - Instance ID: $INSTANCE_ID"
        echo ""
        
        sleep 10
        
        PUBLIC_IP=$(oci compute instance list-vnics \
            --region "$REGION" \
            --instance-id "$INSTANCE_ID" \
            --query 'data[0]."public-ip"' \
            --raw-output 2>/dev/null || echo "")
        
        if [ -n "$PUBLIC_IP" ]; then
            echo "✅ Public IP: $PUBLIC_IP"
            echo ""
            echo "🔗 للاتصال:"
            echo "   ssh -i ~/.oci/oci_api_key.pem ubuntu@$PUBLIC_IP"
            echo ""
            echo "📝 احفظ هذا IP!"
        fi
        
        SUCCESS=1
    fi
    
    ATTEMPT=$((ATTEMPT + 1))
done

if [ $SUCCESS -eq 0 ]; then
    echo ""
    echo "❌ فشلت جميع المحاولات"
    echo ""
    echo "💡 جرّب:"
    echo "   - منطقة أخرى"
    echo "   - وقت آخر (الليل أفضل)"
    echo "   - ./create-backup-instance.sh (E2.1.Micro)"
    exit 1
fi

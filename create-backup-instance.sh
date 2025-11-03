#!/bin/bash

# سكريبت احتياطي لإنشاء خادم E2.1.Micro (متوفر دائماً)
# 1 OCPU + 1 GB RAM - مجاني للأبد

set -e

COMPARTMENT_ID="ocid1.tenancy.oc1..aaaaaaaay7in5ik5o23vpicjf4ec6ihgmear32t6lttkrjxvrrx7buylw3qq"
SSH_KEY_FILE="/home/ameen/Desktop/BOOKIN/BOOKIN/oracle_ssh_key.pub"

echo "================================================"
echo "  إنشاء خادم E2.1.Micro (1 OCPU + 1 GB)"
echo "  متوفر دائماً - مضمون النجاح"
echo "================================================"
echo ""

# التحقق من وجود المفتاح العام
if [ ! -f "$SSH_KEY_FILE" ]; then
    echo "❌ خطأ: لم يتم العثور على المفتاح العام"
    exit 1
fi

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
    
    # إضافة قاعدة routing
    RT_ID=$(oci network route-table list \
        --compartment-id "$COMPARTMENT_ID" \
        --vcn-id "$VCN_ID" \
        --query 'data[0].id' \
        --raw-output)
    
    oci network route-table update \
        --rt-id "$RT_ID" \
        --route-rules "[{\"destination\": \"0.0.0.0/0\", \"networkEntityId\": \"$IGW_ID\"}]" \
        --force
fi

echo "✅ VCN ID: $VCN_ID"

# الحصول على Subnet
echo "🔍 البحث عن Subnet..."
SUBNET_ID=$(oci network subnet list \
    --compartment-id "$COMPARTMENT_ID" \
    --vcn-id "$VCN_ID" \
    --query 'data[0].id' \
    --raw-output 2>/dev/null || echo "")

if [ -z "$SUBNET_ID" ]; then
    echo "📝 إنشاء Subnet جديدة..."
    SUBNET_ID=$(oci network subnet create \
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

# الحصول على أول AD
echo "🔍 الحصول على Availability Domain..."
AD=$(oci iam availability-domain list \
    --compartment-id "$COMPARTMENT_ID" \
    --query 'data[0].name' \
    --raw-output)

echo "✅ AD: $AD"

# الحصول على صورة Ubuntu
echo "🔍 البحث عن صورة Ubuntu..."
IMAGE_ID=$(oci compute image list \
    --compartment-id "$COMPARTMENT_ID" \
    --operating-system "Canonical Ubuntu" \
    --operating-system-version "22.04" \
    --shape "VM.Standard.E2.1.Micro" \
    --sort-by TIMECREATED \
    --sort-order DESC \
    --limit 1 \
    --query 'data[0].id' \
    --raw-output)

echo "✅ Image ID: $IMAGE_ID"

# إنشاء الخادم
echo ""
echo "🚀 إنشاء الخادم..."
echo ""

oci compute instance launch \
    --compartment-id "$COMPARTMENT_ID" \
    --availability-domain "$AD" \
    --shape "VM.Standard.E2.1.Micro" \
    --image-id "$IMAGE_ID" \
    --subnet-id "$SUBNET_ID" \
    --display-name "ubuntu-desktop" \
    --assign-public-ip true \
    --ssh-authorized-keys-file "$SSH_KEY_FILE" \
    --wait-for-state RUNNING

echo ""
echo "================================================"
echo "   ✅ تم إنشاء الخادم بنجاح!"
echo "================================================"
echo ""

# الحصول على معلومات الخادم
INSTANCE_ID=$(oci compute instance list \
    --compartment-id "$COMPARTMENT_ID" \
    --display-name "ubuntu-desktop" \
    --lifecycle-state RUNNING \
    --query 'data[0].id' \
    --raw-output)

echo "📋 معلومات الخادم:"
echo "   - Instance ID: $INSTANCE_ID"
echo "   - Shape: VM.Standard.E2.1.Micro"
echo "   - OCPUs: 1"
echo "   - Memory: 1 GB"
echo ""

# الحصول على IP العام
echo "🔍 الحصول على IP العام..."
sleep 5

PUBLIC_IP=$(oci compute instance list-vnics \
    --instance-id "$INSTANCE_ID" \
    --query 'data[0]."public-ip"' \
    --raw-output)

echo "✅ Public IP: $PUBLIC_IP"
echo ""
echo "🔗 للاتصال بالخادم:"
echo "   ssh -i ~/.oci/oci_api_key.pem ubuntu@$PUBLIC_IP"
echo ""
echo "📝 احفظ IP الخادم للاستخدام لاحقاً!"

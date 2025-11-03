#!/bin/bash

# سكريبت محسّن لإنشاء خادم مع تجنب "Too many requests"
# ينتظر 10 ثوان بين كل محاولة

set -e

COMPARTMENT_ID="ocid1.tenancy.oc1..aaaaaaaay7in5ik5o23vpicjf4ec6ihgmear32t6lttkrjxvrrx7buylw3qq"
SSH_KEY_FILE="/home/ameen/Desktop/BOOKIN/BOOKIN/oracle_ssh_key.pub"

echo "================================================"
echo "  إنشاء خادم A1.Flex (محسّن)"
echo "  4 OCPUs + 24 GB RAM"
echo "================================================"
echo ""

if [ ! -f "$SSH_KEY_FILE" ]; then
    echo "❌ خطأ: المفتاح العام غير موجود"
    exit 1
fi

echo "🔍 جاري التحقق من الموارد..."
echo ""

# الحصول على VCN
VCN_ID=$(oci network vcn list \
    --compartment-id "$COMPARTMENT_ID" \
    --query 'data[0].id' \
    --raw-output 2>/dev/null || echo "")

if [ -z "$VCN_ID" ]; then
    echo "📝 إنشاء شبكة افتراضية..."
    VCN_ID=$(oci network vcn create \
        --compartment-id "$COMPARTMENT_ID" \
        --cidr-block "10.0.0.0/16" \
        --display-name "vcn-main" \
        --dns-label "vcnmain" \
        --wait-for-state AVAILABLE \
        --query 'data.id' \
        --raw-output)
    
    IGW_ID=$(oci network internet-gateway create \
        --compartment-id "$COMPARTMENT_ID" \
        --vcn-id "$VCN_ID" \
        --is-enabled true \
        --display-name "igw-main" \
        --wait-for-state AVAILABLE \
        --query 'data.id' \
        --raw-output)
    
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

echo "✅ VCN: موجود"

# الحصول على Subnet
SUBNET_ID=$(oci network subnet list \
    --compartment-id "$COMPARTMENT_ID" \
    --vcn-id "$VCN_ID" \
    --query 'data[0].id' \
    --raw-output 2>/dev/null || echo "")

if [ -z "$SUBNET_ID" ]; then
    echo "📝 إنشاء Subnet..."
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

echo "✅ Subnet: موجود"

# الحصول على ADs
ADS=($(oci iam availability-domain list \
    --compartment-id "$COMPARTMENT_ID" \
    --query 'data[*].name' \
    --raw-output | tr '\t' '\n'))

echo "✅ Availability Domains: ${#ADS[@]}"

# الحصول على Image
IMAGE_ID=$(oci compute image list \
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
    echo "❌ لم يتم العثور على صورة Ubuntu"
    exit 1
fi

echo "✅ Image: موجود"
echo ""
echo "================================================"
echo "  بدء المحاولات (بانتظار 10 ثوان بين كل محاولة)"
echo "================================================"
echo ""

SUCCESS=0
ATTEMPT=1
MAX_ATTEMPTS=20

while [ $ATTEMPT -le $MAX_ATTEMPTS ] && [ $SUCCESS -eq 0 ]; do
    AD_INDEX=$(( (ATTEMPT - 1) % ${#ADS[@]} ))
    AD="${ADS[$AD_INDEX]}"
    
    echo "[$ATTEMPT/$MAX_ATTEMPTS] محاولة في: $AD"
    
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
        2>&1 || echo "FAILED")
    
    if [[ "$RESULT" == *"FAILED"* ]] || [[ "$RESULT" == *"Out of capacity"* ]] || [[ "$RESULT" == *"Out of host capacity"* ]]; then
        echo "   ❌ فشل - نفاد السعة"
        echo "   ⏳ انتظار 10 ثوان قبل المحاولة التالية..."
        sleep 10
    elif [[ "$RESULT" == *"TooManyRequests"* ]] || [[ "$RESULT" == *"Too many requests"* ]]; then
        echo "   ⚠️  تم الوصول لحد الطلبات"
        echo "   ⏳ انتظار 30 ثانية..."
        sleep 30
    else
        # محاولة استخراج Instance ID
        INSTANCE_ID=$(echo "$RESULT" | grep -o 'ocid1\.instance\.[^"]*' | head -1 || echo "")
        
        if [ -n "$INSTANCE_ID" ]; then
            echo ""
            echo "================================================"
            echo "   🎉 نجح! تم إنشاء الخادم!"
            echo "================================================"
            echo ""
            echo "📋 معلومات الخادم:"
            echo "   - AD: $AD"
            echo "   - Instance ID: $INSTANCE_ID"
            echo "   - Shape: VM.Standard.A1.Flex (4 OCPU + 24 GB)"
            echo ""
            echo "⏳ انتظار تشغيل الخادم..."
            
            oci compute instance action \
                --instance-id "$INSTANCE_ID" \
                --action START \
                --wait-for-state RUNNING 2>/dev/null || true
            
            sleep 15
            
            PUBLIC_IP=$(oci compute instance list-vnics \
                --instance-id "$INSTANCE_ID" \
                --query 'data[0]."public-ip"' \
                --raw-output 2>/dev/null || echo "")
            
            if [ -n "$PUBLIC_IP" ]; then
                echo "✅ Public IP: $PUBLIC_IP"
                echo ""
                echo "🔗 للاتصال بالخادم:"
                echo "   ssh -i ~/.oci/oci_api_key.pem ubuntu@$PUBLIC_IP"
                echo ""
                echo "📝 احفظ هذا IP!"
            fi
            
            SUCCESS=1
        else
            echo "   ⚠️  استجابة غير متوقعة"
            echo "   ⏳ انتظار 15 ثانية..."
            sleep 15
        fi
    fi
    
    ATTEMPT=$((ATTEMPT + 1))
done

if [ $SUCCESS -eq 0 ]; then
    echo ""
    echo "❌ فشلت جميع المحاولات"
    echo ""
    echo "💡 جرّب:"
    echo "   1. انتظر 10 دقائق"
    echo "   2. شغّل السكريبت مرة أخرى"
    echo "   3. أو جرّب E2.1.Micro: ./create-backup-instance.sh"
    exit 1
fi

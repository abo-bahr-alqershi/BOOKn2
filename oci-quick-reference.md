# دليل استخدام Oracle Cloud Infrastructure

## معلومات الحساب

- **المنطقة (Region):** us-chicago-1
- **Tenancy ID:** ocid1.tenancy.oc1..aaaaaaaay7in5ik5o23vpicjf4ec6ihgmear32t6lttkrjxvrrx7buylw3qq
- **User ID:** ocid1.user.oc1..aaaaaaaahpmqrbui4brzwrp7ftsd667o26b7r4gq5kizqkw2qgo6yxnumhqa

## الأوامر الأساسية

### عرض المناطق المتاحة
```bash
oci iam region list --output table
```

### عرض مناطق التوفر (Availability Domains)
```bash
oci iam availability-domain list --output table
```

### إدارة الخوادم الافتراضية (Compute Instances)

#### عرض جميع الخوادم
```bash
oci compute instance list --compartment-id ocid1.tenancy.oc1..aaaaaaaay7in5ik5o23vpicjf4ec6ihgmear32t6lttkrjxvrrx7buylw3qq --output table
```

#### عرض تفاصيل خادم معين
```bash
oci compute instance get --instance-id <INSTANCE_OCID>
```

#### إيقاف خادم
```bash
oci compute instance action --instance-id <INSTANCE_OCID> --action STOP
```

#### تشغيل خادم
```bash
oci compute instance action --instance-id <INSTANCE_OCID> --action START
```

#### إعادة تشغيل خادم
```bash
oci compute instance action --instance-id <INSTANCE_OCID> --action RESET
```

### إدارة الشبكات (Networking)

#### عرض الشبكات الافتراضية (VCNs)
```bash
oci network vcn list --compartment-id ocid1.tenancy.oc1..aaaaaaaay7in5ik5o23vpicjf4ec6ihgmear32t6lttkrjxvrrx7buylw3qq --output table
```

#### عرض الشبكات الفرعية (Subnets)
```bash
oci network subnet list --compartment-id ocid1.tenancy.oc1..aaaaaaaay7in5ik5o23vpicjf4ec6ihgmear32t6lttkrjxvrrx7buylw3qq --output table
```

#### عرض عناوين IP العامة
```bash
oci network public-ip list --scope REGION --compartment-id ocid1.tenancy.oc1..aaaaaaaay7in5ik5o23vpicjf4ec6ihgmear32t6lttkrjxvrrx7buylw3qq --output table
```

### إدارة التخزين (Block Storage)

#### عرض وحدات التخزين
```bash
oci bv volume list --compartment-id ocid1.tenancy.oc1..aaaaaaaay7in5ik5o23vpicjf4ec6ihgmear32t6lttkrjxvrrx7buylw3qq --output table
```

#### عرض النسخ الاحتياطية
```bash
oci bv backup list --compartment-id ocid1.tenancy.oc1..aaaaaaaay7in5ik5o23vpicjf4ec6ihgmear32t6lttkrjxvrrx7buylw3qq --output table
```

### إدارة قواعد البيانات

#### عرض قواعد البيانات المستقلة (Autonomous Databases)
```bash
oci db autonomous-database list --compartment-id ocid1.tenancy.oc1..aaaaaaaay7in5ik5o23vpicjf4ec6ihgmear32t6lttkrjxvrrx7buylw3qq --output table
```

### إدارة Object Storage

#### عرض Buckets
```bash
oci os bucket list --compartment-id ocid1.tenancy.oc1..aaaaaaaay7in5ik5o23vpicjf4ec6ihgmear32t6lttkrjxvrrx7buylw3qq --output table
```

#### رفع ملف
```bash
oci os object put --bucket-name <BUCKET_NAME> --file <LOCAL_FILE_PATH>
```

#### تحميل ملف
```bash
oci os object get --bucket-name <BUCKET_NAME> --name <OBJECT_NAME> --file <LOCAL_FILE_PATH>
```

### عرض الفواتير والتكاليف

#### عرض التكاليف الحالية
```bash
oci usage-api usage-summary list --tenant-id ocid1.tenancy.oc1..aaaaaaaay7in5ik5o23vpicjf4ec6ihgmear32t6lttkrjxvrrx7buylw3qq --time-usage-started 2025-01-01T00:00:00.000Z --time-usage-ended 2025-12-31T23:59:59.999Z --granularity DAILY
```

## أشكال الإخراج المختلفة

يمكنك تغيير شكل الإخراج باستخدام `--output`:
- `--output table` - عرض جدولي
- `--output json` - تنسيق JSON
- `--output json-pretty` - JSON منسق وسهل القراءة

## ملفات التكوين

- **ملف التكوين الرئيسي:** `~/.oci/config`
- **المفتاح الخاص:** `~/.oci/oci_api_key.pem`

## الاتصال بالخادم عبر SSH

إذا كان لديك خادم مع IP عام، يمكنك الاتصال به:
```bash
ssh -i ~/.oci/oci_api_key.pem opc@<PUBLIC_IP_ADDRESS>
```

## الحصول على المساعدة

```bash
oci --help
oci compute --help
oci compute instance --help
```

## موارد إضافية

- [OCI CLI Documentation](https://docs.oracle.com/en-us/iaas/tools/oci-cli/latest/oci_cli_docs/)
- [OCI Console](https://cloud.oracle.com/)

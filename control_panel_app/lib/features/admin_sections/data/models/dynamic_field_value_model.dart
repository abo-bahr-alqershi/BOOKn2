class DynamicFieldValueModel {
  final String fieldKey;
  final dynamic value;

  const DynamicFieldValueModel({required this.fieldKey, this.value});

  factory DynamicFieldValueModel.fromJson(Map<String, dynamic> json) {
    return DynamicFieldValueModel(
      fieldKey: json['fieldKey']?.toString() ?? '',
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() => {
        'fieldKey': fieldKey,
        'value': value,
      };
}


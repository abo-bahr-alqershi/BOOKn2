import '../../domain/entities/section_metadata.dart' as domain;

class SectionMetadataModel {
  final Map<String, dynamic> values;

  const SectionMetadataModel({this.values = const {}});

  factory SectionMetadataModel.fromJson(Map<String, dynamic> json) {
    return SectionMetadataModel(values: Map<String, dynamic>.from(json));
  }

  Map<String, dynamic> toJson() => values;

  domain.SectionMetadata toEntity() => domain.SectionMetadata(values: values);
}


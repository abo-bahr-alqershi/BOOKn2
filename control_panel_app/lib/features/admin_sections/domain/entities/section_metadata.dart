import 'package:equatable/equatable.dart';

class SectionMetadata extends Equatable {
  final Map<String, dynamic> values;

  const SectionMetadata({this.values = const {}});

  SectionMetadata merge(SectionMetadata other) {
    return SectionMetadata(values: {...values, ...other.values});
  }

  @override
  List<Object?> get props => [values];
}


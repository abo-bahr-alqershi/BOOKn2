import '../../domain/entities/city.dart' as domain;

class CityModel {
  final String name;
  final String country;
  final List<String> images;

  const CityModel({
    required this.name,
    required this.country,
    this.images = const <String>[],
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      name: json['name'] ?? '',
      country: json['country'] ?? '',
      images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'country': country,
        'images': images,
      };

  domain.City toEntity() => domain.City(name: name, country: country, images: images);
}


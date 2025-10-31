class City {
  final String name;
  final String country;
  final List<String> images;

  const City({
    required this.name,
    required this.country,
    this.images = const <String>[],
  });
}


import 'package:equatable/equatable.dart';

class SearchResult<T> extends Equatable {
  final T item;
  final String id;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;

  const SearchResult({
    required this.item,
    required this.id,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.metadata,
  });

  @override
  List<Object?> get props => [id, title, subtitle, imageUrl, metadata];
}
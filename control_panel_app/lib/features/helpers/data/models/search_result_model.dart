import '../../domain/entities/search_result.dart';

class SearchResultModel<T> extends SearchResult<T> {
  const SearchResultModel({
    required T item,
    required String id,
    required String title,
    required String subtitle,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) : super(
          item: item,
          id: id,
          title: title,
          subtitle: subtitle,
          imageUrl: imageUrl,
          metadata: metadata,
        );

  factory SearchResultModel.fromJson(
    Map<String, dynamic> json,
    T item,
  ) {
    return SearchResultModel<T>(
      item: item,
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      imageUrl: json['imageUrl'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'metadata': metadata,
    };
  }
}
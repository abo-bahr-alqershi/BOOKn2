import 'package:equatable/equatable.dart';

class PaginatedResult<T> extends Equatable {
  final List<T> items;
  final int pageNumber;
  final int pageSize;
  final int totalCount;
  final Object? metadata;

  const PaginatedResult({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
    this.metadata,
  });

  int get _safePageSize {
    if (pageSize <= 0) return items.isNotEmpty ? items.length : 1;
    return pageSize;
  }

  int get _safePageNumber => pageNumber < 1 ? 1 : pageNumber;

  int get totalPages {
    final size = _safePageSize;
    if (totalCount <= 0) return 0;
    return ((totalCount + size - 1) ~/ size);
  }

  bool get hasPreviousPage => _safePageNumber > 1;
  bool get hasNextPage => totalPages > 0 && _safePageNumber < totalPages;
  int get currentPage => _safePageNumber;
  int? get previousPageNumber => hasPreviousPage ? _safePageNumber - 1 : null;
  int? get nextPageNumber => hasNextPage ? _safePageNumber + 1 : null;
  int get startIndex =>
      (_safePageNumber - 1) * _safePageSize + (items.isEmpty ? 0 : 1);
  int get endIndex => items.isEmpty ? 0 : startIndex + items.length - 1;

  factory PaginatedResult.empty({
    int pageNumber = 1,
    int pageSize = 10,
  }) {
    return PaginatedResult<T>(
      items: const [],
      pageNumber: pageNumber,
      pageSize: pageSize,
      totalCount: 0,
    );
  }

  factory PaginatedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    // Accept both bare payload and ResultDto-wrapped
    final Object? root;
    if (json['items'] != null) {
      root = json;
    } else if (json['data'] is Map<String, dynamic>) {
      root = json['data'];
    } else if (json['data'] is List) {
      // Envelope with list as data
      root = {
        'items': json['data'],
        'pageNumber': json['pageNumber'] ?? 1,
        'pageSize': (json['data'] as List).length,
        'totalCount': (json['data'] as List).length,
        'metadata': json['metadata'],
      };
    } else {
      // Some backends might return list directly
      if (json.isEmpty) {
        return PaginatedResult<T>.empty();
      }
      root = json;
    }

    final Map<String, dynamic> payload = Map<String, dynamic>.from(root as Map);

    final List rawItems;
    if (payload['items'] is List) {
      rawItems = payload['items'] as List;
    } else if (payload['data'] is List) {
      rawItems = payload['data'] as List;
    } else {
      rawItems = const [];
    }
    final parsedItems = rawItems
        .whereType<Map>()
        .map((item) => fromJsonT(Map<String, dynamic>.from(item)))
        .toList();

    int parseInt(dynamic v, int fallback) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? fallback;
      if (v is num) return v.toInt();
      return fallback;
    }

    final pn = parseInt(payload['pageNumber'], 1);
    final ps = parseInt(payload['pageSize'], 10);
    final tc = parseInt(payload['totalCount'], parsedItems.length);

    return PaginatedResult<T>(
      items: parsedItems,
      pageNumber: pn < 1 ? 1 : pn,
      pageSize:
          ps <= 0 ? (parsedItems.isNotEmpty ? parsedItems.length : 10) : ps,
      totalCount: tc < 0 ? 0 : tc,
      metadata: payload['metadata'],
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJsonT) {
    return {
      'items': items.map((item) => toJsonT(item)).toList(),
      'pageNumber': _safePageNumber,
      'pageSize': _safePageSize,
      'totalCount': totalCount,
      'totalPages': totalPages,
      'hasPreviousPage': hasPreviousPage,
      'hasNextPage': hasNextPage,
      'previousPageNumber': previousPageNumber,
      'nextPageNumber': nextPageNumber,
      'startIndex': startIndex,
      'endIndex': endIndex,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        items,
        pageNumber,
        pageSize,
        totalCount,
        metadata,
      ];
}

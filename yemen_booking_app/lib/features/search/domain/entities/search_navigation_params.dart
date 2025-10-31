import 'package:equatable/equatable.dart';

class SearchNavigationParams extends Equatable {
	final String? propertyTypeId;
	final String? unitTypeId;
	final Map<String, dynamic> dynamicFieldFilters;
	final String? city;
	final String? searchTerm;
	final DateTime? checkIn;
	final DateTime? checkOut;
	final int? adults;
	final int? children;
	final int? guestsCount;

	const SearchNavigationParams({
		this.propertyTypeId,
		this.unitTypeId,
		this.dynamicFieldFilters = const {},
		this.city,
		this.searchTerm,
		this.checkIn,
		this.checkOut,
		this.adults,
		this.children,
		this.guestsCount,
	});

	SearchNavigationParams copyWith({
		String? propertyTypeId,
		String? unitTypeId,
		Map<String, dynamic>? dynamicFieldFilters,
		String? city,
		String? searchTerm,
		DateTime? checkIn,
		DateTime? checkOut,
		int? adults,
		int? children,
		int? guestsCount,
	}) {
		return SearchNavigationParams(
			propertyTypeId: propertyTypeId ?? this.propertyTypeId,
			unitTypeId: unitTypeId ?? this.unitTypeId,
			dynamicFieldFilters: dynamicFieldFilters ?? this.dynamicFieldFilters,
			city: city ?? this.city,
			searchTerm: searchTerm ?? this.searchTerm,
			checkIn: checkIn ?? this.checkIn,
			checkOut: checkOut ?? this.checkOut,
			adults: adults ?? this.adults,
			children: children ?? this.children,
			guestsCount: guestsCount ?? this.guestsCount,
		);
	}

	Map<String, dynamic> toMap() => {
		'propertyTypeId': propertyTypeId,
		'unitTypeId': unitTypeId,
		'dynamicFieldFilters': dynamicFieldFilters,
		'city': city,
		'searchTerm': searchTerm,
		'checkIn': checkIn?.toIso8601String(),
		'checkOut': checkOut?.toIso8601String(),
		'adults': adults,
		'children': children,
		'guestsCount': guestsCount,
	};

	factory SearchNavigationParams.fromMap(Map<String, dynamic> map) {
		return SearchNavigationParams(
			propertyTypeId: map['propertyTypeId'] as String?,
			unitTypeId: map['unitTypeId'] as String?,
			dynamicFieldFilters: (map['dynamicFieldFilters'] as Map<String, dynamic>?) ?? const {},
			city: map['city'] as String?,
			searchTerm: map['searchTerm'] as String?,
			checkIn: map['checkIn'] != null ? DateTime.tryParse(map['checkIn'] as String) : null,
			checkOut: map['checkOut'] != null ? DateTime.tryParse(map['checkOut'] as String) : null,
			adults: map['adults'] is int ? map['adults'] as int : int.tryParse(map['adults']?.toString() ?? ''),
			children: map['children'] is int ? map['children'] as int : int.tryParse(map['children']?.toString() ?? ''),
			guestsCount: map['guestsCount'] as int?,
		);
	}

	@override
	List<Object?> get props => [
		propertyTypeId,
		unitTypeId,
		dynamicFieldFilters,
		city,
		searchTerm,
		checkIn,
		checkOut,
		adults,
		children,
		guestsCount,
	];
}
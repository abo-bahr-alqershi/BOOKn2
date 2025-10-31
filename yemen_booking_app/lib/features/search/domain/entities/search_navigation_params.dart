import 'package:equatable/equatable.dart';

class SearchNavigationParams extends Equatable {
	final String? propertyTypeId;
	final String? unitTypeId;
	final Map<String, dynamic> dynamicFieldFilters;
	final String? city;
	final String? searchTerm;
	final DateTime? checkIn;
	final DateTime? checkOut;
	final int? guestsCount;

	const SearchNavigationParams({
		this.propertyTypeId,
		this.unitTypeId,
		this.dynamicFieldFilters = const {},
		this.city,
		this.searchTerm,
		this.checkIn,
		this.checkOut,
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
		guestsCount,
	];
}
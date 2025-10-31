import 'package:equatable/equatable.dart';
import '../../../../../core/models/paginated_result.dart' as core;

abstract class SectionItemsState extends Equatable {
  const SectionItemsState();

  @override
  List<Object?> get props => [];
}

class SectionItemsInitial extends SectionItemsState {}

class SectionItemsLoading extends SectionItemsState {}

class SectionItemsLoaded extends SectionItemsState {
  final core.PaginatedResult<dynamic> page;
  const SectionItemsLoaded(this.page);

  @override
  List<Object?> get props => [page];
}

class SectionItemsError extends SectionItemsState {
  final String message;
  const SectionItemsError(this.message);

  @override
  List<Object?> get props => [message];
}

class SectionItemsOperationSuccess extends SectionItemsState {}


import 'package:equatable/equatable.dart';
import '../../domain/entities/currency.dart';

abstract class CurrenciesEvent extends Equatable {
  const CurrenciesEvent();

  @override
  List<Object?> get props => [];
}

class LoadCurrenciesEvent extends CurrenciesEvent {}

class AddCurrencyEvent extends CurrenciesEvent {
  final Currency currency;

  const AddCurrencyEvent({required this.currency});

  @override
  List<Object> get props => [currency];
}

class UpdateCurrencyEvent extends CurrenciesEvent {
  final Currency currency;
  final String oldCode;

  const UpdateCurrencyEvent({
    required this.currency,
    required this.oldCode,
  });

  @override
  List<Object> get props => [currency, oldCode];
}

class DeleteCurrencyEvent extends CurrenciesEvent {
  final String code;

  const DeleteCurrencyEvent({required this.code});

  @override
  List<Object> get props => [code];
}

class SetDefaultCurrencyEvent extends CurrenciesEvent {
  final String code;

  const SetDefaultCurrencyEvent({required this.code});

  @override
  List<Object> get props => [code];
}

class UpdateExchangeRateEvent extends CurrenciesEvent {
  final String code;
  final double rate;

  const UpdateExchangeRateEvent({
    required this.code,
    required this.rate,
  });

  @override
  List<Object> get props => [code, rate];
}

class SearchCurrenciesEvent extends CurrenciesEvent {
  final String query;

  const SearchCurrenciesEvent({required this.query});

  @override
  List<Object> get props => [query];
}

class RefreshCurrenciesEvent extends CurrenciesEvent {}
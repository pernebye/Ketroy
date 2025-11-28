part of 'bonus_bloc.dart';

abstract class BonusEvent extends Equatable {
  const BonusEvent();

  @override
  List<Object> get props => [];
}

class GetBonussesFetch extends BonusEvent {}

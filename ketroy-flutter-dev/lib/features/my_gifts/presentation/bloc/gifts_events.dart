part of 'gifts_bloc.dart';

abstract class GiftsEvent extends Equatable {
  const GiftsEvent();

  @override
  List<Object> get props => [];
}

class GetGiftsListFetch extends GiftsEvent {}

class ActivateGiftFetch extends GiftsEvent {
  final int giftId;

  const ActivateGiftFetch({required this.giftId});
}

class SaveGiftFetch extends GiftsEvent {
  final int giftId;

  const SaveGiftFetch({required this.giftId});
}

class ResetStateFetch extends GiftsEvent {}

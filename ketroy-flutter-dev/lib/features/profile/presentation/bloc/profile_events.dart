part of 'profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object> get props => [];
}

class LoadUserInfo extends ProfileEvent {}

class LoadDetailedUserInfo extends ProfileEvent {}

class ProfileUpdateFetch extends ProfileEvent {
  final String height;
  final String clothingSize;
  final String shoeSize;
  final String city;
  final String name;
  final String surname;
  final String birthDay;

  const ProfileUpdateFetch(
      {required this.height,
      required this.clothingSize,
      required this.shoeSize,
      required this.city,
      required this.name,
      required this.surname,
      required this.birthDay});
}

// class GetProfileUserFetch extends ProfileEvent {}

class UploadProfileImage extends ProfileEvent {}

class UpdateValue extends ProfileEvent {
  final String? height;
  final String? clothingSize;
  final String? shoeSize;
  final String? city;
  final String? name;

  const UpdateValue(
      {this.height, this.clothingSize, this.shoeSize, this.city, this.name});
}

class ResetListener extends ProfileEvent {}

class DeleteAllStorageFetch extends ProfileEvent {}

class GetProfileUserFetch extends ProfileEvent {}

class GetDiscountFetch extends ProfileEvent {}

class ScanQrFetch extends ProfileEvent {
  final String scanQrUrl;

  const ScanQrFetch({required this.scanQrUrl});
}

class LogOutFetch extends ProfileEvent {}

class DeleteUserFetch extends ProfileEvent {}

class ResetProfileState extends ProfileEvent {}

/// Событие для мягкого обновления профиля (сохраняет скидку и QR статус)
class SoftRefreshProfile extends ProfileEvent {}

/// Событие для сброса статуса QR-сканирования
class ResetQrStatus extends ProfileEvent {}

class GetCityListFetch extends ProfileEvent {}

class LoadCityShop extends ProfileEvent {}

class GetPromotionsFetch extends ProfileEvent {}

/// Событие для обновления бонусов с сервера (при получении push-уведомления)
class RefreshBonusFromServer extends ProfileEvent {
  final int? expectedAmount; // Ожидаемое количество бонусов (если известно из push)
  
  const RefreshBonusFromServer({this.expectedAmount});
  
  @override
  List<Object> get props => [expectedAmount ?? 0];
}

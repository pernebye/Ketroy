part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

/// Событие для отправки кода на регистрацию
final class AuthSendVerifyCode extends AuthEvent {
  final String phone;
  final String code;
  const AuthSendVerifyCode({required this.phone, required this.code});
}

/// Событие для отправки кода на вход
final class AuthLoginSendCode extends AuthEvent {
  final String phone;
  final String code;
  const AuthLoginSendCode({required this.phone, required this.code});
}

final class AuthSmsSend extends AuthEvent {
  final String code;
  final String phone;
  final String sms;

  const AuthSmsSend(
      {required this.code, required this.phone, required this.sms});
}

final class AuthSignUpWithPhone extends AuthEvent {
  final String name;
  final String surname;
  final String phone;
  final String code;
  final String birthDate;
  final String city;
  final String height;
  final String clothingSize;
  final String shoeSize;
  final String? promoCode;

  const AuthSignUpWithPhone(
      {required this.name,
      required this.surname,
      required this.phone,
      required this.code,
      required this.birthDate,
      required this.city,
      required this.height,
      required this.clothingSize,
      required this.shoeSize,
      this.promoCode});
}

final class CountryCodesFetch extends AuthEvent {}

final class CityNamesFetch extends AuthEvent {}

final class UpdateUserFetch extends AuthEvent {
  final String city;
  final String birthDate;
  final String height;
  final String clothingSize;
  final String shoeSize;

  const UpdateUserFetch(
      {required this.city,
      required this.birthDate,
      required this.height,
      required this.clothingSize,
      required this.shoeSize});
}

final class GetProfileUserFetch extends AuthEvent {}

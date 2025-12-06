part of 'auth_bloc.dart';

enum AuthStatus { initial, loading, success, failure }

enum VerifyCodeStatus { initial, loading, success, failure }

enum CountryCodesStatus { initial, loading, success, failure }

enum CityNamesStatus { initial, loading, success, failure }

enum ProfileStatus { initial, loading, success, failure }

enum SignUpWithDataStatus { initial, loading, success, failure }

class AuthState extends Equatable {
  final AuthStatus status;
  final VerifyCodeStatus verifyCodeStatus;
  final CountryCodesStatus countryCodesStatus;
  final CityNamesStatus cityNamesStatus;
  final SignUpWithDataStatus signUpWithDataStatus;

  final String? message;
  final AuthAnswer? authAnswerUserInfo;
  final RegisterAnswer? registerAnswer;
  final SignUpEntity? user;
  final AuthUserEntity? userData;
  final List<CountryCodesEntity> codes;
  final List<CityEntity> cityNames;
  final AuthUserEntity? profileData;
  final String? deviceToken;

  /// Флаг существования пользователя (null если не проверялся)
  final bool? userExists;

  /// Примененный промокод (для показа диалога)
  final String? appliedPromoCode;
  
  /// Флаг успешного применения промокода
  final bool? promoCodeAppliedSuccessfully;
  
  /// Флаг что промокод уже был использован ранее
  final bool? promoCodeAlreadyUsed;

  const AuthState(
      {this.status = AuthStatus.initial,
      this.verifyCodeStatus = VerifyCodeStatus.initial,
      this.countryCodesStatus = CountryCodesStatus.initial,
      this.cityNamesStatus = CityNamesStatus.initial,
      this.signUpWithDataStatus = SignUpWithDataStatus.initial,
      this.message,
      this.authAnswerUserInfo,
      this.registerAnswer,
      this.codes = const [],
      this.userData,
      this.cityNames = const [],
      this.user,
      this.profileData,
      this.deviceToken,
      this.userExists,
      this.appliedPromoCode,
      this.promoCodeAppliedSuccessfully,
      this.promoCodeAlreadyUsed});

  @override
  List<Object?> get props => [
        status,
        verifyCodeStatus,
        countryCodesStatus,
        cityNamesStatus,
        signUpWithDataStatus,
        message,
        authAnswerUserInfo,
        codes,
        userData,
        cityNames,
        user,
        profileData,
        deviceToken,
        userExists,
        appliedPromoCode,
        promoCodeAppliedSuccessfully,
        promoCodeAlreadyUsed,
      ];

  bool get isInitial => status == AuthStatus.initial;
  bool get isLoading => status == AuthStatus.loading;
  bool get isSuccess => status == AuthStatus.success;
  bool get isFailure => status == AuthStatus.failure;

  bool get isVerifyInitial => verifyCodeStatus == VerifyCodeStatus.initial;
  bool get isVerifyLoading => verifyCodeStatus == VerifyCodeStatus.loading;
  bool get isVerifySuccess => verifyCodeStatus == VerifyCodeStatus.success;
  bool get isVerifyFailure => verifyCodeStatus == VerifyCodeStatus.failure;

  bool get isCodesInitial => countryCodesStatus == CountryCodesStatus.initial;
  bool get isCodesLoading => countryCodesStatus == CountryCodesStatus.loading;
  bool get isCodesSuccess => countryCodesStatus == CountryCodesStatus.success;
  bool get isCodesFailure => countryCodesStatus == CountryCodesStatus.failure;

  bool get isSignUpWithDataInitial =>
      signUpWithDataStatus == SignUpWithDataStatus.initial;
  bool get isSignUpWithDataLoading =>
      signUpWithDataStatus == SignUpWithDataStatus.loading;
  bool get isSignUpWithDataSuccess =>
      signUpWithDataStatus == SignUpWithDataStatus.success;
  bool get isSignUpWithDataFailure =>
      signUpWithDataStatus == SignUpWithDataStatus.failure;

  // bool get isCityInitial => cityNamesStatus == CityNamesStatus.initial;
  // bool get isCityLoading => cityNamesStatus == CityNamesStatus.loading;
  // bool get isCitySuccess => cityNamesStatus == CityNamesStatus.success;
  // bool get isCityFailure => cityNamesStatus == CityNamesStatus.failure;

  AuthState copyWith(
      {AuthStatus? status,
      VerifyCodeStatus? verifyCodeStatus,
      CountryCodesStatus? countryCodesStatus,
      CityNamesStatus? cityNamesStatus,
      ProfileStatus? profileStatus,
      SignUpWithDataStatus? signUpWithDataStatus,
      String? message,
      AuthAnswer? authAnswerUserInfo,
      RegisterAnswer? registerAnswer,
      List<CountryCodesEntity>? codes,
      List<CityEntity>? cityNames,
      AuthUserEntity? userData,
      SignUpEntity? user,
      AuthUserEntity? profileData,
      String? deviceToken,
      bool? userExists,
      String? appliedPromoCode,
      bool? promoCodeAppliedSuccessfully,
      bool? promoCodeAlreadyUsed}) {
    return AuthState(
        status: status ?? this.status,
        verifyCodeStatus: verifyCodeStatus ?? this.verifyCodeStatus,
        countryCodesStatus: countryCodesStatus ?? this.countryCodesStatus,
        cityNamesStatus: cityNamesStatus ?? this.cityNamesStatus,
        signUpWithDataStatus: signUpWithDataStatus ?? this.signUpWithDataStatus,
        message: message ?? this.message,
        authAnswerUserInfo: authAnswerUserInfo ?? this.authAnswerUserInfo,
        registerAnswer: registerAnswer ?? this.registerAnswer,
        codes: codes ?? this.codes,
        userData: userData ?? this.userData,
        cityNames: cityNames ?? this.cityNames,
        user: user ?? this.user,
        profileData: profileData ?? this.profileData,
        deviceToken: deviceToken ?? this.deviceToken,
        userExists: userExists,
        appliedPromoCode: appliedPromoCode,
        promoCodeAppliedSuccessfully: promoCodeAppliedSuccessfully,
        promoCodeAlreadyUsed: promoCodeAlreadyUsed);
  }
}

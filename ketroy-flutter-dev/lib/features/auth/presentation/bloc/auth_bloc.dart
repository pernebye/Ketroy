import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/auth/domain/entities/auth_answer.dart';
import 'package:ketroy_app/features/auth/domain/entities/city_entity.dart';
import 'package:ketroy_app/features/auth/domain/entities/country_codes_entity.dart';
import 'package:ketroy_app/features/auth/domain/entities/register_answer.dart';
import 'package:ketroy_app/features/auth/domain/entities/sign_up_entity.dart';
import 'package:ketroy_app/features/auth/domain/entities/user_entity.dart';
import 'package:ketroy_app/features/auth/domain/use_cases/city_names.dart';
import 'package:ketroy_app/features/auth/domain/use_cases/country_codes.dart';
import 'package:ketroy_app/features/auth/domain/use_cases/send_verify_code.dart';
import 'package:ketroy_app/features/auth/domain/use_cases/sign_up_with_phone.dart';
import 'package:ketroy_app/features/auth/domain/use_cases/sms_auth.dart';
import 'package:ketroy_app/features/auth/domain/use_cases/update_user.dart';
import 'package:ketroy_app/features/discount/domain/use_cases/post_promo_code.dart';
import 'package:ketroy_app/services/local_storage/user_data_manager.dart';
import 'package:ketroy_app/services/notification_services.dart';

part 'auth_events.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SendVerifyCode _sendVerifyCode;
  final LoginSendCode _loginSendCode;
  final SmsAuth _smsAuth;
  final SignUpWithPhone _signUpWithPhone;
  final CountryCodes _countryCodes;
  final CityNames _cityNames;
  final PostPromoCode _postPromoCode;
  AuthBloc({
    required SendVerifyCode sendVerifyCode,
    required LoginSendCode loginSendCode,
    required SmsAuth smsAuth,
    required SignUpWithPhone signUpWithPhone,
    required CountryCodes countryCodes,
    required CityNames cityNames,
    required UpdateUser updateUser,
    required PostPromoCode postPromoCode,
  })  : _sendVerifyCode = sendVerifyCode,
        _loginSendCode = loginSendCode,
        _smsAuth = smsAuth,
        _signUpWithPhone = signUpWithPhone,
        _countryCodes = countryCodes,
        _cityNames = cityNames,
        _postPromoCode = postPromoCode,
        super(const AuthState()) {
    on<AuthResetState>(_resetState);
    on<AuthSendVerifyCode>(_sendVerifyCodeFetch);
    on<AuthLoginSendCode>(_loginSendCodeFetch);
    on<AuthSmsSend>(_authSmsSendFetch);
    on<AuthSignUpWithPhone>(_authSignUpWithPhoneFetch);
    on<CountryCodesFetch>(_countryCodesFetch);
    on<CityNamesFetch>(_cityNamesFetch);
  }

  /// Сброс состояния авторизации
  /// Используется при повторной попытке авторизации после ошибки
  void _resetState(AuthResetState event, Emitter<AuthState> emit) {
    emit(const AuthState());
  }

  void _authSignUpWithPhoneFetch(
      AuthSignUpWithPhone event, Emitter<AuthState> emit) async {
    final fcmToken = NotificationServices.instance.fcmToken;

    emit(state.copyWith(signUpWithDataStatus: SignUpWithDataStatus.loading));

    try {
      // Получаем промокод: сначала из события, потом из сохраненного
      String? promoCodeToApply = event.promoCode;
      if (promoCodeToApply == null || promoCodeToApply.isEmpty) {
        promoCodeToApply = await UserDataManager.getPromoCode();
        debugPrint('📦 Using saved promo code for registration: $promoCodeToApply');
      }

      // Основная регистрация
      final res = await _signUpWithPhone(
          SignUpWithPhoneParams(
              name: event.name,
              surname: event.surname,
              phone: event.phone,
              code: event.code,
              deviceToken: fcmToken,
              birthDate: event.birthDate,
              city: event.city,
              height: event.height,
              clothingSize: event.clothingSize,
              shoeSize: event.shoeSize),
          null);

      await res.fold((failure) async {
        emit(state.copyWith(
            signUpWithDataStatus: SignUpWithDataStatus.failure,
            message: failure.message));
      }, (registerAnswer) async {
        try {
          // Сохраняем данные регистрации
          if (registerAnswer.user != null) {
            await UserDataManager.saveRegisterAnswerAndConvert(registerAnswer);
          }

          // ✅ Применяем промокод если он есть
          String? promoMessage;
          String? appliedPromoCode;
          bool promoCodeAppliedSuccessfully = false;
          
          if (promoCodeToApply != null && promoCodeToApply.isNotEmpty) {
            appliedPromoCode = promoCodeToApply;
            final resPromo = await _postPromoCode(
                PostPromoCodeParams(promoCode: promoCodeToApply), null);

            // ✅ Обрабатываем результат промо-кода
            resPromo.fold((promoFailure) {
              debugPrint('⚠️ Promo code error: ${promoFailure.message}');
              promoMessage =
                  'Регистрация успешна, но промо-код не активирован: ${promoFailure.message}';
              promoCodeAppliedSuccessfully = false;
            }, (promoSuccess) {
              debugPrint('✅ Promo code applied successfully during registration');
              promoMessage = 'Регистрация успешна! Промо-код активирован.';
              promoCodeAppliedSuccessfully = true;
              // ✅ Очищаем сохраненный промокод после успешного применения
              UserDataManager.clearPromoCode();
            });
          }

          if (!emit.isDone) {
            emit(state.copyWith(
              signUpWithDataStatus: SignUpWithDataStatus.success,
              registerAnswer: registerAnswer,
              message: promoMessage,
              appliedPromoCode: appliedPromoCode,
              promoCodeAppliedSuccessfully: promoCodeAppliedSuccessfully,
            ));
          }
        } catch (e) {
          debugPrint('❌ Error in registration success handling: $e');
          if (!emit.isDone) {
            emit(state.copyWith(
                signUpWithDataStatus: SignUpWithDataStatus.failure,
                message: 'Ошибка при сохранении данных: $e'));
          }
        }
      });
    } catch (e) {
      debugPrint('❌ Unexpected error in sign up: $e');
      if (!emit.isDone) {
        emit(state.copyWith(
            signUpWithDataStatus: SignUpWithDataStatus.failure,
            message: 'Неожиданная ошибка: $e'));
      }
    }
  }

  void _countryCodesFetch(
      CountryCodesFetch event, Emitter<AuthState> emit) async {
    final res = await _countryCodes(NoParams(), null);
    res.fold(
        (failure) => emit(
            state.copyWith(countryCodesStatus: CountryCodesStatus.failure)),
        (countryCodes) {
      emit(state.copyWith(
          countryCodesStatus: CountryCodesStatus.success, codes: countryCodes));
    });
  }

  void _authSmsSendFetch(AuthSmsSend event, Emitter<AuthState> emit) async {
    final res = await _smsAuth(
        SmsAuthParams(code: event.code, phone: event.phone, sms: event.sms),
        null);
    // Переменные для промокода - объявляем вне блока
    String? appliedPromoCode;
    bool promoCodeAppliedSuccessfully = false;
    bool promoCodeAlreadyUsed = false;
    
    await res.fold(
        (failure) async => emit(state.copyWith(
            status: AuthStatus.failure,
            message: failure.message)), (userInfo) async {
      if (userInfo.user != null) {
        await UserDataManager.saveToken(userInfo.token);
        await UserDataManager.saveUser(userInfo.user!);
        
        // ✅ Проверяем и применяем промокод при авторизации
        // Применяем только если у пользователя еще не был применен промокод
        final user = userInfo.user!;
        final hasUsedPromoCode = user.userPromoCode != null && user.userPromoCode! > 0;
        
        // Получаем сохраненный промокод
        final savedPromoCode = await UserDataManager.getPromoCode();
        
        if (!hasUsedPromoCode) {
          if (savedPromoCode != null && savedPromoCode.isNotEmpty) {
            appliedPromoCode = savedPromoCode;
            debugPrint('💎 Applying saved promo code during login: $savedPromoCode');
            
            // Применяем промокод
            final resPromo = await _postPromoCode(
                PostPromoCodeParams(promoCode: savedPromoCode), null);
            
            resPromo.fold((promoFailure) {
              debugPrint('⚠️ Promo code error during login: ${promoFailure.message}');
              promoCodeAppliedSuccessfully = false;
            }, (promoSuccess) {
              debugPrint('✅ Promo code applied successfully during login');
              promoCodeAppliedSuccessfully = true;
              // ✅ Очищаем сохраненный промокод после успешного применения
              UserDataManager.clearPromoCode();
            });
          }
        } else {
          debugPrint('ℹ️ User already has used promo code, skipping application');
          // Если был сохранённый промокод, значит пользователь пытался его применить
          if (savedPromoCode != null && savedPromoCode.isNotEmpty) {
            promoCodeAlreadyUsed = true;
          }
          // Очищаем сохраненный промокод даже если он не был применен
          // (чтобы не пытаться применять его снова)
          await UserDataManager.clearPromoCode();
        }
      }

      emit(state.copyWith(
          status: AuthStatus.success,
          authAnswerUserInfo: userInfo,
          appliedPromoCode: appliedPromoCode,
          promoCodeAppliedSuccessfully: promoCodeAppliedSuccessfully,
          promoCodeAlreadyUsed: promoCodeAlreadyUsed));
    });
  }

  /// Отправка кода для регистрации
  void _sendVerifyCodeFetch(
      AuthSendVerifyCode event, Emitter<AuthState> emit) async {
    emit(state.copyWith(verifyCodeStatus: VerifyCodeStatus.loading));

    final res = await _sendVerifyCode(
        SendVerifyCodeParams(phone: event.phone, countryCode: event.code),
        null);
    res.fold((failure) {
      emit(state.copyWith(
          verifyCodeStatus: VerifyCodeStatus.failure,
          message: failure.message,
          userExists: null));
    }, (response) {
      emit(state.copyWith(
          verifyCodeStatus: VerifyCodeStatus.success,
          message: response.message,
          userExists: response.userExists));
    });
  }

  /// Отправка кода для входа
  void _loginSendCodeFetch(
      AuthLoginSendCode event, Emitter<AuthState> emit) async {
    emit(state.copyWith(verifyCodeStatus: VerifyCodeStatus.loading));

    final res = await _loginSendCode(
        SendVerifyCodeParams(phone: event.phone, countryCode: event.code),
        null);
    res.fold((failure) {
      emit(state.copyWith(
          verifyCodeStatus: VerifyCodeStatus.failure,
          message: failure.message,
          userExists: null));
    }, (response) {
      emit(state.copyWith(
          verifyCodeStatus: VerifyCodeStatus.success,
          message: response.message,
          userExists: response.userExists));
    });
  }

  void _cityNamesFetch(CityNamesFetch event, Emitter<AuthState> emit) async {
    final res = await _cityNames(NoParams(), null);
    res.fold(
        (failure) =>
            emit(state.copyWith(cityNamesStatus: CityNamesStatus.failure)),
        (cityNames) {
      emit(state.copyWith(
          cityNamesStatus: CityNamesStatus.success, cityNames: cityNames));
    });
  }
}

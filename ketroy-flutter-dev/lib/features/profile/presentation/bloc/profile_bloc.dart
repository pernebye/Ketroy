import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/auth/domain/entities/user_entity.dart';
import 'package:ketroy_app/features/profile/data/promotion_model.dart';
import 'package:ketroy_app/features/profile/domain/entities/city_entity.dart';
import 'package:ketroy_app/features/profile/domain/entities/discount_entity.dart';
import 'package:ketroy_app/features/profile/domain/entities/scan_entity.dart';
import 'package:ketroy_app/features/profile/domain/usecase/delete_user.dart';
import 'package:ketroy_app/features/profile/domain/usecase/get_city.dart';
import 'package:ketroy_app/features/profile/domain/usecase/get_discount.dart';
import 'package:ketroy_app/features/profile/domain/usecase/get_profile_user.dart';
import 'package:ketroy_app/features/profile/domain/usecase/get_promotions.dart';
import 'package:ketroy_app/features/profile/domain/usecase/log_out.dart';
import 'package:ketroy_app/features/profile/domain/usecase/scan_qr.dart';
import 'package:ketroy_app/features/profile/domain/usecase/update_user.dart';
import 'package:ketroy_app/features/profile/domain/usecase/upload_avatar.dart';
import 'package:ketroy_app/features/shop/domain/entities/shop_entity.dart';
import 'package:ketroy_app/features/shop/domain/usecases/get_shop_list.dart';
import 'package:ketroy_app/init_dependencies.dart';
import 'package:ketroy_app/services/local_storage/user_data_manager.dart';
import 'package:ketroy_app/services/shared_preferences_service.dart';

part 'profile_events.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileUpdateUser _profileUpdateUser;
  final GetProfileUser _getProfileUser;
  final GetDiscount _getDiscount;
  final ScanQr _scanQr;
  final LogOut _logOut;
  final DeleteUser _deleteUser;
  final GetCity _getCity;
  final UploadAvatar _uploadAvatar;
  final GetShopList _getShopList;
  final GetPromotions _getPromotions;
  
  ProfileBloc({
    required ProfileUpdateUser profileUpdateUser,
    required GetProfileUser getProfileUser,
    required GetDiscount getDiscount,
    required ScanQr scanQr,
    required LogOut logOut,
    required DeleteUser deleteUser,
    required GetCity getCity,
    required UploadAvatar uploadAvatar,
    required GetShopList getShopList,
    required GetPromotions getPromotions,
  })  : _profileUpdateUser = profileUpdateUser,
        _getProfileUser = getProfileUser,
        _getDiscount = getDiscount,
        _scanQr = scanQr,
        _logOut = logOut,
        _deleteUser = deleteUser,
        _getCity = getCity,
        _uploadAvatar = uploadAvatar,
        _getShopList = getShopList,
        _getPromotions = getPromotions,
        super(const ProfileState()) {
    on<LoadUserInfo>(_loadUserInfo);
    on<LoadDetailedUserInfo>(_loadDetailedUserInfo);
    on<ProfileUpdateFetch>(_profileUpdateFetch);
    on<UploadProfileImage>(_uploadProfileImage);
    on<ResetListener>(
      (event, emit) => emit(state.copyWith(updateStatus: UpdateStatus.initial)),
    );
    on<DeleteAllStorageFetch>(_deleteAllStorageFetch);
    on<GetProfileUserFetch>(_getProfileUserFetch);
    on<GetDiscountFetch>(_getDiscountFetch);
    on<ScanQrFetch>(_scanQrFetch);
    on<LogOutFetch>(_logOutFetch);
    on<DeleteUserFetch>(_deleteUserFetch);
    on<ResetProfileState>(_resetProfileState);
    on<GetCityListFetch>(_cityListFetch);
    on<LoadCityShop>(_loadCityShop);
    on<GetPromotionsFetch>(_getPromotionsFetch);
  }

  void _resetProfileState(ResetProfileState event, Emitter<ProfileState> emit) {
    emit(const ProfileState()); // Полностью сбрасываем состояние
  }

  void _uploadProfileImage(
      UploadProfileImage event, Emitter<ProfileState> emit) async {
    final returnedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (returnedImage != null) {
      // Показываем состояние загрузки
      emit(state.copyWith(isUploadingAvatar: true));
      
      // Загружаем изображение на сервер
      final result = await _uploadAvatar(
        UploadAvatarParams(filePath: returnedImage.path),
        null,
      );
      
      await result.fold(
        (failure) async {
          debugPrint('❌ Avatar upload failed: ${failure.message}');
          emit(state.copyWith(
            isUploadingAvatar: false,
            message: failure.message,
          ));
        },
        (avatarUrl) async {
          debugPrint('✅ Avatar uploaded successfully: $avatarUrl');
          
          // Обновляем данные пользователя с URL аватара с сервера
          final currentUser = await UserDataManager.getUser();
          if (currentUser != null) {
            final updatedUser = AuthUserEntity(
              id: currentUser.id,
              name: currentUser.name,
              phone: currentUser.phone,
              avatarImage: avatarUrl, // URL с сервера
              countryCode: currentUser.countryCode,
              city: currentUser.city,
              birthdate: currentUser.birthdate,
              height: currentUser.height,
              clothingSize: currentUser.clothingSize,
              shoeSize: currentUser.shoeSize,
              verificationCode: currentUser.verificationCode,
              codeExpires: currentUser.codeExpires,
              createdAt: currentUser.createdAt,
              updatedAt: DateTime.now(),
              deviceToken: currentUser.deviceToken,
              surname: currentUser.surname,
              discount: currentUser.discount,
              userPromoCode: currentUser.userPromoCode,
              referrerId: currentUser.referrerId,
              bonusAmount: currentUser.bonusAmount,
              promoCode: currentUser.promoCode,
            );

            await UserDataManager.saveUser(updatedUser);
          }

          emit(state.copyWith(
            avatarImage: avatarUrl,
            isUploadingAvatar: false,
          ));
        },
      );
    }
  }

  void _profileUpdateFetch(
      ProfileUpdateFetch event, Emitter<ProfileState> emit) async {
    final res = await _profileUpdateUser(
        ProfileUserParams(
            height: event.height,
            clothingSize: event.clothingSize,
            shoeSize: event.shoeSize,
            city: event.city,
            name: event.name,
            surname: event.surname,
            birthDay: event.birthDay),
        null);
    await res.fold((failure) {
      emit(state.copyWith(
          updateStatus: UpdateStatus.failure, message: failure.message));
    }, (message) async {
      // Обновляем данные пользователя локально
      final currentUser = await UserDataManager.getUser();
      if (currentUser != null) {
        final updatedUser = AuthUserEntity(
          id: currentUser.id,
          name: event.name,
          phone: currentUser.phone,
          avatarImage: currentUser.avatarImage,
          countryCode: currentUser.countryCode,
          city: event.city,
          birthdate: currentUser.birthdate,
          height: event.height,
          clothingSize: event.clothingSize,
          shoeSize: event.shoeSize,
          verificationCode: currentUser.verificationCode,
          codeExpires: currentUser.codeExpires,
          createdAt: currentUser.createdAt,
          updatedAt: DateTime.now(), // обновляем время
          deviceToken: currentUser.deviceToken,
          surname: event.surname,
          discount: currentUser.discount,
          userPromoCode: currentUser.userPromoCode,
          referrerId: currentUser.referrerId,
          bonusAmount: currentUser.bonusAmount,
          promoCode: currentUser.promoCode,
        );

        await UserDataManager.saveUser(updatedUser);
      }

      emit(state.copyWith(
          message: message,
          updateStatus: UpdateStatus.success,
          name: event.name,
          surname: event.surname,
          city: event.city,
          height: event.height,
          clotherSize: event.clothingSize,
          shoeSize: event.shoeSize));
    });
  }

  void _loadUserInfo(LoadUserInfo event, Emitter<ProfileState> emit) async {
    try {
      final user = await UserDataManager.getUser();
      final token = await UserDataManager.getToken();

      if (user != null && token != null) {
        emit(state.copyWith(
            avatarImage: user.avatarImage?.toString(),
            status: ProfileStatus.success,
            name: user.name,
            surname: user.surname,
            phoneNumber: user.phone,
            birthDay: user.birthdate, // или другой формат даты если нужен
            bonus: user.bonusAmount?.toString(),
            token: token,
            isCleaned: false));
      } else {
        // Пользователь не найден
        emit(state.copyWith(
          status: ProfileStatus.success,
          token: null, // ✅ Явно устанавливаем null
          name: null,
          surname: null,
          phoneNumber: null,
          birthDay: null,
          bonus: null,
          avatarImage: null,
          isCleaned: false,
        ));
      }
    } catch (e) {
      // Ошибка загрузки данных
      emit(state.copyWith(
          status: ProfileStatus.failure, isCleaned: false, token: null));
    }
  }

  void _loadDetailedUserInfo(
      LoadDetailedUserInfo event, Emitter<ProfileState> emit) async {
    try {
      final user = await UserDataManager.getUser();

      if (user != null) {
        emit(state.copyWith(
            profileDetailStatus: ProfileDetailedStatus.success,
            updateStatus: UpdateStatus.initial,
            city: user.city,
            height: user.height.isEmpty ? null : user.height,
            clotherSize: user.clothingSize?.toString().isEmpty == true
                ? null
                : user.clothingSize?.toString(),
            shoeSize: user.shoeSize.isEmpty ? null : user.shoeSize,
            avatarImage: user.avatarImage?.toString(),
            birthDay: user.birthdate,
            name: user.name,
            surname: user.surname,
            phoneNumber: user.phone,
            isCleaned: false)); // Сбрасываем isCleaned
      } else {
        emit(state.copyWith(
            profileDetailStatus: ProfileDetailedStatus.failure,
            isCleaned: false));
      }
    } catch (e) {
      emit(state.copyWith(
          profileDetailStatus: ProfileDetailedStatus.failure,
          isCleaned: false));
    }
  }

  void _getProfileUserFetch(
      GetProfileUserFetch event, Emitter<ProfileState> emit) async {
    final res = await _getProfileUser(NoParams(), null);

    await res.fold(
        (failure) async => emit(state.copyWith(
            status: ProfileStatus.failure,
            message: failure.message)), (userData) async {
      // Сохраняем обновленные данные пользователя
      await UserDataManager.saveUser(userData);

      emit(state.copyWith(
          profileData: userData,
          status: ProfileStatus.success,
          isCleaned: false)); // Сбрасываем isCleaned
    });
  }

  void _deleteAllStorageFetch(
      DeleteAllStorageFetch event, Emitter<ProfileState> emit) async {
    await UserDataManager.clearUserData();
    emit(state.copyWith(isCleaned: true));
  }

  void _getDiscountFetch(
      GetDiscountFetch event, Emitter<ProfileState> emit) async {
    // Получаем валидный QR токен (если не истёк)
    final token = await UserDataManager.getValidQrToken();
    
    if (token == null) {
      // Токен отсутствует или истёк
      emit(state.copyWith(discount: null));
      return;
    }
    
    final res = await _getDiscount(GetDiscountParams(token: token), null);

    res.fold((failure) {
      debugPrint('❌ GetDiscount failed: ${failure.message}');
      emit(state.copyWith(discount: null));
    }, (discount) {
      debugPrint('✅ Discount received: ${discount.discount}%');
      emit(state.copyWith(discount: discount));
    });
  }

  void _scanQrFetch(ScanQrFetch event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(qrStatus: QrStatus.loading));
    final res = await _scanQr(ScanQrParams(scanQrUrl: event.scanQrUrl), null);
    
    await res.fold(
      (failure) async {
        emit(state.copyWith(qrStatus: QrStatus.failure, message: failure.message));
      },
      (scan) async {
        // ✅ ВАЖНО: Сначала сохраняем токен, потом обновляем состояние
        // Это гарантирует, что токен будет доступен когда GetDiscountFetch вызывается
        await UserDataManager.saveQrToken(scan.token);
        emit(state.copyWith(scan: scan, qrStatus: QrStatus.success));
      },
    );
  }

  void _logOutFetch(LogOutFetch event, Emitter<ProfileState> emit) async {
    final res = await _logOut(NoParams(), null);
    // Очищаем все локальные данные
    await UserDataManager.clearUserData();
    
    // Сбрасываем флаг deviceTokenPassed чтобы при следующем входе
    // device_token был отправлен на сервер заново и активирован
    final sharedService = serviceLocator<SharedPreferencesService>();
    sharedService.deviceTokenPassed = false;

    res.fold(
        (failure) => emit(state.copyWith(
            message: failure.message,
            status: ProfileStatus.failure)), (message) {
      emit(const ProfileState(isCleaned: true));
    });
  }

  void _deleteUserFetch(
      DeleteUserFetch event, Emitter<ProfileState> emit) async {
    final res = await _deleteUser(NoParams(), null);
    await UserDataManager.clearUserData();
    
    // Сбрасываем флаг deviceTokenPassed
    final sharedService = serviceLocator<SharedPreferencesService>();
    sharedService.deviceTokenPassed = false;
    
    res.fold(
        (failure) => emit(state.copyWith(
            status: ProfileStatus.failure,
            message: failure.message)), (message) {
      emit(const ProfileState(isCleaned: true));
    });
  }

  void _cityListFetch(
      GetCityListFetch event, Emitter<ProfileState> emit) async {
    final res = await _getCity(NoParams(), null);
    res.fold((failure) => emit(state.copyWith(message: failure.message)),
        (cityList) {
      emit(state.copyWith(cityList: cityList));
    });
  }

  /// Загрузка магазина по городу пользователя для отображения соцсетей
  void _loadCityShop(LoadCityShop event, Emitter<ProfileState> emit) async {
    final user = await UserDataManager.getUser();
    final userCity = user?.city;

    if (userCity == null || userCity.isEmpty) {
      debugPrint('⚠️ User city is not set, cannot load city shop');
      return;
    }

    final res = await _getShopList(ShopParams(city: userCity), null);

    res.fold(
      (failure) {
        debugPrint('❌ Failed to load shops for city $userCity: ${failure.message}');
      },
      (shopList) {
        if (shopList.isNotEmpty) {
          // Берём первый магазин из города пользователя
          final shop = shopList.first;
          debugPrint('✅ Loaded shop for socials: ${shop.name} (${shop.city})');
          emit(state.copyWith(cityShop: shop));
        } else {
          debugPrint('⚠️ No shops found in city $userCity');
        }
      },
    );
  }

  /// Загрузка активных акций
  void _getPromotionsFetch(
      GetPromotionsFetch event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(promotionsStatus: PromotionsStatus.loading));

    final res = await _getPromotions(NoParams(), null);

    res.fold(
      (failure) {
        debugPrint('❌ Failed to load promotions: ${failure.message}');
        emit(state.copyWith(
          promotionsStatus: PromotionsStatus.failure,
          message: failure.message,
        ));
      },
      (promotions) {
        debugPrint('✅ Loaded ${promotions.length} promotions');
        emit(state.copyWith(
          promotions: promotions,
          promotionsStatus: PromotionsStatus.success,
        ));
      },
    );
  }
}

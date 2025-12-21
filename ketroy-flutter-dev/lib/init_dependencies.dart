import 'package:get_it/get_it.dart';
import 'package:ketroy_app/core/theme/theme.dart';
import 'package:ketroy_app/services/localization/localization_service.dart';
import 'package:ketroy_app/features/ai/data/data_sources/ai_data_source.dart';
import 'package:ketroy_app/features/ai/data/repository/ai_repository_impl.dart';
import 'package:ketroy_app/features/ai/domain/repository/ai_repository.dart';
import 'package:ketroy_app/features/ai/domain/use_cases/get_ai_response.dart';
import 'package:ketroy_app/features/ai/presentation/bloc/ai_bloc.dart';
import 'package:ketroy_app/features/auth/data/data_source/auth_api_service.dart';
import 'package:ketroy_app/features/auth/data/repository/auth_repository_impl.dart';
import 'package:ketroy_app/features/auth/domain/repository/auth_repository.dart';
import 'package:ketroy_app/features/auth/domain/use_cases/city_names.dart';
import 'package:ketroy_app/features/auth/domain/use_cases/country_codes.dart';
import 'package:ketroy_app/features/auth/domain/use_cases/send_verify_code.dart';
import 'package:ketroy_app/features/auth/domain/use_cases/sign_up_with_phone.dart';
import 'package:ketroy_app/features/auth/domain/use_cases/sms_auth.dart';
import 'package:ketroy_app/features/auth/domain/use_cases/update_user.dart';
import 'package:ketroy_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ketroy_app/features/certificates/presentation/bloc/certificate_bloc.dart';
import 'package:ketroy_app/features/discount/data/data_source/discount_data_source.dart';
import 'package:ketroy_app/features/discount/data/repository/discount_repository_impl.dart';
import 'package:ketroy_app/features/discount/domain/repository/discount_repository.dart';
import 'package:ketroy_app/features/discount/domain/use_cases/post_promo_code.dart';
import 'package:ketroy_app/features/discount/presentation/bloc/discount_bloc.dart';
import 'package:ketroy_app/features/my_gifts/data/data_source/gift_data_source.dart';
import 'package:ketroy_app/features/my_gifts/data/repository/gifts_repository_impl.dart';
import 'package:ketroy_app/features/my_gifts/domain/repository/gifts_repository.dart';
import 'package:ketroy_app/features/my_gifts/domain/use_cases/activate_gift.dart';
import 'package:ketroy_app/features/my_gifts/domain/use_cases/get_gifts_list.dart';
import 'package:ketroy_app/features/my_gifts/domain/use_cases/save_gift.dart';
import 'package:ketroy_app/features/my_gifts/presentation/bloc/gifts_bloc.dart';
import 'package:ketroy_app/features/news/data/data_source/news_data_source.dart';
import 'package:ketroy_app/features/news/data/repository/news_repository_impl.dart';
import 'package:ketroy_app/features/news/domain/repository/news_repository.dart';
import 'package:ketroy_app/features/news/domain/usecases/get_actuals.dart';
import 'package:ketroy_app/features/news/domain/usecases/get_banners_list.dart';
import 'package:ketroy_app/features/news/domain/usecases/get_categories.dart';
import 'package:ketroy_app/features/news/domain/usecases/get_news_list.dart';
import 'package:ketroy_app/features/news/domain/usecases/get_news_list_by_id.dart';
import 'package:ketroy_app/features/news/domain/usecases/post_device_token.dart';
import 'package:ketroy_app/features/news/presentation/bloc/news_bloc.dart';
import 'package:ketroy_app/features/notification/data/data_source/notification_data_source.dart';
import 'package:ketroy_app/features/notification/data/repository/notification_repository_impl.dart';
import 'package:ketroy_app/features/notification/domain/repository/notification_repository.dart';
import 'package:ketroy_app/features/notification/domain/usecases/delete_notifications.dart';
import 'package:ketroy_app/features/notification/domain/usecases/get_notification.dart';
import 'package:ketroy_app/features/notification/domain/usecases/mark_all_read.dart';
import 'package:ketroy_app/features/notification/domain/usecases/notification_read.dart';
import 'package:ketroy_app/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:ketroy_app/features/partners/data/data_source/partners_data_source.dart';
import 'package:ketroy_app/features/partners/data/repository/partners_repository_impl.dart';
import 'package:ketroy_app/features/partners/domain/repository/partners_repository.dart';
import 'package:ketroy_app/features/partners/domain/use_cases/get_amount.dart';
import 'package:ketroy_app/features/partners/presentation/bloc/partners_bloc.dart';
import 'package:ketroy_app/features/profile/data/data_source/profile_data_source.dart';
import 'package:ketroy_app/features/profile/data/repository/profile_repository_impl.dart';
import 'package:ketroy_app/features/profile/domain/repository/profile_repository.dart';
import 'package:ketroy_app/features/profile/domain/usecase/delete_user.dart';
import 'package:ketroy_app/features/profile/domain/usecase/get_city.dart';
import 'package:ketroy_app/features/profile/domain/usecase/get_discount.dart';
import 'package:ketroy_app/features/profile/domain/usecase/get_profile_user.dart';
import 'package:ketroy_app/features/profile/domain/usecase/get_promotions.dart';
import 'package:ketroy_app/features/profile/domain/usecase/log_out.dart';
import 'package:ketroy_app/features/profile/domain/usecase/scan_qr.dart';
import 'package:ketroy_app/features/profile/domain/usecase/update_user.dart';
import 'package:ketroy_app/features/profile/domain/usecase/upload_avatar.dart';
import 'package:ketroy_app/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:ketroy_app/features/shop/data/data_source/shop_data_source.dart';
import 'package:ketroy_app/features/shop/data/repository/shop_repository_impl.dart';
import 'package:ketroy_app/features/shop/domain/repository/shop_repository.dart';
import 'package:ketroy_app/features/shop/domain/usecases/get_city_list.dart';
import 'package:ketroy_app/features/shop/domain/usecases/get_shop_list.dart';
import 'package:ketroy_app/features/shop/presentation/bloc/shop_bloc.dart';
import 'package:ketroy_app/features/shop_detail/data/data_source/shop_detail_data_sources.dart';
import 'package:ketroy_app/features/shop_detail/data/repositories/shop_detail_repository_impl.dart';
import 'package:ketroy_app/features/shop_detail/domain/repositories/shop_detail_repository.dart';
import 'package:ketroy_app/features/shop_detail/domain/usecases/get_shop_review.dart';
import 'package:ketroy_app/features/shop_detail/domain/usecases/send_shop_review.dart';
import 'package:ketroy_app/features/shop_detail/presentation/bloc/shop_detail_bloc.dart';
import 'package:ketroy_app/services/shared_preferences_service.dart';
import 'package:ketroy_app/features/loyalty/data/data_source/loyalty_data_source.dart';
import 'package:ketroy_app/features/loyalty/data/repository/loyalty_repository_impl.dart';
import 'package:ketroy_app/features/loyalty/domain/repository/loyalty_repository.dart';
import 'package:ketroy_app/features/loyalty/domain/usecases/get_loyalty_info.dart';
import 'package:ketroy_app/features/loyalty/domain/usecases/get_unviewed_achievements.dart';
import 'package:ketroy_app/features/loyalty/domain/usecases/mark_levels_viewed.dart';
import 'package:ketroy_app/features/loyalty/presentation/bloc/loyalty_bloc.dart';

final serviceLocator = GetIt.instance;

Future<void> initDependencies() async {
  final sharedPreferencesService = await SharedPreferencesService.getInstance();
  serviceLocator.registerSingleton(sharedPreferencesService);

  // Initialize fonts for Kazakh character support
  await AppTheme.initFonts();

  // Initialize Localization Service
  final localizationService = LocalizationService();
  await localizationService.initialize();
  serviceLocator.registerSingleton(localizationService);

  initAuth();
  initNewsPage();
  initProfile();
  initShop();
  initReview();
  initCertificate();
  initDiscount();
  initGifts();
  initPartners();
  initNotification();
  initAi();
  initLoyalty();
}

void initAuth() {
  // DataSource
  serviceLocator
    ..registerFactory<AuthApiService>(() => AuthApiServiceImpl())
    // Repository
    ..registerFactory<AuthRepository>(
        () => AuthRepositoryImpl(serviceLocator()))
    // UseCase
    ..registerFactory(() => SendVerifyCode(serviceLocator()))
    ..registerFactory(() => LoginSendCode(serviceLocator()))
    ..registerFactory(() => SignUpWithPhone(serviceLocator()))
    ..registerFactory(() => SmsAuth(serviceLocator()))
    ..registerFactory(() => CountryCodes(serviceLocator()))
    ..registerFactory(() => CityNames(serviceLocator()))
    ..registerFactory(() => UpdateUser(serviceLocator()))

    // Bloc
    ..registerLazySingleton(() => AuthBloc(
        sendVerifyCode: serviceLocator(),
        loginSendCode: serviceLocator(),
        smsAuth: serviceLocator(),
        countryCodes: serviceLocator(),
        signUpWithPhone: serviceLocator(),
        cityNames: serviceLocator(),
        updateUser: serviceLocator(),
        postPromoCode: serviceLocator()));
}

void initNewsPage() {
  //DataSource
  serviceLocator
    ..registerFactory<NewsDataSource>(() => NewsDataSourceImpl())
    //Repository
    ..registerFactory<NewsRepository>(
        () => NewsRepositoryImpl(serviceLocator()))
    //UseCase
    ..registerFactory(() => GetBannersList(serviceLocator()))
    ..registerFactory(() => GetNewsList(serviceLocator()))
    ..registerFactory(() => GetCategories(serviceLocator()))
    ..registerFactory(() => GetActuals(serviceLocator()))
    ..registerFactory(() => PostDeviceToken(newsRepository: serviceLocator()))
    ..registerFactory(() => GetNewsListById(serviceLocator()))
    //Bloc
    ..registerLazySingleton(() => NewsBloc(
        getBannersList: serviceLocator(),
        getNewsList: serviceLocator(),
        getCategories: serviceLocator(),
        getActuals: serviceLocator(),
        postDeviceToken: serviceLocator(),
        getNewsListById: serviceLocator()));
}

void initProfile() {
  //DataSource
  serviceLocator
    ..registerFactory<ProfileDataSource>(() => ProfileDataSourceImpl())
//Repository
    ..registerFactory<ProfileRepository>(
        () => ProfileRepositoryImpl(serviceLocator()))
//Usecase
    ..registerFactory(() => ProfileUpdateUser(serviceLocator()))
    ..registerFactory(() => GetProfileUser(serviceLocator()))
    ..registerFactory(() => GetDiscount(profileRepository: serviceLocator()))
    ..registerFactory(() => ScanQr(profileRepository: serviceLocator()))
    ..registerFactory(() => LogOut(profileRepository: serviceLocator()))
    ..registerFactory(() => DeleteUser(profileRepository: serviceLocator()))
    ..registerFactory(() => GetCity(serviceLocator()))
    ..registerFactory(() => UploadAvatar(serviceLocator()))
    ..registerFactory(() => GetPromotions(serviceLocator()))
//Bloc
    ..registerLazySingleton(() => ProfileBloc(
        getDiscount: serviceLocator(),
        profileUpdateUser: serviceLocator(),
        getProfileUser: serviceLocator(),
        scanQr: serviceLocator(),
        deleteUser: serviceLocator(),
        logOut: serviceLocator(),
        getCity: serviceLocator(),
        uploadAvatar: serviceLocator(),
        getShopList: serviceLocator(),
        getPromotions: serviceLocator()));
}

void initShop() {
  //DataSource
  serviceLocator
    ..registerFactory<ShopDataSource>(() => ShopDataSourceImpl())
    //Repository
    ..registerFactory<ShopRepository>(
        () => ShopRepositoryImpl(serviceLocator()))
    //UseCase
    ..registerFactory(() => GetShopList(serviceLocator()))
    ..registerFactory(() => GetCityList(serviceLocator()))
    //Bloc
    ..registerLazySingleton(() =>
        ShopBloc(getShopList: serviceLocator(), getCityList: serviceLocator()));
}

void initReview() {
  //DataSource
  serviceLocator
    ..registerFactory<ShopDetailDataSources>(() => ShopDetailDataSourcesImpl())
    //Repository
    ..registerFactory<ShopDetailRepository>(
        () => ShopDetailRepositoryImpl(serviceLocator()))
    //UseCase
    ..registerFactory(() => GetShopReview(serviceLocator()))
    ..registerFactory(() => SendShopReview(serviceLocator()))
    //Bloc
    ..registerLazySingleton(() => ShopDetailBloc(
        getShopReview: serviceLocator(), sendShopReview: serviceLocator()));
}

void initCertificate() {
  //Bloc
  serviceLocator.registerLazySingleton(() => CertificateBloc());
}

void initDiscount() {
  //DataSource
  serviceLocator
    ..registerFactory<DiscountDataSource>(() => DiscountDataSourceImpl())
    //Repository
    ..registerFactory<DiscountRepository>(
        () => DiscountRepositoryImpl(discountDataSource: serviceLocator()))
    //Usecase
    ..registerFactory(() => PostPromoCode(discountRepository: serviceLocator()))
    //Bloc
    ..registerLazySingleton(
        () => DiscountBloc(
              postPromoCode: serviceLocator(),
              discountRepository: serviceLocator(),
            ));
}

void initGifts() {
  //DataSource
  serviceLocator
    ..registerFactory<GiftDataSource>(() => GiftDataSourceImpl())
    //Repository
    ..registerFactory<GiftsRepository>(
        () => GiftsRepositoryImpl(giftDataSource: serviceLocator()))
    //UseCase
    ..registerFactory(() => GetGiftsList(giftsRepository: serviceLocator()))
    ..registerFactory(() => ActivateGift(giftsRepository: serviceLocator()))
    ..registerFactory(() => SaveGift(giftsRepository: serviceLocator()))
    //Bloc
    ..registerLazySingleton(() => GiftsBloc(
        getGiftsList: serviceLocator(),
        activateGift: serviceLocator(),
        saveGift: serviceLocator()));
}

void initPartners() {
  //Datasource
  serviceLocator
    ..registerFactory<PartnersDataSource>(() => PartnersDataSourceImpl())
    //Repository
    ..registerFactory<PartnersRepository>(
        () => PartnersRepositoryImpl(partnersDataSource: serviceLocator()))
    //UseCase
    ..registerFactory(() => GetAmount(partnersRepository: serviceLocator()))
    //Bloc
    ..registerLazySingleton(() => PartnersBloc(getAmount: serviceLocator()));
}

void initNotification() {
  //DataSource
  serviceLocator
    ..registerFactory<NotificationDataSource>(
        () => NotificationDataSourceImpl())
    //Repository
    ..registerFactory<NotificationRepository>(() =>
        NotificationRepositoryImpl(notificationDataSource: serviceLocator()))
    //UseCase
    ..registerFactory(
        () => GetNotification(notificationRepository: serviceLocator()))
    ..registerFactory(
        () => NotificationRead(notificationRepository: serviceLocator()))
    ..registerFactory(() => DeleteNotifications(serviceLocator()))
    ..registerFactory(
        () => MarkAllRead(notificationRepository: serviceLocator()))
    //Bloc
    ..registerLazySingleton(() => NotificationBloc(
        getNotification: serviceLocator(),
        notificationRead: serviceLocator(),
        deleteNotifications: serviceLocator(),
        markAllRead: serviceLocator()));
}

void initAi() {
  //DataSource
  serviceLocator
    ..registerFactory<AiDataSource>(() => AiDataSourceImpl())
    //Repository
    ..registerFactory<AiRepository>(
        () => AiRepositoryImpl(aiDataSource: serviceLocator()))
    //Usecase
    ..registerFactory(() => GetAiResponse(aiRepository: serviceLocator()))
    //bloc
    ..registerLazySingleton(() => AiBloc(
          getAiResponse: serviceLocator(),
          aiDataSource: serviceLocator(),
        ));
}

void initLoyalty() {
  // DataSource
  serviceLocator
    ..registerFactory<LoyaltyDataSource>(() => LoyaltyDataSourceImpl())
    // Repository
    ..registerFactory<LoyaltyRepository>(
        () => LoyaltyRepositoryImpl(loyaltyDataSource: serviceLocator()))
    // UseCases
    ..registerFactory(
        () => GetLoyaltyInfo(loyaltyRepository: serviceLocator()))
    ..registerFactory(
        () => GetUnviewedAchievements(loyaltyRepository: serviceLocator()))
    ..registerFactory(
        () => MarkLevelsViewed(loyaltyRepository: serviceLocator()))
    // Bloc
    ..registerLazySingleton(() => LoyaltyBloc(
          getLoyaltyInfo: serviceLocator(),
          getUnviewedAchievements: serviceLocator(),
          markLevelsViewed: serviceLocator(),
        ));
}


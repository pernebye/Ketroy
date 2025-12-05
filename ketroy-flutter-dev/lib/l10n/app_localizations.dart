import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_kk.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('kk'),
    Locale('ru'),
    Locale('tr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In ru, this message translates to:
  /// **'Ketroy'**
  String get appTitle;

  /// No description provided for @profile.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get profile;

  /// No description provided for @account.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт'**
  String get account;

  /// No description provided for @bonuses.
  ///
  /// In ru, this message translates to:
  /// **'Бонусы'**
  String get bonuses;

  /// No description provided for @user.
  ///
  /// In ru, this message translates to:
  /// **'Пользователь'**
  String get user;

  /// No description provided for @welcome.
  ///
  /// In ru, this message translates to:
  /// **'Добро пожаловать'**
  String get welcome;

  /// No description provided for @loginForFullAccess.
  ///
  /// In ru, this message translates to:
  /// **'Войдите для доступа ко всем функциям'**
  String get loginForFullAccess;

  /// No description provided for @profileSettings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки профиля'**
  String get profileSettings;

  /// No description provided for @shops.
  ///
  /// In ru, this message translates to:
  /// **'Магазины'**
  String get shops;

  /// No description provided for @myGifts.
  ///
  /// In ru, this message translates to:
  /// **'Мои подарки'**
  String get myGifts;

  /// No description provided for @bonusProgram.
  ///
  /// In ru, this message translates to:
  /// **'Бонусная программа'**
  String get bonusProgram;

  /// No description provided for @shareDiscount.
  ///
  /// In ru, this message translates to:
  /// **'Подари скидку другу'**
  String get shareDiscount;

  /// No description provided for @notificationSettings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки уведомлений'**
  String get notificationSettings;

  /// No description provided for @settings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get language;

  /// No description provided for @languageSettings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки языка'**
  String get languageSettings;

  /// No description provided for @systemLanguage.
  ///
  /// In ru, this message translates to:
  /// **'Системный язык'**
  String get systemLanguage;

  /// No description provided for @selectLanguage.
  ///
  /// In ru, this message translates to:
  /// **'Выберите язык'**
  String get selectLanguage;

  /// No description provided for @russian.
  ///
  /// In ru, this message translates to:
  /// **'Русский'**
  String get russian;

  /// No description provided for @kazakh.
  ///
  /// In ru, this message translates to:
  /// **'Қазақша'**
  String get kazakh;

  /// No description provided for @english.
  ///
  /// In ru, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @turkish.
  ///
  /// In ru, this message translates to:
  /// **'Türkçe'**
  String get turkish;

  /// No description provided for @notifications.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get notifications;

  /// No description provided for @pushNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Push-уведомления'**
  String get pushNotifications;

  /// No description provided for @managePushNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Управление push-уведомлениями'**
  String get managePushNotifications;

  /// No description provided for @allNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Все уведомления'**
  String get allNotifications;

  /// No description provided for @enabled.
  ///
  /// In ru, this message translates to:
  /// **'Включены'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In ru, this message translates to:
  /// **'Выключены'**
  String get disabled;

  /// No description provided for @notificationCategories.
  ///
  /// In ru, this message translates to:
  /// **'Категории уведомлений'**
  String get notificationCategories;

  /// No description provided for @newsAndPromotions.
  ///
  /// In ru, this message translates to:
  /// **'Новости и акции'**
  String get newsAndPromotions;

  /// No description provided for @newsDescription.
  ///
  /// In ru, this message translates to:
  /// **'Новые коллекции, скидки, события'**
  String get newsDescription;

  /// No description provided for @gifts.
  ///
  /// In ru, this message translates to:
  /// **'Подарки'**
  String get gifts;

  /// No description provided for @giftsDescription.
  ///
  /// In ru, this message translates to:
  /// **'Новые подарки и промокоды'**
  String get giftsDescription;

  /// No description provided for @discounts.
  ///
  /// In ru, this message translates to:
  /// **'Скидки'**
  String get discounts;

  /// No description provided for @discountsDescription.
  ///
  /// In ru, this message translates to:
  /// **'Персональные скидки и предложения'**
  String get discountsDescription;

  /// No description provided for @bonusNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Бонусы'**
  String get bonusNotifications;

  /// No description provided for @bonusDescription.
  ///
  /// In ru, this message translates to:
  /// **'Начисление и списание бонусов'**
  String get bonusDescription;

  /// No description provided for @systemNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Системные'**
  String get systemNotifications;

  /// No description provided for @systemDescription.
  ///
  /// In ru, this message translates to:
  /// **'Важные уведомления от приложения'**
  String get systemDescription;

  /// No description provided for @notificationSettingsHint.
  ///
  /// In ru, this message translates to:
  /// **'Вы всегда можете изменить настройки уведомлений в системных настройках устройства'**
  String get notificationSettingsHint;

  /// No description provided for @authRequired.
  ///
  /// In ru, this message translates to:
  /// **'Требуется авторизация'**
  String get authRequired;

  /// No description provided for @authRequiredMessage.
  ///
  /// In ru, this message translates to:
  /// **'Чтобы узнать информацию о себе, скидках, подарках и других бонусах — необходимо пройти регистрацию!'**
  String get authRequiredMessage;

  /// No description provided for @authRequiredQr.
  ///
  /// In ru, this message translates to:
  /// **'Для сканирования QR-кода и получения бонусов необходимо войти в аккаунт.'**
  String get authRequiredQr;

  /// No description provided for @authRequiredNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Для просмотра уведомлений необходимо войти в аккаунт.'**
  String get authRequiredNotifications;

  /// No description provided for @loginToAccount.
  ///
  /// In ru, this message translates to:
  /// **'Войти в аккаунт'**
  String get loginToAccount;

  /// No description provided for @cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get cancel;

  /// No description provided for @startUsing.
  ///
  /// In ru, this message translates to:
  /// **'С чего хотите начать\nиспользование приложения?'**
  String get startUsing;

  /// No description provided for @register.
  ///
  /// In ru, this message translates to:
  /// **'Зарегистрироваться'**
  String get register;

  /// No description provided for @browseAsGuest.
  ///
  /// In ru, this message translates to:
  /// **'Ознакомиться как гость'**
  String get browseAsGuest;

  /// No description provided for @welcomeBack.
  ///
  /// In ru, this message translates to:
  /// **'Добро пожаловать!'**
  String get welcomeBack;

  /// No description provided for @joinPrivilegeClub.
  ///
  /// In ru, this message translates to:
  /// **'Войти в клуб привилегий'**
  String get joinPrivilegeClub;

  /// No description provided for @enterPrivateClub.
  ///
  /// In ru, this message translates to:
  /// **'Войти в закрытый клуб'**
  String get enterPrivateClub;

  /// No description provided for @noAccount.
  ///
  /// In ru, this message translates to:
  /// **'У вас нет аккаунта?'**
  String get noAccount;

  /// No description provided for @signUp.
  ///
  /// In ru, this message translates to:
  /// **'Зарегистрироваться'**
  String get signUp;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In ru, this message translates to:
  /// **'Введите номер телефона'**
  String get enterPhoneNumber;

  /// No description provided for @phoneNumberTooShort.
  ///
  /// In ru, this message translates to:
  /// **'Номер телефона слишком короткий'**
  String get phoneNumberTooShort;

  /// No description provided for @accountNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт не найден. Пожалуйста, зарегистрируйтесь.'**
  String get accountNotFound;

  /// No description provided for @codeSendError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка отправки кода'**
  String get codeSendError;

  /// No description provided for @unknownError.
  ///
  /// In ru, this message translates to:
  /// **'Неизвестная ошибка'**
  String get unknownError;

  /// No description provided for @dataLoadError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка загрузки данных'**
  String get dataLoadError;

  /// No description provided for @retry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get retry;

  /// No description provided for @showcase.
  ///
  /// In ru, this message translates to:
  /// **'Витрина'**
  String get showcase;

  /// No description provided for @ai.
  ///
  /// In ru, this message translates to:
  /// **'AI'**
  String get ai;

  /// No description provided for @giftsTab.
  ///
  /// In ru, this message translates to:
  /// **'Подарки'**
  String get giftsTab;

  /// No description provided for @logoutFromAccount.
  ///
  /// In ru, this message translates to:
  /// **'Выйти с аккаунта'**
  String get logoutFromAccount;

  /// No description provided for @deleteAccount.
  ///
  /// In ru, this message translates to:
  /// **'Удалить аккаунт'**
  String get deleteAccount;

  /// No description provided for @logoutConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Выйти с аккаунта?'**
  String get logoutConfirm;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Удалить аккаунт?'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In ru, this message translates to:
  /// **'Удаляя аккаунт, вы теряете доступ ко всем персональным данным, включая бонусы и специальные предложения. Повторная регистрация останется доступной в любой момент.'**
  String get deleteAccountWarning;

  /// No description provided for @yes.
  ///
  /// In ru, this message translates to:
  /// **'Да'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In ru, this message translates to:
  /// **'Нет'**
  String get no;

  /// No description provided for @delete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get delete;

  /// No description provided for @personalData.
  ///
  /// In ru, this message translates to:
  /// **'Личные данные'**
  String get personalData;

  /// No description provided for @surname.
  ///
  /// In ru, this message translates to:
  /// **'Фамилия'**
  String get surname;

  /// No description provided for @name.
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get name;

  /// No description provided for @birthDate.
  ///
  /// In ru, this message translates to:
  /// **'Дата рождения'**
  String get birthDate;

  /// No description provided for @selectDate.
  ///
  /// In ru, this message translates to:
  /// **'Выберите дату'**
  String get selectDate;

  /// No description provided for @city.
  ///
  /// In ru, this message translates to:
  /// **'Город'**
  String get city;

  /// No description provided for @selectCity.
  ///
  /// In ru, this message translates to:
  /// **'Выберите город'**
  String get selectCity;

  /// No description provided for @sizes.
  ///
  /// In ru, this message translates to:
  /// **'Размеры'**
  String get sizes;

  /// No description provided for @height.
  ///
  /// In ru, this message translates to:
  /// **'Рост'**
  String get height;

  /// No description provided for @clothingSize.
  ///
  /// In ru, this message translates to:
  /// **'Размер одежды'**
  String get clothingSize;

  /// No description provided for @shoeSize.
  ///
  /// In ru, this message translates to:
  /// **'Размер обуви'**
  String get shoeSize;

  /// No description provided for @saveChanges.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить изменения'**
  String get saveChanges;

  /// No description provided for @done.
  ///
  /// In ru, this message translates to:
  /// **'Готово'**
  String get done;

  /// No description provided for @allCities.
  ///
  /// In ru, this message translates to:
  /// **'Все города'**
  String get allCities;

  /// No description provided for @ketroyStoreNetwork.
  ///
  /// In ru, this message translates to:
  /// **'Сеть магазинов KETROY'**
  String get ketroyStoreNetwork;

  /// No description provided for @moreDetails.
  ///
  /// In ru, this message translates to:
  /// **'Подробнее'**
  String get moreDetails;

  /// No description provided for @noShopsFound.
  ///
  /// In ru, this message translates to:
  /// **'Магазинов не найдено'**
  String get noShopsFound;

  /// No description provided for @noShopsInCity.
  ///
  /// In ru, this message translates to:
  /// **'В выбранном городе пока нет\nмагазинов KETROY'**
  String get noShopsInCity;

  /// No description provided for @yourSavedGifts.
  ///
  /// In ru, this message translates to:
  /// **'Ваши сохранённые подарки'**
  String get yourSavedGifts;

  /// No description provided for @noGiftsYet.
  ///
  /// In ru, this message translates to:
  /// **'У вас пока нет подарков'**
  String get noGiftsYet;

  /// No description provided for @saveGiftsHint.
  ///
  /// In ru, this message translates to:
  /// **'Сохраняйте подарки из витрины,\nчтобы активировать их в магазине'**
  String get saveGiftsHint;

  /// No description provided for @giftActivated.
  ///
  /// In ru, this message translates to:
  /// **'Подарок активирован!'**
  String get giftActivated;

  /// No description provided for @dontCloseWindow.
  ///
  /// In ru, this message translates to:
  /// **'Не закрывайте окно, пока не получите подарок в магазине.'**
  String get dontCloseWindow;

  /// No description provided for @activatedGift.
  ///
  /// In ru, this message translates to:
  /// **'Активированный подарок'**
  String get activatedGift;

  /// No description provided for @earnAndSave.
  ///
  /// In ru, this message translates to:
  /// **'Накапливайте и экономьте'**
  String get earnAndSave;

  /// No description provided for @newItems.
  ///
  /// In ru, this message translates to:
  /// **'НОВИНКИ'**
  String get newItems;

  /// No description provided for @bonusProgramTitle.
  ///
  /// In ru, this message translates to:
  /// **'Бонусная программа'**
  String get bonusProgramTitle;

  /// No description provided for @earnBonusesWithPurchase.
  ///
  /// In ru, this message translates to:
  /// **'Накапливайте бонусы с каждой покупкой'**
  String get earnBonusesWithPurchase;

  /// No description provided for @upTo.
  ///
  /// In ru, this message translates to:
  /// **'До 10%'**
  String get upTo;

  /// No description provided for @cashback.
  ///
  /// In ru, this message translates to:
  /// **'Кэшбэк'**
  String get cashback;

  /// No description provided for @forPurchases.
  ///
  /// In ru, this message translates to:
  /// **'За покупки'**
  String get forPurchases;

  /// No description provided for @vipStatus.
  ///
  /// In ru, this message translates to:
  /// **'VIP'**
  String get vipStatus;

  /// No description provided for @status.
  ///
  /// In ru, this message translates to:
  /// **'Статус'**
  String get status;

  /// No description provided for @january.
  ///
  /// In ru, this message translates to:
  /// **'Январь'**
  String get january;

  /// No description provided for @february.
  ///
  /// In ru, this message translates to:
  /// **'Февраль'**
  String get february;

  /// No description provided for @march.
  ///
  /// In ru, this message translates to:
  /// **'Март'**
  String get march;

  /// No description provided for @april.
  ///
  /// In ru, this message translates to:
  /// **'Апрель'**
  String get april;

  /// No description provided for @may.
  ///
  /// In ru, this message translates to:
  /// **'Май'**
  String get may;

  /// No description provided for @june.
  ///
  /// In ru, this message translates to:
  /// **'Июнь'**
  String get june;

  /// No description provided for @july.
  ///
  /// In ru, this message translates to:
  /// **'Июль'**
  String get july;

  /// No description provided for @august.
  ///
  /// In ru, this message translates to:
  /// **'Август'**
  String get august;

  /// No description provided for @september.
  ///
  /// In ru, this message translates to:
  /// **'Сентябрь'**
  String get september;

  /// No description provided for @october.
  ///
  /// In ru, this message translates to:
  /// **'Октябрь'**
  String get october;

  /// No description provided for @november.
  ///
  /// In ru, this message translates to:
  /// **'Ноябрь'**
  String get november;

  /// No description provided for @december.
  ///
  /// In ru, this message translates to:
  /// **'Декабрь'**
  String get december;

  /// No description provided for @writeReview.
  ///
  /// In ru, this message translates to:
  /// **'Написать отзыв'**
  String get writeReview;

  /// No description provided for @shareYourExperience.
  ///
  /// In ru, this message translates to:
  /// **'Поделитесь впечатлениями о магазине'**
  String get shareYourExperience;

  /// No description provided for @selectShop.
  ///
  /// In ru, this message translates to:
  /// **'Выберите магазин'**
  String get selectShop;

  /// No description provided for @rateShop.
  ///
  /// In ru, this message translates to:
  /// **'Оцените магазин'**
  String get rateShop;

  /// No description provided for @tapStarsToRate.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите на звёзды для оценки'**
  String get tapStarsToRate;

  /// No description provided for @ratingVeryBad.
  ///
  /// In ru, this message translates to:
  /// **'Очень плохо 😞'**
  String get ratingVeryBad;

  /// No description provided for @ratingBad.
  ///
  /// In ru, this message translates to:
  /// **'Плохо 😕'**
  String get ratingBad;

  /// No description provided for @ratingNormal.
  ///
  /// In ru, this message translates to:
  /// **'Нормально 😐'**
  String get ratingNormal;

  /// No description provided for @ratingGood.
  ///
  /// In ru, this message translates to:
  /// **'Хорошо 😊'**
  String get ratingGood;

  /// No description provided for @ratingExcellent.
  ///
  /// In ru, this message translates to:
  /// **'Отлично! 🤩'**
  String get ratingExcellent;

  /// No description provided for @reviewHint.
  ///
  /// In ru, this message translates to:
  /// **'Расскажите о вашем опыте посещения магазина...'**
  String get reviewHint;

  /// No description provided for @sendReview.
  ///
  /// In ru, this message translates to:
  /// **'Отправить отзыв'**
  String get sendReview;

  /// No description provided for @reviewSentSuccess.
  ///
  /// In ru, this message translates to:
  /// **'Отзыв успешно отправлен!'**
  String get reviewSentSuccess;

  /// No description provided for @reviewSentError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка отправки отзыва'**
  String get reviewSentError;

  /// No description provided for @discount.
  ///
  /// In ru, this message translates to:
  /// **'скидка'**
  String get discount;

  /// No description provided for @scanQr.
  ///
  /// In ru, this message translates to:
  /// **'Сканируй QR'**
  String get scanQr;

  /// No description provided for @tg.
  ///
  /// In ru, this message translates to:
  /// **'ТГ'**
  String get tg;

  /// No description provided for @requiredField.
  ///
  /// In ru, this message translates to:
  /// **'Обязательное поле'**
  String get requiredField;

  /// No description provided for @serverError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка сервера'**
  String get serverError;

  /// No description provided for @tokenExpired.
  ///
  /// In ru, this message translates to:
  /// **'Токен истёк. Необходимо войти заново.'**
  String get tokenExpired;

  /// No description provided for @menu.
  ///
  /// In ru, this message translates to:
  /// **'Меню'**
  String get menu;

  /// No description provided for @mainMenu.
  ///
  /// In ru, this message translates to:
  /// **'Главное меню'**
  String get mainMenu;

  /// No description provided for @forPartners.
  ///
  /// In ru, this message translates to:
  /// **'Для партнёров'**
  String get forPartners;

  /// No description provided for @weInSocials.
  ///
  /// In ru, this message translates to:
  /// **'Мы в соцсетях'**
  String get weInSocials;

  /// No description provided for @appInitError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка инициализации приложения'**
  String get appInitError;

  /// No description provided for @closeApp.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть приложение'**
  String get closeApp;

  /// No description provided for @expired.
  ///
  /// In ru, this message translates to:
  /// **'Истёк'**
  String get expired;

  /// No description provided for @critical.
  ///
  /// In ru, this message translates to:
  /// **'Критично'**
  String get critical;

  /// No description provided for @expiringSoon.
  ///
  /// In ru, this message translates to:
  /// **'Скоро истечёт'**
  String get expiringSoon;

  /// No description provided for @active.
  ///
  /// In ru, this message translates to:
  /// **'Активен'**
  String get active;

  /// No description provided for @activeGifts.
  ///
  /// In ru, this message translates to:
  /// **'Активные подарки'**
  String get activeGifts;

  /// No description provided for @savedGifts.
  ///
  /// In ru, this message translates to:
  /// **'Сохраненные подарки'**
  String get savedGifts;

  /// No description provided for @noSavedGifts.
  ///
  /// In ru, this message translates to:
  /// **'У вас нет сохраненных подарков'**
  String get noSavedGifts;

  /// No description provided for @giftsWillAppear.
  ///
  /// In ru, this message translates to:
  /// **'Подарки появятся здесь после получения'**
  String get giftsWillAppear;

  /// No description provided for @noActiveGifts.
  ///
  /// In ru, this message translates to:
  /// **'Нет активных подарков'**
  String get noActiveGifts;

  /// No description provided for @activateGiftToSee.
  ///
  /// In ru, this message translates to:
  /// **'Активируйте подарок, чтобы увидеть его здесь'**
  String get activateGiftToSee;

  /// No description provided for @updating.
  ///
  /// In ru, this message translates to:
  /// **'Обновляется...'**
  String get updating;

  /// No description provided for @update.
  ///
  /// In ru, this message translates to:
  /// **'Обновить'**
  String get update;

  /// No description provided for @updateError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка обновления'**
  String get updateError;

  /// No description provided for @youActivatedGift.
  ///
  /// In ru, this message translates to:
  /// **'Вы активировали подарок'**
  String get youActivatedGift;

  /// No description provided for @giftIsNearby.
  ///
  /// In ru, this message translates to:
  /// **'Подарок уже рядом! Не закрывайте окно, пока не получите его.'**
  String get giftIsNearby;

  /// No description provided for @activatedGiftNumber.
  ///
  /// In ru, this message translates to:
  /// **'Активированный подарок #{id}'**
  String activatedGiftNumber(String id);

  /// No description provided for @congratulations.
  ///
  /// In ru, this message translates to:
  /// **'Поздравляем!'**
  String get congratulations;

  /// No description provided for @giftActivatedLabel.
  ///
  /// In ru, this message translates to:
  /// **'Подарок активирован'**
  String get giftActivatedLabel;

  /// No description provided for @activate.
  ///
  /// In ru, this message translates to:
  /// **'Активировать'**
  String get activate;

  /// No description provided for @activateGiftQuestion.
  ///
  /// In ru, this message translates to:
  /// **'Активировать подарок?'**
  String get activateGiftQuestion;

  /// No description provided for @activateGiftWarning.
  ///
  /// In ru, this message translates to:
  /// **'Активируйте подарок только у кассы и заберите его в течение 10 минут. Если вы хотите забрать подарок позже, сохраните его в разделе «Мои подарки»'**
  String get activateGiftWarning;

  /// No description provided for @back.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get back;

  /// No description provided for @virtualAssistant.
  ///
  /// In ru, this message translates to:
  /// **'Виртуальный помощник'**
  String get virtualAssistant;

  /// No description provided for @aiGreeting.
  ///
  /// In ru, this message translates to:
  /// **'Привет! 👋 Я KETROY AI — ваш персональный помощник по уходу за одеждой.'**
  String get aiGreeting;

  /// No description provided for @aiInstructions.
  ///
  /// In ru, this message translates to:
  /// **'Сфотографируйте этикетку с одежды — и я расшифрую все символы и дам рекомендации по стирке, сушке и глажке! 📸'**
  String get aiInstructions;

  /// No description provided for @analysisResult.
  ///
  /// In ru, this message translates to:
  /// **'Результат анализа'**
  String get analysisResult;

  /// No description provided for @analyzing.
  ///
  /// In ru, this message translates to:
  /// **'Анализирую...'**
  String get analyzing;

  /// No description provided for @typeMessage.
  ///
  /// In ru, this message translates to:
  /// **'Напишите сообщение...'**
  String get typeMessage;

  /// No description provided for @takePhoto.
  ///
  /// In ru, this message translates to:
  /// **'Сделать фото'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать из галереи'**
  String get chooseFromGallery;

  /// No description provided for @pointCameraAtLabel.
  ///
  /// In ru, this message translates to:
  /// **'Наведите камеру на этикетку одежды'**
  String get pointCameraAtLabel;

  /// No description provided for @processing.
  ///
  /// In ru, this message translates to:
  /// **'Обработка...'**
  String get processing;

  /// No description provided for @scanLabel.
  ///
  /// In ru, this message translates to:
  /// **'Сканировать этикетку'**
  String get scanLabel;

  /// No description provided for @photoError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка при съемке фото'**
  String get photoError;

  /// No description provided for @errorOccurred.
  ///
  /// In ru, this message translates to:
  /// **'Произошла ошибка'**
  String get errorOccurred;

  /// No description provided for @aiAuthRequired.
  ///
  /// In ru, this message translates to:
  /// **'Для использования AI помощника необходимо войти в аккаунт!'**
  String get aiAuthRequired;

  /// No description provided for @sendCodeAgain.
  ///
  /// In ru, this message translates to:
  /// **'Отправить код повторно'**
  String get sendCodeAgain;

  /// No description provided for @photoLoadError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка при загрузке фото'**
  String get photoLoadError;

  /// No description provided for @imageSentForAnalysis.
  ///
  /// In ru, this message translates to:
  /// **'Изображение успешно отправлено на анализ!'**
  String get imageSentForAnalysis;

  /// No description provided for @sendError.
  ///
  /// In ru, this message translates to:
  /// **'Произошла ошибка при отправке'**
  String get sendError;

  /// No description provided for @retake.
  ///
  /// In ru, this message translates to:
  /// **'Переснять'**
  String get retake;

  /// No description provided for @send.
  ///
  /// In ru, this message translates to:
  /// **'Отправить'**
  String get send;

  /// No description provided for @photoPreview.
  ///
  /// In ru, this message translates to:
  /// **'Предпросмотр'**
  String get photoPreview;

  /// No description provided for @error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка'**
  String get error;

  /// No description provided for @allNotificationsMarkedRead.
  ///
  /// In ru, this message translates to:
  /// **'Все уведомления отмечены как прочитанные'**
  String get allNotificationsMarkedRead;

  /// No description provided for @yourPromocode.
  ///
  /// In ru, this message translates to:
  /// **'Ваш промокод'**
  String get yourPromocode;

  /// No description provided for @shareAndGetBonuses.
  ///
  /// In ru, this message translates to:
  /// **'Поделитесь и получайте бонусы'**
  String get shareAndGetBonuses;

  /// No description provided for @promocodeCopied.
  ///
  /// In ru, this message translates to:
  /// **'Промокод скопирован'**
  String get promocodeCopied;

  /// No description provided for @sharePromoDescription.
  ///
  /// In ru, this message translates to:
  /// **'Поделитесь промокодом с другом и получайте 2% с его первых трёх покупок.'**
  String get sharePromoDescription;

  /// No description provided for @share.
  ///
  /// In ru, this message translates to:
  /// **'Поделиться'**
  String get share;

  /// No description provided for @friendPromocode.
  ///
  /// In ru, this message translates to:
  /// **'Промокод друга'**
  String get friendPromocode;

  /// No description provided for @enterAndGetDiscount.
  ///
  /// In ru, this message translates to:
  /// **'Введите и получите скидку 10%'**
  String get enterAndGetDiscount;

  /// No description provided for @enterFriendPromocode.
  ///
  /// In ru, this message translates to:
  /// **'Введите промокод друга'**
  String get enterFriendPromocode;

  /// No description provided for @friendPromoDescription.
  ///
  /// In ru, this message translates to:
  /// **'Получите персональную скидку 10% и участвуйте в программе накопления.'**
  String get friendPromoDescription;

  /// No description provided for @apply.
  ///
  /// In ru, this message translates to:
  /// **'Применить'**
  String get apply;

  /// No description provided for @promocodeApplied.
  ///
  /// In ru, this message translates to:
  /// **'Промокод применён!'**
  String get promocodeApplied;

  /// No description provided for @promocodeAppliedDescription.
  ///
  /// In ru, this message translates to:
  /// **'Теперь у вас персональная скидка 10% на покупки в магазинах KETROY.'**
  String get promocodeAppliedDescription;

  /// No description provided for @great.
  ///
  /// In ru, this message translates to:
  /// **'Отлично'**
  String get great;

  /// No description provided for @promocodeNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Промокод не найден'**
  String get promocodeNotFound;

  /// No description provided for @promocodeNotFoundDescription.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте правильность ввода или попросите друга отправить промокод ещё раз.'**
  String get promocodeNotFoundDescription;

  /// No description provided for @enterAgain.
  ///
  /// In ru, this message translates to:
  /// **'Ввести заново'**
  String get enterAgain;

  /// No description provided for @giveDiscount.
  ///
  /// In ru, this message translates to:
  /// **'Подари скидку'**
  String get giveDiscount;

  /// No description provided for @shareWithFriends.
  ///
  /// In ru, this message translates to:
  /// **'Поделитесь с друзьями'**
  String get shareWithFriends;

  /// No description provided for @joinKetroy.
  ///
  /// In ru, this message translates to:
  /// **'🎁 Присоединяйтесь к Ketroy Shop!\nПолучите скидку в 20% при регистрации по этой ссылке:\n{link}\n\n📱 Скачайте приложение и начните экономить!'**
  String joinKetroy(String link);

  /// No description provided for @ketroyInvitation.
  ///
  /// In ru, this message translates to:
  /// **'Приглашение в Ketroy Shop'**
  String get ketroyInvitation;

  /// No description provided for @downloadKetroyApp.
  ///
  /// In ru, this message translates to:
  /// **'Скачайте приложение Ketroy Shop и получайте эксклюзивные скидки!'**
  String get downloadKetroyApp;

  /// No description provided for @systemLanguageHint.
  ///
  /// In ru, this message translates to:
  /// **'Выберите \"Системный язык\" для автоматического определения языка устройства'**
  String get systemLanguageHint;

  /// No description provided for @pendingGiftsTitle.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, =1{У вас {count} подарок ожидает выбора!} few{У вас {count} подарка ожидают выбора!} many{У вас {count} подарков ожидают выбора!} other{У вас {count} подарка ожидают выбора!}}'**
  String pendingGiftsTitle(int count);

  /// No description provided for @pendingGiftsSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Заберите подарок в магазине'**
  String get pendingGiftsSubtitle;

  /// No description provided for @scanQrToGetGift.
  ///
  /// In ru, this message translates to:
  /// **'Сканировать QR для получения'**
  String get scanQrToGetGift;

  /// No description provided for @usAlready.
  ///
  /// In ru, this message translates to:
  /// **'Нас уже'**
  String get usAlready;

  /// No description provided for @users.
  ///
  /// In ru, this message translates to:
  /// **'пользователей'**
  String get users;

  /// No description provided for @contactUs.
  ///
  /// In ru, this message translates to:
  /// **'Свяжитесь с нами'**
  String get contactUs;

  /// No description provided for @partnershipDescription.
  ///
  /// In ru, this message translates to:
  /// **'Если у вас есть предложения о сотрудничестве, партнёрстве или вопросы о рекламе в нашем мобильном приложении — напишите нам в WhatsApp!'**
  String get partnershipDescription;

  /// No description provided for @writeToWhatsApp.
  ///
  /// In ru, this message translates to:
  /// **'Написать в WhatsApp'**
  String get writeToWhatsApp;

  /// No description provided for @partnershipBenefits.
  ///
  /// In ru, this message translates to:
  /// **'Что мы предлагаем'**
  String get partnershipBenefits;

  /// No description provided for @benefitAds.
  ///
  /// In ru, this message translates to:
  /// **'Рекламу в мобильном приложении'**
  String get benefitAds;

  /// No description provided for @benefitPromo.
  ///
  /// In ru, this message translates to:
  /// **'Совместные акции и розыгрыши'**
  String get benefitPromo;

  /// No description provided for @benefitBusiness.
  ///
  /// In ru, this message translates to:
  /// **'B2B сотрудничество'**
  String get benefitBusiness;

  /// No description provided for @currentPromotions.
  ///
  /// In ru, this message translates to:
  /// **'Действующие акции'**
  String get currentPromotions;

  /// No description provided for @noActivePromotions.
  ///
  /// In ru, this message translates to:
  /// **'Нет активных акций'**
  String get noActivePromotions;

  /// No description provided for @checkBackLater.
  ///
  /// In ru, this message translates to:
  /// **'Загляните позже'**
  String get checkBackLater;

  /// No description provided for @news.
  ///
  /// In ru, this message translates to:
  /// **'Новости'**
  String get news;

  /// No description provided for @all.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get all;

  /// No description provided for @readMore.
  ///
  /// In ru, this message translates to:
  /// **'Подробнее'**
  String get readMore;

  /// No description provided for @noNewsFound.
  ///
  /// In ru, this message translates to:
  /// **'Новости не найдены'**
  String get noNewsFound;

  /// No description provided for @viewedAllNews.
  ///
  /// In ru, this message translates to:
  /// **'Вы просмотрели все новости'**
  String get viewedAllNews;

  /// No description provided for @loadingNews.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка...'**
  String get loadingNews;

  /// No description provided for @loadError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка загрузки'**
  String get loadError;

  /// No description provided for @refreshError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка обновления данных'**
  String get refreshError;

  /// No description provided for @notificationsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get notificationsTitle;

  /// No description provided for @filterUnread.
  ///
  /// In ru, this message translates to:
  /// **'Не прочитано'**
  String get filterUnread;

  /// No description provided for @filterDebit.
  ///
  /// In ru, this message translates to:
  /// **'Списание'**
  String get filterDebit;

  /// No description provided for @filterGifts.
  ///
  /// In ru, this message translates to:
  /// **'Подарки'**
  String get filterGifts;

  /// No description provided for @filterDiscounts.
  ///
  /// In ru, this message translates to:
  /// **'Скидки'**
  String get filterDiscounts;

  /// No description provided for @filterNews.
  ///
  /// In ru, this message translates to:
  /// **'Новости'**
  String get filterNews;

  /// No description provided for @filterSystem.
  ///
  /// In ru, this message translates to:
  /// **'Системные'**
  String get filterSystem;

  /// No description provided for @noUnreadNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Нет непрочитанных уведомлений'**
  String get noUnreadNotifications;

  /// No description provided for @noDebitNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Нет уведомлений о списаниях'**
  String get noDebitNotifications;

  /// No description provided for @noGiftNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Нет уведомлений о подарках'**
  String get noGiftNotifications;

  /// No description provided for @noDiscountNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Нет уведомлений о скидках'**
  String get noDiscountNotifications;

  /// No description provided for @noNewsNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Нет новостей'**
  String get noNewsNotifications;

  /// No description provided for @noSystemNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Нет системных уведомлений'**
  String get noSystemNotifications;

  /// No description provided for @markAllAsRead.
  ///
  /// In ru, this message translates to:
  /// **'Прочитать все'**
  String get markAllAsRead;

  /// No description provided for @giftStatusPending.
  ///
  /// In ru, this message translates to:
  /// **'Ожидает выбора'**
  String get giftStatusPending;

  /// No description provided for @giftStatusSelected.
  ///
  /// In ru, this message translates to:
  /// **'Выбран'**
  String get giftStatusSelected;

  /// No description provided for @giftStatusActivated.
  ///
  /// In ru, this message translates to:
  /// **'Активирован'**
  String get giftStatusActivated;

  /// No description provided for @giftStatusIssued.
  ///
  /// In ru, this message translates to:
  /// **'Выдан'**
  String get giftStatusIssued;

  /// No description provided for @giftStatusReceived.
  ///
  /// In ru, this message translates to:
  /// **'Получен'**
  String get giftStatusReceived;

  /// No description provided for @getAtStore.
  ///
  /// In ru, this message translates to:
  /// **'Получить в магазине'**
  String get getAtStore;

  /// No description provided for @selectGiftNow.
  ///
  /// In ru, this message translates to:
  /// **'Выберите свой подарок прямо сейчас!'**
  String get selectGiftNow;

  /// No description provided for @giftNumber.
  ///
  /// In ru, this message translates to:
  /// **'Подарок {number}'**
  String giftNumber(int number);

  /// No description provided for @variantsCount.
  ///
  /// In ru, this message translates to:
  /// **'{count} вариантов'**
  String variantsCount(int count);

  /// No description provided for @selectButton.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать'**
  String get selectButton;

  /// No description provided for @loadingGifts.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка подарков...'**
  String get loadingGifts;

  /// No description provided for @failedToLoad.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить'**
  String get failedToLoad;

  /// No description provided for @checkInternet.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте подключение к интернету'**
  String get checkInternet;

  /// No description provided for @newGiftBanner.
  ///
  /// In ru, this message translates to:
  /// **'Новый подарок!'**
  String get newGiftBanner;

  /// No description provided for @listUpdated.
  ///
  /// In ru, this message translates to:
  /// **'Список обновлён'**
  String get listUpdated;

  /// No description provided for @profileSettingsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Настройки профиля'**
  String get profileSettingsTitle;

  /// No description provided for @sectionPersonalData.
  ///
  /// In ru, this message translates to:
  /// **'Личные данные'**
  String get sectionPersonalData;

  /// No description provided for @sectionSizes.
  ///
  /// In ru, this message translates to:
  /// **'Размеры'**
  String get sectionSizes;

  /// No description provided for @fieldSurname.
  ///
  /// In ru, this message translates to:
  /// **'Фамилия'**
  String get fieldSurname;

  /// No description provided for @fieldName.
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get fieldName;

  /// No description provided for @fieldBirthDate.
  ///
  /// In ru, this message translates to:
  /// **'Дата рождения'**
  String get fieldBirthDate;

  /// No description provided for @fieldCity.
  ///
  /// In ru, this message translates to:
  /// **'Город'**
  String get fieldCity;

  /// No description provided for @fieldHeight.
  ///
  /// In ru, this message translates to:
  /// **'Рост'**
  String get fieldHeight;

  /// No description provided for @fieldClothingSize.
  ///
  /// In ru, this message translates to:
  /// **'Размер одежды'**
  String get fieldClothingSize;

  /// No description provided for @fieldShoeSize.
  ///
  /// In ru, this message translates to:
  /// **'Размер обуви'**
  String get fieldShoeSize;

  /// No description provided for @selectDatePlaceholder.
  ///
  /// In ru, this message translates to:
  /// **'Выберите дату'**
  String get selectDatePlaceholder;

  /// No description provided for @selectCityPlaceholder.
  ///
  /// In ru, this message translates to:
  /// **'Выберите город'**
  String get selectCityPlaceholder;

  /// No description provided for @saveButton.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить изменения'**
  String get saveButton;

  /// No description provided for @cancelButton.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get cancelButton;

  /// No description provided for @doneButton.
  ///
  /// In ru, this message translates to:
  /// **'Готово'**
  String get doneButton;

  /// No description provided for @userPlaceholder.
  ///
  /// In ru, this message translates to:
  /// **'Пользователь'**
  String get userPlaceholder;

  /// No description provided for @chooseOneGift.
  ///
  /// In ru, this message translates to:
  /// **'Выберите один из подарков'**
  String get chooseOneGift;

  /// No description provided for @activateButton.
  ///
  /// In ru, this message translates to:
  /// **'Активировать'**
  String get activateButton;

  /// No description provided for @saveGiftButton.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get saveGiftButton;

  /// No description provided for @readyButton.
  ///
  /// In ru, this message translates to:
  /// **'Готово'**
  String get readyButton;

  /// No description provided for @myGiftsButton.
  ///
  /// In ru, this message translates to:
  /// **'Мои подарки'**
  String get myGiftsButton;

  /// No description provided for @activateGiftInstructions.
  ///
  /// In ru, this message translates to:
  /// **'Активируйте подарок только у кассы и заберите его в течение 10 минут. Если вы хотите забрать подарок позже, сохраните его в разделе «Мои подарки»'**
  String get activateGiftInstructions;

  /// No description provided for @timeNow.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас'**
  String get timeNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} минуту назад} few{{count} минуты назад} other{{count} минут назад}}'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} час назад} few{{count} часа назад} other{{count} часов назад}}'**
  String timeHoursAgo(int count);

  /// No description provided for @timeYesterday.
  ///
  /// In ru, this message translates to:
  /// **'Вчера'**
  String get timeYesterday;

  /// No description provided for @timeWeekday.
  ///
  /// In ru, this message translates to:
  /// **'{day}'**
  String timeWeekday(String day);

  /// No description provided for @timeWeeksAgo.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} неделю назад} few{{count} недели назад} other{{count} недель назад}}'**
  String timeWeeksAgo(int count);

  /// No description provided for @timeMonthsAgo.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} месяц назад} few{{count} месяца назад} other{{count} месяцев назад}}'**
  String timeMonthsAgo(int count);

  /// No description provided for @timeYearsAgo.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} год назад} few{{count} года назад} other{{count} лет назад}}'**
  String timeYearsAgo(int count);

  /// No description provided for @weekdayMonday.
  ///
  /// In ru, this message translates to:
  /// **'Понедельник'**
  String get weekdayMonday;

  /// No description provided for @weekdayTuesday.
  ///
  /// In ru, this message translates to:
  /// **'Вторник'**
  String get weekdayTuesday;

  /// No description provided for @weekdayWednesday.
  ///
  /// In ru, this message translates to:
  /// **'Среду'**
  String get weekdayWednesday;

  /// No description provided for @weekdayThursday.
  ///
  /// In ru, this message translates to:
  /// **'Четверг'**
  String get weekdayThursday;

  /// No description provided for @weekdayFriday.
  ///
  /// In ru, this message translates to:
  /// **'Пятницу'**
  String get weekdayFriday;

  /// No description provided for @weekdaySaturday.
  ///
  /// In ru, this message translates to:
  /// **'Субботу'**
  String get weekdaySaturday;

  /// No description provided for @weekdaySunday.
  ///
  /// In ru, this message translates to:
  /// **'Воскресенье'**
  String get weekdaySunday;

  /// No description provided for @sending.
  ///
  /// In ru, this message translates to:
  /// **'Отправка кода'**
  String get sending;

  /// No description provided for @agreementStart.
  ///
  /// In ru, this message translates to:
  /// **'Нажав \"ЗАРЕГИСТРИРОВАТЬСЯ\", вы соглашаетесь c'**
  String get agreementStart;

  /// No description provided for @termsOfUse.
  ///
  /// In ru, this message translates to:
  /// **'Условиями использования'**
  String get termsOfUse;

  /// No description provided for @and.
  ///
  /// In ru, this message translates to:
  /// **'и'**
  String get and;

  /// No description provided for @privacyPolicy.
  ///
  /// In ru, this message translates to:
  /// **'Политикой конфиденциальности'**
  String get privacyPolicy;

  /// No description provided for @haveAccount.
  ///
  /// In ru, this message translates to:
  /// **'Уже есть аккаунт?'**
  String get haveAccount;

  /// No description provided for @accountFound.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт найден! Введите код для входа.'**
  String get accountFound;

  /// No description provided for @enterCode.
  ///
  /// In ru, this message translates to:
  /// **'Введите код'**
  String get enterCode;

  /// No description provided for @smsSent.
  ///
  /// In ru, this message translates to:
  /// **'Мы отправили SMS с кодом активации на ваш номер телефона'**
  String get smsSent;

  /// No description provided for @proceed.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить'**
  String get proceed;

  /// No description provided for @wrongCode.
  ///
  /// In ru, this message translates to:
  /// **'Неверный код'**
  String get wrongCode;

  /// No description provided for @through.
  ///
  /// In ru, this message translates to:
  /// **'через'**
  String get through;

  /// No description provided for @userNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Пользователь не найден. Пожалуйста, зарегистрируйтесь.'**
  String get userNotFound;

  /// No description provided for @almostDone.
  ///
  /// In ru, this message translates to:
  /// **'Еще немного'**
  String get almostDone;

  /// No description provided for @provideDataHint.
  ///
  /// In ru, this message translates to:
  /// **'Пожалуйста, предоставьте актуальные данные, чтобы мы подобрали для вас идеальный стиль.'**
  String get provideDataHint;

  /// No description provided for @scanGiftAtCheckout.
  ///
  /// In ru, this message translates to:
  /// **'Отсканируйте QR-код у кассы'**
  String get scanGiftAtCheckout;

  /// No description provided for @qrCodeAtCheckout.
  ///
  /// In ru, this message translates to:
  /// **'QR-код находится у кассы'**
  String get qrCodeAtCheckout;

  /// No description provided for @scanQrAtStore.
  ///
  /// In ru, this message translates to:
  /// **'Отсканируйте QR-код в магазине'**
  String get scanQrAtStore;

  /// No description provided for @qrCodeForGift.
  ///
  /// In ru, this message translates to:
  /// **'QR-код для получения подарка'**
  String get qrCodeForGift;

  /// No description provided for @qrCodeScannedSuccess.
  ///
  /// In ru, this message translates to:
  /// **'QR-код успешно отсканирован!'**
  String get qrCodeScannedSuccess;

  /// No description provided for @pointCameraAtQr.
  ///
  /// In ru, this message translates to:
  /// **'Наведите камеру на QR-код'**
  String get pointCameraAtQr;

  /// No description provided for @qrCodeInStore.
  ///
  /// In ru, this message translates to:
  /// **'QR-код в магазине KETROY'**
  String get qrCodeInStore;

  /// No description provided for @qrCodeEmpty.
  ///
  /// In ru, this message translates to:
  /// **'QR-код пустой или повреждён'**
  String get qrCodeEmpty;

  /// No description provided for @invalidQrCode.
  ///
  /// In ru, this message translates to:
  /// **'Неверный QR-код. Используйте QR-код из магазина KETROY'**
  String get invalidQrCode;

  /// No description provided for @giftReceivedSuccess.
  ///
  /// In ru, this message translates to:
  /// **'Подарок успешно получен! 🎁'**
  String get giftReceivedSuccess;

  /// No description provided for @giftDataError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка данных подарка. Попробуйте ещё раз.'**
  String get giftDataError;

  /// No description provided for @giftActivationError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка при активации подарков'**
  String get giftActivationError;

  /// No description provided for @activatingGift.
  ///
  /// In ru, this message translates to:
  /// **'Активация подарка'**
  String get activatingGift;

  /// No description provided for @checkingGifts.
  ///
  /// In ru, this message translates to:
  /// **'Проверяем подарки...'**
  String get checkingGifts;

  /// No description provided for @flashOff.
  ///
  /// In ru, this message translates to:
  /// **'Выкл'**
  String get flashOff;

  /// No description provided for @flashOn.
  ///
  /// In ru, this message translates to:
  /// **'Вспышка'**
  String get flashOn;

  /// No description provided for @giftConfirmationError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка подтверждения'**
  String get giftConfirmationError;

  /// No description provided for @giftConfirmationFailed.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка при подтверждении выдачи'**
  String get giftConfirmationFailed;

  /// No description provided for @noInternetConnection.
  ///
  /// In ru, this message translates to:
  /// **'Нет подключения к интернету'**
  String get noInternetConnection;

  /// No description provided for @giftNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Подарок не найден в каталоге, либо был удален'**
  String get giftNotFound;

  /// No description provided for @giftNotYours.
  ///
  /// In ru, this message translates to:
  /// **'Подарок не принадлежит вам'**
  String get giftNotYours;

  /// No description provided for @giftAlreadyIssued.
  ///
  /// In ru, this message translates to:
  /// **'Подарок уже был выдан или не готов к выдаче'**
  String get giftAlreadyIssued;

  /// No description provided for @showEmployeeMessage.
  ///
  /// In ru, this message translates to:
  /// **'Покажите это сообщение сотруднику'**
  String get showEmployeeMessage;

  /// No description provided for @excellent.
  ///
  /// In ru, this message translates to:
  /// **'Отлично!'**
  String get excellent;

  /// No description provided for @receivingGift.
  ///
  /// In ru, this message translates to:
  /// **'Получение подарка'**
  String get receivingGift;

  /// No description provided for @yourGift.
  ///
  /// In ru, this message translates to:
  /// **'Ваш подарок:'**
  String get yourGift;

  /// No description provided for @confirmingIssue.
  ///
  /// In ru, this message translates to:
  /// **'Подтверждаем выдачу...'**
  String get confirmingIssue;

  /// No description provided for @selectGiftInstruction.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите на любой подарок,\nчтобы узнать что внутри!'**
  String get selectGiftInstruction;

  /// No description provided for @photographClothingLabel.
  ///
  /// In ru, this message translates to:
  /// **'Сфотографируйте ярлык одежды'**
  String get photographClothingLabel;

  /// No description provided for @washingSymbols.
  ///
  /// In ru, this message translates to:
  /// **'Символы стирки, глажки и сушки'**
  String get washingSymbols;

  /// No description provided for @analyzingLabel.
  ///
  /// In ru, this message translates to:
  /// **'Анализирую этикетку...'**
  String get analyzingLabel;

  /// No description provided for @aiProcessingImage.
  ///
  /// In ru, this message translates to:
  /// **'AI обрабатывает изображение'**
  String get aiProcessingImage;

  /// No description provided for @analyzeThisLabel.
  ///
  /// In ru, this message translates to:
  /// **'Проанализируй эту этикетку'**
  String get analyzeThisLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'kk', 'ru', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'kk':
      return AppLocalizationsKk();
    case 'ru':
      return AppLocalizationsRu();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

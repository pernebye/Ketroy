part of 'profile_bloc.dart';

enum ProfileStatus { initial, loading, success, failure }

enum ProfileDetailedStatus { initial, loading, success, failure }

enum ProfileLocalStatus { initial, loading, success, failure }

enum UpdateStatus { initial, loading, success, failure }

enum QrStatus { initial, loading, success, failure }

enum PromotionsStatus { initial, loading, success, failure }

class ProfileState extends Equatable {
  final ProfileStatus status;
  final ProfileDetailedStatus profileDetailStatus;
  final ProfileLocalStatus profileLocalStatus;
  final UpdateStatus updateStatus;
  final String? name;
  final String? surname;
  final String? phoneNumber;
  final String? birthDay;
  final String? city;
  final String? height;
  final String? clotherSize;
  final String? shoeSize;
  final String? avatarImage;
  final String? message;
  final String? bonus;
  final String? token;
  final AuthUserEntity? profileData;
  final List<CityEntity> cityList;
  final bool isCleaned;
  final DiscountEntity? discount;
  final ScanEntity? scan;
  final QrStatus qrStatus;
  final bool isUploadingAvatar;
  final ShopEntity? cityShop; // Магазин из города пользователя
  final List<PromotionModel> promotions; // Список активных акций
  final PromotionsStatus promotionsStatus;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profileDetailStatus = ProfileDetailedStatus.initial,
    this.profileLocalStatus = ProfileLocalStatus.initial,
    this.updateStatus = UpdateStatus.initial,
    this.name,
    this.surname,
    this.phoneNumber,
    this.birthDay,
    this.city,
    this.height,
    this.clotherSize,
    this.shoeSize,
    this.avatarImage,
    this.message,
    this.bonus,
    this.token,
    this.profileData,
    this.cityList = const [],
    this.isCleaned = false,
    this.discount,
    this.scan,
    this.qrStatus = QrStatus.initial,
    this.isUploadingAvatar = false,
    this.cityShop,
    this.promotions = const [],
    this.promotionsStatus = PromotionsStatus.initial,
  });

  @override
  List<Object?> get props => [
        status,
        profileDetailStatus,
        profileLocalStatus,
        updateStatus,
        name,
        surname,
        phoneNumber,
        birthDay,
        city,
        height,
        clotherSize,
        shoeSize,
        avatarImage,
        message,
        token,
        bonus,
        profileData,
        cityList,
        isCleaned,
        discount,
        scan,
        qrStatus,
        isUploadingAvatar,
        cityShop,
        promotions,
        promotionsStatus,
      ];

  bool get isInitial => status == ProfileStatus.initial;
  bool get isLoading => status == ProfileStatus.loading;
  bool get isSuccess => status == ProfileStatus.success;
  bool get isFailure => status == ProfileStatus.failure;

  bool get isDetailedInitial =>
      profileDetailStatus == ProfileDetailedStatus.initial;
  bool get isDetailedLoading =>
      profileDetailStatus == ProfileDetailedStatus.loading;
  bool get isDetailedSuccess =>
      profileDetailStatus == ProfileDetailedStatus.success;
  bool get isDetailedFailure =>
      profileDetailStatus == ProfileDetailedStatus.failure;

  bool get isLocalInitial => profileLocalStatus == ProfileLocalStatus.initial;
  bool get isLocalLoading => profileLocalStatus == ProfileLocalStatus.loading;
  bool get isLocalSuccess => profileLocalStatus == ProfileLocalStatus.success;
  bool get isLocalFailure => profileLocalStatus == ProfileLocalStatus.failure;

  bool get isUpdateInitial => updateStatus == UpdateStatus.initial;
  bool get isUpdateLoading => updateStatus == UpdateStatus.loading;
  bool get isUpdateSuccess => updateStatus == UpdateStatus.success;
  bool get isUpdateFailure => updateStatus == UpdateStatus.failure;

  bool get isQrInitial => qrStatus == QrStatus.initial;
  bool get isQrLoading => qrStatus == QrStatus.loading;
  bool get isQrSuccess => qrStatus == QrStatus.success;
  bool get isQrFailure => qrStatus == QrStatus.failure;

  ProfileState copyWith({
    ProfileStatus? status,
    ProfileDetailedStatus? profileDetailStatus,
    ProfileLocalStatus? profileLocalStatus,
    UpdateStatus? updateStatus,
    String? name,
    String? surname,
    String? phoneNumber,
    String? birthDay,
    String? city,
    String? height,
    String? clotherSize,
    String? shoeSize,
    String? avatarImage,
    String? message,
    String? bonus,
    String? token,
    AuthUserEntity? profileData,
    List<CityEntity>? cityList,
    bool? isCleaned,
    DiscountEntity? discount,
    ScanEntity? scan,
    QrStatus? qrStatus,
    bool? isUploadingAvatar,
    ShopEntity? cityShop,
    List<PromotionModel>? promotions,
    PromotionsStatus? promotionsStatus,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profileDetailStatus: profileDetailStatus ?? this.profileDetailStatus,
      profileLocalStatus: profileLocalStatus ?? this.profileLocalStatus,
      updateStatus: updateStatus ?? this.updateStatus,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      birthDay: birthDay ?? this.birthDay,
      city: city ?? this.city,
      height: height ?? this.height,
      clotherSize: clotherSize ?? this.clotherSize,
      shoeSize: shoeSize ?? this.shoeSize,
      avatarImage: avatarImage ?? this.avatarImage,
      message: message ?? this.message,
      bonus: bonus ?? this.bonus,
      token: token ?? this.token,
      profileData: profileData ?? this.profileData,
      cityList: cityList ?? this.cityList,
      isCleaned: isCleaned ?? this.isCleaned,
      discount: discount,
      scan: scan ?? this.scan,
      qrStatus: qrStatus ?? this.qrStatus,
      isUploadingAvatar: isUploadingAvatar ?? this.isUploadingAvatar,
      cityShop: cityShop ?? this.cityShop,
      promotions: promotions ?? this.promotions,
      promotionsStatus: promotionsStatus ?? this.promotionsStatus,
    );
  }
}

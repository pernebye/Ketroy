import 'package:dio/dio.dart';
import 'package:ketroy_app/core/config/app_config.dart';
import 'package:ketroy_app/core/internet_services/dio_client.dart';
import 'package:ketroy_app/core/internet_services/error/dio_exception.dart';
import 'package:ketroy_app/core/internet_services/error/exceptions.dart';
import 'package:ketroy_app/core/internet_services/paths.dart';
import 'package:ketroy_app/features/auth/data/models/user_model.dart';
import 'package:ketroy_app/features/profile/data/models/city_model.dart';
import 'package:ketroy_app/features/profile/data/models/discount_model.dart';
import 'package:ketroy_app/features/profile/data/models/scan_model.dart';
import 'package:ketroy_app/features/profile/data/promotion_model.dart';
import 'package:ketroy_app/services/notification_services.dart';

abstract interface class ProfileDataSource {
  Future<String> updateUser(
      {required String height,
      required String clothingSize,
      required String shoeSize,
      required String city,
      required String name,
      required String surname,
      required String birthDay});

  Future<String> uploadAvatar({required String filePath});

  Future<AuthUserModel> getUserData();

  Future<DiscountModel> getDiscount({required String? token});
  Future<ScanModel> scanQr({required String scanQrUrl});

  Future<String> logOut();

  Future<String> deleteAccount();
  Future<List<CityModel>> getCity();
  
  Future<List<PromotionModel>> getPromotions();
}

class ProfileDataSourceImpl implements ProfileDataSource {
  @override
  Future<String> updateUser(
      {required String height,
      required String clothingSize,
      required String shoeSize,
      required String city,
      required String name,
      required String surname,
      required String birthDay}) async {
    try {
      final response = await DioClient.instance.put(update, data: {
        'height': height,
        'clothing_size': clothingSize,
        'shoe_size': shoeSize,
        'city': city,
        'name': name,
        'surname': surname,
        'birthdate': birthDay
      });
      return response['message'];
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }

  @override
  Future<String> uploadAvatar({required String filePath}) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: 'avatar.jpg'),
      });
      final response = await DioClient.instance.putFormData(
        uploadAvatarUrl,
        data: formData,
      );
      return response['avatar_image'] ?? '';
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }

  @override
  Future<AuthUserModel> getUserData() async {
    try {
      final response = await DioClient.instance.get(userUrl);
      return AuthUserModel.fromjson(response['user']);
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }

  @override
  Future<DiscountModel> getDiscount({required String? token}) async {
    try {
      final response = await DioClient.instance
          .post(verifyDiscountUrl, data: {'token': token}, tokenNeed: true);
      return DiscountModel.fromjson(response);
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }

  @override
  Future<ScanModel> scanQr({required String scanQrUrl}) async {
    try {
      // Заменяем localhost на правильный адрес для dev-окружения
      String url = scanQrUrl;
      if (AppConfig.current == Environment.development) {
        // Для Android эмулятора: localhost → 10.0.2.2
        url = scanQrUrl
            .replaceAll('://localhost:', '://10.0.2.2:')
            .replaceAll('://127.0.0.1:', '://10.0.2.2:');
      }
      final response = await DioClient.instance.get(url);
      return ScanModel.fromjson(response);
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }

  @override
  Future<String> deleteAccount() async {
    try {
      final response = await DioClient.instance.delete(userUrl);
      return response['message'];
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }

  @override
  Future<String> logOut() async {
    try {
      // Передаём device_token для деактивации push-уведомлений на сервере
      final deviceToken = NotificationServices.instance.fcmToken;
      
      final response = await DioClient.instance.post(
        logOutUrl,
        data: deviceToken != null ? {'device_token': deviceToken} : null,
        tokenNeed: true,
      );
      return response['message'];
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }

  @override
  Future<List<CityModel>> getCity() async {
    try {
      final response = await DioClient.instance.getList(cityPath);
      List<dynamic> data = response;
      return data.map((city) => CityModel.fromjson(city)).toList();
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }

  @override
  Future<List<PromotionModel>> getPromotions() async {
    try {
      final response = await DioClient.instance.get(promotionsUrl);
      // API возвращает пагинированный ответ с полем data
      final List<dynamic> data = response['data'] ?? [];
      return data
          .map((promo) => PromotionModel.fromJson(promo))
          .where((promo) => promo.isCurrentlyActive) // Фильтруем только активные
          .toList();
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }
}

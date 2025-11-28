import 'package:dio/dio.dart';
import 'package:ketroy_app/core/internet_services/dio_client.dart';
import 'package:ketroy_app/core/internet_services/error/dio_exception.dart';
import 'package:ketroy_app/core/internet_services/error/exceptions.dart';
import 'package:ketroy_app/core/internet_services/paths.dart';
import 'package:ketroy_app/features/discount/domain/entities/referral_info.dart';

abstract interface class DiscountDataSource {
  Future<String> postPromoCode({required String promoCode});
  Future<bool> checkReferralAvailability();
  Future<ReferralInfo> getReferralInfo();
}

class DiscountDataSourceImpl implements DiscountDataSource {
  @override
  Future<String> postPromoCode({required String promoCode}) async {
    try {
      final response = await DioClient.instance.post(promoCodeApply,
          data: {'promo_code': promoCode}, tokenNeed: true);
      return response['message'];
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }

  @override
  Future<bool> checkReferralAvailability() async {
    try {
      final response = await DioClient.instance.get(referralInfoUrl, needToken: true);
      return response['is_available'] ?? false;
    } on DioException {
      return false;
    } catch (_) {
      return false;
    }
  }
  
  @override
  Future<ReferralInfo> getReferralInfo() async {
    try {
      final response = await DioClient.instance.get(referralInfoUrl, needToken: true);
      return ReferralInfo.fromJson(response);
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }
}

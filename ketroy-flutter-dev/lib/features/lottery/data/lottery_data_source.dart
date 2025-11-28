import 'package:dio/dio.dart';
import 'package:ketroy_app/core/internet_services/dio_client.dart';
import 'package:ketroy_app/core/internet_services/error/dio_exception.dart';
import 'package:ketroy_app/core/internet_services/error/exceptions.dart';
import 'package:ketroy_app/core/internet_services/paths.dart';
import 'package:ketroy_app/features/my_gifts/data/data_source/gift_data_source.dart';

/// Модель данных лотереи
class LotteryData {
  final int promotionId;
  final String modalTitle;
  final String modalText;
  final String? modalImage;
  final String modalButtonText;
  final int giftsCount;
  final List<GiftOption> gifts;

  LotteryData({
    required this.promotionId,
    required this.modalTitle,
    required this.modalText,
    this.modalImage,
    required this.modalButtonText,
    required this.giftsCount,
    required this.gifts,
  });

  factory LotteryData.fromJson(Map<String, dynamic> json) {
    return LotteryData(
      promotionId: json['promotion_id'] ?? 0,
      modalTitle: json['modal_title'] ?? 'Поздравляем! 🎉',
      modalText: json['modal_text'] ?? 'Вы получили подарок!',
      modalImage: json['modal_image'],
      modalButtonText: json['modal_button_text'] ?? 'Получить подарок',
      giftsCount: json['gifts_count'] ?? 0,
      gifts: (json['gifts'] as List<dynamic>?)
              ?.map((g) => GiftOption.fromJson(g))
              .toList() ??
          [],
    );
  }
}

/// Результат проверки активной лотереи
class LotteryCheckResult {
  final bool hasActiveLottery;
  final LotteryData? lottery;

  LotteryCheckResult({
    required this.hasActiveLottery,
    this.lottery,
  });

  factory LotteryCheckResult.fromJson(Map<String, dynamic> json) {
    return LotteryCheckResult(
      hasActiveLottery: json['has_active_lottery'] ?? false,
      lottery: json['lottery'] != null
          ? LotteryData.fromJson(json['lottery'])
          : null,
    );
  }
}

/// Результат получения подарка лотереи
class LotteryClaimResult {
  final bool success;
  final String message;
  final String? giftGroupId;
  final List<GiftOption> gifts;
  final bool giftAlreadyClaimed;

  LotteryClaimResult({
    required this.success,
    required this.message,
    this.giftGroupId,
    required this.gifts,
    this.giftAlreadyClaimed = false,
  });

  factory LotteryClaimResult.fromJson(Map<String, dynamic> json) {
    return LotteryClaimResult(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      giftGroupId: json['gift_group_id'],
      gifts: (json['gifts'] as List<dynamic>?)
              ?.map((g) => GiftOption.fromJson(g))
              .toList() ??
          [],
      giftAlreadyClaimed: json['gift_already_claimed'] ?? false,
    );
  }
}

abstract interface class LotteryDataSource {
  Future<LotteryCheckResult> checkActiveLottery();
  Future<LotteryClaimResult> claimLotteryGift(int promotionId);
  Future<void> dismissLottery(int promotionId);
}

class LotteryDataSourceImpl implements LotteryDataSource {
  @override
  Future<LotteryCheckResult> checkActiveLottery() async {
    try {
      final response = await DioClient.instance.get(
        lotteryCheckUrl,
        needToken: true,
      );
      return LotteryCheckResult.fromJson(response);
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }

  @override
  Future<LotteryClaimResult> claimLotteryGift(int promotionId) async {
    try {
      final response = await DioClient.instance.post(
        lotteryClaimUrl,
        data: {'promotion_id': promotionId},
        tokenNeed: true,
      );
      return LotteryClaimResult.fromJson(response);
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }

  @override
  Future<void> dismissLottery(int promotionId) async {
    try {
      await DioClient.instance.post(
        lotteryDismissUrl,
        data: {'promotion_id': promotionId},
        tokenNeed: true,
      );
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }
}


import 'package:dio/dio.dart';
import 'package:ketroy_app/core/internet_services/dio_client.dart';
import 'package:ketroy_app/core/internet_services/error/dio_exception.dart';
import 'package:ketroy_app/core/internet_services/error/exceptions.dart';
import 'package:ketroy_app/core/internet_services/paths.dart';
import 'package:ketroy_app/features/my_gifts/data/model/gifts_model.dart';

/// Результат получения списка подарков с pending группами
class GiftsListResponse {
  final List<GiftsModel> gifts;
  final List<GiftGroup> pendingGroups;
  final bool hasPending;

  GiftsListResponse({
    required this.gifts,
    required this.pendingGroups,
    required this.hasPending,
  });

  factory GiftsListResponse.fromJson(Map<String, dynamic> json) {
    final giftsData = json['gifts'] as List<dynamic>? ?? [];
    final pendingGroupsData = json['pending_groups'] as List<dynamic>? ?? [];
    
    return GiftsListResponse(
      gifts: giftsData.map((g) => GiftsModel.fromjson(g)).toList(),
      pendingGroups: pendingGroupsData.map((g) => GiftGroup.fromJson(g)).toList(),
      hasPending: json['has_pending'] ?? false,
    );
  }
}

/// Модель для подарка в группе выбора
class GiftOption {
  final int id;
  final String name;
  final String? image;

  GiftOption({required this.id, required this.name, this.image});

  factory GiftOption.fromJson(Map<String, dynamic> json) {
    return GiftOption(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      image: json['image'],
    );
  }
}

/// Модель для группы подарков
class GiftGroup {
  final String giftGroupId;
  final List<GiftOption> gifts;
  final DateTime createdAt;

  GiftGroup({
    required this.giftGroupId,
    required this.gifts,
    required this.createdAt,
  });

  factory GiftGroup.fromJson(Map<String, dynamic> json) {
    return GiftGroup(
      giftGroupId: json['gift_group_id'] ?? '',
      gifts: (json['gifts'] as List<dynamic>?)
              ?.map((g) => GiftOption.fromJson(g))
              .toList() ??
          [],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

/// Результат активации подарка через QR
class QrActivationResult {
  final bool hasPendingGifts;
  final String? giftGroupId;
  final List<GiftOption> gifts;
  final String message;

  QrActivationResult({
    required this.hasPendingGifts,
    this.giftGroupId,
    required this.gifts,
    required this.message,
  });

  factory QrActivationResult.fromJson(Map<String, dynamic> json) {
    return QrActivationResult(
      hasPendingGifts: json['has_pending_gifts'] ?? false,
      giftGroupId: json['gift_group_id'],
      gifts: (json['gifts'] as List<dynamic>?)
              ?.map((g) => GiftOption.fromJson(g))
              .toList() ??
          [],
      message: json['message'] ?? '',
    );
  }
}

/// Результат выбора подарка
class GiftSelectionResult {
  final String message;
  final GiftOption? gift;

  GiftSelectionResult({required this.message, this.gift});

  factory GiftSelectionResult.fromJson(Map<String, dynamic> json) {
    return GiftSelectionResult(
      message: json['message'] ?? '',
      gift: json['gift'] != null ? GiftOption.fromJson(json['gift']) : null,
    );
  }
}

/// Результат подтверждения выдачи подарка
class IssuanceConfirmResult {
  final bool success;
  final String message;
  final int? giftId;

  IssuanceConfirmResult({
    required this.success,
    required this.message,
    this.giftId,
  });

  factory IssuanceConfirmResult.fromJson(Map<String, dynamic> json) {
    return IssuanceConfirmResult(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      giftId: json['gift_id'],
    );
  }
}

abstract interface class GiftDataSource {
  Future<GiftsListResponse> getGiftsList();
  Future<String> activateGift({required int giftId});
  Future<String> saveGift({required int giftId});
  
  // Новые методы для системы выбора подарков
  Future<List<GiftGroup>> getPendingGiftGroups();
  Future<QrActivationResult> activateByQr();
  Future<GiftSelectionResult> selectGift({required String giftGroupId});
  Future<String> activateSelectedGift({required int giftId});
  
  // Подтверждение выдачи подарка по QR-коду магазина
  Future<IssuanceConfirmResult> confirmIssuance({required int giftId, required String qrCode});
}

class GiftDataSourceImpl implements GiftDataSource {
  @override
  Future<GiftsListResponse> getGiftsList() async {
    try {
      final response = await DioClient.instance.get(giftsUrl);
      return GiftsListResponse.fromJson(response);
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }

  @override
  Future<String> activateGift({required int giftId}) async {
    try {
      final response = await DioClient.instance
          .post(activateGiftUrl, data: {'gift_id': giftId}, tokenNeed: true);
      return response['message'];
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }

  @override
  Future<String> saveGift({required int giftId}) async {
    try {
      final response = await DioClient.instance
          .post(saveGiftUrl, data: {'gift_id': giftId}, tokenNeed: true);
      return response['message'];
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }

  @override
  Future<List<GiftGroup>> getPendingGiftGroups() async {
    try {
      final response = await DioClient.instance.get(pendingGiftGroupsUrl);
      List<dynamic> groups = response['groups'] ?? [];
      return groups.map((g) => GiftGroup.fromJson(g)).toList();
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }

  @override
  Future<QrActivationResult> activateByQr() async {
    try {
      final response = await DioClient.instance
          .post(activateGiftByQrUrl, tokenNeed: true);
      return QrActivationResult.fromJson(response);
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }

  @override
  Future<GiftSelectionResult> selectGift({required String giftGroupId}) async {
    try {
      final response = await DioClient.instance.post(
        selectGiftUrl,
        data: {'gift_group_id': giftGroupId},
        tokenNeed: true,
      );
      return GiftSelectionResult.fromJson(response);
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }

  @override
  Future<String> activateSelectedGift({required int giftId}) async {
    try {
      final response = await DioClient.instance.post(
        newActivateGiftUrl,
        data: {'gift_id': giftId},
        tokenNeed: true,
      );
      return response['message'];
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }

  @override
  Future<IssuanceConfirmResult> confirmIssuance({
    required int giftId,
    required String qrCode,
  }) async {
    try {
      final response = await DioClient.instance.post(
        confirmGiftIssuanceUrl,
        data: {
          'gift_id': giftId,
          'qr_code': qrCode,
        },
        tokenNeed: true,
      );
      return IssuanceConfirmResult.fromJson(response);
    } on DioException catch (e) {
      var error = DioExceptionService.fromDioError(e);
      throw ServerException(error.errorMessage);
    }
  }
}

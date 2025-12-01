import 'package:flutter/material.dart';
import 'package:ketroy_app/features/lottery/data/lottery_data_source.dart';
import 'package:ketroy_app/features/lottery/presentation/lottery_modal.dart';
import 'package:ketroy_app/features/my_gifts/data/data_source/gift_data_source.dart';
import 'package:ketroy_app/features/my_gifts/presentation/pages/gift_selection_page.dart';

/// Сервис для управления лотереей
/// Проверяет наличие активной лотереи при входе в приложение
class LotteryService {
  static final LotteryService _instance = LotteryService._internal();
  factory LotteryService() => _instance;
  LotteryService._internal();

  final LotteryDataSourceImpl _dataSource = LotteryDataSourceImpl();
  bool _hasCheckedThisSession = false;

  /// Проверить и показать модальное окно лотереи если есть активная акция
  /// Вызывать при каждом входе в приложение (после авторизации)
  Future<void> checkAndShowLotteryModal(BuildContext context) async {
    // Проверяем только один раз за сессию
    if (_hasCheckedThisSession) return;
    _hasCheckedThisSession = true;

    try {
      final result = await _dataSource.checkActiveLottery();

      if (!result.hasActiveLottery || result.lottery == null) {
        return;
      }

      if (!context.mounted) return;

      // Показываем модальное окно с небольшой задержкой для плавности
      await Future.delayed(const Duration(milliseconds: 500));

      if (!context.mounted) return;

      await LotteryModal.show(
        context: context,
        lotteryData: result.lottery!,
        onDismiss: () {
          // Отмечаем что пользователь закрыл модалку
          _dataSource.dismissLottery(result.lottery!.promotionId);
        },
        onClaimSuccess: (giftGroupId, gifts) {
          // Открываем страницу выбора подарка
          _navigateToGiftSelection(context, giftGroupId, gifts);
        },
      );
    } catch (e) {
      debugPrint('Error checking lottery: $e');
      // Не показываем ошибку пользователю - это фоновая проверка
    }
  }

  void _navigateToGiftSelection(
    BuildContext context,
    String giftGroupId,
    List<GiftOption> gifts,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GiftSelectionPage(
          giftGroupId: giftGroupId,
          gifts: gifts,
        ),
      ),
    );
  }

  /// Сбросить флаг проверки (вызывать при выходе из аккаунта)
  void resetSessionCheck() {
    _hasCheckedThisSession = false;
  }
}







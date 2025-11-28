import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:ketroy_app/core/constants/hive_constants.dart';
import 'package:ketroy_app/core/model/active_gift_model.dart';
import 'package:ketroy_app/features/active_gifts/presentation/view_model/active_gifts_view_model.dart';

class AllGiftsViewModel with ChangeNotifier {
  List<ActiveGiftsViewModel> items = [];
  Timer? _cleanupTimer;
  bool _disposed = false;

  void initialize() {
    if (_disposed) return;
    loadItems();
    startCleanUp();
  }

  void loadItems() {
    if (_disposed) return; // Проверяем перед выполнением

    try {
      final activeGiftBox = Hive.box<ActiveGiftModel>(activeGiftsBoxName);

      // Фильтруем только не истекшие подарки при загрузке
      final validItems =
          activeGiftBox.values.where((item) => !_isExpired(item)).toList();

      items = validItems
          .map((e) => ActiveGiftsViewModel(
              giftModel: e, onExpired: () => _removeExpiredItem(e.id)))
          .toList();

      // Сортируем по дате создания (новые сверху)
      items.sort(
          (a, b) => b.giftModel.createdAt.compareTo(a.giftModel.createdAt));

      debugPrint(
          'AllGiftsViewModel: Загружено ${items.length} активных подарков');

      // Проверяем перед вызовом notifyListeners
      if (!_disposed) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Ошибка при загрузке подарков: $e');
    }
  }

  Future<bool> addItem(String image, int id, String name) async {
    if (_disposed) return false; // Проверяем перед выполнением

    try {
      final activeGiftsBox = Hive.box<ActiveGiftModel>(activeGiftsBoxName);

      // Проверяем, не существует ли уже подарок с таким ID
      final existingItem = activeGiftsBox.values.where((item) => item.id == id);
      if (existingItem.isNotEmpty) {
        debugPrint('Подарок с ID $id уже существует');
        return false;
      }

      final item = ActiveGiftModel(
          image: image, createdAt: DateTime.now(), id: id, name: name);

      await activeGiftsBox.add(item);
      debugPrint('Подарок добавлен в базу: ID=$id, name=$name');

      loadItems(); // Перезагружаем список
      return true;
    } catch (e) {
      debugPrint('Ошибка при добавлении подарка: $e');
      return false;
    }
  }

  // Проверка истек ли подарок (10 минут = 600 секунд)
  bool _isExpired(ActiveGiftModel item) {
    final now = DateTime.now();
    return now.difference(item.createdAt).inSeconds >= 600;
  }

  // Удаление конкретного истекшего подарка
  Future<void> _removeExpiredItem(int id) async {
    if (_disposed) return; // Проверяем перед выполнением

    try {
      final activeGiftBox = Hive.box<ActiveGiftModel>(activeGiftsBoxName);

      // Находим элемент по ID и удаляем
      for (int i = 0; i < activeGiftBox.length; i++) {
        final item = activeGiftBox.getAt(i);
        if (item != null && item.id == id) {
          await activeGiftBox.deleteAt(i);
          debugPrint('Удален истекший подарок с ID: $id');
          break;
        }
      }

      // Удаляем из локального списка
      items.removeWhere((viewModel) => viewModel.giftModel.id == id);

      // Проверяем перед вызовом notifyListeners
      if (!_disposed) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Ошибка при удалении истекшего подарка: $e');
    }
  }

  // Автоматическая очистка каждые 10 секунд
  void startCleanUp() {
    if (_disposed) return; // Проверяем перед запуском

    _cleanupTimer?.cancel(); // Отменяем предыдущий таймер

    _cleanupTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      // Проверяем не был ли объект disposed
      if (_disposed) {
        timer.cancel();
        return;
      }

      await _cleanupExpiredItems();
    });
  }

  // Очистка всех истекших подарков
  Future<void> _cleanupExpiredItems() async {
    if (_disposed) return; // Проверяем перед выполнением

    try {
      final activeGiftBox = Hive.box<ActiveGiftModel>(activeGiftsBoxName);
      final now = DateTime.now();

      // Собираем список истекших элементов
      List<int> expiredKeys = [];
      for (int i = 0; i < activeGiftBox.length; i++) {
        final item = activeGiftBox.getAt(i);
        if (item != null && now.difference(item.createdAt).inSeconds >= 600) {
          expiredKeys.add(i);
        }
      }

      // Удаляем в обратном порядке (чтобы индексы не сбились)
      for (int i = expiredKeys.length - 1; i >= 0; i--) {
        await activeGiftBox.deleteAt(expiredKeys[i]);
      }

      if (expiredKeys.isNotEmpty) {
        debugPrint(
            'Автоматически удалено ${expiredKeys.length} истекших подарков');
        loadItems(); // Обновляем список (внутри есть проверка на _disposed)
      }
    } catch (e) {
      debugPrint('Ошибка при автоматической очистке: $e');
    }
  }

  // Принудительная очистка всех истекших подарков
  Future<void> forceCleanupExpiredItems() async {
    if (_disposed) return;
    await _cleanupExpiredItems();
  }

  // Получение количества активных подарков
  int get activeItemsCount => _disposed ? 0 : items.length;

  // Остановка автоматической очистки
  void stopCleanUp() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }

  @override
  void dispose() {
    debugPrint('AllGiftsViewModel: dispose вызван');
    _disposed = true; // Устанавливаем флаг disposed

    // Останавливаем таймер очистки
    stopCleanUp();

    // Очищаем таймеры во всех элементах
    for (var item in items) {
      item.dispose();
    }

    items.clear(); // Очищаем список
    super.dispose();
  }
}

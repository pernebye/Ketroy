import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:ketroy_app/core/constants/hive_constants.dart';
import 'package:ketroy_app/core/model/active_gift_model.dart';
import 'package:ketroy_app/features/active_gifts/presentation/view_model/active_gifts_view_model.dart';

class AllGiftsViewModel with ChangeNotifier {
  List<ActiveGiftsViewModel> items = [];
  bool _disposed = false;

  void initialize() {
    if (_disposed) return;
    loadItems();
  }

  void loadItems() {
    if (_disposed) return; // Проверяем перед выполнением

    try {
      final activeGiftBox = Hive.box<ActiveGiftModel>(activeGiftsBoxName);

      // Загружаем все подарки
      final allItems = activeGiftBox.values.toList();

      items = allItems
          .map((e) => ActiveGiftsViewModel(giftModel: e))
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


  // Получение количества активных подарков
  int get activeItemsCount => _disposed ? 0 : items.length;


  @override
  void dispose() {
    debugPrint('AllGiftsViewModel: dispose вызван');
    _disposed = true; // Устанавливаем флаг disposed

    // Очищаем таймеры во всех элементах
    for (var item in items) {
      item.dispose();
    }

    items.clear(); // Очищаем список
    super.dispose();
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ketroy_app/core/model/active_gift_model.dart';

class ActiveGiftsViewModel with ChangeNotifier {
  final ActiveGiftModel giftModel;
  final VoidCallback? onExpired;
  late int _secondsRemaining;
  Timer? _timer;
  bool _isExpired = false;
  bool _disposed = false; // Флаг для отслеживания состояния

  ActiveGiftsViewModel({
    required this.giftModel,
    this.onExpired,
  }) {
    _startCountDown();
  }

  int get secondsRemaining => _secondsRemaining;
  bool get isExpired => _isExpired;
  String get giftName => giftModel.name;
  String get giftImage => giftModel.image;
  int get giftId => giftModel.id;
  DateTime get createdAt => giftModel.createdAt;

  String get formattedTime {
    if (_isExpired) return '00:00';

    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Процент оставшегося времени (0-100)
  double get progressPercentage {
    if (_isExpired) return 0.0;
    const totalSeconds = 600; // 10 минут
    return (_secondsRemaining / totalSeconds) * 100;
  }

  // Цвет индикатора в зависимости от оставшегося времени
  Color get timeColor {
    if (_isExpired) return Colors.red;
    if (_secondsRemaining < 60) return Colors.red; // Последняя минута
    if (_secondsRemaining < 180) return Colors.orange; // Последние 3 минуты
    return Colors.green;
  }

  // Статус подарка в виде строки
  String get status {
    if (_isExpired) return 'Истёк';
    if (_secondsRemaining < 60) return 'Критично';
    if (_secondsRemaining < 180) return 'Скоро истечёт';
    return 'Активен';
  }

  void _startCountDown() {
    if (_disposed) return;

    final end = giftModel.createdAt.add(const Duration(minutes: 10));
    final now = DateTime.now();
    _secondsRemaining = end.difference(now).inSeconds;

    // Если подарок уже истёк
    if (_secondsRemaining <= 0) {
      _secondsRemaining = 0;
      _isExpired = true;
      onExpired?.call(); // Уведомляем о истечении

      if (!_disposed) {
        notifyListeners();
      }
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Проверяем не был ли объект disposed
      if (_disposed) {
        timer.cancel();
        return;
      }

      if (_secondsRemaining > 0) {
        _secondsRemaining--;

        if (!_disposed) {
          notifyListeners();
        }
      } else {
        _secondsRemaining = 0;
        _isExpired = true;
        timer.cancel();

        // Уведомляем родительский ViewModel об истечении
        onExpired?.call();

        if (!_disposed) {
          notifyListeners();
        }
      }
    });
  }

  // Пауза таймера
  void pauseTimer() {
    _timer?.cancel();
  }

  // Возобновление таймера
  void resumeTimer() {
    if (!_disposed && !_isExpired && _secondsRemaining > 0) {
      _startCountDown();
    }
  }

  // Принудительное завершение подарка
  void expireGift() {
    if (_disposed) return;

    _timer?.cancel();
    _secondsRemaining = 0;
    _isExpired = true;

    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true; // Устанавливаем флаг disposed
    _timer?.cancel(); // Отменяем таймер
    super.dispose();
  }
}

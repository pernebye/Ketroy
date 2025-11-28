import 'dart:async';

import 'package:flutter/material.dart';

class SmsPageViewModel extends ChangeNotifier {
  Timer? _timer;
  static const _maxSeconds = 60;
  int _seconds = _maxSeconds;

  int get seconds => _seconds;

  void startTimer() {
    _timer?.cancel();
    _seconds = _maxSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds > 0) {
        _seconds--;
        notifyListeners();
      } else {
        stopTimer();
      }
    });
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

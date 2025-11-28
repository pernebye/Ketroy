import 'package:flutter/material.dart';
import 'package:ketroy_app/select_page.dart';

/// Главный экран приложения - показывает страницу выбора (регистрация/гость)
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SelectPage();
  }
}

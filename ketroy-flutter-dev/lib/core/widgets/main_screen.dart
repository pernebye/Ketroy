import 'package:flutter/material.dart';
import 'package:ketroy_app/core/navBar/nav_bar.dart';
import 'package:ketroy_app/core/widgets/loader.dart';
import 'package:ketroy_app/select_page.dart';
import 'package:ketroy_app/services/local_storage/user_data_manager.dart';

/// Главный экран приложения - проверяет авторизацию и показывает соответствующий экран
/// 
/// Если пользователь уже авторизован (есть сохранённый токен и данные):
/// - Перенаправляет на NavScreen с полным функционалом
/// 
/// Если не авторизован:
/// - Показывает SelectPage (выбор: регистрация или гость)
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: UserDataManager.isUserLoggedIn(),
      builder: (context, snapshot) {
        // Показываем лоадер пока проверяем авторизацию
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const BrandedLoadingScreen();
        }
        
        final isLoggedIn = snapshot.data ?? false;
        
        if (isLoggedIn) {
          // Пользователь авторизован - переходим на главный экран с токеном
          debugPrint('✅ MainScreen: User is logged in, navigating to NavScreen');
          return NavScreen(
            key: NavScreen.globalKey,
            withToken: true,
            initialTab: 0,
          );
        } else {
          // Пользователь не авторизован - показываем страницу выбора
          debugPrint('👤 MainScreen: User not logged in, showing SelectPage');
          return SelectPage();
        }
      },
    );
  }
}

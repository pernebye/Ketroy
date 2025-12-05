# Команды для исправления сборки iOS

## Вариант 1: Автоматический скрипт (рекомендуется)

Выполните в терминале:

```bash
cd /Users/yernar/Documents/Ketroy/ketroy-flutter-dev
bash fix_ios_build.sh
```

Скрипт автоматически найдет Flutter и настроит все зависимости.

---

## Вариант 2: Ручные команды

Если знаете путь к Flutter SDK, выполните:

```bash
# 1. Перейдите в директорию проекта
cd /Users/yernar/Documents/Ketroy/ketroy-flutter-dev

# 2. Добавьте Flutter в PATH (замените /path/to/flutter на реальный путь)
export PATH="/path/to/flutter/bin:$PATH"

# 3. Сгенерируйте конфигурацию Flutter
flutter pub get

# 4. Установите CocoaPods зависимости
cd ios
pod install

# 5. Вернитесь в корень проекта
cd ..
```

---

## Вариант 3: Если Flutter установлен через Homebrew

```bash
cd /Users/yernar/Documents/Ketroy/ketroy-flutter-dev
brew install --cask flutter
export PATH="/opt/homebrew/bin:$PATH"
flutter pub get
cd ios && pod install && cd ..
```

---

## После выполнения команд

После успешного выполнения команд можно собирать проект:

1. **Через Xcode:**
   - Откройте `ios/Runner.xcworkspace` в Xcode
   - Выберите устройство "Pernebye"
   - Нажмите Run (⌘R)

2. **Через командную строку:**
   ```bash
   flutter run -d 00008130-0014281E0C01001C
   ```

---

## Если Flutter не установлен

Установите Flutter:
1. Скачайте с https://docs.flutter.dev/get-started/install/macos
2. Распакуйте в `~/flutter` или другое место
3. Добавьте в PATH: `export PATH="$HOME/flutter/bin:$PATH"` в `~/.zshrc`
4. Выполните команды из Варианта 2


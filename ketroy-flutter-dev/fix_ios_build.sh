#!/bin/bash
# Скрипт для исправления проблем сборки iOS
# Автоматически находит Flutter и настраивает проект

set -e

cd "$(dirname "$0")"

echo "🔍 Ищу Flutter SDK..."

# Список возможных путей к Flutter
FLUTTER_PATHS=(
  "$HOME/flutter"
  "$HOME/development/flutter"
  "$HOME/Documents/flutter"
  "/usr/local/flutter"
  "/opt/flutter"
  "$HOME/Library/flutter"
  "/Applications/flutter"
)

FLUTTER_PATH=""

# Поиск Flutter
for path in "${FLUTTER_PATHS[@]}"; do
  if [ -f "$path/bin/flutter" ]; then
    FLUTTER_PATH="$path"
    echo "✅ Найден Flutter: $FLUTTER_PATH"
    break
  fi
done

# Если не найден, спрашиваем у пользователя
if [ -z "$FLUTTER_PATH" ]; then
  echo ""
  echo "❌ Flutter SDK не найден автоматически."
  echo "Пожалуйста, введите путь к Flutter SDK (например: /Users/yourname/flutter):"
  read -r FLUTTER_PATH
  
  if [ ! -f "$FLUTTER_PATH/bin/flutter" ]; then
    echo "❌ Ошибка: Flutter не найден по указанному пути: $FLUTTER_PATH"
    exit 1
  fi
fi

# Добавляем Flutter в PATH
export PATH="$FLUTTER_PATH/bin:$PATH"

echo ""
echo "🔧 Шаг 1: Генерация Flutter конфигурации..."
flutter pub get

echo ""
echo "📦 Шаг 2: Установка CocoaPods (если не установлен)..."
if ! command -v pod &> /dev/null; then
  echo "Устанавливаю CocoaPods..."
  sudo gem install cocoapods || {
    echo "⚠️ Не удалось установить CocoaPods через sudo. Пробую через gem без sudo..."
    gem install --user-install cocoapods
    export PATH="$HOME/.gem/ruby/2.6.0/bin:$PATH"
  }
fi

echo ""
echo "📦 Шаг 3: Установка CocoaPods зависимостей..."
cd ios
pod install

echo ""
echo "✅ Готово! Все зависимости установлены."
echo ""
echo "Теперь можно собирать проект через Xcode или командой:"
echo "  flutter run -d 00008130-0014281E0C01001C"


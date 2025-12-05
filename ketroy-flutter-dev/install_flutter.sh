#!/bin/bash
# Автоматическая установка Flutter через Homebrew
# Этот скрипт установит Homebrew (если нужно) и Flutter

set -e

echo "🚀 Автоматическая установка Flutter через Homebrew"
echo ""

# Функция для определения пути к Homebrew
find_brew() {
  if [ -f "/opt/homebrew/bin/brew" ]; then
    echo "/opt/homebrew/bin/brew"
  elif [ -f "/usr/local/bin/brew" ]; then
    echo "/usr/local/bin/brew"
  else
    echo ""
  fi
}

BREW_PATH=$(find_brew)

# Установка Homebrew, если не найден
if [ -z "$BREW_PATH" ]; then
  echo "📦 Homebrew не найден. Устанавливаю Homebrew..."
  echo "⚠️  Потребуется ввести пароль администратора"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  
  # Определяем путь после установки
  if [ -f "/opt/homebrew/bin/brew" ]; then
    BREW_PATH="/opt/homebrew/bin/brew"
    # Добавляем в PATH для Apple Silicon
    if [ -f "$HOME/.zshrc" ]; then
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
  elif [ -f "/usr/local/bin/brew" ]; then
    BREW_PATH="/usr/local/bin/brew"
  fi
else
  echo "✅ Homebrew найден: $BREW_PATH"
  export PATH="$(dirname $BREW_PATH):$PATH"
fi

# Проверяем, установлен ли Flutter
echo ""
echo "🔍 Проверяю, установлен ли Flutter..."
if $BREW_PATH list --cask flutter &>/dev/null; then
  echo "✅ Flutter уже установлен через Homebrew"
  FLUTTER_PATH="$($BREW_PATH --prefix)/Caskroom/flutter"
else
  echo "📦 Устанавливаю Flutter через Homebrew..."
  $BREW_PATH install --cask flutter
  
  # Ждем завершения установки
  sleep 2
  FLUTTER_PATH="$($BREW_PATH --prefix)/Caskroom/flutter"
fi

# Находим реальный путь к Flutter
if [ -d "$FLUTTER_PATH" ]; then
  FLUTTER_BIN=$(find "$FLUTTER_PATH" -name "flutter" -type f -path "*/bin/flutter" | head -1)
  if [ -n "$FLUTTER_BIN" ]; then
    FLUTTER_DIR=$(dirname $(dirname "$FLUTTER_BIN"))
    echo "✅ Flutter установлен: $FLUTTER_DIR"
    export PATH="$FLUTTER_DIR/bin:$PATH"
  fi
fi

# Проверяем установку
echo ""
echo "🔧 Проверяю установку Flutter..."
if command -v flutter &> /dev/null; then
  flutter --version | head -3
  echo ""
  echo "✅ Flutter успешно установлен!"
  echo ""
  echo "Теперь настраиваю проект..."
  cd "$(dirname "$0")"
  
  echo ""
  echo "📦 Генерирую Flutter конфигурацию..."
  flutter pub get
  
  echo ""
  echo "📦 Устанавливаю CocoaPods зависимости..."
  cd ios
  
  # Устанавливаем CocoaPods, если нужно
  if ! command -v pod &> /dev/null; then
    echo "Устанавливаю CocoaPods..."
    $BREW_PATH install cocoapods || {
      echo "Пробую установить через gem..."
      sudo gem install cocoapods || gem install --user-install cocoapods
      export PATH="$HOME/.gem/ruby/2.6.0/bin:$PATH"
    }
  fi
  
  pod install
  
  echo ""
  echo "✅ ВСЕ ГОТОВО! Проект настроен и готов к сборке."
  echo ""
  echo "Теперь можно собирать проект:"
  echo "  flutter run -d 00008130-0014281E0C01001C"
  echo "или через Xcode:"
  echo "  open ios/Runner.xcworkspace"
else
  echo "❌ Ошибка: Flutter не найден после установки"
  exit 1
fi


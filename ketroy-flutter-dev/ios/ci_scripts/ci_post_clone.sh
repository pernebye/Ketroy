#!/bin/sh

# ci_post_clone.sh
# This script runs after Xcode Cloud clones the repository
# It installs Flutter and builds the Flutter project

set -e

echo "=== Starting Flutter CI Setup ==="

# Navigate to the root of the Flutter project
cd "$CI_PRIMARY_REPOSITORY_PATH/ketroy-flutter-dev"

# Install Flutter using git
echo "=== Installing Flutter ==="
git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
export PATH="$PATH:$HOME/flutter/bin"

# Disable Flutter analytics
flutter config --no-analytics

# Run Flutter doctor
echo "=== Flutter Doctor ==="
flutter doctor -v

# Get Flutter dependencies
echo "=== Getting Flutter Dependencies ==="
flutter pub get

# Build Flutter iOS app (release mode)
echo "=== Building Flutter iOS ==="
flutter build ios --release --no-codesign

# Install CocoaPods dependencies
echo "=== Installing CocoaPods ==="
cd ios
pod install

echo "=== Flutter CI Setup Complete ==="

#!/bin/sh

# ci_post_clone.sh
# This script runs after Xcode Cloud clones the repository
# It installs Flutter and builds the Flutter project

set -e

echo "=== Starting Flutter CI Setup ==="

# Check if changes are only in ketroy-flutter-dev folder
# Skip build if no mobile app changes detected
echo "=== Checking for mobile app changes ==="

cd "$CI_PRIMARY_REPOSITORY_PATH"

# Get changed files in the last commit
CHANGED_FILES=$(git diff --name-only HEAD~1 HEAD 2>/dev/null || echo "ketroy-flutter-dev/")

# Check if any changes are in ketroy-flutter-dev
if echo "$CHANGED_FILES" | grep -q "^ketroy-flutter-dev/"; then
    echo "✅ Mobile app changes detected, proceeding with build..."
else
    echo "⏭️ No mobile app changes detected. Skipping build."
    echo "Changed files: $CHANGED_FILES"
    # Exit with success to not fail the workflow, but skip actual build
    exit 0
fi

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

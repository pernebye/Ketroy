#!/bin/sh

# ci_pre_xcodebuild.sh
# This script runs before Xcode builds the project
# Use this for any last-minute setup

set -e

echo "=== Pre-Xcodebuild Script ==="

# Navigate to iOS directory
cd "$CI_PRIMARY_REPOSITORY_PATH/ketroy-flutter-dev/ios"

# Ensure pods are installed
if [ ! -d "Pods" ]; then
    echo "=== Pods directory not found, running pod install ==="
    pod install
fi

# Clear any extended attributes that might cause codesign issues
echo "=== Clearing extended attributes ==="
xattr -cr "$CI_PRIMARY_REPOSITORY_PATH/ketroy-flutter-dev" 2>/dev/null || true

echo "=== Pre-Xcodebuild Complete ==="

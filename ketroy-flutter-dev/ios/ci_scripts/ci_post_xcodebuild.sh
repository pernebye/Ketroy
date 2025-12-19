#!/bin/sh

# ci_post_xcodebuild.sh
# This script runs after Xcode builds the project
# Use this for cleanup or notifications

set -e

echo "=== Post-Xcodebuild Script ==="

if [ "$CI_XCODEBUILD_EXIT_CODE" -eq 0 ]; then
    echo "Build succeeded!"
else
    echo "Build failed with exit code: $CI_XCODEBUILD_EXIT_CODE"
fi

echo "=== Build Info ==="
echo "Product: $CI_PRODUCT"
echo "Archive Path: $CI_ARCHIVE_PATH"
echo "Build Number: $CI_BUILD_NUMBER"

echo "=== Post-Xcodebuild Complete ==="

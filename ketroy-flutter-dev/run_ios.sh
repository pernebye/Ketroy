#!/bin/bash
# Script to build and run Flutter iOS app on device

cd "$(dirname "$0")"

echo "🧹 Cleaning..."
rm -rf build/ios

echo "📦 Getting packages..."
flutter pub get

echo "🔨 Building with Xcode..."
cd ios
xcodebuild -workspace Runner.xcworkspace \
    -scheme Runner \
    -destination 'id=00008130-0014281E0C01001C' \
    -configuration Debug \
    CODE_SIGN_IDENTITY="Apple Development" \
    DEVELOPMENT_TEAM=692V473WBW \
    CODE_SIGN_STYLE=Automatic \
    build

if [ $? -eq 0 ]; then
    echo "✅ Build succeeded!"
    echo "📱 Installing on device..."
    
    # Find the built app
    APP_PATH=$(find ../build/ios -name "Runner.app" -type d | head -1)
    
    if [ -n "$APP_PATH" ]; then
        xcrun devicectl device install app --device 00008130-0014281E0C01001C "$APP_PATH"
        
        if [ $? -eq 0 ]; then
            echo "🚀 App installed! Launching..."
            xcrun devicectl device process launch --device 00008130-0014281E0C01001C com.aldiyar.ketroyApp
        fi
    else
        echo "❌ App not found"
    fi
else
    echo "❌ Build failed"
fi


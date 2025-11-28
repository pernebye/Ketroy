@echo off
echo Starting Ketroy in Chrome (CORS disabled for testing)...
cd /d "%~dp0"
flutter run -d chrome --web-browser-flag="--disable-web-security" --web-browser-flag="--user-data-dir=C:/temp/chrome_test_ketroy"
echo.
echo App closed. Press any key to exit...
pause


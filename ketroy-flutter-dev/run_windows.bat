@echo off
echo Starting Ketroy Windows App...
cd /d "%~dp0"

REM Add NuGet to PATH
set PATH=%PATH%;C:\Users\perne\AppData\Local\Microsoft\WinGet\Links

echo Building and launching Windows app...
flutter run -d windows
echo.
echo App closed. Press any key to exit...
pause


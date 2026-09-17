@echo off
setlocal
where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter is not installed or not on PATH.
  echo Install the current stable Flutter SDK, then run this file again.
  pause
  exit /b 1
)

echo [1/4] Regenerating standard Android/iOS platform boilerplate...
flutter create .
if errorlevel 1 exit /b 1

echo [2/5] Applying AdMob native placeholders...
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\configure_ads_after_flutter_create.ps1
if errorlevel 1 exit /b 1

echo [3/5] Getting packages...
flutter pub get
if errorlevel 1 exit /b 1

echo [4/5] Static analysis...
flutter analyze
if errorlevel 1 exit /b 1

echo [5/5] Tests...
flutter test
if errorlevel 1 exit /b 1

echo.
echo Project setup and checks completed.
echo Next: flutter run
pause

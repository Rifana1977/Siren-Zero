@echo off
echo ================================
echo MESH NETWORK TEST - QUICK START
echo ================================
echo.

echo Checking setup...
call flutter doctor -v
echo.

echo Available devices:
call flutter devices
echo.

echo ================================
echo Choose a test method:
echo ================================
echo 1. Test Mesh Network (Recommended)
echo 2. Test with Full App
echo 3. Build APK
echo 4. Clean and Rebuild
echo 5. Exit
echo.

set /p choice="Enter your choice (1-5): "

if "%choice%"=="1" (
    echo.
    echo Running Mesh Network Test...
    call flutter run -t lib/test_mesh.dart
)

if "%choice%"=="2" (
    echo.
    echo Running Full App with Mesh...
    call flutter run -t lib/main_with_mesh.dart
)

if "%choice%"=="3" (
    echo.
    echo Building APK...
    call flutter build apk --debug -t lib/test_mesh.dart
    echo.
    echo APK built at: build\app\outputs\flutter-apk\app-debug.apk
    pause
)

if "%choice%"=="4" (
    echo.
    echo Cleaning project...
    call flutter clean
    echo Getting dependencies...
    call flutter pub get
    echo.
    echo Done! Now run option 1 or 2.
    pause
)

if "%choice%"=="5" (
    exit
)

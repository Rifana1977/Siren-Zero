#!/bin/bash

echo "================================"
echo "MESH NETWORK TEST - QUICK START"
echo "================================"
echo ""

echo "Checking setup..."
flutter doctor -v
echo ""

echo "Available devices:"
flutter devices
echo ""

echo "================================"
echo "Choose a test method:"
echo "================================"
echo "1. Test Mesh Network (Recommended)"
echo "2. Test with Full App"
echo "3. Build APK"
echo "4. Clean and Rebuild"
echo "5. Exit"
echo ""

read -p "Enter your choice (1-5): " choice

case $choice in
    1)
        echo ""
        echo "Running Mesh Network Test..."
        flutter run -t lib/test_mesh.dart
        ;;
    2)
        echo ""
        echo "Running Full App with Mesh..."
        flutter run -t lib/main_with_mesh.dart
        ;;
    3)
        echo ""
        echo "Building APK..."
        flutter build apk --debug -t lib/test_mesh.dart
        echo ""
        echo "APK built at: build/app/outputs/flutter-apk/app-debug.apk"
        ;;
    4)
        echo ""
        echo "Cleaning project..."
        flutter clean
        echo "Getting dependencies..."
        flutter pub get
        echo ""
        echo "Done! Now run option 1 or 2."
        ;;
    5)
        exit 0
        ;;
    *)
        echo "Invalid choice"
        ;;
esac

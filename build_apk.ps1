# Script untuk men-generate Icon, Splash Screen, dan APK Release
Write-Output "Mengambil package terbaru..."
flutter pub get

Write-Output "Membuat App Icon..."
flutter pub run flutter_launcher_icons

Write-Output "Membuat Splash Screen..."
flutter pub run flutter_native_splash:create

Write-Output "Membangun APK versi Release..."
flutter build apk --release

Write-Output "Proses Selesai! File APK dapat ditemukan di folder build\app\outputs\flutter-apk\app-release.apk"

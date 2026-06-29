# Script untuk men-generate Icon, Splash Screen, dan APK Release
echo "Mengambil package terbaru..."
flutter pub get

echo "Membuat App Icon..."
flutter pub run flutter_launcher_icons

echo "Membuat Splash Screen..."
flutter pub run flutter_native_splash:create

echo "Membangun APK versi Release..."
flutter build apk --release

echo "Proses Selesai! File APK dapat ditemukan di folder build\app\outputs\flutter-apk\app-release.apk"

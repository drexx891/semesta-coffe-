import 'package:flutter/material.dart';

/// Smesta Coffee color palette
/// Identitas visual: cokelat tua, cokelat medium, krem, putih, aksen emas/amber
class AppColors {
  AppColors._();

  // === Primary Colors ===
  static const Color primaryDark = Color(0xFF3E1C00);      // Cokelat tua
  static const Color primary = Color(0xFF7B3F00);           // Cokelat medium
  static const Color primaryLight = Color(0xFFA0622D);      // Cokelat terang
  static const Color primarySurface = Color(0xFFF5ECD7);    // Krem

  // === Accent Colors ===
  static const Color accent = Color(0xFFC8860A);            // Emas/amber
  static const Color accentLight = Color(0xFFE8B44D);       // Emas terang
  static const Color accentDark = Color(0xFF9A6700);        // Emas gelap

  // === Neutral Colors ===
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFFAF6EE);        // Warm white
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F0E8);
  static const Color border = Color(0xFFE0D5C5);
  static const Color divider = Color(0xFFEDE6D9);

  // === Text Colors ===
  static const Color textPrimary = Color(0xFF2D1810);        // Cokelat sangat tua
  static const Color textSecondary = Color(0xFF6B5B4E);      // Cokelat medium
  static const Color textTertiary = Color(0xFF9C8D80);       // Cokelat muda
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnAccent = Color(0xFFFFFFFF);

  // === Status Colors ===
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFE65100);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color error = Color(0xFFC62828);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF1565C0);
  static const Color infoLight = Color(0xFFE3F2FD);

  // === Stock Indicator Colors ===
  static const Color stockCritical = Color(0xFFD32F2F);      // 🔴 Di bawah minimum
  static const Color stockWarning = Color(0xFFF9A825);       // 🟡 Mendekati minimum
  static const Color stockSafe = Color(0xFF388E3C);          // 🟢 Aman

  // === Overlay / Dialog ===
  static const Color overlay = Color(0x80000000);
  static const Color shimmerBase = Color(0xFFE0D5C5);
  static const Color shimmerHighlight = Color(0xFFF5ECD7);

  // === Card & Shadows ===
  static const Color cardShadow = Color(0x1A3E1C00);

  // === Order Type Colors ===
  static const Color dineIn = Color(0xFF5D4037);
  static const Color takeAway = Color(0xFFC8860A);

  // === Payment Method Colors ===
  static const Color paymentCash = Color(0xFF2E7D32);
  static const Color paymentQris = Color(0xFF1565C0);
  static const Color paymentTransfer = Color(0xFF6A1B9A);
  static const Color paymentEdc = Color(0xFFE65100);
  static const Color paymentVoucher = Color(0xFFC62828);

  /// Gradient utama aplikasi
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primary],
  );

  /// Gradient aksen
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentLight],
  );

  /// Gradient background
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [background, primarySurface],
  );
}

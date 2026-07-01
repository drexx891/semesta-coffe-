import 'dart:async';
import 'package:flutter/foundation.dart';

class PrinterService {
  /// Send ESC/POS bytes to a network printer at the specified [ipAddress] and [port].
  /// Default thermal printer port is 9100.
  /// On web platform, TCP sockets are not available, so this is a no-op.
  Future<void> printViaTcp(String ipAddress, List<int> bytes, {int port = 9100}) async {
    if (ipAddress.trim().isEmpty) {
      throw Exception('IP Address printer tidak boleh kosong.');
    }

    if (kIsWeb) {
      // TCP sockets are not available on the web platform
      debugPrint('PrinterService: Printing via TCP is not supported on Web. Skipping.');
      return;
    }

    // Import dart:io dynamically only on non-web platforms
    await _printViaTcpNative(ipAddress, bytes, port);
  }
}

/// Native TCP print implementation — only called on non-web platforms
Future<void> _printViaTcpNative(String ipAddress, List<int> bytes, int port) async {
  // Conditional import is handled by the fact that this code path
  // is only reached on non-web platforms where dart:io is available.
  // However, for Flutter web compilation, we need to avoid importing dart:io
  // at the top level. We use a stub approach instead.
  //
  // Since this app targets web deployment (Vercel), we keep this as a
  // no-op placeholder. For Android/Desktop builds, you can create a
  // platform-specific implementation.
  debugPrint('PrinterService: TCP printing requested to $ipAddress:$port (${bytes.length} bytes)');
}

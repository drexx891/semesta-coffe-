import 'dart:io';
import 'dart:async';

class PrinterService {
  /// Send ESC/POS bytes to a network printer at the specified [ipAddress] and [port].
  /// Default thermal printer port is 9100.
  Future<void> printViaTcp(String ipAddress, List<int> bytes, {int port = 9100}) async {
    if (ipAddress.trim().isEmpty) {
      throw Exception('IP Address printer tidak boleh kosong.');
    }
    
    Socket? socket;
    try {
      socket = await Socket.connect(ipAddress, port, timeout: const Duration(seconds: 3));
      socket.add(bytes);
      await socket.flush();
    } on SocketException catch (e) {
      throw Exception('Koneksi printer gagal atau printer offline: ${e.message}');
    } catch (e) {
      throw Exception('Terjadi kesalahan saat mencetak: $e');
    } finally {
      socket?.destroy();
    }
  }
}

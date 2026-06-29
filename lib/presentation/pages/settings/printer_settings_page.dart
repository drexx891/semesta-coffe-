import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection_container.dart';
import '../../../data/database/dao/settings_dao.dart';
import '../../../services/printer_service.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PrinterSettingsPage extends StatefulWidget {
  const PrinterSettingsPage({super.key});

  @override
  State<PrinterSettingsPage> createState() => _PrinterSettingsPageState();
}

class _PrinterSettingsPageState extends State<PrinterSettingsPage> {
  final SettingsDao _settingsDao = sl<SettingsDao>();
  bool _isLoading = true;
  
  bool _autoPrintReceipt = true;
  String _paperSize = '58mm';
  late TextEditingController _receiptPrinterController;
  late TextEditingController _baristaPrinterController;

  @override
  void initState() {
    super.initState();
    _receiptPrinterController = TextEditingController();
    _baristaPrinterController = TextEditingController();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsDao.getSettings();
    final prefs = sl<SharedPreferences>();
    
    if (settings != null) {
      _paperSize = settings['printer_paper_size'] as String? ?? '58mm';
      _receiptPrinterController.text = settings['receipt_printer_address'] as String? ?? '';
      _baristaPrinterController.text = settings['barista_printer_address'] as String? ?? '';
    }
    
    _autoPrintReceipt = prefs.getBool('auto_print_receipt') ?? true;
    
    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      final prefs = sl<SharedPreferences>();
      await prefs.setBool('auto_print_receipt', _autoPrintReceipt);
      
      await _settingsDao.updateSettings({
        'printer_paper_size': _paperSize,
        'receipt_printer_address': _receiptPrinterController.text.trim(),
        'barista_printer_address': _baristaPrinterController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengaturan printer berhasil disimpan')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _testPrint(String ipAddress) async {
    if (ipAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alamat IP kosong')));
      return;
    }
    
    try {
      final printerService = sl<PrinterService>();
      final bytes = [
        0x1B, 0x40, // Init
        ...('TEST PRINT S.COFFEE\nTest koneksi berhasil.\n').codeUnits,
        0x0A, 0x0A, // Feed
        0x1D, 0x56, 0x00, // Cut
      ];
      await printerService.printViaTcp(ipAddress, bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test print berhasil dikirim!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  void dispose() {
    _receiptPrinterController.dispose();
    _baristaPrinterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Pengaturan Printer', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primaryDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded),
            onPressed: _isLoading ? null : _saveSettings,
            tooltip: 'Simpan',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Konfigurasi Kertas', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _paperSize,
                          decoration: const InputDecoration(
                            labelText: 'Ukuran Kertas Printer',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.receipt_rounded),
                          ),
                          items: const [
                            DropdownMenuItem(value: '58mm', child: Text('58mm (Kecil)')),
                            DropdownMenuItem(value: '80mm', child: Text('80mm (Standar/Besar)')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _paperSize = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cetak Otomatis', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          title: const Text('Auto-Print Struk Transaksi'),
                          subtitle: const Text('Otomatis memicu dialog print struk sesaat setelah transaksi berhasil disimpan'),
                          value: _autoPrintReceipt,
                          onChanged: (val) {
                            setState(() => _autoPrintReceipt = val);
                          },
                          activeThumbColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Koneksi Printer', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _receiptPrinterController,
                          decoration: InputDecoration(
                            labelText: 'Alamat Jaringan Printer Kasir (IP Jaringan/LAN)',
                            hintText: 'Cth: 192.168.1.100',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(LucideLucideIcons.printerer),
                            suffixIcon: TextButton(
                              onPressed: () => _testPrint(_receiptPrinterController.text.trim()),
                              child: const Text('TEST PRINT'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _baristaPrinterController,
                          decoration: InputDecoration(
                            labelText: 'Alamat Jaringan Printer Dapur/Barista',
                            hintText: 'Cth: 192.168.1.101',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.restaurant_rounded),
                            suffixIcon: TextButton(
                              onPressed: () => _testPrint(_baristaPrinterController.text.trim()),
                              child: const Text('TEST PRINT'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.warning)),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: AppColors.warning),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Catatan: Integrasi hardware printer (Bluetooth/Network) secara riil dapat bervariasi bergantung platform (Android/Windows/Web). Simpan konfigurasi ini agar backend siap digunakan saat driver terpasang.',
                                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

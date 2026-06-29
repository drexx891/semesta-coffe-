import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection_container.dart';
import '../../../data/database/dao/settings_dao.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

class TransactionConfigPage extends StatefulWidget {
  const TransactionConfigPage({super.key});

  @override
  State<TransactionConfigPage> createState() => _TransactionConfigPageState();
}

class _TransactionConfigPageState extends State<TransactionConfigPage> {
  final SettingsDao _settingsDao = sl<SettingsDao>();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _taxController;
  late TextEditingController _serviceChargeController;
  late TextEditingController _discountController;

  bool _taxEnabled = true;
  bool _isLoading = true;
  bool _isSaving = false;
  
  String? _qrisBase64;

  @override
  void initState() {
    super.initState();
    _taxController = TextEditingController();
    _serviceChargeController = TextEditingController();
    _discountController = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    _taxController.dispose();
    _serviceChargeController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _settingsDao.getSettings();
      if (settings != null) {
        _taxController.text = (settings['tax_percentage'] as num?)?.toString() ?? '11.0';
        _serviceChargeController.text = (settings['service_charge_percentage'] as num?)?.toString() ?? '5.0';
        _discountController.text = (settings['max_cashier_discount'] as num?)?.toString() ?? '20.0';
        _taxEnabled = (settings['tax_enabled'] as int?) == 1;
        _qrisBase64 = settings['qris_image_path'] as String?;
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickQrisImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _qrisBase64 = base64Encode(result.files.single.bytes!);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar QRIS: $e')),
        );
      }
    }
  }

  Future<void> _removeQrisImage() async {
    setState(() {
      _qrisBase64 = null;
    });
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    try {
      await _settingsDao.updateSettings({
        'tax_percentage': double.tryParse(_taxController.text) ?? 0.0,
        'service_charge_percentage': double.tryParse(_serviceChargeController.text) ?? 0.0,
        'max_cashier_discount': double.tryParse(_discountController.text) ?? 0.0,
        'tax_enabled': _taxEnabled ? 1 : 0,
        'qris_image_path': _qrisBase64,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konfigurasi transaksi disimpan')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan konfigurasi: $e')));
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Konfigurasi Transaksi', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primaryDark,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      SwitchListTile(
                        title: Text('Aktifkan Perhitungan Pajak (PPN)', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Pajak akan otomatis dihitung pada setiap transaksi.'),
                        value: _taxEnabled,
                        onChanged: (v) => setState(() => _taxEnabled = v),
                        activeThumbColor: AppColors.primary,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _taxController,
                        keyboardType: TextInputType.number,
                        enabled: _taxEnabled,
                        decoration: const InputDecoration(
                          labelText: 'Persentase Pajak (PPN)',
                          suffixText: '%',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (_taxEnabled && (v == null || v.isEmpty)) return 'Wajib diisi';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _serviceChargeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Persentase Service Charge',
                          suffixText: '%',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _discountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Maksimal Diskon Kasir',
                          suffixText: '%',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      Text('QRIS Toko (Semua Pembayaran)', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 8),
                      const Text('Upload gambar QRIS statis yang akan ditampilkan di layar kasir saat metode pembayaran QRIS dipilih.'),
                      const SizedBox(height: 16),
                      if (_qrisBase64 != null) ...[
                        Container(
                          height: 200,
                          alignment: Alignment.centerLeft,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(base64Decode(_qrisBase64!), fit: BoxFit.contain),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickQrisImage,
                            icon: const Icon(Icons.upload_file_rounded),
                            label: const Text('Upload QRIS'),
                          ),
                          if (_qrisBase64 != null) ...[
                            const SizedBox(width: 12),
                            TextButton.icon(
                              onPressed: _removeQrisImage,
                              icon: const Icon(Icons.delete_rounded, color: Colors.red),
                              label: const Text('Hapus', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _saveSettings,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.primary,
                        ),
                        child: _isSaving 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text('SIMPAN PERUBAHAN', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

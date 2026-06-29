import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection_container.dart';
import '../../../data/database/dao/settings_dao.dart';

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
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
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

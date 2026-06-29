import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection_container.dart';
import '../../../data/database/dao/shift_dao.dart';
import '../../../services/session_manager.dart';
import '../../../core/utils/currency_formatter.dart';

class ShiftPage extends StatefulWidget {
  const ShiftPage({super.key});

  @override
  State<ShiftPage> createState() => _ShiftPageState();
}

class _ShiftPageState extends State<ShiftPage> {
  final ShiftDao _shiftDao = sl<ShiftDao>();
  final SessionManager _session = sl<SessionManager>();
  
  bool _isLoading = true;
  Map<String, dynamic>? _activeShift;
  Map<String, dynamic>? _shiftSummary;

  final TextEditingController _cashController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadShiftState();
  }

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  Future<void> _loadShiftState() async {
    setState(() => _isLoading = true);
    try {
      _activeShift = await _shiftDao.getActiveShift();
      if (_activeShift != null) {
        _shiftSummary = await _shiftDao.calculateShiftSummary(_activeShift!['id'] as int);
      }
    } catch (e) {
      // ignore
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _openShift() async {
    final cashText = _cashController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final startingCash = double.tryParse(cashText) ?? 0.0;

    if (startingCash < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uang modal tidak valid')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _shiftDao.openShift({
        'user_id': _session.currentUser?.id ?? 1,
        'opening_cash': startingCash,
        'status': 'open',
        'opened_at': DateTime.now().toIso8601String(),
      });
      _cashController.clear();
      await _loadShiftState();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuka shift: $e')));
      }
    }
  }

  Future<void> _closeShift() async {
    final cashText = _cashController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final closingCash = double.tryParse(cashText) ?? 0.0;

    if (_activeShift == null || _shiftSummary == null) return;

    final startingCash = (_activeShift!['opening_cash'] as num).toDouble();
    final totalCashSales = (_shiftSummary!['totalCashSales'] as num).toDouble();
    final expectedCash = startingCash + totalCashSales;
    final difference = closingCash - expectedCash;

    setState(() => _isLoading = true);
    try {
      await _shiftDao.closeShift(
        shiftId: _activeShift!['id'] as int,
        closingCash: closingCash,
        expectedCash: expectedCash,
        cashDifference: difference,
        summary: _shiftSummary!,
      );
      _cashController.clear();
      await _loadShiftState();
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Shift Ditutup'),
            content: Text(
              difference == 0 
                ? 'Uang fisik sesuai dengan sistem (Balance).' 
                : difference > 0 
                  ? 'Terdapat kelebihan uang kasir sebesar ${CurrencyFormatter.format(difference)}'
                  : 'Terdapat kekurangan uang kasir sebesar ${CurrencyFormatter.format(difference.abs())}',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menutup shift: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.shift, style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primaryDark,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _activeShift == null
              ? _buildOpenShiftForm()
              : _buildCloseShiftForm(),
    );
  }

  Widget _buildOpenShiftForm() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.lock_open_rounded, size: 48, color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  'Buka Shift',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Masukkan uang modal awal di kasir sebelum memulai transaksi.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _cashController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Uang Modal Awal (Rp)',
                    prefixIcon: Icon(Icons.account_balance_wallet_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _openShift,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('BUKA SHIFT', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCloseShiftForm() {
    final startingCash = (_activeShift!['opening_cash'] as num).toDouble();
    final totalCashSales = _shiftSummary != null ? (_shiftSummary!['totalCashSales'] as num).toDouble() : 0.0;
    final totalSales = _shiftSummary != null ? (_shiftSummary!['totalSales'] as num).toDouble() : 0.0;
    final expectedCash = startingCash + totalCashSales;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.lock_rounded, size: 48, color: AppColors.accent),
                  const SizedBox(height: 16),
                  Text(
                    'Tutup Shift',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 24),
                  
                  // Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow('Uang Modal Awal', startingCash),
                        const SizedBox(height: 8),
                        _buildSummaryRow('Total Penjualan (Semua Metode)', totalSales),
                        const Divider(height: 16),
                        _buildSummaryRow('Pemasukan Tunai', totalCashSales),
                        const Divider(height: 16),
                        _buildSummaryRow('Uang Kasir Seharusnya', expectedCash, isBold: true),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  Text(
                    'Masukkan jumlah uang fisik aktual yang ada di laci kasir saat ini:',
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cashController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Uang Fisik Aktual (Rp)',
                      prefixIcon: Icon(Icons.money_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _closeShift,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('TUTUP SHIFT', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: isBold ? FontWeight.w600 : FontWeight.w400)),
        Text(CurrencyFormatter.format(value), style: GoogleFonts.inter(fontSize: 14, fontWeight: isBold ? FontWeight.w700 : FontWeight.w500)),
      ],
    );
  }
}

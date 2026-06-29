import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/voucher.dart';
import '../../../data/database/dao/voucher_dao.dart';
import 'widgets/voucher_form_dialog.dart';
import 'package:lucide_icons/lucide_icons.dart';

class VoucherManagementPage extends StatefulWidget {
  const VoucherManagementPage({super.key});

  @override
  State<VoucherManagementPage> createState() => _VoucherManagementPageState();
}

class _VoucherManagementPageState extends State<VoucherManagementPage> {
  final VoucherDao _voucherDao = GetIt.I<VoucherDao>();
  List<Voucher> _vouchers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    setState(() => _isLoading = true);
    try {
      final vouchers = await _voucherDao.getAllVouchers();
      if (mounted) setState(() => _vouchers = vouchers);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleVoucherStatus(Voucher voucher) async {
    try {
      final updated = Voucher(
        id: voucher.id,
        code: voucher.code,
        discountPercentage: voucher.discountPercentage,
        discountNominal: voucher.discountNominal,
        minPurchase: voucher.minPurchase,
        maxDiscount: voucher.maxDiscount,
        validFrom: voucher.validFrom,
        validUntil: voucher.validUntil,
        usageLimit: voucher.usageLimit,
        usedCount: voucher.usedCount,
        isActive: !voucher.isActive,
        createdAt: voucher.createdAt,
      );
      await _voucherDao.updateVoucher(updated);
      _loadVouchers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengupdate voucher: $e')));
      }
    }
  }

  Future<void> _deleteVoucher(Voucher voucher) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Voucher'),
        content: Text('Apakah Anda yakin ingin menghapus voucher ${voucher.code}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && voucher.id != null) {
      await _voucherDao.deleteVoucher(voucher.id!);
      _loadVouchers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Manajemen Voucher/Promo', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primaryDark,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            tooltip: 'Tambah Voucher',
            onPressed: () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (ctx) => const VoucherFormDialog(),
              );
              if (result == true) _loadVouchers();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vouchers.isEmpty
              ? Center(
                  child: Text('Belum ada voucher', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _vouchers.length,
                  itemBuilder: (context, index) {
                    final voucher = _vouchers[index];
                    final DateFormat dateFormat = DateFormat('dd MMM yyyy HH:mm');
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(LucideIcons.ticket, color: AppColors.primary, size: 20),
                                    const SizedBox(width: 8),
                                    Text(voucher.code, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                  ],
                                ),
                                Switch(
                                  value: voucher.isActive,
                                  onChanged: (_) => _toggleVoucherStatus(voucher),
                                  activeThumbColor: AppColors.success,
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Text(
                              voucher.discountPercentage > 0
                                  ? 'Diskon ${voucher.discountPercentage.toStringAsFixed(0)}% (Max ${CurrencyFormatter.format(voucher.maxDiscount)})'
                                  : 'Diskon Nominal: ${CurrencyFormatter.format(voucher.discountNominal)}',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            Text('Min. Pembelian: ${CurrencyFormatter.format(voucher.minPurchase)}', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textTertiary)),
                            Text('Masa Berlaku: ${dateFormat.format(voucher.validFrom)} - ${dateFormat.format(voucher.validUntil)}', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textTertiary)),
                            Text('Kuota Terpakai: ${voucher.usedCount} / ${voucher.usageLimit}', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textTertiary)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(LucideIcons.pencil, color: AppColors.info, size: 20),
                                  onPressed: () async {
                                    final result = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => VoucherFormDialog(voucher: voucher),
                                    );
                                    if (result == true) _loadVouchers();
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(LucideIcons.trash2, color: AppColors.error, size: 20),
                                  onPressed: () => _deleteVoucher(voucher),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

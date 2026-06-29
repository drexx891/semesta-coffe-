import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/di/injection_container.dart';
import '../../../data/database/dao/transaction_dao.dart';
import '../../../core/utils/currency_formatter.dart';
import 'transaction_detail_page.dart';

import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Halaman Riwayat Transaksi
class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  final TransactionDao _transactionDao = sl<TransactionDao>();
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final endOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);
      _transactions = await _transactionDao.getByDateRange(startOfDay, endOfDay);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryDark,
              onPrimary: AppColors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isToday = _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;
    final dateLabel = isToday ? 'Hari Ini' : DateFormat('dd MMM yyyy').format(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.transactions, style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600, fontSize: 18)),
            Text(dateLabel, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400)),
          ],
        ),
        backgroundColor: AppColors.primaryDark,
        actions: [
          IconButton(icon: const Icon(Icons.calendar_month_rounded), onPressed: () => _selectDate(context)),
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadTransactions),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _transactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.receiptText, size: 64, color: AppColors.textTertiary.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Text('Belum ada transaksi pada $dateLabel', style: GoogleFonts.inter(color: AppColors.textTertiary)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTransactions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppDimensions.spacing16),
                    itemCount: _transactions.length,
                    itemBuilder: (ctx, index) {
                      final trx = _transactions[index];
                      final isVoid = trx['status'] == 'void';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TransactionDetailPage(transactionId: trx['id'] as int),
                              ),
                            );
                            _loadTransactions();
                          },
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isVoid ? AppColors.errorLight : AppColors.successLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isVoid ? Icons.cancel_rounded : LucideIcons.receipt,
                              color: isVoid ? AppColors.error : AppColors.success,
                            ),
                          ),
                          title: Text(
                            trx['transaction_number'] as String? ?? '-',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${trx['user_name'] ?? '-'} · ${trx['payment_method']?.toString().toUpperCase() ?? '-'}',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                CurrencyFormatter.format((trx['total'] as num?)?.toDouble() ?? 0),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isVoid ? AppColors.textTertiary : AppColors.accent,
                                  decoration: isVoid ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              if (isVoid)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('VOID', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.white)),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/utils/receipt_printer.dart';
import '../../../data/database/dao/transaction_dao.dart';
import '../../../data/database/dao/shift_dao.dart';
import '../../../core/utils/csv_exporter.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum ReportType { daily, monthly, bestSeller, salesByCashier, paymentMethods, voidTransactions, discount, tax, shift, hpp, generic }

class ReportDetailPage extends StatefulWidget {
  final String title;
  final ReportType type;

  const ReportDetailPage({super.key, required this.title, required this.type});

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  final TransactionDao _transactionDao = sl<TransactionDao>();
  final ShiftDao _shiftDao = sl<ShiftDao>();
  bool _isLoading = true;

  // Data
  double _totalSales = 0;
  List<Map<String, dynamic>> _chartData = [];
  List<Map<String, dynamic>> _listData = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      if (widget.type == ReportType.daily) {
        _totalSales = await _transactionDao.getTodayTotalSales();
        _listData = await _transactionDao.getTodayTransactions();
      } else if (widget.type == ReportType.monthly) {
        final now = DateTime.now();
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        final list = await _transactionDao.getByDateRange(start, end);
        _totalSales = list.where((t) => t['status'] == 'completed').fold(0.0, (s, t) => s + (t['total'] as num).toDouble());
        _chartData = await _transactionDao.getLast7DaysSales();
        _listData = list;
      } else if (widget.type == ReportType.bestSeller) {
        _listData = await _transactionDao.getSalesByCategory();
        _totalSales = _listData.fold(0.0, (s, c) => s + (c['total_sales'] as num).toDouble());
      } else if (widget.type == ReportType.salesByCashier) {
        _listData = await _transactionDao.getSalesByCashier();
        _totalSales = _listData.fold(0.0, (s, c) => s + (c['total_sales'] as num).toDouble());
      } else if (widget.type == ReportType.paymentMethods) {
        _listData = await _transactionDao.getSalesByPaymentMethod();
        _totalSales = _listData.fold(0.0, (s, c) => s + (c['total_sales'] as num).toDouble());
      } else if (widget.type == ReportType.voidTransactions) {
        _listData = await _transactionDao.getVoidTransactions();
        _totalSales = _listData.fold(0.0, (s, c) => s + (c['total'] as num).toDouble());
      } else if (widget.type == ReportType.discount) {
        _listData = await _transactionDao.getDiscountReport();
        _totalSales = _listData.fold(0.0, (s, c) => s + (c['total_discount'] as num).toDouble());
      } else if (widget.type == ReportType.tax) {
        _listData = await _transactionDao.getTaxReport();
        _totalSales = _listData.fold(0.0, (s, c) => s + (c['total_tax'] as num).toDouble());
      } else if (widget.type == ReportType.hpp) {
        _listData = await _transactionDao.getHppReport();
        _totalSales = _listData.fold(0.0, (s, c) => s + (c['total_revenue'] as num).toDouble());
      } else if (widget.type == ReportType.shift) {
        final now = DateTime.now();
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        _listData = await _shiftDao.getByDateRange(start, end);
        _totalSales = _listData.fold(0.0, (s, c) => s + ((c['closing_cash'] as num?)?.toDouble() ?? 0.0));
      }
    } catch (e) {
      // Ignore
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.title, style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primaryDark,
        actions: [
          if (!_isLoading && widget.type != ReportType.generic && _listData.isNotEmpty) ...[
            IconButton(
              icon: const Icon(LucideIcons.download),
              tooltip: 'Export CSV',
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                try {
                  if (widget.type == ReportType.shift) {
                    await CsvExporter.exportShifts(_listData);
                  } else {
                    await CsvExporter.exportTransactions(_listData);
                  }
                  if (!mounted) return;
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Berhasil mengekspor ke CSV')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Gagal mengekspor: $e')),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(LucideIcons.printerer),
              tooltip: 'Cetak Laporan',
              onPressed: () async {
                await ReceiptPrinter.printReportSummary(
                  reportTitle: widget.title,
                  totalSales: _totalSales,
                  listData: _listData,
                );
              },
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (widget.type == ReportType.generic) {
      return Center(
        child: Text('Laporan belum tersedia.', style: GoogleFonts.inter(color: AppColors.textSecondary)),
      );
    }

    return Column(
      children: [
        // Summary
        Container(
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          color: AppColors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Penjualan', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Text(
                CurrencyFormatter.format(_totalSales),
                style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.accent),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        
        // Chart for monthly
        if (widget.type == ReportType.monthly && _chartData.isNotEmpty)
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            color: AppColors.white,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value >= 0 && value < _chartData.length) {
                          final dateStr = _chartData[value.toInt()]['date'] as String;
                          final day = dateStr.split('-').last;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(day, style: GoogleFonts.inter(fontSize: 10)),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                barGroups: _chartData.asMap().entries.map((e) {
                  final sales = (e.value['total_sales'] as num).toDouble();
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: sales,
                        color: AppColors.primary,
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                      )
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          
        if (widget.type == ReportType.monthly && _chartData.isNotEmpty)
          const Divider(height: 1),

        // List Data
        Expanded(
          child: _listData.isEmpty
              ? Center(child: Text('Tidak ada data.', style: GoogleFonts.inter()))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _listData.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (ctx, i) {
                    final item = _listData[i];
                    if (widget.type == ReportType.bestSeller) {
                      return ListTile(
                        leading: const Icon(LucideIcons.layoutGrid, color: AppColors.primary),
                        title: Text(item['category_name'] as String, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        subtitle: Text('${item['total_qty']} item terjual', style: GoogleFonts.inter(fontSize: 12)),
                        trailing: Text(
                          CurrencyFormatter.format((item['total_sales'] as num).toDouble()),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.accent),
                        ),
                      );
                    } else if (widget.type == ReportType.salesByCashier) {
                      return ListTile(
                        leading: const Icon(LucideIcons.user, color: AppColors.primary),
                        title: Text(item['cashier_name'] as String, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        subtitle: Text('${item['total_transactions']} transaksi', style: GoogleFonts.inter(fontSize: 12)),
                        trailing: Text(
                          CurrencyFormatter.format((item['total_sales'] as num).toDouble()),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.accent),
                        ),
                      );
                    } else if (widget.type == ReportType.paymentMethods) {
                      return ListTile(
                        leading: const Icon(Icons.payment_rounded, color: AppColors.primary),
                        title: Text(item['payment_method'].toString().toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        subtitle: Text('${item['total_transactions']} transaksi', style: GoogleFonts.inter(fontSize: 12)),
                        trailing: Text(
                          CurrencyFormatter.format((item['total_sales'] as num).toDouble()),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.accent),
                        ),
                      );
                    } else if (widget.type == ReportType.discount) {
                      return ListTile(
                        leading: const Icon(Icons.discount_rounded, color: AppColors.warning),
                        title: Text(item['discount_reason'] as String? ?? 'Diskon', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        subtitle: Text('${item['total_transactions']} transaksi', style: GoogleFonts.inter(fontSize: 12)),
                        trailing: Text(
                          CurrencyFormatter.format((item['total_discount'] as num).toDouble()),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.error),
                        ),
                      );
                    } else if (widget.type == ReportType.tax) {
                      return ListTile(
                        leading: const Icon(Icons.account_balance_rounded, color: AppColors.paymentTransfer),
                        title: Text('Tanggal: ${item['date']}', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        subtitle: Text('SC: ${CurrencyFormatter.format((item['total_service_charge'] as num).toDouble())}', style: GoogleFonts.inter(fontSize: 12)),
                        trailing: Text(
                          '+ ${CurrencyFormatter.format((item['total_tax'] as num).toDouble())}',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      );
                    } else if (widget.type == ReportType.hpp) {
                      final revenue = (item['total_revenue'] as num).toDouble();
                      final cogs = (item['total_cogs'] as num).toDouble();
                      final margin = revenue - cogs;
                      return ListTile(
                        leading: const Icon(Icons.inventory_rounded, color: AppColors.accentDark),
                        title: Text(item['product_name'] as String, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        subtitle: Text('Terjual: ${item['total_qty']} • HPP: ${CurrencyFormatter.format(cogs)}', style: GoogleFonts.inter(fontSize: 12)),
                        trailing: Text(
                          CurrencyFormatter.format(margin),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: margin >= 0 ? AppColors.success : AppColors.error),
                        ),
                      );
                    } else if (widget.type == ReportType.shift) {
                      final startTime = DateTime.parse(item['opened_at']);
                      final endTime = item['closed_at'] != null ? DateTime.parse(item['closed_at']) : null;
                      final difference = (item['cash_difference'] as num?)?.toDouble() ?? 0;
                      return ListTile(
                        leading: const Icon(LucideIcons.clock, color: AppColors.primaryLight),
                        title: Text(item['user_name'] as String? ?? 'Kasir', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        subtitle: Text('${startTime.day}/${startTime.month}/${startTime.year} ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')} - ${endTime != null ? '${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}' : 'Buka'}', style: GoogleFonts.inter(fontSize: 12)),
                        trailing: Text(
                          difference == 0 ? 'Sesuai' : difference > 0 ? '+${CurrencyFormatter.format(difference)}' : CurrencyFormatter.format(difference),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: difference == 0 ? AppColors.success : difference > 0 ? AppColors.info : AppColors.error),
                        ),
                      );
                    } else {
                      final trxNumber = item['transaction_number'] as String;
                      final total = (item['total'] as num).toDouble();
                      final status = item['status'] as String;
                      final type = item['order_type'] != null ? item['order_type'] as String : '';
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: status == 'completed' ? AppColors.successLight : AppColors.errorLight,
                          child: Icon(
                            status == 'completed' ? LucideIcons.check : LucideIcons.x,
                            color: status == 'completed' ? AppColors.success : AppColors.error,
                            size: 18,
                          ),
                        ),
                        title: Text(trxNumber, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        subtitle: Text(type.replaceAll('_', ' ').toUpperCase(), style: GoogleFonts.inter(fontSize: 12)),
                        trailing: Text(
                          CurrencyFormatter.format(total),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: status == 'completed' ? AppColors.accent : AppColors.textSecondary,
                            decoration: status == 'void' ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      );
                    }
                  },
                ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/di/injection_container.dart';
import '../../data/database/dao/transaction_dao.dart';
import '../../data/database/dao/stock_dao.dart';
import '../../data/database/dao/shift_dao.dart';
import '../../core/utils/currency_formatter.dart';
import '../../services/session_manager.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Dashboard — ringkasan penjualan hari ini
class DashboardPage extends StatefulWidget {
  final Function(String destination)? onNavigate;

  const DashboardPage({super.key, this.onNavigate});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final TransactionDao _transactionDao = sl<TransactionDao>();
  final StockDao _stockDao = sl<StockDao>();
  final ShiftDao _shiftDao = sl<ShiftDao>();
  final SessionManager _session = sl<SessionManager>();

  double _totalSales = 0;
  int _totalTransactions = 0;
  int _criticalStockCount = 0;
  String? _bestSellerName;
  int _bestSellerQty = 0;
  Map<String, dynamic>? _activeShift;
  bool _isLoading = true;
  List<Map<String, dynamic>> _weeklySales = [];
  List<Map<String, dynamic>> _paymentMethods = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      _totalSales = await _transactionDao.getTodayTotalSales();

      final todayTrx = await _transactionDao.getTodayTransactions();
      _totalTransactions = todayTrx.where((t) => t['status'] == 'completed').length;

      _criticalStockCount = await _stockDao.countCriticalStock();

      final bestSeller = await _transactionDao.getTodayBestSeller();
      if (bestSeller != null) {
        _bestSellerName = bestSeller['product_name'] as String?;
        _bestSellerQty = (bestSeller['total_qty'] as num?)?.toInt() ?? 0;
      }

      _activeShift = await _shiftDao.getActiveShift();
      _weeklySales = await _transactionDao.getWeeklySalesData();
      _paymentMethods = await _transactionDao.getPaymentMethodDistribution();
    } catch (e) {
      // Silently handle — dashboard data is non-critical
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = _session.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.dashboard, style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primaryDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadDashboardData,
            tooltip: AppStrings.refresh,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              color: AppColors.accent,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppDimensions.spacing16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting
                    _buildGreeting(user?.name ?? 'User'),
                    const SizedBox(height: AppDimensions.spacing20),

                    // Stock alert banner
                    if (_criticalStockCount > 0) _buildStockAlertBanner(),
                    if (_criticalStockCount > 0) const SizedBox(height: AppDimensions.spacing16),

                    // Active shift indicator
                    if (_activeShift != null) _buildActiveShiftCard(),
                    if (_activeShift != null) const SizedBox(height: AppDimensions.spacing16),

                    // Summary cards
                    _buildSummaryGrid(),
                    const SizedBox(height: AppDimensions.spacing24),

                    // Analytics Charts (fl_chart)
                    _buildAnalyticsCharts(),
                    const SizedBox(height: AppDimensions.spacing24),

                    // Quick actions
                    _buildQuickActions(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildGreeting(String name) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Selamat Pagi';
    } else if (hour < 15) {
      greeting = 'Selamat Siang';
    } else if (hour < 18) {
      greeting = 'Selamat Sore';
    } else {
      greeting = 'Selamat Malam';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, $name! ☕',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Berikut ringkasan toko hari ini',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStockAlertBanner() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing12),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.triangleAlert_amber_rounded, color: AppColors.error, size: 24),
          const SizedBox(width: AppDimensions.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppStrings.stockAlert}!',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.error, fontSize: 14),
                ),
                Text(
                  '$_criticalStockCount bahan baku di bawah stok minimum',
                  style: GoogleFonts.inter(color: AppColors.error, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.error),
        ],
      ),
    );
  }

  Widget _buildActiveShiftCard() {
    final shiftUser = _activeShift!['user_name'] as String? ?? '-';

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing12),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppDimensions.spacing12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Shift Aktif: ',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.success),
                  ),
                  TextSpan(
                    text: shiftUser,
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.success),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppDimensions.spacing12,
          mainAxisSpacing: AppDimensions.spacing12,
          childAspectRatio: 1.5,
          children: [
            _buildSummaryCard(
              icon: Icons.attach_money_rounded,
              label: AppStrings.todaySales,
              value: CurrencyFormatter.format(_totalSales),
              color: AppColors.accent,
            ),
            _buildSummaryCard(
              icon: Icons.receipt_rounded,
              label: AppStrings.totalTransactions,
              value: '$_totalTransactions',
              color: AppColors.info,
            ),
            _buildSummaryCard(
              icon: LucideLucideIcons.star,
              label: AppStrings.bestSeller,
              value: _bestSellerName ?? '-',
              subtitle: _bestSellerQty > 0 ? '$_bestSellerQty terjual' : null,
              color: AppColors.warning,
            ),
            _buildSummaryCard(
              icon: Icons.inventory_rounded,
              label: 'Stok Kritis',
              value: '$_criticalStockCount',
              color: _criticalStockCount > 0 ? AppColors.error : AppColors.success,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null)
            Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary)),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aksi Cepat',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spacing12),
        Wrap(
          spacing: AppDimensions.spacing12,
          runSpacing: AppDimensions.spacing12,
          children: [
            _buildQuickActionChip(LucideIcons.monitorCheck, 'Mulai Transaksi', AppColors.primary, 'pos'),
            _buildQuickActionChip(LucideIcons.clock, 'Buka Shift', AppColors.success, 'shift'),
            _buildQuickActionChip(LucideIcons.packageSearch, 'Cek Stok', AppColors.warning, 'stock'),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionChip(IconData icon, String label, Color color, String destination) {
    return ActionChip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
      backgroundColor: color.withValues(alpha: 0.08),
      side: BorderSide(color: color.withValues(alpha: 0.2)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      onPressed: () {
        if (widget.onNavigate != null) {
          widget.onNavigate!(destination);
        }
      },
    );
  }

  Widget _buildAnalyticsCharts() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        
        final weeklyChart = _buildWeeklySalesChart();
        final pieChart = _buildPaymentMethodChart();

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: weeklyChart),
              const SizedBox(width: AppDimensions.spacing24),
              Expanded(flex: 1, child: pieChart),
            ],
          );
        } else {
          return Column(
            children: [
              weeklyChart,
              const SizedBox(height: AppDimensions.spacing24),
              pieChart,
            ],
          );
        }
      },
    );
  }

  Widget _buildWeeklySalesChart() {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [BoxShadow(color: AppColors.cardShadow.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tren Penjualan (7 Hari)', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textPrimary)),
          const SizedBox(height: 24),
          Expanded(
            child: _weeklySales.isEmpty
                ? const Center(child: Text('Belum ada data penjualan'))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 100000),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() < 0 || value.toInt() >= _weeklySales.length) return const SizedBox.shrink();
                              final dateStr = _weeklySales[value.toInt()]['sale_date'] as String;
                              final date = DateTime.parse(dateStr);
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text('${date.day}/${date.month}', style: const TextStyle(fontSize: 10)),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text('${(value / 1000).toInt()}k', style: const TextStyle(fontSize: 10));
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _weeklySales.asMap().entries.map((e) {
                            return FlSpot(e.key.toDouble(), (e.value['total_sales'] as num).toDouble());
                          }).toList(),
                          isCurved: true,
                          color: AppColors.primary,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.primary.withValues(alpha: 0.2),
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

  Widget _buildPaymentMethodChart() {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [BoxShadow(color: AppColors.cardShadow.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Metode Pembayaran', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textPrimary)),
          const SizedBox(height: 24),
          Expanded(
            child: _paymentMethods.isEmpty
                ? const Center(child: Text('Belum ada data'))
                : PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: _paymentMethods.map((e) {
                        final method = e['payment_method'] as String;
                        final count = (e['count'] as num).toDouble();
                        
                        Color color;
                        switch (method) {
                          case 'cash': color = AppColors.success; break;
                          case 'qris': color = AppColors.info; break;
                          case 'transfer': color = AppColors.primary; break;
                          case 'edc': color = AppColors.warning; break;
                          default: color = Colors.grey;
                        }
                        
                        return PieChartSectionData(
                          color: color,
                          value: count,
                          title: '$count',
                          radius: 50,
                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _paymentMethods.map((e) {
              final method = e['payment_method'] as String;
              Color color;
              switch (method) {
                case 'cash': color = AppColors.success; break;
                case 'qris': color = AppColors.info; break;
                case 'transfer': color = AppColors.primary; break;
                case 'edc': color = AppColors.warning; break;
                default: color = Colors.grey;
              }
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 12, color: color, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 4),
                  Text(method.toUpperCase(), style: const TextStyle(fontSize: 11)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

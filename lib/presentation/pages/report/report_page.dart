import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import 'report_detail_page.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final reports = [
      _ReportItem(AppStrings.dailyReport, Icons.today_rounded, AppColors.info),
      _ReportItem(AppStrings.monthlyReport, Icons.calendar_month_rounded, AppColors.primary),
      _ReportItem(AppStrings.bestSellerReport, LucideIcons.star, AppColors.accent),
      _ReportItem(AppStrings.salesByCashier, LucideIcons.user, AppColors.success),
      _ReportItem(AppStrings.paymentMethodReport, Icons.payment_rounded, AppColors.paymentQris),
      _ReportItem(AppStrings.discountReport, Icons.discount_rounded, AppColors.warning),
      _ReportItem(AppStrings.taxReport, Icons.account_balance_rounded, AppColors.paymentTransfer),
      _ReportItem(AppStrings.voidReport, Icons.cancel_rounded, AppColors.error),
      _ReportItem(AppStrings.shiftReport, LucideIcons.clock, AppColors.primaryLight),
      _ReportItem(AppStrings.hppReport, Icons.calculate_rounded, AppColors.accentDark),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.reports, style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primaryDark,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          childAspectRatio: 1.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: reports.length,
        itemBuilder: (ctx, index) {
          final report = reports[index];
          return Card(
            child: InkWell(
              onTap: () {
                ReportType type = ReportType.generic;
                if (report.title == AppStrings.dailyReport) type = ReportType.daily;
                if (report.title == AppStrings.monthlyReport) type = ReportType.monthly;
                if (report.title == AppStrings.bestSellerReport) type = ReportType.bestSeller;
                if (report.title == AppStrings.salesByCashier) type = ReportType.salesByCashier;
                if (report.title == AppStrings.paymentMethodReport) type = ReportType.paymentMethods;
                if (report.title == AppStrings.voidReport) type = ReportType.voidTransactions;
                if (report.title == AppStrings.discountReport) type = ReportType.discount;
                if (report.title == AppStrings.taxReport) type = ReportType.tax;
                if (report.title == AppStrings.shiftReport) type = ReportType.shift;
                if (report.title == AppStrings.hppReport) type = ReportType.hpp;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReportDetailPage(
                      title: report.title,
                      type: type,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: report.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(report.icon, color: report.color, size: 28),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      report.title,
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReportItem {
  final String title;
  final IconData icon;
  final Color color;
  _ReportItem(this.title, this.icon, this.color);
}

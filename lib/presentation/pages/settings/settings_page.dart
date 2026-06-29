import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import 'store_profile_page.dart';
import 'transaction_config_page.dart';
import 'user_management_page.dart';
import 'printer_settings_page.dart';
import 'activity_log_page.dart';
import 'backup_restore_page.dart';
import 'voucher_management_page.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsSections = [
      _SettingsSection(AppStrings.storeProfile, Icons.store_rounded, AppColors.primary, const StoreProfilePage()),
      _SettingsSection(AppStrings.transactionConfig, Icons.tune_rounded, AppColors.accent, const TransactionConfigPage()),
      _SettingsSection(AppStrings.printerSettings, LucideIcons.printer, AppColors.info, const PrinterSettingsPage()),
      _SettingsSection(AppStrings.userManagement, Icons.group_rounded, AppColors.success, const UserManagementPage()),
      _SettingsSection('Promo & Voucher', LucideIcons.ticket, AppColors.paymentQris, const VoucherManagementPage()),
      _SettingsSection(AppStrings.activityLog, LucideIcons.history, AppColors.warning, const ActivityLogPage()),
      _SettingsSection(AppStrings.backupRestore, Icons.backup_rounded, AppColors.paymentTransfer, const BackupRestorePage()),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.settings, style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primaryDark,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: settingsSections.length,
        itemBuilder: (ctx, index) {
          final section = settingsSections[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: section.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(section.icon, color: section.color),
              ),
              title: Text(section.title, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
              onTap: () {
                if (section.page != null) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => section.page!));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur ini belum tersedia')));
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class _SettingsSection {
  final String title;
  final IconData icon;
  final Color color;
  final Widget? page;
  _SettingsSection(this.title, this.icon, this.color, this.page);
}

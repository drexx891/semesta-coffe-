import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection_container.dart';
import '../../../data/database/database_helper.dart';
import '../../../data/database/dao/transaction_dao.dart';
import '../../../services/supabase_sync_service.dart';
import 'package:lucide_icons/lucide_icons.dart';

class BackupRestorePage extends StatefulWidget {
  const BackupRestorePage({super.key});

  @override
  State<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends State<BackupRestorePage> {
  bool _isLoading = false;

  Future<void> _exportDatabase() async {
    setState(() => _isLoading = true);
    try {
      if (kIsWeb) {
        throw Exception('Backup database melalui file lokal tidak didukung di Web. Gunakan layanan cloud sync.');
      }

      final dbPath = await DatabaseHelper().getDatabasePath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        throw Exception('File database tidak ditemukan.');
      }

      final now = DateTime.now();
      final fileName = 'smesta_coffee_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.db';

      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Pilih Folder untuk Menyimpan Backup');

      if (selectedDirectory != null) {
        final backupPath = p.join(selectedDirectory, fileName);
        await dbFile.copy(backupPath);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup berhasil disimpan di: $backupPath'), backgroundColor: AppColors.success));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal backup: $e'), backgroundColor: AppColors.error));
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _shareDatabase() async {
    setState(() => _isLoading = true);
    try {
      if (kIsWeb) {
        throw Exception('Share database tidak didukung di Web.');
      }
      final dbPath = await DatabaseHelper().getDatabasePath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        throw Exception('File database tidak ditemukan.');
      }

      final result = await Share.shareXFiles([XFile(dbPath)], text: 'Backup Database Smesta Coffee');
      if (result.status == ShareResultStatus.success) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Database berhasil dibagikan.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal share: $e'), backgroundColor: AppColors.error));
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pushToCloud() async {
    setState(() => _isLoading = true);
    try {
      final syncService = sl<SupabaseSyncService>();
      await syncService.pushAllDataToCloud();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil backup ke Cloud (Supabase)'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal backup ke Cloud: $e'), backgroundColor: AppColors.error));
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pullFromCloud() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore dari Cloud'),
        content: const Text('PERINGATAN: Semua data lokal saat ini akan digantikan oleh data dari Cloud. Apakah Anda yakin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Ya, Restore')
          ),
        ],
      ),
    );

    if (confirm != true) return;
    
    setState(() => _isLoading = true);
    try {
      final syncService = sl<SupabaseSyncService>();
      await syncService.pullAllDataFromCloud();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil restore dari Cloud. Silakan restart aplikasi.'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal restore dari Cloud: $e'), backgroundColor: AppColors.error));
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _exportCsv() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restore database tidak didukung di Web.')));
      return;
    }
  }

  Future<void> _restoreDatabase() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restore database tidak didukung di Web.')));
      return;
    }
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Database'),
        content: const Text('PERINGATAN: Semua data saat ini akan digantikan oleh data dari file backup. Anda akan otomatis logout. Apakah Anda yakin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Ya, Restore')
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Pilih File Backup Database',
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        final backupFile = File(result.files.single.path!);
        final dbPath = await DatabaseHelper().getDatabasePath();
        
        await DatabaseHelper().close(); // close current connection
        await backupFile.copy(dbPath); // overwrite db
        
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text('Restore Berhasil'),
              content: const Text('Aplikasi akan ditutup. Silakan buka kembali aplikasi.'),
              actions: [
                ElevatedButton(
                  onPressed: () => exit(0), // Quit the app
                  child: const Text('Tutup Aplikasi'),
                )
              ],
            )
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal restore: $e'), backgroundColor: AppColors.error));
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _clearTransactions() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Semua Transaksi'),
        content: const Text('PERINGATAN: Tindakan ini akan menghapus semua riwayat transaksi, pergerakan stok, dan laporan. Stok bahan baku tidak akan kembali ke awal. Apakah Anda yakin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Ya, Hapus Data')
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final transactionDao = sl<TransactionDao>();
      await transactionDao.deleteAllTransactions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua transaksi berhasil dihapus.'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus data: $e'), backgroundColor: AppColors.error));
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Backup & Restore', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primaryDark,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
            Text('Cloud Sync (Supabase)', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
            const SizedBox(height: 8),
            Text('Sinkronisasi data ke server cloud untuk keamanan dan akses multi-perangkat. Pastikan koneksi internet stabil.', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _pushToCloud,
                    icon: const Icon(Icons.cloud_upload_rounded),
                    label: const Text('Backup ke Cloud'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _pullFromCloud,
                    icon: const Icon(Icons.cloud_download_rounded),
                    label: const Text('Restore dari Cloud'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // Local Database Backup
            Text('Database Lokal (.db)', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
            const SizedBox(height: 8),
            Text('Backup seluruh database ke dalam satu file .db. Tidak dapat digunakan di Web (hanya Desktop/Android).', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: kIsWeb ? null : (_isLoading ? null : _exportDatabase),
                    icon: const Icon(LucideLucideIcons.download),
                    label: const Text('Simpan File'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: kIsWeb ? null : (_isLoading ? null : _shareDatabase),
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Bagikan (Share)'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: kIsWeb ? null : (_isLoading ? null : _restoreDatabase),
                icon: const Icon(Icons.restore_rounded),
                label: const Text('Restore dari File (.db)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // CSV Export
            Text('Export Data Transaksi (CSV)', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
            const SizedBox(height: 8),
            Text('Export data transaksi ke format spreadsheet untuk keperluan laporan/akuntansi.', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _exportCsv,
                icon: const Icon(Icons.table_view_rounded),
                label: const Text('Export ke CSV'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(backgroundColor: AppColors.errorLight, child: Icon(Icons.delete_forever_rounded, color: AppColors.error)),
                  title: Text('Hapus Semua Transaksi', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Reset data kasir. Hapus semua riwayat transaksi dan laporan.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _clearTransactions,
                ),
              ),
            ],
          ),
    );
  }
}

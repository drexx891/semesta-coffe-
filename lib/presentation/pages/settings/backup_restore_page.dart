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
    }
    setState(() => _isLoading = false);
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
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(backgroundColor: AppColors.primaryLight, child: Icon(Icons.download_rounded, color: AppColors.primaryDark)),
                  title: Text('Export Database Lokal', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Simpan salinan database ke direktori di perangkat ini.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _exportDatabase,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(backgroundColor: AppColors.infoLight, child: Icon(Icons.share_rounded, color: AppColors.info)),
                  title: Text('Bagikan Database', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Kirim salinan database melalui email atau aplikasi lain.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _shareDatabase,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(backgroundColor: AppColors.errorLight, child: Icon(Icons.upload_rounded, color: AppColors.error)),
                  title: Text('Restore Database', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Pulihkan data dari file backup (.db). Data saat ini akan tertimpa.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _restoreDatabase,
                ),
              ),
              const SizedBox(height: 12),
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

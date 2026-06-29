import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection_container.dart';
import '../../../data/database/dao/user_dao.dart';
import 'widgets/user_form_dialog.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final UserDao _userDao = sl<UserDao>();
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      _users = await _userDao.getAll();
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _deleteUser(int id, String username) async {
    if (username == 'owner') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Akun Owner utama tidak dapat dihapus')));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pengguna?'),
        content: const Text('Tindakan ini akan menonaktifkan pengguna. Pengguna tidak akan bisa login lagi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Hapus')
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _userDao.toggleActive(id, false);
      _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengguna berhasil dinonaktifkan')));
      }
    }
  }

  void _showUserForm([Map<String, dynamic>? user]) async {
    if (user?['username'] == 'owner') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Akun Owner utama hanya bisa diubah passwordnya, hubungi dukungan teknis.')));
      // You can still allow edit by bypassing this check if you want, but as a safeguard we show this.
      // Let's just allow edit but show a dialog.
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UserFormDialog(user: user),
    );

    if (result == true) {
      _loadUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Manajemen Pengguna', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primaryDark,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: () => _showUserForm(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _users.length,
              itemBuilder: (ctx, index) {
                final user = _users[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Text(user['name'].toString().substring(0, 1).toUpperCase(), style: const TextStyle(color: AppColors.primaryDark)),
                    ),
                    title: Text(user['name'] as String, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    subtitle: Text(user['role'].toString().toUpperCase(), style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(LucideIcons.pencil, color: AppColors.primary),
                          onPressed: () => _showUserForm(user),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_rounded, color: AppColors.error),
                          onPressed: () => _deleteUser(user['id'] as int, user['username'] as String),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

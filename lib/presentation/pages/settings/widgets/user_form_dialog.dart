import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../data/database/dao/user_dao.dart';
import 'package:lucide_icons/lucide_icons.dart';

class UserFormDialog extends StatefulWidget {
  final Map<String, dynamic>? user;

  const UserFormDialog({super.key, this.user});

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final UserDao _userDao = sl<UserDao>();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _pinController;

  String _selectedRole = 'cashier';
  bool _isSaving = false;
  bool _obscurePassword = true;
  bool _obscurePin = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?['name'] as String? ?? '');
    _usernameController = TextEditingController(text: widget.user?['username'] as String? ?? '');
    _passwordController = TextEditingController(); // empty initially
    _pinController = TextEditingController(text: widget.user?['pin'] as String? ?? '');
    _selectedRole = widget.user?['role'] as String? ?? 'cashier';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      final name = _nameController.text.trim();
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();
      final pin = _pinController.text.trim();

      // Check if username exists
      final exists = await _userDao.usernameExists(username, excludeId: widget.user?['id'] as int?);
      if (exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username sudah digunakan!')));
        }
        setState(() => _isSaving = false);
        return;
      }

      final data = {
        'name': name,
        'username': username,
        'role': _selectedRole,
        'pin': pin.isEmpty ? null : pin,
      };

      if (widget.user == null) {
        // Create new user
        data['password_hash'] = UserDao.hashPassword(password);
        await _userDao.insert(data);
      } else {
        // Update user
        if (password.isNotEmpty) {
          data['password_hash'] = UserDao.hashPassword(password);
        }
        await _userDao.update(widget.user!['id'] as int, data);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    }
    
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.user != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEdit ? 'Edit Pengguna' : 'Tambah Pengguna Baru',
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nama Lengkap', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: isEdit ? 'Password Baru (Kosongkan jika tidak diubah)' : 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? LucideIcons.eye_off : LucideIcons.eye),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (!isEdit && (v == null || v.isEmpty)) return 'Wajib diisi untuk pengguna baru';
                    if (v != null && v.isNotEmpty && v.length < 6) return 'Password minimal 6 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: const InputDecoration(labelText: 'Peran (Role)', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'cashier', child: Text('Kasir')),
                    DropdownMenuItem(value: 'supervisor', child: Text('Supervisor')),
                    DropdownMenuItem(value: 'owner', child: Text('Owner')),
                  ],
                  onChanged: (v) => setState(() => _selectedRole = v ?? 'cashier'),
                ),
                const SizedBox(height: 16),
                if (_selectedRole == 'supervisor' || _selectedRole == 'owner')
                  TextFormField(
                    controller: _pinController,
                    obscureText: _obscurePin,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: InputDecoration(
                      labelText: 'PIN 4 Digit (Khusus Akses Supervisor)',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePin ? LucideIcons.eye_off : LucideIcons.eye),
                        onPressed: () => setState(() => _obscurePin = !_obscurePin),
                      ),
                    ),
                    validator: (v) {
                      if (v != null && v.isNotEmpty && v.length != 4) return 'PIN harus 4 digit';
                      if ((_selectedRole == 'supervisor' || _selectedRole == 'owner') && (v == null || v.isEmpty)) {
                        return 'PIN wajib diisi untuk role ini';
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveUser,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: _isSaving 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Simpan', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

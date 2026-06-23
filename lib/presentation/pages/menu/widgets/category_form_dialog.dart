import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

class CategoryFormDialog extends StatefulWidget {
  final Map<String, dynamic>? category;

  const CategoryFormDialog({super.key, this.category});

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _sortOrderController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?['name'] ?? '');
    _sortOrderController = TextEditingController(
      text: widget.category?['sort_order']?.toString() ?? '0',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, {
        'name': _nameController.text.trim(),
        'sort_order': int.tryParse(_sortOrderController.text) ?? 0,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;

    return AlertDialog(
      title: Text(
        isEditing ? 'Edit Kategori' : 'Tambah Kategori Baru',
        style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Kategori',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama kategori tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sortOrderController,
              decoration: const InputDecoration(
                labelText: 'Urutan (Sort Order)',
                border: OutlineInputBorder(),
                helperText: 'Angka lebih kecil akan tampil lebih dulu',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Urutan tidak boleh kosong';
                }
                if (int.tryParse(value) == null) {
                  return 'Harus berupa angka';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryDark,
            foregroundColor: AppColors.white,
          ),
          child: Text(isEditing ? 'Simpan Perubahan' : 'Tambah'),
        ),
      ],
    );
  }
}

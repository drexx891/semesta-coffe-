import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/stock/stock_bloc.dart';
import '../../../bloc/stock/stock_event.dart';

class IngredientFormDialog extends StatefulWidget {
  final Map<String, dynamic>? ingredient;

  const IngredientFormDialog({super.key, this.ingredient});

  @override
  State<IngredientFormDialog> createState() => _IngredientFormDialogState();
}

class _IngredientFormDialogState extends State<IngredientFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _unitController;
  late TextEditingController _minStockController;
  
  String _category = 'Biji Kopi';
  final List<String> _categories = ['Biji Kopi', 'Susu', 'Sirup', 'Gula', 'Bubuk', 'Lainnya'];
  
  bool _isActive = true;
  final bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.ingredient?['name'] as String? ?? '');
    _unitController = TextEditingController(text: widget.ingredient?['unit'] as String? ?? 'gram');
    _minStockController = TextEditingController(text: widget.ingredient != null ? (widget.ingredient!['min_stock'] as num).toString() : '0');
    
    if (widget.ingredient != null) {
      final cat = widget.ingredient!['category'] as String?;
      if (cat != null && _categories.contains(cat)) {
        _category = cat;
      }
      _isActive = (widget.ingredient!['is_active'] as int? ?? 1) == 1;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'name': _nameController.text.trim(),
      'category': _category,
      'unit': _unitController.text.trim(),
      'min_stock': double.tryParse(_minStockController.text) ?? 0.0,
      'is_active': _isActive ? 1 : 0,
    };

    if (widget.ingredient == null) {
      // Create new
      data['current_stock'] = 0.0;
      data['created_at'] = DateTime.now().toIso8601String();
      data['updated_at'] = DateTime.now().toIso8601String();
      context.read<StockBloc>().add(AddIngredient(data));
    } else {
      // Update
      context.read<StockBloc>().add(UpdateIngredient(widget.ingredient!['id'] as int, data));
    }
    
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.ingredient == null ? 'Tambah Bahan Baku' : 'Edit Bahan Baku',
        style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Bahan', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Nama bahan harus diisi' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _category = v);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minStockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Stok Minimum', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'Harus diisi' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _unitController,
                      decoration: const InputDecoration(labelText: 'Satuan (gram, ml, pcs)', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'Harus diisi' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Aktif (Bisa digunakan di resep)'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Simpan'),
        ),
      ],
    );
  }
}

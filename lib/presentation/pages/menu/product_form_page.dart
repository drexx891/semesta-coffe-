import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../bloc/menu_management/menu_management_bloc.dart';
import '../../bloc/menu_management/menu_management_event.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../../../core/utils/base64_image_helper.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ProductFormPage extends StatefulWidget {
  final Map<String, dynamic>? product;
  final List<Map<String, dynamic>> categories;

  const ProductFormPage({super.key, this.product, required this.categories});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceRegularController;
  late TextEditingController _priceLargeController;
  late TextEditingController _extraShotPriceController;
  late TextEditingController _sortOrderController;

  int? _selectedCategoryId;
  bool _hasLargeSize = false;
  bool _hasSugarLevel = false;
  bool _hasIceLevel = false;
  bool _hasExtraShot = false;

  String? _imageBase64;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?['name'] ?? '');
    _descController = TextEditingController(text: p?['description'] ?? '');
    _priceRegularController = TextEditingController(text: p?['price_regular']?.toString() ?? '');
    _priceLargeController = TextEditingController(text: p?['price_large']?.toString() ?? '');
    _extraShotPriceController = TextEditingController(text: p?['extra_shot_price']?.toString() ?? '');
    _sortOrderController = TextEditingController(text: p?['sort_order']?.toString() ?? '0');

    _selectedCategoryId = p?['category_id'] as int?;
    // Fallback if the selected category is no longer in the list (rare, but possible if DB constrained)
    if (_selectedCategoryId != null && !widget.categories.any((c) => c['id'] == _selectedCategoryId)) {
      _selectedCategoryId = null;
    }

    _hasLargeSize = (p?['has_large_size'] ?? 0) == 1;
    _hasSugarLevel = (p?['has_sugar_level'] ?? 0) == 1;
    _hasIceLevel = (p?['has_ice_level'] ?? 0) == 1;
    _hasExtraShot = (p?['has_extra_shot'] ?? 0) == 1;
    _imageBase64 = p?['image_path'] as String?;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengambil gambar')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceRegularController.dispose();
    _priceLargeController.dispose();
    _extraShotPriceController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih kategori terlebih dahulu')),
        );
        return;
      }

      final data = <String, dynamic>{
        'category_id': _selectedCategoryId,
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'price_regular': double.tryParse(_priceRegularController.text) ?? 0.0,
        'has_large_size': _hasLargeSize ? 1 : 0,
        'price_large': _hasLargeSize ? (double.tryParse(_priceLargeController.text) ?? 0.0) : null,
        'has_sugar_level': _hasSugarLevel ? 1 : 0,
        'has_ice_level': _hasIceLevel ? 1 : 0,
        'has_extra_shot': _hasExtraShot ? 1 : 0,
        'extra_shot_price': _hasExtraShot ? (double.tryParse(_extraShotPriceController.text) ?? 0.0) : 0.0,
        'sort_order': int.tryParse(_sortOrderController.text) ?? 0,
        'is_active': widget.product?['is_active'] ?? 1, // preserve active status
        'image_path': _imageBase64,
      };

      if (widget.product == null) {
        context.read<MenuManagementBloc>().add(CreateProduct(data));
      } else {
        context.read<MenuManagementBloc>().add(UpdateProduct(widget.product!['id'], data));
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Produk' : 'Tambah Produk Baru',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primaryDark,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.check),
            onPressed: _submit,
            tooltip: 'Simpan',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Informasi Dasar'),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // IMAGE PICKER
                          Center(
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: _imageBase64 != null && _imageBase64!.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Base64ImageHelper.buildImage(_imageBase64),
                                      )
                                    : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(LucideIcons.plus_a_photo_rounded, size: 32, color: Colors.grey.shade500),
                                          const SizedBox(height: 8),
                                          Text('Pilih Foto', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                          if (_imageBase64 != null && _imageBase64!.isNotEmpty)
                            TextButton(
                              onPressed: () => setState(() => _imageBase64 = null),
                              child: const Text('Hapus Foto', style: TextStyle(color: AppColors.error)),
                            ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nama Produk',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            initialValue: _selectedCategoryId,
                            decoration: const InputDecoration(
                              labelText: 'Kategori',
                              border: OutlineInputBorder(),
                            ),
                            items: widget.categories.map((c) {
                              return DropdownMenuItem<int>(
                                value: c['id'],
                                child: Text(c['name']),
                              );
                            }).toList(),
                            onChanged: (v) => setState(() => _selectedCategoryId = v),
                            validator: (v) => v == null ? 'Pilih kategori' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descController,
                            decoration: const InputDecoration(
                              labelText: 'Deskripsi Singkat (Opsional)',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _sortOrderController,
                            decoration: const InputDecoration(
                              labelText: 'Urutan (Sort Order)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Harga'),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _priceRegularController,
                            decoration: const InputDecoration(
                              labelText: 'Harga Dasar (Regular)',
                              border: OutlineInputBorder(),
                              prefixText: 'Rp ',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Opsi Kustomisasi & Modifier'),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Tersedia Ukuran Large'),
                          value: _hasLargeSize,
                          activeThumbColor: AppColors.primary,
                          onChanged: (v) => setState(() => _hasLargeSize = v),
                        ),
                        if (_hasLargeSize)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: TextFormField(
                              controller: _priceLargeController,
                              decoration: const InputDecoration(
                                labelText: 'Harga Ukuran Large',
                                border: OutlineInputBorder(),
                                prefixText: 'Rp ',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) => _hasLargeSize && v!.isEmpty ? 'Wajib diisi jika fitur Large diaktifkan' : null,
                            ),
                          ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Bisa Kustomisasi Gula (Sugar Level)'),
                          value: _hasSugarLevel,
                          activeThumbColor: AppColors.primary,
                          onChanged: (v) => setState(() => _hasSugarLevel = v),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Bisa Kustomisasi Es (Ice Level)'),
                          value: _hasIceLevel,
                          activeThumbColor: AppColors.primary,
                          onChanged: (v) => setState(() => _hasIceLevel = v),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Bisa Tambah Extra Shot (Espresso)'),
                          value: _hasExtraShot,
                          activeThumbColor: AppColors.primary,
                          onChanged: (v) => setState(() => _hasExtraShot = v),
                        ),
                        if (_hasExtraShot)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: TextFormField(
                              controller: _extraShotPriceController,
                              decoration: const InputDecoration(
                                labelText: 'Harga per Extra Shot',
                                border: OutlineInputBorder(),
                                prefixText: 'Rp ',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) => _hasExtraShot && v!.isEmpty ? 'Wajib diisi jika fitur Extra Shot diaktifkan' : null,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        foregroundColor: AppColors.white,
                      ),
                      child: Text(
                        isEditing ? 'Simpan Perubahan' : 'Tambahkan Produk',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

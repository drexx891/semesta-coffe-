import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../domain/entities/customer.dart';
import '../../../../data/database/dao/customer_dao.dart';
import '../../../../core/di/injection_container.dart';

class CustomerSelectionDialog extends StatefulWidget {
  const CustomerSelectionDialog({super.key});

  @override
  State<CustomerSelectionDialog> createState() => _CustomerSelectionDialogState();
}

class _CustomerSelectionDialogState extends State<CustomerSelectionDialog> {
  final CustomerDao _customerDao = sl<CustomerDao>();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  List<Customer> _customers = [];
  bool _isSearching = false;
  bool _isAddingNew = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isSearching = true);
    final results = await _customerDao.getAll();
    setState(() {
      _customers = results;
      _isSearching = false;
    });
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      await _loadAll();
      return;
    }
    setState(() => _isSearching = true);
    final results = await _customerDao.search(query);
    setState(() {
      _customers = results;
      _isSearching = false;
    });
  }

  Future<void> _saveNewCustomer() async {
    if (_nameController.text.trim().isEmpty) return;
    final customer = Customer(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
    );
    final id = await _customerDao.insert(customer);
    if (mounted) {
      Navigator.pop(context, customer.copyWith(id: id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: _isAddingNew ? _buildAddNew() : _buildSearchList(),
      ),
    );
  }

  Widget _buildSearchList() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Pilih Member', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w600)),
            IconButton(
              icon: const Icon(Icons.person_add_rounded, color: AppColors.primary),
              onPressed: () => setState(() => _isAddingNew = true),
              tooltip: 'Member Baru',
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _searchController,
          onChanged: _search,
          decoration: InputDecoration(
            hintText: 'Cari nama atau nomor WA...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: _isSearching
              ? const Center(child: CircularProgressIndicator())
              : _customers.isEmpty
                  ? const Center(child: Text('Tidak ada pelanggan.'))
                  : ListView.separated(
                      itemCount: _customers.length,
                      separatorBuilder: (ctx, i) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final c = _customers[i];
                        return ListTile(
                          title: Text(c.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          subtitle: Text(c.phone ?? 'Tanpa nomor WA'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.warningLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('${c.loyaltyPoints} Pts', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.warning)),
                          ),
                          onTap: () => Navigator.pop(context, c),
                        );
                      },
                    ),
        ),
        const SizedBox(height: 16),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
      ],
    );
  }

  Widget _buildAddNew() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Member Baru', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Nama Lengkap'),
          autofocus: true,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Nomor WhatsApp (Opsional)'),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: () => setState(() => _isAddingNew = false), child: const Text('Kembali')),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _saveNewCustomer,
              child: const Text('Simpan'),
            ),
          ],
        )
      ],
    );
  }
}

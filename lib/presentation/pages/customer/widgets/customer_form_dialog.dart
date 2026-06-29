import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../domain/entities/customer.dart';
import '../../../bloc/customer/customer_bloc.dart';
import '../../../bloc/customer/customer_event.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CustomerFormDialog extends StatefulWidget {
  final Customer? customer;

  const CustomerFormDialog({super.key, this.customer});

  @override
  State<CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _pointsController;
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _phoneController = TextEditingController(text: widget.customer?.phone ?? '');
    _pointsController = TextEditingController(text: (widget.customer?.loyaltyPoints ?? 0).toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final customer = Customer(
      id: widget.customer?.id,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      loyaltyPoints: int.tryParse(_pointsController.text) ?? 0,
      createdAt: widget.customer?.createdAt ?? DateTime.now(),
    );

    if (widget.customer == null) {
      context.read<CustomerBloc>().add(AddCustomer(customer));
    } else {
      context.read<CustomerBloc>().add(UpdateCustomer(customer));
    }
    
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: AlertDialog(
        backgroundColor: AppColors.surface.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          widget.customer == null ? 'Tambah Member' : 'Edit Member',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    prefixIcon: Icon(LucideIcons.user),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: AppDimensions.spacing16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Telepon',
                    prefixIcon: Icon(LucideLucideIcons.phone),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacing16),
                if (widget.customer != null)
                  TextFormField(
                    controller: _pointsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Poin Loyalitas',
                      prefixIcon: Icon(LucideIcons.stars_rounded),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: _save,
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

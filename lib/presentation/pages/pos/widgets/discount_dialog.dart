import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

class DiscountDialog extends StatefulWidget {
  final double currentPercentage;
  final double currentNominal;
  final double maxPercentage;

  const DiscountDialog({
    super.key,
    required this.currentPercentage,
    required this.currentNominal,
    required this.maxPercentage,
  });

  @override
  State<DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<DiscountDialog> {
  late TextEditingController _percentageController;
  late TextEditingController _nominalController;

  @override
  void initState() {
    super.initState();
    _percentageController = TextEditingController(text: widget.currentPercentage > 0 ? widget.currentPercentage.toStringAsFixed(0) : '');
    _nominalController = TextEditingController(text: widget.currentNominal > 0 ? widget.currentNominal.toStringAsFixed(0) : '');
  }

  @override
  void dispose() {
    _percentageController.dispose();
    _nominalController.dispose();
    super.dispose();
  }

  void _applyDiscount() {
    final pct = double.tryParse(_percentageController.text.trim()) ?? 0;
    final nom = double.tryParse(_nominalController.text.trim()) ?? 0;

    if (pct > widget.maxPercentage) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Diskon persentase maksimal adalah ${widget.maxPercentage}%')));
      return;
    }

    if (pct > 0 && nom > 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih salah satu, Persentase atau Nominal')));
      return;
    }

    Navigator.pop(context, {
      'percentage': pct,
      'nominal': nom,
    });
  }

  void _removeDiscount() {
    Navigator.pop(context, {
      'percentage': 0.0,
      'nominal': 0.0,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Terapkan Diskon', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _percentageController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Diskon Persentase (%)',
              hintText: 'Maksimal ${widget.maxPercentage}%',
              border: const OutlineInputBorder(),
              suffixText: '%',
            ),
            onChanged: (val) {
              if (val.isNotEmpty) _nominalController.clear();
            },
          ),
          const SizedBox(height: 16),
          Text('ATAU', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textTertiary)),
          const SizedBox(height: 16),
          TextField(
            controller: _nominalController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Diskon Nominal (Rp)',
              border: OutlineInputBorder(),
              prefixText: 'Rp ',
            ),
            onChanged: (val) {
              if (val.isNotEmpty) _percentageController.clear();
            },
          ),
        ],
      ),
      actions: [
        if (widget.currentPercentage > 0 || widget.currentNominal > 0)
          TextButton(
            onPressed: _removeDiscount,
            child: const Text('Hapus Diskon', style: TextStyle(color: AppColors.error)),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: _applyDiscount,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDark),
          child: const Text('Terapkan'),
        ),
      ],
    );
  }
}

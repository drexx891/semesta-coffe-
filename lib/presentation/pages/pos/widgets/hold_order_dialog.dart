import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SaveHoldOrderDialog extends StatefulWidget {
  final Function(String) onSave;

  const SaveHoldOrderDialog({super.key, required this.onSave});

  @override
  State<SaveHoldOrderDialog> createState() => _SaveHoldOrderDialogState();
}

class _SaveHoldOrderDialogState extends State<SaveHoldOrderDialog> {
  final _labelController = TextEditingController();

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Simpan Pesanan', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(
              labelText: 'Label (Nama / No Meja)',
              hintText: 'Contoh: Meja 4 / Budi',
            ),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_labelController.text.trim().isEmpty) return;
            widget.onSave(_labelController.text.trim());
            Navigator.pop(context);
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

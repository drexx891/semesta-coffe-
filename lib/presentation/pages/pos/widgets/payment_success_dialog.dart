import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../data/database/dao/transaction_dao.dart';
import '../../../../core/utils/receipt_printer.dart';
import '../../../../services/session_manager.dart';
import '../../../../services/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../bloc/pos/pos_bloc.dart';
import '../../../bloc/pos/pos_event.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PaymentSuccessDialog extends StatefulWidget {
  final int transactionId;
  final String queueNumber;
  final String trxNumber;

  const PaymentSuccessDialog({
    super.key,
    required this.transactionId,
    required this.queueNumber,
    required this.trxNumber,
  });

  @override
  State<PaymentSuccessDialog> createState() => _PaymentSuccessDialogState();
}

class _PaymentSuccessDialogState extends State<PaymentSuccessDialog> {
  
  @override
  void initState() {
    super.initState();
    _playAudio();
    _checkAutoPrint();
  }

  Future<void> _playAudio() async {
    final audioService = sl<AudioService>();
    await audioService.playSuccessSound();
  }

  Future<void> _checkAutoPrint() async {
    final prefs = sl<SharedPreferences>();
    final autoPrint = prefs.getBool('auto_print_receipt') ?? true;
    if (autoPrint) {
      _doPrint();
    }
  }

  Future<void> _doPrint() async {
    final transactionDao = sl<TransactionDao>();
    final session = sl<SessionManager>();
    final trxData = await transactionDao.getById(widget.transactionId);
    if (trxData != null) {
      final items = List<Map<String, dynamic>>.from(trxData['items'] as List);
      await ReceiptPrinter.printReceipt(
        transaction: trxData,
        items: items,
        cashier: session.currentUser!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.successLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.checkCircle, color: AppColors.success, size: 48),
          ),
          const SizedBox(height: 16),
          Text(AppStrings.paymentSuccess,
              style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(widget.trxNumber, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(AppStrings.queueNumber, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                Text(widget.queueNumber,
                    style: GoogleFonts.playfairDisplay(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.accent)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _doPrint,
                  icon: const Icon(LucideIcons.printer, size: 18),
                  label: Text(AppStrings.printReceipt, style: GoogleFonts.inter(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    context.read<PosBloc>().add(StartNewTransaction());
                    Navigator.pop(context); // Close dialog
                  },
                  child: Text(AppStrings.newTransaction, style: GoogleFonts.inter(fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

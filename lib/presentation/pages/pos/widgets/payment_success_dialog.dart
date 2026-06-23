import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../data/database/dao/transaction_dao.dart';
import '../../../../core/utils/receipt_printer.dart';
import '../../../../services/session_manager.dart';
import '../../../bloc/pos/pos_bloc.dart';
import '../../../bloc/pos/pos_event.dart';

class PaymentSuccessDialog extends StatelessWidget {
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
            child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 48),
          ),
          const SizedBox(height: 16),
          Text(AppStrings.paymentSuccess,
              style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(trxNumber, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
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
                Text(queueNumber,
                    style: GoogleFonts.playfairDisplay(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.accent)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final transactionDao = sl<TransactionDao>();
                    final session = sl<SessionManager>();
                    final trxData = await transactionDao.getById(transactionId);
                    if (trxData != null) {
                      final items = List<Map<String, dynamic>>.from(trxData['items'] as List);
                      await ReceiptPrinter.printReceipt(
                        transaction: trxData,
                        items: items,
                        cashier: session.currentUser!,
                      );
                    }
                  },
                  icon: const Icon(Icons.print_rounded, size: 18),
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

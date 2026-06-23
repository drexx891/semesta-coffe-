import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../bloc/pos/pos_bloc.dart';
import '../../../bloc/pos/pos_state.dart';

class ShiftWarningBanner extends StatelessWidget {
  const ShiftWarningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosBloc, PosState>(
      builder: (context, state) {
        if (state.isShiftOpen) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          color: AppColors.errorLight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shift Belum Dibuka',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.error),
                    ),
                    Text(
                      AppStrings.shiftMustBeOpen,
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

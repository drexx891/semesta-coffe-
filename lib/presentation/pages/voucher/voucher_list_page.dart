import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../domain/entities/voucher.dart';
import '../../bloc/voucher/voucher_bloc.dart';
import '../../bloc/voucher/voucher_event.dart';
import '../../bloc/voucher/voucher_state.dart';
import 'widgets/voucher_form_dialog.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class VoucherListPage extends StatelessWidget {
  const VoucherListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<VoucherBloc, VoucherState>(
      listener: (context, state) {
        if (state is VoucherActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.success),
          );
        } else if (state is VoucherError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Manajemen Voucher', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        body: BlocBuilder<VoucherBloc, VoucherState>(
          builder: (context, state) {
            if (state is VoucherLoading || state is VoucherInitial) {
              return const Center(child: CircularProgressIndicator(color: AppColors.accent));
            }
            if (state is VoucherLoaded) {
              final vouchers = state.vouchers;
              if (vouchers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.ticket, size: 80, color: AppColors.textTertiary.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text('Belum ada voucher', style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 16)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(AppDimensions.spacing16),
                itemCount: vouchers.length,
                itemBuilder: (context, index) {
                  return _VoucherCard(voucher: vouchers[index]);
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => BlocProvider.value(
                value: context.read<VoucherBloc>(),
                child: const VoucherFormDialog(),
              ),
            );
          },
          icon: const Icon(LucideIcons.circle_plus),
          label: const Text('Buat Voucher'),
          backgroundColor: AppColors.accent,
        ),
      ),
    );
  }
}

class _VoucherCard extends StatefulWidget {
  final Voucher voucher;
  const _VoucherCard({required this.voucher});

  @override
  State<_VoucherCard> createState() => _VoucherCardState();
}

class _VoucherCardState extends State<_VoucherCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isValid = widget.voucher.isValid;
    final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => BlocProvider.value(
              value: context.read<VoucherBloc>(),
              child: VoucherFormDialog(voucher: widget.voucher),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isValid ? AppColors.surface : AppColors.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
            border: Border.all(
              color: _isHovered ? AppColors.primary : AppColors.border.withValues(alpha: 0.3),
              width: _isHovered ? 1.5 : 1.0,
            ),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isValid ? AppColors.primarySurface : AppColors.divider,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.ticket,
                    color: isValid ? AppColors.primaryDark : AppColors.textTertiary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.voucher.code,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isValid ? AppColors.textPrimary : AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isValid ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              isValid ? 'Aktif' : 'Tidak Aktif',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isValid ? AppColors.success : AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.voucher.discountPercentage > 0 
                            ? 'Diskon ${widget.voucher.discountPercentage}% (Max ${formatter.format(widget.voucher.maxDiscount)})'
                            : 'Potongan ${formatter.format(widget.voucher.discountNominal)}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Berlaku hingga: ${DateFormat('dd MMM yyyy').format(widget.voucher.validUntil)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.trash_2, color: AppColors.error),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Hapus Voucher?'),
                        content: Text('Anda yakin ingin menghapus kode ${widget.voucher.code}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () {
                              context.read<VoucherBloc>().add(DeleteVoucher(widget.voucher.id!));
                              Navigator.pop(ctx);
                            },
                            child: const Text('Hapus', style: TextStyle(color: AppColors.error)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../bloc/attendance/attendance_bloc.dart';
import '../../bloc/attendance/attendance_event.dart';
import '../../bloc/attendance/attendance_state.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class AttendanceHistoryPage extends StatefulWidget {
  final int userId;
  const AttendanceHistoryPage({super.key, required this.userId});

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<AttendanceBloc>().add(LoadAttendanceHistory(widget.userId));
  }

  String _formatTime(String? isoTime) {
    if (isoTime == null) return '-';
    try {
      final dt = DateTime.parse(isoTime).toLocal();
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return '-';
    }
  }

  String _formatDate(String isoTime) {
    try {
      final dt = DateTime.parse(isoTime).toLocal();
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return isoTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Riwayat Absensi', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: BlocBuilder<AttendanceBloc, AttendanceState>(
        builder: (context, state) {
          if (state is AttendanceLoading || state is AttendanceInitial) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }

          if (state is AttendanceHistoryLoaded) {
            final history = state.history;

            if (history.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.history, size: 80, color: AppColors.textTertiary.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text('Belum ada riwayat absensi', style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 16)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.spacing16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final record = history[index];
                final clockIn = record['clock_in_time'] as String;
                final clockOut = record['clock_out_time'] as String?;
                final notes = record['notes'] as String?;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  color: AppColors.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: clockOut != null ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            clockOut != null ? LucideIcons.circle_check : LucideIcons.clock_3,
                            color: clockOut != null ? AppColors.success : AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatDate(clockIn),
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(LucideIcons.log_in, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text('Masuk: ${_formatTime(clockIn)}', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                                  const SizedBox(width: 16),
                                  const Icon(LucideIcons.log_out, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text('Pulang: ${_formatTime(clockOut)}', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                                ],
                              ),
                              if (notes != null && notes.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(LucideIcons.file_text, size: 12, color: AppColors.textTertiary),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          notes,
                                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textTertiary, fontStyle: FontStyle.italic),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

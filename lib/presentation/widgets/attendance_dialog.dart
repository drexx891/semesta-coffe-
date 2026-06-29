import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/attendance/attendance_bloc.dart';
import '../bloc/attendance/attendance_event.dart';
import '../bloc/attendance/attendance_state.dart';

class AttendanceDialog extends StatefulWidget {
  final int userId;

  const AttendanceDialog({super.key, required this.userId});

  @override
  State<AttendanceDialog> createState() => _AttendanceDialogState();
}

class _AttendanceDialogState extends State<AttendanceDialog> {
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AttendanceBloc>().add(LoadAttendanceStatus(widget.userId));
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _processClockIn() {
    context.read<AttendanceBloc>().add(ClockIn(widget.userId));
  }

  void _processClockOut() {
    context.read<AttendanceBloc>().add(ClockOut(userId: widget.userId, notes: _notesController.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AttendanceBloc, AttendanceState>(
      listener: (context, state) {
        if (state is AttendanceActionSuccess) {
          Navigator.pop(context, state.message.contains('Out') ? 'Keluar' : 'Masuk');
        } else if (state is AttendanceError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        if (state is AttendanceLoading || state is AttendanceInitial) {
          return const Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
          );
        }

        bool isClockedIn = false;
        Map<String, dynamic>? activeAttendance;

        if (state is AttendanceStatusLoaded) {
          isClockedIn = state.activeAttendance != null;
          activeAttendance = state.activeAttendance;
        }

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Dialog(
            backgroundColor: AppColors.surface.withValues(alpha: 0.95),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), // pill shape rounded
            child: Container(
              width: 350,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    isClockedIn ? Icons.output_rounded : Icons.login_rounded,
                    size: 48,
                    color: isClockedIn ? AppColors.warning : AppColors.success,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isClockedIn ? 'Clock Out (Pulang)' : 'Clock In (Masuk)',
                    style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isClockedIn
                        ? 'Anda tercatat masuk pada:\n${_formatTime(activeAttendance!['clock_in_time'])}'
                        : 'Klik tombol di bawah untuk mencatat kehadiran masuk Anda hari ini.',
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (isClockedIn) ...[
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Catatan Pulang (Opsional)',
                        hintText: 'Cth: Selesai shift pagi',
                        prefixIcon: const Icon(Icons.notes_rounded),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)), // pill shape
                          ),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isClockedIn ? _processClockOut : _processClockIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isClockedIn ? AppColors.warning : AppColors.success,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)), // pill shape
                          ),
                          child: Text(
                            isClockedIn ? 'Pulang' : 'Masuk',
                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(String isoTime) {
    try {
      final dt = DateTime.parse(isoTime).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoTime;
    }
  }
}

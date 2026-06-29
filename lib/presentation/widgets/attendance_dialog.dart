import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/di/injection_container.dart';
import '../../data/database/dao/attendance_dao.dart';
import '../../services/audio_service.dart';

class AttendanceDialog extends StatefulWidget {
  final int userId;

  const AttendanceDialog({super.key, required this.userId});

  @override
  State<AttendanceDialog> createState() => _AttendanceDialogState();
}

class _AttendanceDialogState extends State<AttendanceDialog> {
  final AttendanceDao _attendanceDao = sl<AttendanceDao>();
  final AudioService _audioService = sl<AudioService>();
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = true;
  Map<String, dynamic>? _activeAttendance;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    setState(() => _isLoading = true);
    final active = await _attendanceDao.getActiveAttendance(widget.userId);
    if (mounted) {
      setState(() {
        _activeAttendance = active;
        _isLoading = false;
      });
    }
  }

  Future<void> _processClockIn() async {
    setState(() => _isLoading = true);
    await _attendanceDao.clockIn(widget.userId);
    await _audioService.playSuccessSound();
    if (mounted) {
      Navigator.pop(context, 'Masuk');
    }
  }

  Future<void> _processClockOut() async {
    setState(() => _isLoading = true);
    await _attendanceDao.clockOut(widget.userId, _notesController.text.trim());
    await _audioService.playSuccessSound();
    if (mounted) {
      Navigator.pop(context, 'Keluar');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [CircularProgressIndicator()],
          ),
        ),
      );
    }

    final isClockedIn = _activeAttendance != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isClockedIn
                  ? 'Anda tercatat masuk pada:\n${_formatTime(_activeAttendance!['clock_in_time'])}'
                  : 'Klik tombol di bawah untuk mencatat kehadiran masuk Anda.',
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

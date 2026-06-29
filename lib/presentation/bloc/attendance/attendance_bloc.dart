import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/database/dao/attendance_dao.dart';
import '../../../../services/audio_service.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final AttendanceDao attendanceDao;
  final AudioService audioService;

  AttendanceBloc({
    required this.attendanceDao,
    required this.audioService,
  }) : super(AttendanceInitial()) {
    on<LoadAttendanceStatus>(_onLoadAttendanceStatus);
    on<ClockIn>(_onClockIn);
    on<ClockOut>(_onClockOut);
    on<LoadAttendanceHistory>(_onLoadAttendanceHistory);
  }

  Future<void> _onLoadAttendanceStatus(LoadAttendanceStatus event, Emitter<AttendanceState> emit) async {
    emit(AttendanceLoading());
    try {
      final active = await attendanceDao.getActiveAttendance(event.userId);
      emit(AttendanceStatusLoaded(active));
    } catch (e) {
      emit(AttendanceError('Gagal memuat status absensi: $e'));
    }
  }

  Future<void> _onClockIn(ClockIn event, Emitter<AttendanceState> emit) async {
    emit(AttendanceLoading());
    try {
      await attendanceDao.clockIn(event.userId);
      await audioService.playSuccessSound();
      emit(const AttendanceActionSuccess('Berhasil Clock In'));
      // Return to loaded status
      add(LoadAttendanceStatus(event.userId));
    } catch (e) {
      emit(AttendanceError('Gagal Clock In: $e'));
      add(LoadAttendanceStatus(event.userId));
    }
  }

  Future<void> _onClockOut(ClockOut event, Emitter<AttendanceState> emit) async {
    emit(AttendanceLoading());
    try {
      await attendanceDao.clockOut(event.userId, event.notes);
      await audioService.playSuccessSound();
      emit(const AttendanceActionSuccess('Berhasil Clock Out'));
      add(LoadAttendanceStatus(event.userId));
    } catch (e) {
      emit(AttendanceError('Gagal Clock Out: $e'));
      add(LoadAttendanceStatus(event.userId));
    }
  }

  Future<void> _onLoadAttendanceHistory(LoadAttendanceHistory event, Emitter<AttendanceState> emit) async {
    emit(AttendanceLoading());
    try {
      final history = await attendanceDao.getHistory(event.userId);
      emit(AttendanceHistoryLoaded(history));
    } catch (e) {
      emit(AttendanceError('Gagal memuat riwayat: $e'));
    }
  }
}

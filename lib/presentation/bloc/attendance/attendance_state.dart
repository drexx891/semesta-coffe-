import 'package:equatable/equatable.dart';

abstract class AttendanceState extends Equatable {
  const AttendanceState();

  @override
  List<Object?> get props => [];
}

class AttendanceInitial extends AttendanceState {}

class AttendanceLoading extends AttendanceState {}

class AttendanceStatusLoaded extends AttendanceState {
  final Map<String, dynamic>? activeAttendance;

  const AttendanceStatusLoaded(this.activeAttendance);

  @override
  List<Object?> get props => [activeAttendance];
}

class AttendanceHistoryLoaded extends AttendanceState {
  final List<Map<String, dynamic>> history;

  const AttendanceHistoryLoaded(this.history);

  @override
  List<Object?> get props => [history];
}

class AttendanceActionSuccess extends AttendanceState {
  final String message;

  const AttendanceActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class AttendanceError extends AttendanceState {
  final String message;

  const AttendanceError(this.message);

  @override
  List<Object?> get props => [message];
}

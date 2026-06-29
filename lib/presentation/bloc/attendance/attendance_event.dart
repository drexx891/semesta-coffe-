import 'package:equatable/equatable.dart';

abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

class LoadAttendanceStatus extends AttendanceEvent {
  final int userId;
  const LoadAttendanceStatus(this.userId);
  
  @override
  List<Object?> get props => [userId];
}

class ClockIn extends AttendanceEvent {
  final int userId;
  const ClockIn(this.userId);

  @override
  List<Object?> get props => [userId];
}

class ClockOut extends AttendanceEvent {
  final int userId;
  final String notes;

  const ClockOut({required this.userId, required this.notes});

  @override
  List<Object?> get props => [userId, notes];
}

class LoadAttendanceHistory extends AttendanceEvent {
  final int userId;
  const LoadAttendanceHistory(this.userId);

  @override
  List<Object?> get props => [userId];
}

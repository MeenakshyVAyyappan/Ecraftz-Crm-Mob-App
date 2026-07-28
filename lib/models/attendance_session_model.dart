class AttendanceSession {
  final String id;
  final String employeeId;
  final DateTime sessionDate;
  final String? shiftId;
  final DateTime? firstPunchIn;
  final DateTime? lastPunchOut;
  final int? totalWorkMinutes;
  final int? overtimeMinutes;
  final String? status;
  final bool isLate;
  final bool isHalfDay;

  AttendanceSession({
    required this.id,
    required this.employeeId,
    required this.sessionDate,
    this.shiftId,
    this.firstPunchIn,
    this.lastPunchOut,
    this.totalWorkMinutes,
    this.overtimeMinutes,
    this.status,
    this.isLate = false,
    this.isHalfDay = false,
  });

  factory AttendanceSession.fromJson(Map<String, dynamic> json) {
    return AttendanceSession(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      sessionDate: DateTime.parse(json['session_date'] as String),
      shiftId: json['shift_id'] as String?,
      firstPunchIn: json['first_punch_in'] != null ? DateTime.parse(json['first_punch_in'] as String).toLocal() : null,
      lastPunchOut: json['last_punch_out'] != null ? DateTime.parse(json['last_punch_out'] as String).toLocal() : null,
      totalWorkMinutes: json['total_work_minutes'] as int?,
      overtimeMinutes: json['overtime_minutes'] as int?,
      status: json['status'] as String?,
      isLate: json['is_late'] as bool? ?? false,
      isHalfDay: json['is_half_day'] as bool? ?? false,
    );
  }
}

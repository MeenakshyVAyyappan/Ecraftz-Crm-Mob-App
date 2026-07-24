class TeamTimesheetEntry {
  final String id;
  final String userId;
  final String userName;
  final String? userEmail;
  final String? departmentName;
  final DateTime date;
  final DateTime? clockIn;
  final DateTime? clockOut;
  final int totalWorkMinutes;
  final int totalBreakMinutes;
  final int overtimeMinutes;
  final String status; // 'present', 'absent', 'late', 'half_day'
  final bool isLate;
  final bool isHalfDay;

  TeamTimesheetEntry({
    required this.id,
    required this.userId,
    required this.userName,
    this.userEmail,
    this.departmentName,
    required this.date,
    this.clockIn,
    this.clockOut,
    this.totalWorkMinutes = 0,
    this.totalBreakMinutes = 0,
    this.overtimeMinutes = 0,
    this.status = 'present',
    this.isLate = false,
    this.isHalfDay = false,
  });

  factory TeamTimesheetEntry.fromJson(Map<String, dynamic> json) {
    String uName = 'Employee';
    String? uEmail;
    if (json['profiles'] is Map) {
      final p = json['profiles'] as Map;
      uName = p['full_name']?.toString() ?? 'Employee';
      uEmail = p['email']?.toString();
    }

    final sDate = json['session_date'] ?? json['work_date'] ?? json['date'];
    final dateVal = sDate != null ? DateTime.parse(sDate.toString()) : DateTime.now();

    final cIn = json['first_punch_in'] ?? json['first_check_in'] ?? json['clock_in'] ?? json['start_time'];
    final cOut = json['last_punch_out'] ?? json['last_check_out'] ?? json['clock_out'] ?? json['end_time'];

    return TeamTimesheetEntry(
      id: json['id']?.toString() ?? '${json['user_id']}_${sDate}',
      userId: json['employee_id']?.toString() ?? json['user_id']?.toString() ?? '',
      userName: uName,
      userEmail: uEmail,
      departmentName: json['department_name']?.toString(),
      date: dateVal,
      clockIn: cIn != null ? DateTime.tryParse(cIn.toString()) : null,
      clockOut: cOut != null ? DateTime.tryParse(cOut.toString()) : null,
      totalWorkMinutes: (json['total_work_minutes'] ?? json['net_work_minutes'] ?? json['total_session_minutes'] ?? 0) as int,
      totalBreakMinutes: (json['total_break_minutes'] ?? 0) as int,
      overtimeMinutes: (json['overtime_minutes'] ?? 0) as int,
      status: json['status']?.toString() ?? 'present',
      isLate: json['is_late'] ?? false,
      isHalfDay: json['is_half_day'] ?? false,
    );
  }
}

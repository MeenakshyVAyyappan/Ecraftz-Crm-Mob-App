class EmployeeShift {
  final String id;
  final String shiftName; // e.g. "09:00 AM – 06:00 PM"
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final int graceMinutes; // 15
  final int requiredWorkMinutes; // 540 (9 hours)

  const EmployeeShift({
    required this.id,
    required this.shiftName,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    this.graceMinutes = 15,
    this.requiredWorkMinutes = 540,
  });

  /// Late threshold: Shift Start + 15 mins grace
  DateTime lateThreshold(DateTime baseDate) {
    return DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      startHour,
      startMinute + graceMinutes,
    );
  }

  /// Exact shift start time
  DateTime startTime(DateTime baseDate) {
    return DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      startHour,
      startMinute,
    );
  }

  /// Exact shift end time
  DateTime endTime(DateTime baseDate) {
    return DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      endHour,
      endMinute,
    );
  }

  static const List<EmployeeShift> defaultShifts = [
    EmployeeShift(
      id: 'shift_9_6',
      shiftName: '09:00 AM – 06:00 PM',
      startHour: 9,
      startMinute: 0,
      endHour: 18,
      endMinute: 0,
    ),
    EmployeeShift(
      id: 'shift_930_630',
      shiftName: '09:30 AM – 06:30 PM',
      startHour: 9,
      startMinute: 30,
      endHour: 18,
      endMinute: 30,
    ),
    EmployeeShift(
      id: 'shift_10_7',
      shiftName: '10:00 AM – 07:00 PM',
      startHour: 10,
      startMinute: 0,
      endHour: 19,
      endMinute: 0,
    ),
    EmployeeShift(
      id: 'shift_1030_730',
      shiftName: '10:30 AM – 07:30 PM',
      startHour: 10,
      startMinute: 30,
      endHour: 19,
      endMinute: 30,
    ),
  ];

  static EmployeeShift getShiftByIdOrIndex(String? idOrIndex, [int index = 0]) {
    if (idOrIndex != null && idOrIndex.isNotEmpty) {
      for (final s in defaultShifts) {
        if (s.id == idOrIndex || s.shiftName.toLowerCase().contains(idOrIndex.toLowerCase())) {
          return s;
        }
      }
    }
    return defaultShifts[index % defaultShifts.length];
  }
}

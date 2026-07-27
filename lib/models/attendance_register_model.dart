import 'package:flutter/material.dart';
import 'employee_shift_model.dart';

class AttendanceDailyRecord {
  final String id;
  final String employeeId;
  final String employeeName;
  final DateTime workDate;
  final String? checkIn;  // e.g. "09:43"
  final String? checkOut; // e.g. "17:50"
  final int totalWorkMinutes;
  final int totalBreakMinutes;
  final String status; // 'P' (Present), 'L' (Late), 'A' (Absent), 'WFH' (Work From Home)
  final int lateMinutes;
  final String? deviceId;
  final EmployeeShift shift;

  AttendanceDailyRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.workDate,
    this.checkIn,
    this.checkOut,
    this.totalWorkMinutes = 0,
    this.totalBreakMinutes = 0,
    this.status = 'A',
    this.lateMinutes = 0,
    this.deviceId,
    EmployeeShift? shift,
  }) : shift = shift ?? EmployeeShift.defaultShifts.first;

  /// Required work minutes = 540 (9.0 hours)
  int get requiredWorkMinutes => shift.requiredWorkMinutes;

  /// Remaining work minutes (if work < 540 mins)
  int get remainingWorkMinutes {
    if (status == 'A') return 540;
    return totalWorkMinutes < 540 ? (540 - totalWorkMinutes) : 0;
  }

  /// Overtime minutes (if work > 540 mins)
  int get overtimeMinutes {
    return totalWorkMinutes > 540 ? (totalWorkMinutes - 540) : 0;
  }

  String get formattedWorkHours {
    final hrs = (totalWorkMinutes / 60).toStringAsFixed(1);
    return '$hrs hrs';
  }

  String get formattedRemainingHours {
    final hrs = (remainingWorkMinutes / 60).toStringAsFixed(1);
    return '$hrs hrs';
  }

  String get formattedOvertimeHours {
    final hrs = (overtimeMinutes / 60).toStringAsFixed(1);
    return '$hrs hrs';
  }

  Color get statusColor {
    switch (status.toUpperCase()) {
      case 'P':
        return const Color(0xFF10B981); // Green
      case 'L':
        return const Color(0xFFF59E0B); // Yellow / Amber
      case 'WFH':
        return const Color(0xFF3B82F6); // Blue
      case 'A':
      default:
        return const Color(0xFFEF4444); // Red
    }
  }

  String get statusLabel {
    switch (status.toUpperCase()) {
      case 'P':
        return 'Present';
      case 'L':
        return 'Late';
      case 'WFH':
        return 'Work From Home';
      case 'A':
      default:
        return 'Absent';
    }
  }
}

class EmployeeAttendanceSummaryRow {
  final String employeeId;
  final String employeeName;
  final String employeeCode;
  final String? avatarUrl;
  final EmployeeShift shift;
  final Map<int, AttendanceDailyRecord> dailyRecords; // day of month -> record

  EmployeeAttendanceSummaryRow({
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    this.avatarUrl,
    EmployeeShift? shift,
    required this.dailyRecords,
  }) : shift = shift ?? EmployeeShift.defaultShifts.first;
}

class SnapshotEmployeeItem {
  final String employeeId;
  final String name;
  final String displayId;
  final String? checkInTime;
  final String? checkOutTime;
  final EmployeeShift shift;

  SnapshotEmployeeItem({
    required this.employeeId,
    required this.name,
    required this.displayId,
    this.checkInTime,
    this.checkOutTime,
    EmployeeShift? shift,
  }) : shift = shift ?? EmployeeShift.defaultShifts.first;
}

class AttendanceSnapshotData {
  final DateTime snapshotDate;
  final List<SnapshotEmployeeItem> presentList;
  final List<SnapshotEmployeeItem> absentList;
  final List<SnapshotEmployeeItem> wfhList;

  AttendanceSnapshotData({
    required this.snapshotDate,
    this.presentList = const [],
    this.absentList = const [],
    this.wfhList = const [],
  });

  int get presentCount => presentList.length;
  int get absentCount => absentList.length;
  int get wfhCount => wfhList.length;
}
  });

  int get presentCount => presentList.length;
  int get absentCount => absentList.length;
  int get wfhCount => wfhList.length;
}

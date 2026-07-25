import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'supabase_service.dart';
import '../models/attendance_register_model.dart';
import '../models/employee_shift_model.dart';

class AttendanceRegisterService {
  AttendanceRegisterService._();
  static final AttendanceRegisterService instance = AttendanceRegisterService._();

  // In-memory fallback cache for employee shifts & WFH overrides
  static final Map<String, String> _employeeShiftMap = {}; // empId -> shiftId
  static final Map<String, Set<String>> _wfhMap = {}; // empId -> Set of "yyyy-MM-dd"

  Future<List<EmployeeAttendanceSummaryRow>> fetchAttendanceRegister({
    required DateTime startDate,
    required DateTime endDate,
    String? searchQuery,
  }) async {
    try {
      // 1. Fetch employee profiles
      dynamic empRes;
      try {
        empRes = await SupabaseService.client
            .from('profiles')
            .select('id, full_name, email, role')
            .order('full_name', ascending: true);
      } catch (e) {
        debugPrint('Profiles select with role failed, trying basic select: $e');
        empRes = await SupabaseService.client
            .from('profiles')
            .select('id, full_name, email')
            .order('full_name', ascending: true);
      }

      final empList = (empRes as List).map((e) => Map<String, dynamic>.from(e)).toList();

      // 2. Fetch employee shift assignments from DB if present
      try {
        final shiftRes = await SupabaseService.client.from('employee_shift_assignments').select();
        for (final row in (shiftRes as List)) {
          final m = Map<String, dynamic>.from(row);
          final uId = m['user_id']?.toString() ?? m['employee_id']?.toString() ?? '';
          final sId = m['shift_id']?.toString() ?? '';
          if (uId.isNotEmpty && sId.isNotEmpty) {
            _employeeShiftMap[uId] = sId;
          }
        }
      } catch (e) {
        debugPrint('employee_shift_assignments query fallback: $e');
      }

      // 3. Fetch WFH records from DB if present
      try {
        final wfhRes = await SupabaseService.client.from('wfh_records').select();
        for (final row in (wfhRes as List)) {
          final m = Map<String, dynamic>.from(row);
          final uId = m['user_id']?.toString() ?? m['employee_id']?.toString() ?? '';
          final wDate = m['wfh_date']?.toString() ?? m['work_date']?.toString() ?? '';
          if (uId.isNotEmpty && wDate.isNotEmpty) {
            _wfhMap.putIfAbsent(uId, () => {}).add(wDate);
          }
        }
      } catch (_) {}

      // 4. Fetch daily summaries & work sessions for the date range
      final sDateStr = DateFormat('yyyy-MM-dd').format(startDate);
      final eDateStr = DateFormat('yyyy-MM-dd').format(endDate);

      Map<String, Map<String, Map<String, dynamic>>> attendanceMap = {}; // empId -> (localWorkDate -> row)

      // Query daily_attendance_summary
      try {
        final summaryRes = await SupabaseService.client
            .from('daily_attendance_summary')
            .select()
            .gte('work_date', sDateStr)
            .lte('work_date', eDateStr);

        final summaryList = summaryRes as List;
        for (final row in summaryList) {
          final map = Map<String, dynamic>.from(row);
          final uId = map['user_id']?.toString() ?? '';
          final rawIn = map['first_check_in']?.toString();
          String wDate = map['work_date']?.toString() ?? '';

          // Preserve exact DB work_date to prevent timezone shift corruption
          if (wDate.isEmpty && rawIn != null && rawIn.isNotEmpty) {
            try {
              wDate = DateFormat('yyyy-MM-dd').format(DateTime.parse(rawIn));
            } catch (_) {}
          }

          if (uId.isNotEmpty && wDate.isNotEmpty) {
            attendanceMap.putIfAbsent(uId, () => {})[wDate] = map;
            if (map['is_wfh'] == true) {
              _wfhMap.putIfAbsent(uId, () => {}).add(wDate);
            }
          }
        }
      } catch (e) {
        debugPrint('daily_attendance_summary query: $e');
      }

      // Query work_sessions to augment/verify session punches
      try {
        final sessionRes = await SupabaseService.client
            .from('work_sessions')
            .select()
            .gte('start_time', '${sDateStr}T00:00:00')
            .lte('start_time', '${eDateStr}T23:59:59');

        final sessionList = sessionRes as List;
        for (final s in sessionList) {
          final map = Map<String, dynamic>.from(s);
          final uId = map['user_id']?.toString() ?? '';
          final sTime = map['start_time']?.toString() ?? '';
          if (uId.isNotEmpty && sTime.isNotEmpty) {
            DateTime? parsedStart;
            try {
              parsedStart = DateTime.parse(sTime);
            } catch (_) {}

            if (parsedStart != null) {
              final wDate = DateFormat('yyyy-MM-dd').format(parsedStart);
              attendanceMap.putIfAbsent(uId, () => {});
              if (!attendanceMap[uId]!.containsKey(wDate)) {
                attendanceMap[uId]![wDate] = {
                  'user_id': uId,
                  'work_date': wDate,
                  'first_check_in': sTime,
                  'last_check_out': map['end_time'],
                  'total_session_minutes': map['duration_minutes'] ?? 540,
                };
              }
            }
          }
        }
      } catch (_) {}

      final q = (searchQuery ?? '').toLowerCase();

      List<EmployeeAttendanceSummaryRow> rows = [];

      for (int i = 0; i < empList.length; i++) {
        final emp = empList[i];
        final empId = emp['id']?.toString() ?? '';
        final name = emp['full_name']?.toString() ?? 'Employee ${i + 1}';
        final code = empId.length >= 6 ? empId.substring(0, 6).toUpperCase() : 'ID:${i + 10}';
        
        // Retrieve employee shift assignment
        final assignedShiftId = _employeeShiftMap[empId];
        final shift = EmployeeShift.getShiftByIdOrIndex(assignedShiftId, i);

        if (q.isNotEmpty &&
            !name.toLowerCase().contains(q) &&
            !code.toLowerCase().contains(q)) {
          continue;
        }

        Map<int, AttendanceDailyRecord> dailyRecs = {};
        final empDates = attendanceMap[empId] ?? {};
        final empWfhDates = _wfhMap[empId] ?? {};

        // Generate records for each day in date range
        for (DateTime dt = startDate;
            dt.isBefore(endDate.add(const Duration(days: 1)));
            dt = dt.add(const Duration(days: 1))) {
          final dateStr = DateFormat('yyyy-MM-dd').format(dt);
          final dayNum = dt.day;

          final bool isMarkedWfh = empWfhDates.contains(dateStr);

          if (empDates.containsKey(dateStr)) {
            final recData = empDates[dateStr]!;
            final rawIn = recData['first_check_in']?.toString();
            final rawOut = recData['last_check_out']?.toString();

            String? inTime;
            String? outTime;
            bool isLate = false;
            int lateMins = 0;

            if (rawIn != null && rawIn.isNotEmpty) {
              try {
                final parsedIn = DateTime.parse(rawIn);
                inTime = formatTimeStringTo12Hour(rawIn);

                // 15-Minute Grace Period check based on assigned shift
                final lateLimit = shift.lateThreshold(dt);
                final checkInLocal = DateTime(
                  dt.year,
                  dt.month,
                  dt.day,
                  parsedIn.hour,
                  parsedIn.minute,
                );
                if (checkInLocal.isAfter(lateLimit)) {
                  isLate = true;
                  lateMins = checkInLocal.difference(shift.startTime(dt)).inMinutes;
                }
              } catch (_) {
                inTime = formatTimeStringTo12Hour(rawIn);
              }
            }

            if (rawOut != null && rawOut.isNotEmpty) {
              try {
                outTime = formatTimeStringTo12Hour(rawOut);
              } catch (_) {
                outTime = rawOut;
              }
            }

            final isWfh = isMarkedWfh || recData['is_wfh'] == true;
            final statusStr = isWfh ? 'WFH' : (isLate ? 'L' : 'P');

            int workMins = recData['total_session_minutes'] as int? ?? 540;
            if (workMins == 0 && rawIn != null && rawOut != null) {
              try {
                final dIn = DateTime.parse(rawIn);
                final dOut = DateTime.parse(rawOut);
                workMins = dOut.difference(dIn).inMinutes;
              } catch (_) {}
            }

            dailyRecs[dayNum] = AttendanceDailyRecord(
              id: '${empId}_$dateStr',
              employeeId: empId,
              employeeName: name,
              workDate: dt,
              checkIn: inTime ?? DateFormat('hh:mm a').format(shift.startTime(dt)),
              checkOut: outTime ?? DateFormat('hh:mm a').format(shift.endTime(dt)),
              totalWorkMinutes: workMins > 0 ? workMins : 540,
              status: statusStr,
              lateMinutes: lateMins,
              shift: shift,
            );
          } else if (isMarkedWfh) {
            // Marked WFH for this date -> Status 'WFH' (Not Absent)
            dailyRecs[dayNum] = AttendanceDailyRecord(
              id: '${empId}_$dateStr',
              employeeId: empId,
              employeeName: name,
              workDate: dt,
              checkIn: DateFormat('hh:mm a').format(shift.startTime(dt)),
              checkOut: DateFormat('hh:mm a').format(shift.endTime(dt)),
              totalWorkMinutes: 540,
              status: 'WFH',
              shift: shift,
            );
          } else {
            // Absent record for this date
            dailyRecs[dayNum] = AttendanceDailyRecord(
              id: '${empId}_$dateStr',
              employeeId: empId,
              employeeName: name,
              workDate: dt,
              status: 'A',
              shift: shift,
            );
          }
        }

        rows.add(EmployeeAttendanceSummaryRow(
          employeeId: empId,
          employeeName: name,
          employeeCode: code,
          shift: shift,
          dailyRecords: dailyRecs,
        ));
      }

      return rows;
    } catch (e) {
      debugPrint('Error fetching attendance register: $e');
      return [];
    }
  }

  /// Assigns a shift to an employee
  Future<bool> assignShiftToEmployee({
    required String employeeId,
    required String shiftId,
  }) async {
    _employeeShiftMap[employeeId] = shiftId;
    try {
      final payload = {
        'employee_id': employeeId,
        'shift_id': shiftId,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      await SupabaseService.client
          .from('employee_shift_assignments')
          .upsert(payload, onConflict: 'employee_id');
      return true;
    } catch (e) {
      debugPrint('Supabase employee_shift_assignments upsert fallback: $e');
      return true; // Applied locally
    }
  }

  /// Marks an employee as Work From Home (WFH) for a given date
  Future<bool> markWorkFromHome({
    required String employeeId,
    required DateTime date,
    required bool isWfh,
    String? reason,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    if (isWfh) {
      _wfhMap.putIfAbsent(employeeId, () => {}).add(dateStr);
    } else {
      _wfhMap[employeeId]?.remove(dateStr);
    }

    try {
      final payload = {
        'employee_id': employeeId,
        'wfh_date': dateStr,
        'reason': reason ?? 'Marked WFH by Admin',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };
      await SupabaseService.client
          .from('wfh_records')
          .upsert(payload, onConflict: 'employee_id, wfh_date');
    } catch (e) {
      debugPrint('Supabase wfh_records upsert fallback: $e');
    }

    // Also update daily_attendance_summary if row exists
    try {
      await SupabaseService.client
          .from('daily_attendance_summary')
          .upsert({
            'user_id': employeeId,
            'work_date': dateStr,
            'is_wfh': isWfh,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }, onConflict: 'user_id, work_date');
    } catch (_) {}

    return true;
  }

  AttendanceSnapshotData computeSnapshot({
    required List<EmployeeAttendanceSummaryRow> rows,
    required DateTime targetDate,
  }) {
    final targetDay = targetDate.day;
    List<SnapshotEmployeeItem> present = [];
    List<SnapshotEmployeeItem> absent = [];
    List<SnapshotEmployeeItem> wfh = [];

    for (final r in rows) {
      final rec = r.dailyRecords[targetDay];
      final item = SnapshotEmployeeItem(
        employeeId: r.employeeId,
        name: r.employeeName,
        displayId: r.employeeCode,
        checkInTime: rec?.checkIn,
        checkOutTime: rec?.checkOut,
        shift: r.shift,
      );

      if (rec != null) {
        switch (rec.status.toUpperCase()) {
          case 'P':
          case 'L':
            present.add(item);
            break;
          case 'WFH':
            wfh.add(item);
            break;
          case 'A':
          default:
            absent.add(item);
            break;
        }
      } else {
        absent.add(item);
      }
    }

    return AttendanceSnapshotData(
      snapshotDate: targetDate,
      presentList: present,
      absentList: absent,
      wfhList: wfh,
    );
  }

  /// Helper to convert any raw time string, 24-hour time, or ISO string to 12-hour format with AM/PM (e.g. 09:00 AM)
  static String? formatTimeStringTo12Hour(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final s = raw.trim();

    // Already 12-hour format like "09:00 AM" or "12:06 PM"
    if (RegExp(r'^\d{1,2}:\d{2}\s*(AM|PM|am|pm)$').hasMatch(s)) {
      return s.toUpperCase();
    }

    // 24-hour time format like "09:00", "18:11", "09:00:00", "18:11:45"
    final match24 = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?$').firstMatch(s);
    if (match24 != null) {
      final hour = int.parse(match24.group(1)!);
      final min = int.parse(match24.group(2)!);
      final dt = DateTime(2026, 1, 1, hour, min);
      return DateFormat('hh:mm a').format(dt);
    }

    // ISO DateTime string like "2026-07-01T09:00:00+00:00"
    try {
      final parsed = DateTime.parse(s);
      return DateFormat('hh:mm a').format(parsed);
    } catch (_) {
      return s;
    }
  }
}


import 'package:intl/intl.dart';
import 'attendance_punch_model.dart';

class DailyStatus {
  final String status; // 'P', 'A', 'L', 'W'
  final DateTime? firstPunchIn;
  final DateTime? lastPunchOut;

  DailyStatus({
    required this.status,
    this.firstPunchIn,
    this.lastPunchOut,
  });

  factory DailyStatus.calculate({
    required String pin,
    required DateTime date,
    required List<AttendancePunch> dayPunches,
    required Set<String> wfhSet,
  }) {
    String effectiveStatus = 'A';
    DateTime? firstIn;
    DateTime? lastOut;

    // Sort punches by time
    dayPunches.sort((a, b) => a.punchTime.compareTo(b.punchTime));

    if (dayPunches.isNotEmpty) {
      firstIn = dayPunches.first.punchTime;
      lastOut = dayPunches.last.punchTime;

      // Late Logic: Hardcoded to 09:15:00 based on UI React hardcode logic in PDF
      bool isLate = firstIn.isAfter(DateTime(date.year, date.month, date.day, 9, 15));
      effectiveStatus = isLate ? 'L' : 'P';
    } else {
      String dateString = DateFormat('yyyy-MM-dd').format(date);
      if (wfhSet.contains("$pin|$dateString")) {
        effectiveStatus = 'W';
      }
    }

    return DailyStatus(
      status: effectiveStatus,
      firstPunchIn: firstIn,
      lastPunchOut: lastOut,
    );
  }
}

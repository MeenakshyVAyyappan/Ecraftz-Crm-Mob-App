import 'package:intl/intl.dart';

class WorkSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final String status;
  final int breakMinutes;

  WorkSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.status,
    this.breakMinutes = 0,
  });

  bool get isActive {
    final lower = status.toLowerCase().trim();
    return endTime == null && !['completed', 'done', 'finished', 'checked_out'].contains(lower);
  }

  Duration get duration => endTime?.difference(startTime) ?? DateTime.now().difference(startTime);
  String get signIn => DateFormat('hh:mm a').format(startTime);
  String get signOut => endTime != null ? DateFormat('hh:mm a').format(endTime!) : '--:--';
  String get displayStatus {
    final lower = status.toLowerCase();
    if (isActive) return 'WORKING';
    if (lower == 'completed') return 'COMPLETED';
    if (lower == 'absent') return 'ABSENT';
    return status.toUpperCase();
  }

  factory WorkSession.fromMap(Map<String, dynamic> json, {int breakMinutes = 0}) {
    DateTime? parseDate(String? value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    return WorkSession(
      id: json['id']?.toString() ?? '',
      startTime: parseDate(json['start_time']?.toString())?.toLocal() ?? DateTime.now().toLocal(),
      endTime: parseDate(json['end_time']?.toString())?.toLocal(),
      status: json['status']?.toString() ?? 'working',
      breakMinutes: breakMinutes,
    );
  }
}

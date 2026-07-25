import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

void main() {
  test('Inspect July 2026 Attendance Records for MARZA / MEENAKSHY', () async {
    final client = SupabaseClient(
      'https://bnjvugxvcoqgfvvvwpzc.supabase.co',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJuanZ1Z3h2Y29xZ2Z2dnZ3cHpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMzMTA4NTMsImV4cCI6MjA5ODg4Njg1M30.Fe5COvy60ezaVwrrDOR_Ec-1wDRizd6FiPp9vtHy2O4',
    );

    print('\n--- PROFILES ---');
    final emps = await client.from('profiles').select('id, full_name, email');
    for (final e in (emps as List)) {
      print('${e['full_name']} -> id: ${e['id']}');
    }

    print('\n--- DAILY ATTENDANCE SUMMARY (July 2026) ---');
    final summaries = await client
        .from('daily_attendance_summary')
        .select()
        .gte('work_date', '2026-07-01')
        .lte('work_date', '2026-07-31');
    print('Found ${(summaries as List).length} summary rows in July 2026:');
    for (final s in summaries) {
      print('  Summary: $s');
    }

    print('\n--- WORK SESSIONS (July 2026) ---');
    final sessions = await client
        .from('work_sessions')
        .select()
        .gte('start_time', '2026-07-01T00:00:00')
        .lte('start_time', '2026-07-31T23:59:59');
    print('Found ${(sessions as List).length} work_session rows in July 2026:');
    for (final s in sessions) {
      print('  Session: user_id=${s['user_id']} start=${s['start_time']} end=${s['end_time']} source=${s['punch_source']}');
    }
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Inspect Dashboard Supabase Tables', () async {
    final client = SupabaseClient(
      'https://bnjvugxvcoqgfvvvwpzc.supabase.co',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJuanZ1Z3h2Y29xZ2Z2dnZ3cHpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMzMTA4NTMsImV4cCI6MjA5ODg4Njg1M30.Fe5COvy60ezaVwrrDOR_Ec-1wDRizd6FiPp9vtHy2O4',
    );

    final tablesToTest = [
      'bde_call_logs',
      'call_logs',
      'bde_reports',
      'bde_daily_reports',
      'meetings',
      'meeting_schedules',
      'client_feedback',
      'client_feedbacks',
      'activities',
      'audit_logs',
      'profiles',
      'users',
      'crm_leads',
      'leads',
    ];

    for (final table in tablesToTest) {
      try {
        final res = await client.from(table).select('*').limit(3);
        print('=== Table: $table ===');
        print('Count: ${(res as List).length}');
        if (res.isNotEmpty) {
          print('Sample keys: ${(res.first as Map).keys.toList()}');
          print('Sample row: ${res.first}');
        }
      } catch (e) {
        print('Table $table failed: $e');
      }
    }
  });
}

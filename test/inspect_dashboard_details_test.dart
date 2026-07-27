import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Inspect Supabase Dashboard Tables Columns and Samples', () async {
    final client = SupabaseClient(
      'https://bnjvugxvcoqgfvvvwpzc.supabase.co',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJuanZ1Z3h2Y29xZ2Z2dnZ3cHpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMzMTA4NTMsImV4cCI6MjA5ODg4Njg1M30.Fe5COvy60ezaVwrrDOR_Ec-1wDRizd6FiPp9vtHy2O4',
    );

    final tablesToTest = [
      'bde_daily_reports',
      'meetings',
      'meeting_attendees',
      'client_feedback',
      'activities',
      'audit_logs',
      'profiles',
      'user_roles',
      'invoices',
      'projects',
      'tasks',
      'leads',
    ];

    for (final table in tablesToTest) {
      try {
        final res = await client.from(table).select('*').limit(5);
        print('=== Table: $table ===');
        print('Row count returned: ${(res as List).length}');
        if (res.isNotEmpty) {
          print('Keys: ${(res.first as Map).keys.toList()}');
          print('First Row: ${res.first}');
        } else {
          // If empty, try select count
          try {
            final countRes = await client.from(table).select('*');
            print('Total rows in $table: ${(countRes as List).length}');
          } catch (_) {}
        }
      } catch (e) {
        print('Table $table error: $e');
      }
    }
  });
}

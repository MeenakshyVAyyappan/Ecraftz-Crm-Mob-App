import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  print('Connecting to Supabase...');
  await Supabase.initialize(
    url: 'https://vbosonyrosxfttyoengz.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZib3Nvbnlyb3N4ZnR0eW9lbmd6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzczNTU3MDQsImV4cCI6MjA5MjkzMTcwNH0.OyJKw9QvXyp3DcnR_lYkc0ID9O64bnvk521hRtW1DcE',
  );

  final client = Supabase.instance.client;
  print('Supabase connected!');

  final commonTables = [
    'leads',
    'clients',
    'projects',
    'tasks',
    'invoices',
    'profiles',
    'crm_leads',
    'active_clients',
    'team_members',
    'billing',
  ];

  for (final table in commonTables) {
    try {
      final response = await client.from(table).select().limit(1);
      print('Table "$table" exists! Sample data: $response');
    } catch (e) {
      print('Table "$table" failed or does not exist: $e');
    }
  }
}

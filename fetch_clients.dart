import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://vbosonyrosxfttyoengz.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZib3Nvbnlyb3N4ZnR0eW9lbmd6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzczNTU3MDQsImV4cCI6MjA5MjkzMTcwNH0.OyJKw9QvXyp3DcnR_lYkc0ID9O64bnvk521hRtW1DcE'
  );
  try {
    final clients = await client.from('clients').select().limit(5);
    print('CLIENTS: $clients');
  } catch (e) {
    print('ERROR: $e');
  }
}

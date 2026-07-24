import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://bnjvugxvcoqgfvvvwpzc.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJuanZ1Z3h2Y29xZ2Z2dnZ3cHpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMzMTA4NTMsImV4cCI6MjA5ODg4Njg1M30.Fe5COvy60ezaVwrrDOR_Ec-1wDRizd6FiPp9vtHy2O4'
  );
  try {
    final clients = await client.from('clients').select().limit(5);
    print('CLIENTS: $clients');
  } catch (e) {
    print('ERROR: $e');
  }
}

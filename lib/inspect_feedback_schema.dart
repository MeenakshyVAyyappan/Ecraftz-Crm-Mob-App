import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  final client = SupabaseClient(
    'https://bnjvugxvcoqgfvvvwpzc.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJuanZ1Z3h2Y29xZ2Z2dnZ3cHpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMzMTA4NTMsImV4cCI6MjA5ODg4Njg1M30.Fe5COvy60ezaVwrrDOR_Ec-1wDRizd6FiPp9vtHy2O4',
  );

  print('=== CHECKING CLIENT FEEDBACK TABLES & DATA ===');

  try {
    final fbList = await client.from('client_feedback').select('*, clients(name), projects(name)').limit(5);
    print('client_feedback sample count: ${fbList.length}');
    if (fbList.isNotEmpty) {
      print('client_feedback sample record: ${fbList.first}');
    }
  } catch (e) {
    print('client_feedback error: $e');
  }

  try {
    final cats = await client.from('feedback_categories').select();
    print('feedback_categories count: ${cats.length}');
    print('feedback_categories records: $cats');
  } catch (e) {
    print('feedback_categories error: $e');
  }

  try {
    final buckets = await client.storage.listBuckets();
    print('Storage buckets: ${buckets.map((b) => b.name).toList()}');
  } catch (e) {
    print('Storage buckets error: $e');
  }
}

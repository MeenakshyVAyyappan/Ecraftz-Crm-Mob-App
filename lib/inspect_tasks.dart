import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('inspect tasks', () async {
    const MethodChannel('plugins.flutter.io/shared_preferences')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'getAll') {
        return <String, Object>{};
      }
      return null;
    });

    await Supabase.initialize(
      url: 'https://bnjvugxvcoqgfvvvwpzc.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJuanZ1Z3h2Y29xZ2Z2dnZ3cHpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMzMTA4NTMsImV4cCI6MjA5ODg4Njg1M30.Fe5COvy60ezaVwrrDOR_Ec-1wDRizd6FiPp9vtHy2O4',
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
      ),
    );

    final client = Supabase.instance.client;
    try {
      final res1 = await client.from('tasks').select().limit(1);
      print('Tasks table raw: $res1');
    } catch (e) {
      print('Failed res1: $e');
    }
    
    try {
      final res2 = await client
            .from('tasks')
            .select('*, projects(name, client_id, clients(name))')
            .limit(1);
      print('Tasks table with joins: $res2');
    } catch (e) {
      print('Failed res2: $e');
    }
  });
}

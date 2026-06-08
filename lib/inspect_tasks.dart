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
      url: 'https://vbosonyrosxfttyoengz.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZib3Nvbnlyb3N4ZnR0eW9lbmd6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzczNTU3MDQsImV4cCI6MjA5MjkzMTcwNH0.OyJKw9QvXyp3DcnR_lYkc0ID9O64bnvk521hRtW1DcE',
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

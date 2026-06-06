import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('inspect database tables', () async {
    // Mock shared_preferences channel calls
    const MethodChannel('plugins.flutter.io/shared_preferences')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'getAll') {
        return <String, Object>{};
      }
      return null;
    });

    print('Connecting to Supabase...');
    await Supabase.initialize(
      url: 'https://vbosonyrosxfttyoengz.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZib3Nvbnlyb3N4ZnR0eW9lbmd6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzczNTU3MDQsImV4cCI6MjA5MjkzMTcwNH0.OyJKw9QvXyp3DcnR_lYkc0ID9O64bnvk521hRtW1DcE',
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
      ),
    );

    final client = Supabase.instance.client;
    print('Supabase connected!');

    try {
      final payrollRes = await client.from('payroll').select().limit(5);
      print('Payroll rows: $payrollRes');
    } catch (e) {
      print('Error querying payroll: $e');
    }

    try {
      final dmRes = await client.from('department_members').select().limit(5);
      print('Department members: $dmRes');
    } catch (e) {
      print('Error querying department_members: $e');
    }

    try {
      final profileRes = await client.from('profiles').select().limit(5);
      print('Profiles: $profileRes');
    } catch (e) {
      print('Error querying profiles: $e');
    }
  });
}

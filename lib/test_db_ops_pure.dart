import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  print('Connecting to Supabase...');
  
  // We can initialize Supabase in pure Dart without localStorage (uses Hive/etc. which might fail in pure dart, so we can use a custom storage if needed, or pass empty storage)
  await Supabase.initialize(
    url: 'https://vbosonyrosxfttyoengz.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZib3Nvbnlyb3N4ZnR0eW9lbmd6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzczNTU3MDQsImV4cCI6MjA5MjkzMTcwNH0.OyJKw9QvXyp3DcnR_lYkc0ID9O64bnvk521hRtW1DcE',
    authOptions: const FlutterAuthClientOptions(
      localStorage: EmptyLocalStorage(),
    ),
  );

  final client = Supabase.instance.client;
  print('Supabase connected!');

  final testEmail = 'tester_${DateTime.now().millisecondsSinceEpoch}@ecraftz.com';
  final testPassword = 'Password123!';
  
  print('Signing up user: $testEmail');
  try {
    final authRes = await client.auth.signUp(
      email: testEmail,
      password: testPassword,
      data: {
        'name': 'Test User',
        'full_name': 'Test User',
        'role': 'super admin',
        'organization_id': '00000000-0000-0000-0000-000000000000',
      },
    );
    print('Signed up: ${authRes.user?.id}');

    // Select profiles
    final profiles = await client.from('profiles').select();
    print('Profiles count: ${profiles.length}');
    if (profiles.isNotEmpty) {
      print('First profile: ${profiles.first}');
    }

    // Check payroll
    final payrolls = await client.from('payroll').select();
    print('Payrolls count: ${payrolls.length}');
    if (payrolls.isNotEmpty) {
      final p = payrolls.first;
      print('First payroll: $p');

      // Let's test update payroll without organization_id
      try {
        print('Testing update payroll without organization_id...');
        await client.from('payroll').update({
          'net_pay': 50000,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', p['id']);
        print('Payroll update success!');
      } catch (e) {
        print('Payroll update without organization_id error: $e');
      }

      // Let's test update payroll WITH organization_id
      try {
        print('Testing update payroll WITH organization_id...');
        await client.from('payroll').update({
          'net_pay': 50000,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
          'organization_id': '00000000-0000-0000-0000-000000000000',
        }).eq('id', p['id']);
        print('Payroll update WITH organization_id success!');
      } catch (e) {
        print('Payroll update WITH organization_id error: $e');
      }
    }

  } catch (e, st) {
    print('Test failed: $e');
    print(st);
  }
}

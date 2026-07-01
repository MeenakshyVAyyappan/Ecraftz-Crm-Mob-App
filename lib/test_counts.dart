import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  test('Count profiles', () async {
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
    final allProfiles = await client.from('profiles').select();
    print('ALL PROFILES COUNT: ${allProfiles.length}');
    final filteredProfiles = await client.from('profiles').select().eq('organization_id', '00000000-0000-0000-0000-000000000000');
    print('FILTERED PROFILES COUNT: ${filteredProfiles.length}');
    
    final admins = filteredProfiles.where((p) => p['role']?.toString().toLowerCase() == 'admin' || p['role']?.toString().toLowerCase() == 'super admin').length;
    final operators = filteredProfiles.where((p) => p['role']?.toString().toLowerCase() != 'admin' && p['role']?.toString().toLowerCase() != 'super admin').length;
    print('FILTERED ADMINS: $admins');
    print('FILTERED OPERATORS: $operators');
  });
}

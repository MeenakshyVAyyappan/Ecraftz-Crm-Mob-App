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
      url: 'https://bnjvugxvcoqgfvvvwpzc.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJuanZ1Z3h2Y29xZ2Z2dnZ3cHpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMzMTA4NTMsImV4cCI6MjA5ODg4Njg1M30.Fe5COvy60ezaVwrrDOR_Ec-1wDRizd6FiPp9vtHy2O4',
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

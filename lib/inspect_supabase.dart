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
      url: 'https://bnjvugxvcoqgfvvvwpzc.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJuanZ1Z3h2Y29xZ2Z2dnZ3cHpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMzMTA4NTMsImV4cCI6MjA5ODg4Njg1M30.Fe5COvy60ezaVwrrDOR_Ec-1wDRizd6FiPp9vtHy2O4',
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
      ),
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
      'onboarding_templates',
      'onboarding_submissions',
      'requirements_submissions',
      'intakes',
      'form_templates',
      'form_sections',
      'form_fields',
      'form_submissions',
      'form_submission_answers',
    ];

    for (final table in commonTables) {
      try {
        final response = await client.from(table).select().limit(1);
        print('Table "$table" exists! Sample data: $response');
      } catch (e) {
        if (e is PostgrestException) {
          print('Table "$table" failed: Code ${e.code}, Message: ${e.message}, Hint: ${e.hint}, Details: ${e.details}');
        } else {
          print('Table "$table" failed: $e');
        }
      }
    }
  });
}

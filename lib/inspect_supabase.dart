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

import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmptyLocalStorage extends LocalStorage {
  const EmptyLocalStorage();
  @override
  Future<void> initialize() async {}
  @override
  Future<String?> accessToken() async => null;
  @override
  Future<bool> hasAccessToken() async => false;
  @override
  Future<void> persistSession(String session) async {}
  @override
  Future<void> removeSession() async {}
  @override
  Future<void> removePersistedSession() async {}
}

void main() async {
  SharedPreferences.setMockInitialValues({});
  
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

  final testEmail = 'tester_openapi_${DateTime.now().millisecondsSinceEpoch}@ecraftz.com';
  final testPassword = 'Password123!';
  
  print('Signing up user: $testEmail');
  try {
    final authRes = await client.auth.signUp(
      email: testEmail,
      password: testPassword,
      data: {
        'name': 'Test Admin',
        'full_name': 'Test Admin',
        'role': 'super admin',
        'organization_id': '00000000-0000-0000-0000-000000000000',
      },
    );
    final token = authRes.session?.accessToken;
    if (token == null) {
      print('Failed to get access token');
      return;
    }
    print('Access token obtained!');

    // Fetch OpenAPI spec
    final hc = HttpClient();
    final url = Uri.parse('https://bnjvugxvcoqgfvvvwpzc.supabase.co/rest/v1/');
    final request = await hc.getUrl(url);
    request.headers.set('apikey', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJuanZ1Z3h2Y29xZ2Z2dnZ3cHpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMzMTA4NTMsImV4cCI6MjA5ODg4Njg1M30.Fe5COvy60ezaVwrrDOR_Ec-1wDRizd6FiPp9vtHy2O4');
    request.headers.set('Authorization', 'Bearer $token');
    
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    
    print('OpenAPI fetch status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final json = jsonDecode(body);
      final definitions = json['definitions'] as Map<String, dynamic>;
      if (definitions.containsKey('daily_tasks')) {
        print('\n📋 Columns of daily_tasks:');
        final properties = definitions['daily_tasks']['properties'] as Map<String, dynamic>;
        for (final entry in properties.entries) {
          print('  - ${entry.key}: ${entry.value}');
        }
      } else {
        print('daily_tasks definition not found in schema');
      }
    } else {
      print('Error response: $body');
    }
    hc.close();

  } catch (e, st) {
    print('Failed: $e');
    print(st);
  }
}

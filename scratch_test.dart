import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  final apiKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJuanZ1Z3h2Y29xZ2Z2dnZ3cHpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMzMTA4NTMsImV4cCI6MjA5ODg4Njg1M30.Fe5COvy60ezaVwrrDOR_Ec-1wDRizd6FiPp9vtHy2O4';

  // 1. Sign up a temporary user to get a JWT
  final email = 'temp_reporter_${DateTime.now().millisecondsSinceEpoch}@ecraftz.com';
  final password = 'Password123!';

  final signupUrl = Uri.parse('https://bnjvugxvcoqgfvvvwpzc.supabase.co/auth/v1/signup');
  final req = await client.postUrl(signupUrl);
  req.headers.set('apikey', apiKey);
  req.headers.set('Content-Type', 'application/json');
  req.add(utf8.encode(jsonEncode({
    'email': email,
    'password': password,
    'data': {
      'name': 'Temp Reporter',
      'full_name': 'Temp Reporter',
      'role': 'employee',
      'organization_id': '00000000-0000-0000-0000-000000000000',
    }
  })));

  final res = await req.close();
  final body = await res.transform(utf8.decoder).join();
  final resJson = jsonDecode(body);
  if (resJson['access_token'] == null) {
    print('Failed to sign up: $body');
    client.close();
    return;
  }
  final jwt = resJson['access_token'] as String;

  try {
    final req = await client.getUrl(Uri.parse('https://bnjvugxvcoqgfvvvwpzc.supabase.co/rest/v1/profiles?organization_id=eq.00000000-0000-0000-0000-000000000000&select=*'));
    req.headers.set('apikey', apiKey);
    req.headers.set('Authorization', 'Bearer $jwt');
    final res = await req.close();
    final responseBody = await res.transform(utf8.decoder).join();
    final list = jsonDecode(responseBody) as List;
    print('PROFILE DETAILED BREAKDOWN (total: ${list.length}):');
    for (final p in list) {
      if (p['email'] == email) continue; // skip temp user
      print('- Name: ${p['full_name'] ?? p['username'] ?? 'No Name'}, Email: ${p['email']}, Role: ${p['role']}, Status: ${p['status']}');
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}

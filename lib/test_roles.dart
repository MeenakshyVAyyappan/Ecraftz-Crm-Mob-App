import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  final apiKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJuanZ1Z3h2Y29xZ2Z2dnZ3cHpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMzMTA4NTMsImV4cCI6MjA5ODg4Njg1M30.Fe5COvy60ezaVwrrDOR_Ec-1wDRizd6FiPp9vtHy2O4';

  // Sign up a user
  final email = 'tester_roles_${DateTime.now().millisecondsSinceEpoch}@ecraftz.com';
  final password = 'Password123!';

  final signupUrl = Uri.parse('https://bnjvugxvcoqgfvvvwpzc.supabase.co/auth/v1/signup');
  final signupReq = await client.postUrl(signupUrl);
  signupReq.headers.set('apikey', apiKey);
  signupReq.headers.set('Content-Type', 'application/json');
  signupReq.add(utf8.encode(jsonEncode({
    'email': email,
    'password': password,
    'data': {
      'name': 'Roles Test',
      'full_name': 'Roles Test',
      'role': 'employee',
      'organization_id': '00000000-0000-0000-0000-000000000000',
    }
  })));

  final signupRes = await signupReq.close();
  final signupBody = await signupRes.transform(utf8.decoder).join();
  final signupJson = jsonDecode(signupBody);
  final accessToken = signupJson['access_token'] as String;
  final userId = signupJson['user']['id'] as String;

  // Let's test inserting a profile with an invalid role to get the postgres error listing all valid values
  final insertUrl = Uri.parse('https://bnjvugxvcoqgfvvvwpzc.supabase.co/rest/v1/profiles');
  final req = await client.postUrl(insertUrl);
  req.headers.set('apikey', apiKey);
  req.headers.set('Authorization', 'Bearer $accessToken');
  req.headers.set('Content-Type', 'application/json');
  req.add(utf8.encode(jsonEncode({
    'id': '00000000-0000-0000-0000-000000000000', // Dummy uuid format
    'full_name': 'Test Role',
    'email': 'test_role_invalid@ecraftz.com',
    'role': 'invalid_role_name',
    'organization_id': '00000000-0000-0000-0000-000000000000'
  })));

  final res = await req.close();
  final body = await res.transform(utf8.decoder).join();
  print('Insert status: ${res.statusCode}');
  print('Insert body: $body');

  client.close();
}

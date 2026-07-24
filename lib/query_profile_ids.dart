import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  final apiKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJuanZ1Z3h2Y29xZ2Z2dnZ3cHpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMzMTA4NTMsImV4cCI6MjA5ODg4Njg1M30.Fe5COvy60ezaVwrrDOR_Ec-1wDRizd6FiPp9vtHy2O4';

  final email = 'tester_ids_${DateTime.now().millisecondsSinceEpoch}@ecraftz.com';
  final password = 'Password123!';

  final signupUrl = Uri.parse('https://bnjvugxvcoqgfvvvwpzc.supabase.co/auth/v1/signup');
  final request = await client.postUrl(signupUrl);
  request.headers.set('apikey', apiKey);
  request.headers.set('Content-Type', 'application/json');
  request.add(utf8.encode(jsonEncode({
    'email': email,
    'password': password,
    'data': {
      'name': 'Test REST',
      'full_name': 'Test REST',
      'role': 'super admin',
      'organization_id': '00000000-0000-0000-0000-000000000000'
    }
  })));

  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  final resJson = jsonDecode(body);
  final accessToken = resJson['access_token'] as String;

  final url = Uri.parse('https://bnjvugxvcoqgfvvvwpzc.supabase.co/rest/v1/profiles?select=*');
  final getReq = await client.getUrl(url);
  getReq.headers.set('apikey', apiKey);
  getReq.headers.set('Authorization', 'Bearer $accessToken');

  final getRes = await getReq.close();
  final getBody = await getRes.transform(utf8.decoder).join();
  final profiles = jsonDecode(getBody) as List;

  print('PROFILES WITH IDS:');
  for (final p in profiles) {
    print('- Email: ${p['email']}, ID: ${p['id']}, Role: ${p['role']}');
  }

  client.close();
}

import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  final apiKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJuanZ1Z3h2Y29xZ2Z2dnZ3cHpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMzMTA4NTMsImV4cCI6MjA5ODg4Njg1M30.Fe5COvy60ezaVwrrDOR_Ec-1wDRizd6FiPp9vtHy2O4';

  // Sign up a user
  final email = 'tester_change_sa_${DateTime.now().millisecondsSinceEpoch}@ecraftz.com';
  final password = 'Password123!';

  final signupUrl = Uri.parse('https://bnjvugxvcoqgfvvvwpzc.supabase.co/auth/v1/signup');
  final request = await client.postUrl(signupUrl);
  request.headers.set('apikey', apiKey);
  request.headers.set('Content-Type', 'application/json');
  request.add(utf8.encode(jsonEncode({
    'email': email,
    'password': password,
    'data': {
      'name': 'SA Changer',
      'full_name': 'SA Changer',
      'role': 'employee',
      'organization_id': '00000000-0000-0000-0000-000000000000',
    }
  })));

  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  final resJson = jsonDecode(body);
  final accessToken = resJson['access_token'] as String;
  final userId = resJson['user']['id'] as String;

  // Update role to admin
  final updateProfUrl = Uri.parse('https://bnjvugxvcoqgfvvvwpzc.supabase.co/rest/v1/profiles?id=eq.$userId');
  final updateProfReq = await client.patchUrl(updateProfUrl);
  updateProfReq.headers.set('apikey', apiKey);
  updateProfReq.headers.set('Authorization', 'Bearer $accessToken');
  updateProfReq.headers.set('Content-Type', 'application/json');
  updateProfReq.add(utf8.encode(jsonEncode({
    'role': 'admin',
    'organization_id': '00000000-0000-0000-0000-000000000000'
  })));
  await updateProfReq.close();

  // Now, try to update viswajithjithu333@gmail.com (ID: f417dc7e-a4c3-4964-9e62-553ffffcef8c) role to 'admin'
  final targetUserId = 'f417dc7e-a4c3-4964-9e62-553ffffcef8c';
  print('Updating role of Super Admin to admin in database...');
  final targetProfUrl = Uri.parse('https://bnjvugxvcoqgfvvvwpzc.supabase.co/rest/v1/profiles?id=eq.$targetUserId');
  final targetProfReq = await client.patchUrl(targetProfUrl);
  targetProfReq.headers.set('apikey', apiKey);
  targetProfReq.headers.set('Authorization', 'Bearer $accessToken');
  targetProfReq.headers.set('Content-Type', 'application/json');
  targetProfReq.add(utf8.encode(jsonEncode({
    'role': 'admin'
  })));

  final targetProfRes = await targetProfReq.close();
  final targetProfBody = await targetProfRes.transform(utf8.decoder).join();
  print('Update Super Admin status: ${targetProfRes.statusCode}, body: $targetProfBody');

  client.close();
}

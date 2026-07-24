import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  final apiKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJuanZ1Z3h2Y29xZ2Z2dnZ3cHpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMzMTA4NTMsImV4cCI6MjA5ODg4Njg1M30.Fe5COvy60ezaVwrrDOR_Ec-1wDRizd6FiPp9vtHy2O4';

  // Sign up a user
  final email = 'tester_logs_${DateTime.now().millisecondsSinceEpoch}@ecraftz.com';
  final password = 'Password123!';

  final signupUrl = Uri.parse('https://bnjvugxvcoqgfvvvwpzc.supabase.co/auth/v1/signup');
  final signupReq = await client.postUrl(signupUrl);
  signupReq.headers.set('apikey', apiKey);
  signupReq.headers.set('Content-Type', 'application/json');
  signupReq.add(utf8.encode(jsonEncode({
    'email': email,
    'password': password,
    'data': {
      'name': 'Logs Test',
      'full_name': 'Logs Test',
      'role': 'employee',
      'organization_id': '00000000-0000-0000-0000-000000000000'
    }
  })));

  final signupRes = await signupReq.close();
  final signupBody = await signupRes.transform(utf8.decoder).join();
  final signupJson = jsonDecode(signupBody);
  final accessToken = signupJson['access_token'] as String;
  final userId = signupJson['user']['id'] as String;

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

  final logTables = ['audit_log', 'audit_logs', 'logs', 'audits', 'activity_logs', 'activity_log'];
  final targetId = '38053b40-0cec-4af2-9dfa-330743a9f95d';

  for (final table in logTables) {
    final url = Uri.parse('https://bnjvugxvcoqgfvvvwpzc.supabase.co/rest/v1/$table?id=eq.$targetId');
    final request = await client.getUrl(url);
    request.headers.set('apikey', apiKey);
    request.headers.set('Authorization', 'Bearer $accessToken');

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    print('Table $table status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final list = jsonDecode(body) as List;
      if (list.isNotEmpty) {
        print('FOUND in table "$table": ${list.first}');
      }
    }
  }

  client.close();
}

import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  final apiKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJuanZ1Z3h2Y29xZ2Z2dnZ3cHpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMzMTA4NTMsImV4cCI6MjA5ODg4Njg1M30.Fe5COvy60ezaVwrrDOR_Ec-1wDRizd6FiPp9vtHy2O4';

  // Sign up a user
  final email = 'tester_real_${DateTime.now().millisecondsSinceEpoch}@ecraftz.com';
  final password = 'Password123!';

  final signupUrl = Uri.parse('https://bnjvugxvcoqgfvvvwpzc.supabase.co/auth/v1/signup');
  final request = await client.postUrl(signupUrl);
  request.headers.set('apikey', apiKey);
  request.headers.set('Content-Type', 'application/json');
  request.add(utf8.encode(jsonEncode({
    'email': email,
    'password': password,
    'data': {
      'name': 'Real Test User',
      'full_name': 'Real Test User',
      'role': 'employee',
      'organization_id': '00000000-0000-0000-0000-000000000000'
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

  // Try to query existing payroll records for Hiba (ID: d511ce23-d82b-4a27-9f2d-fe7601c52bea)
  final hibaId = 'd511ce23-d82b-4a27-9f2d-fe7601c52bea';
  print('Querying payroll for Hiba...');
  final queryUrl = Uri.parse('https://bnjvugxvcoqgfvvvwpzc.supabase.co/rest/v1/payroll?user_id=eq.$hibaId');
  final queryReq = await client.getUrl(queryUrl);
  queryReq.headers.set('apikey', apiKey);
  queryReq.headers.set('Authorization', 'Bearer $accessToken');
  final queryRes = await queryReq.close();
  final queryBody = await queryRes.transform(utf8.decoder).join();
  print('Query status: ${queryRes.statusCode}, body: $queryBody');

  // Try inserting payroll record for Hiba
  print('\nInserting payroll record for Hiba...');
  final payUrl = Uri.parse('https://bnjvugxvcoqgfvvvwpzc.supabase.co/rest/v1/payroll');
  final payReq = await client.postUrl(payUrl);
  payReq.headers.set('apikey', apiKey);
  payReq.headers.set('Authorization', 'Bearer $accessToken');
  payReq.headers.set('Content-Type', 'application/json');
  payReq.add(utf8.encode(jsonEncode({
    'user_id': hibaId,
    'net_pay': 75000,
    'allowances': 0,
    'deductions': 0,
    'status': 'draft',
    'month': 'June',
    'year': 2026,
    'organization_id': '00000000-0000-0000-0000-000000000000'
  })));
  final payRes = await payReq.close();
  final payBody = await payRes.transform(utf8.decoder).join();
  print('Insert status: ${payRes.statusCode}, body: $payBody');

  client.close();
}

import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  final apiKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJuanZ1Z3h2Y29xZ2Z2dnZ3cHpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMzMTA4NTMsImV4cCI6MjA5ODg4Njg1M30.Fe5COvy60ezaVwrrDOR_Ec-1wDRizd6FiPp9vtHy2O4';

  // Sign up a user
  final email = 'tester_find_admin_${DateTime.now().millisecondsSinceEpoch}@ecraftz.com';
  final password = 'Password123!';

  final signupUrl = Uri.parse('https://bnjvugxvcoqgfvvvwpzc.supabase.co/auth/v1/signup');
  final signupReq = await client.postUrl(signupUrl);
  signupReq.headers.set('apikey', apiKey);
  signupReq.headers.set('Content-Type', 'application/json');
  signupReq.add(utf8.encode(jsonEncode({
    'email': email,
    'password': password,
    'data': {
      'name': 'Find Admin Test',
      'full_name': 'Find Admin Test',
      'role': 'employee',
      'organization_id': '00000000-0000-0000-0000-000000000000'
    }
  })));

  final signupRes = await signupReq.close();
  final signupBody = await signupRes.transform(utf8.decoder).join();
  final signupJson = jsonDecode(signupBody);
  final accessToken = signupJson['access_token'] as String;
  final userId = signupJson['user']['id'] as String;

  print('Signed up user: $userId');

  // Update role to admin
  print('Updating role to admin...');
  final updateProfUrl = Uri.parse('https://bnjvugxvcoqgfvvvwpzc.supabase.co/rest/v1/profiles?id=eq.$userId');
  final updateProfReq = await client.patchUrl(updateProfUrl);
  updateProfReq.headers.set('apikey', apiKey);
  updateProfReq.headers.set('Authorization', 'Bearer $accessToken');
  updateProfReq.headers.set('Content-Type', 'application/json');
  updateProfReq.add(utf8.encode(jsonEncode({
    'role': 'admin',
    'organization_id': '00000000-0000-0000-0000-000000000000'
  })));
  final updateProfRes = await updateProfReq.close();
  print('Update profile status: ${updateProfRes.statusCode}');

  final tables = [
    'profiles',
    'department_members',
    'payroll',
    'departments',
    'leave_requests',
    'leave_request_actions',
    'leave_types',
    'client_statements',
    'clients',
    'projects',
    'tasks',
    'invoices',
    'crm_leads',
    'active_clients',
    'team_members',
    'billing'
  ];

  final targetId = '38053b40-0cec-4af2-9dfa-330743a9f95d';
  print('\nSearching for ID: $targetId across tables as ADMIN...');

  for (final table in tables) {
    final url = Uri.parse('https://bnjvugxvcoqgfvvvwpzc.supabase.co/rest/v1/$table?id=eq.$targetId');
    final request = await client.getUrl(url);
    request.headers.set('apikey', apiKey);
    request.headers.set('Authorization', 'Bearer $accessToken');

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode == 200) {
      final list = jsonDecode(body) as List;
      if (list.isNotEmpty) {
        print('FOUND in table "$table": ${list.first}');
      }
    }

    // Also search by other possible columns if it's referenced
    final url2 = Uri.parse('https://bnjvugxvcoqgfvvvwpzc.supabase.co/rest/v1/$table?select=*');
    final request2 = await client.getUrl(url2);
    request2.headers.set('apikey', apiKey);
    request2.headers.set('Authorization', 'Bearer $accessToken');
    final response2 = await request2.close();
    final body2 = await response2.transform(utf8.decoder).join();
    if (response2.statusCode == 200) {
      final list2 = jsonDecode(body2) as List;
      for (final row in list2) {
        if (row.toString().contains(targetId)) {
          print('FOUND in row content of table "$table": $row');
        }
      }
    }
  }

  client.close();
}

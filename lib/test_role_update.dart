import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  final apiKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZib3Nvbnlyb3N4ZnR0eW9lbmd6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzczNTU3MDQsImV4cCI6MjA5MjkzMTcwNH0.OyJKw9QvXyp3DcnR_lYkc0ID9O64bnvk521hRtW1DcE';

  // Sign up a user
  final email = 'tester_admin_${DateTime.now().millisecondsSinceEpoch}@ecraftz.com';
  final password = 'Password123!';

  final signupUrl = Uri.parse('https://vbosonyrosxfttyoengz.supabase.co/auth/v1/signup');
  final request = await client.postUrl(signupUrl);
  request.headers.set('apikey', apiKey);
  request.headers.set('Content-Type', 'application/json');
  request.add(utf8.encode(jsonEncode({
    'email': email,
    'password': password,
    'data': {
      'name': 'Test Role User',
      'full_name': 'Test Role User',
      'role': 'employee',
      'organization_id': '00000000-0000-0000-0000-000000000000'
    }
  })));

  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  final resJson = jsonDecode(body);
  final accessToken = resJson['access_token'] as String;
  final userId = resJson['user']['id'] as String;

  print('Signed up user: $userId');

  // Let's try to update role to 'admin'
  print('\nUpdating tester profile role to admin...');
  final updateProfUrl = Uri.parse('https://vbosonyrosxfttyoengz.supabase.co/rest/v1/profiles?id=eq.$userId');
  final updateProfReq = await client.patchUrl(updateProfUrl);
  updateProfReq.headers.set('apikey', apiKey);
  updateProfReq.headers.set('Authorization', 'Bearer $accessToken');
  updateProfReq.headers.set('Content-Type', 'application/json');
  updateProfReq.add(utf8.encode(jsonEncode({
    'role': 'admin',
    'organization_id': '00000000-0000-0000-0000-000000000000'
  })));
  final updateProfRes = await updateProfReq.close();
  final updateProfBody = await updateProfRes.transform(utf8.decoder).join();
  print('Update profile status: ${updateProfRes.statusCode}, body: $updateProfBody');

  // Let's create another user to be the employee
  final empEmail = 'emp_admin_${DateTime.now().millisecondsSinceEpoch}@ecraftz.com';
  final empReq = await client.postUrl(signupUrl);
  empReq.headers.set('apikey', apiKey);
  empReq.headers.set('Content-Type', 'application/json');
  empReq.add(utf8.encode(jsonEncode({
    'email': empEmail,
    'password': password,
    'data': {
      'name': 'Employee User',
      'full_name': 'Employee User',
      'role': 'employee',
      'organization_id': '00000000-0000-0000-0000-000000000000'
    }
  })));
  final empRes = await empReq.close();
  final empBody = await empRes.transform(utf8.decoder).join();
  final empJson = jsonDecode(empBody);
  final empUserId = empJson['user']['id'] as String;
  print('Created employee user: $empUserId');

  // Now, try inserting a payroll record for the employee user using the tester's accessToken (which is now role: admin)
  print('\nInserting payroll record for employee as admin...');
  final payUrl = Uri.parse('https://vbosonyrosxfttyoengz.supabase.co/rest/v1/payroll');
  final payReq = await client.postUrl(payUrl);
  payReq.headers.set('apikey', apiKey);
  payReq.headers.set('Authorization', 'Bearer $accessToken');
  payReq.headers.set('Content-Type', 'application/json');
  payReq.headers.set('Prefer', 'return=representation');
  payReq.add(utf8.encode(jsonEncode({
    'user_id': empUserId,
    'net_pay': 60000,
    'allowances': 0,
    'deductions': 0,
    'status': 'draft',
    'month': 'June',
    'year': 2026,
    'organization_id': '00000000-0000-0000-0000-000000000000'
  })));
  final payRes = await payReq.close();
  final payBody = await payRes.transform(utf8.decoder).join();
  print('Insert payroll status: ${payRes.statusCode}, body: $payBody');

  client.close();
}

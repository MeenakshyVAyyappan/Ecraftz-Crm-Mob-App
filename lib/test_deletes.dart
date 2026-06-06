import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  final apiKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZib3Nvbnlyb3N4ZnR0eW9lbmd6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzczNTU3MDQsImV4cCI6MjA5MjkzMTcwNH0.OyJKw9QvXyp3DcnR_lYkc0ID9O64bnvk521hRtW1DcE';

  // Sign up a user
  final email = 'tester_del_${DateTime.now().millisecondsSinceEpoch}@ecraftz.com';
  final password = 'Password123!';

  final signupUrl = Uri.parse('https://vbosonyrosxfttyoengz.supabase.co/auth/v1/signup');
  final request = await client.postUrl(signupUrl);
  request.headers.set('apikey', apiKey);
  request.headers.set('Content-Type', 'application/json');
  request.add(utf8.encode(jsonEncode({
    'email': email,
    'password': password,
    'data': {
      'name': 'Test Delete',
      'full_name': 'Test Delete',
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

  // Let's check if there is an organization_id issue
  // Wait, let's update tester profile to set organization_id to '00000000-0000-0000-0000-000000000000'
  print('\nUpdating tester profile organization_id...');
  final updateProfUrl = Uri.parse('https://vbosonyrosxfttyoengz.supabase.co/rest/v1/profiles?id=eq.$userId');
  final updateProfReq = await client.patchUrl(updateProfUrl);
  updateProfReq.headers.set('apikey', apiKey);
  updateProfReq.headers.set('Authorization', 'Bearer $accessToken');
  updateProfReq.headers.set('Content-Type', 'application/json');
  updateProfReq.add(utf8.encode(jsonEncode({
    'organization_id': '00000000-0000-0000-0000-000000000000'
  })));
  final updateProfRes = await updateProfReq.close();
  final updateProfBody = await updateProfRes.transform(utf8.decoder).join();
  print('Update profile status: ${updateProfRes.statusCode}, body: $updateProfBody');

  // Try creating a department member record
  // But wait, what departments exist?
  // Let's fetch departments first
  print('\nFetching departments...');
  final deptUrl = Uri.parse('https://vbosonyrosxfttyoengz.supabase.co/rest/v1/departments?select=*');
  final deptReq = await client.getUrl(deptUrl);
  deptReq.headers.set('apikey', apiKey);
  deptReq.headers.set('Authorization', 'Bearer $accessToken');
  final deptRes = await deptReq.close();
  final deptBody = await deptRes.transform(utf8.decoder).join();
  final depts = jsonDecode(deptBody) as List;
  print('Departments: $depts');

  String? deptId;
  if (depts.isNotEmpty) {
    deptId = depts.first['id'] as String;
  }

  String? dmId;
  if (deptId != null) {
    print('\nCreating department member for user...');
    final dmUrl = Uri.parse('https://vbosonyrosxfttyoengz.supabase.co/rest/v1/department_members');
    final dmReq = await client.postUrl(dmUrl);
    dmReq.headers.set('apikey', apiKey);
    dmReq.headers.set('Authorization', 'Bearer $accessToken');
    dmReq.headers.set('Content-Type', 'application/json');
    dmReq.headers.set('Prefer', 'return=representation');
    dmReq.add(utf8.encode(jsonEncode({
      'profile_id': userId,
      'department_id': deptId
    })));
    final dmRes = await dmReq.close();
    final dmBody = await dmRes.transform(utf8.decoder).join();
    print('Create department member status: ${dmRes.statusCode}, body: $dmBody');
    if (dmRes.statusCode == 201) {
      final dmJson = jsonDecode(dmBody);
      dmId = dmJson[0]['id'] as String;
    }
  }

  // Create a payroll record
  print('\nCreating payroll record for user...');
  final payUrl = Uri.parse('https://vbosonyrosxfttyoengz.supabase.co/rest/v1/payroll');
  final payReq = await client.postUrl(payUrl);
  payReq.headers.set('apikey', apiKey);
  payReq.headers.set('Authorization', 'Bearer $accessToken');
  payReq.headers.set('Content-Type', 'application/json');
  payReq.headers.set('Prefer', 'return=representation');
  payReq.add(utf8.encode(jsonEncode({
    'user_id': userId,
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
  print('Create payroll status: ${payRes.statusCode}, body: $payBody');

  // Try updating payroll record
  print('\nUpdating payroll record...');
  final payUpUrl = Uri.parse('https://vbosonyrosxfttyoengz.supabase.co/rest/v1/payroll?user_id=eq.$userId');
  final payUpReq = await client.patchUrl(payUpUrl);
  payUpReq.headers.set('apikey', apiKey);
  payUpReq.headers.set('Authorization', 'Bearer $accessToken');
  payUpReq.headers.set('Content-Type', 'application/json');
  // First try: with organization_id
  payUpReq.add(utf8.encode(jsonEncode({
    'net_pay': 75000,
    'organization_id': '00000000-0000-0000-0000-000000000000'
  })));
  final payUpRes = await payUpReq.close();
  final payUpBody = await payUpRes.transform(utf8.decoder).join();
  print('Update payroll WITH organization_id status: ${payUpRes.statusCode}, body: $payUpBody');

  // Second try: without organization_id
  final payUpReq2 = await client.patchUrl(payUpUrl);
  payUpReq2.headers.set('apikey', apiKey);
  payUpReq2.headers.set('Authorization', 'Bearer $accessToken');
  payUpReq2.headers.set('Content-Type', 'application/json');
  payUpReq2.add(utf8.encode(jsonEncode({
    'net_pay': 80000
  })));
  final payUpRes2 = await payUpReq2.close();
  final payUpBody2 = await payUpRes2.transform(utf8.decoder).join();
  print('Update payroll WITHOUT organization_id status: ${payUpRes2.statusCode}, body: $payUpBody2');


  // Let's delete department_members
  if (dmId != null) {
    print('\nDeleting department member record...');
    final delDmUrl = Uri.parse('https://vbosonyrosxfttyoengz.supabase.co/rest/v1/department_members?id=eq.$dmId');
    final delDmReq = await client.deleteUrl(delDmUrl);
    delDmReq.headers.set('apikey', apiKey);
    delDmReq.headers.set('Authorization', 'Bearer $accessToken');
    final delDmRes = await delDmReq.close();
    final delDmBody = await delDmRes.transform(utf8.decoder).join();
    print('Delete department member status: ${delDmRes.statusCode}, body: $delDmBody');
  }

  // Let's delete payroll
  print('\nDeleting payroll record...');
  final delPayUrl = Uri.parse('https://vbosonyrosxfttyoengz.supabase.co/rest/v1/payroll?user_id=eq.$userId');
  final delPayReq = await client.deleteUrl(delPayUrl);
  delPayReq.headers.set('apikey', apiKey);
  delPayReq.headers.set('Authorization', 'Bearer $accessToken');
  final delPayRes = await delPayReq.close();
  final delPayBody = await delPayRes.transform(utf8.decoder).join();
  print('Delete payroll status: ${delPayRes.statusCode}, body: $delPayBody');

  // Let's delete profiles
  print('\nDeleting profile record...');
  final delProfUrl = Uri.parse('https://vbosonyrosxfttyoengz.supabase.co/rest/v1/profiles?id=eq.$userId');
  final delProfReq = await client.deleteUrl(delProfUrl);
  delProfReq.headers.set('apikey', apiKey);
  delProfReq.headers.set('Authorization', 'Bearer $accessToken');
  final delProfRes = await delProfReq.close();
  final delProfBody = await delProfRes.transform(utf8.decoder).join();
  print('Delete profile status: ${delProfRes.statusCode}, body: $delProfBody');

  client.close();
}

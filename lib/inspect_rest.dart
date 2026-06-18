import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  final signupUrl = Uri.parse('https://vbosonyrosxfttyoengz.supabase.co/auth/v1/signup');
  final apiKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZib3Nvbnlyb3N4ZnR0eW9lbmd6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzczNTU3MDQsImV4cCI6MjA5MjkzMTcwNH0.OyJKw9QvXyp3DcnR_lYkc0ID9O64bnvk521hRtW1DcE';

  final email = 'tester_${DateTime.now().millisecondsSinceEpoch}@ecraftz.com';
  final password = 'Password123!';

  print('Signing up $email...');
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
  print('Signup status: ${response.statusCode}');
  
  final resJson = jsonDecode(body);
  if (response.statusCode != 200 && response.statusCode != 201) {
    print('Signup failed: $resJson');
    client.close();
    return;
  }

  final accessToken = resJson['access_token'] as String?;
  if (accessToken == null) {
    print('Access token is null: $resJson');
    client.close();
    return;
  }
  print('Signup success, token length: ${accessToken.length}');

  // Now, query profiles
  await queryTable(client, 'profiles', accessToken, apiKey);
  await queryTable(client, 'payroll', accessToken, apiKey);
  await queryTable(client, 'department_members', accessToken, apiKey);
  await queryTable(client, 'departments', accessToken, apiKey);
  
  print('\n=== Querying joined profiles with departments ===');
  await queryTable(client, 'profiles?select=*,departments:departments!fk_profiles_dept(id,name)', accessToken, apiKey);

  client.close();
}

Future<void> queryTable(HttpClient client, String table, String token, String apiKey) async {
  print('\n=== Querying table: $table ===');
  final url = Uri.parse('https://vbosonyrosxfttyoengz.supabase.co/rest/v1/$table?select=*');
  final request = await client.getUrl(url);
  request.headers.set('apikey', apiKey);
  request.headers.set('Authorization', 'Bearer $token');

  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  print('Status: ${response.statusCode}');
  try {
    final json = jsonDecode(body);
    if (json is List) {
      print('Row count: ${json.length}');
      if (table == 'departments') {
        for (final row in json) {
          print('  - ${row['name']} (${row['id']})');
        }
      } else if (table.startsWith('profiles')) {
        for (final row in json) {
          final dept = row['departments'];
          final deptName = dept != null ? dept['name'] : 'No Department';
          print('  - ${row['full_name']} (${row['email']}) | Role: ${row['role']} | Status: ${row['status']} | Dept: $deptName');
        }
      } else if (json.isNotEmpty) {
        print('First row: ${json.first}');
      }
    } else {
      print('Response: $json');
    }
  } catch (e) {
    print('Response: $body');
  }
}

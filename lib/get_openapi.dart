import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  final apiKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZib3Nvbnlyb3N4ZnR0eW9lbmd6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzczNTU3MDQsImV4cCI6MjA5MjkzMTcwNH0.OyJKw9QvXyp3DcnR_lYkc0ID9O64bnvk521hRtW1DcE';

  // Sign up a user
  final email = 'tester_openapi_${DateTime.now().millisecondsSinceEpoch}@ecraftz.com';
  final password = 'Password123!';

  final signupUrl = Uri.parse('https://vbosonyrosxfttyoengz.supabase.co/auth/v1/signup');
  final signupReq = await client.postUrl(signupUrl);
  signupReq.headers.set('apikey', apiKey);
  signupReq.headers.set('Content-Type', 'application/json');
  signupReq.add(utf8.encode(jsonEncode({
    'email': email,
    'password': password,
    'data': {
      'name': 'OpenAPI Test',
      'full_name': 'OpenAPI Test',
      'role': 'super admin',
      'organization_id': '00000000-0000-0000-0000-000000000000'
    }
  })));

  final signupRes = await signupReq.close();
  final signupBody = await signupRes.transform(utf8.decoder).join();
  final signupJson = jsonDecode(signupBody);
  final accessToken = signupJson['access_token'] as String;

  final url = Uri.parse('https://vbosonyrosxfttyoengz.supabase.co/rest/v1/');
  final request = await client.getUrl(url);
  request.headers.set('apikey', apiKey);
  request.headers.set('Authorization', 'Bearer $accessToken');

  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  
  try {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final components = json['components'] as Map<String, dynamic>?;
    if (components != null) {
      final schemas = components['schemas'] as Map<String, dynamic>?;
      if (schemas != null && schemas.containsKey('payroll')) {
        print('=== PAYROLL SCHEMA ===');
        print(const JsonEncoder.withIndent('  ').convert(schemas['payroll']));
        client.close();
        return;
      }
    }

    final definitions = json['definitions'] as Map<String, dynamic>?;
    if (definitions != null && definitions.containsKey('payroll')) {
      print('=== PAYROLL DEFINITION ===');
      print(const JsonEncoder.withIndent('  ').convert(definitions['payroll']));
      client.close();
      return;
    }
    print('Not found. Available: ${json.keys.toList()}');
  } catch (e) {
    print('Failed to parse or query: $e');
    print(body);
  }

  client.close();
}

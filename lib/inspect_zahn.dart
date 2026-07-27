import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  final apiKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJuanZ1Z3h2Y29xZ2Z2dnZ3cHpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMzMTA4NTMsImV4cCI6MjA5ODg4Njg1M30.Fe5COvy60ezaVwrrDOR_Ec-1wDRizd6FiPp9vtHy2O4';

  final email =
      'temp_admin_${DateTime.now().millisecondsSinceEpoch}@ecraftz.com';
  final password = 'Password123!';

  final signupUrl =
      Uri.parse('https://bnjvugxvcoqgfvvvwpzc.supabase.co/auth/v1/signup');
  final signupReq = await client.postUrl(signupUrl);
  signupReq.headers.set('apikey', apiKey);
  signupReq.headers.set('Content-Type', 'application/json');
  signupReq.add(utf8.encode(jsonEncode({
    'email': email,
    'password': password,
    'data': {
      'name': 'Temp Admin',
      'full_name': 'Temp Admin',
      'role': 'super admin',
      'organization_id': '00000000-0000-0000-0000-000000000000'
    }
  })));

  final signupRes = await signupReq.close();
  final signupBody = await signupRes.transform(utf8.decoder).join();
  print('Signup Body: $signupBody');
  final signupJson = jsonDecode(signupBody);
  final accessToken = signupJson['access_token'] as String?;

  final headers = {
    'apikey': apiKey,
    'Authorization': 'Bearer $accessToken',
  };

  print('=== 1. FETCHING CLIENTS (ilike *zahn*) ===');
  final clientsUrl = Uri.parse(
      'https://bnjvugxvcoqgfvvvwpzc.supabase.co/rest/v1/clients?name=ilike.*zahn*&select=*');
  final cReq = await client.getUrl(clientsUrl);
  headers.forEach((k, v) => cReq.headers.set(k, v));
  final cRes = await cReq.close();
  final cBody = await cRes.transform(utf8.decoder).join();
  print('Clients JSON: $cBody\n');

  print('=== 2. FETCHING ALL CLIENTS (id, name) ===');
  final allClientsUrl = Uri.parse(
      'https://bnjvugxvcoqgfvvvwpzc.supabase.co/rest/v1/clients?select=id,name');
  final acReq = await client.getUrl(allClientsUrl);
  headers.forEach((k, v) => acReq.headers.set(k, v));
  final acRes = await acReq.close();
  final acBody = await acRes.transform(utf8.decoder).join();
  print('All Clients JSON: $acBody\n');

  print('=== 3. FETCHING INVOICES ===');
  final invUrl = Uri.parse(
      'https://bnjvugxvcoqgfvvvwpzc.supabase.co/rest/v1/invoices?select=*');
  final iReq = await client.getUrl(invUrl);
  headers.forEach((k, v) => iReq.headers.set(k, v));
  final iRes = await iReq.close();
  final iBody = await iRes.transform(utf8.decoder).join();
  print('Invoices JSON: $iBody\n');

  print('=== 4. FETCHING CLIENT_STATEMENTS ===');
  final csUrl = Uri.parse(
      'https://bnjvugxvcoqgfvvvwpzc.supabase.co/rest/v1/client_statements?select=*');
  final csReq = await client.getUrl(csUrl);
  headers.forEach((k, v) => csReq.headers.set(k, v));
  final csRes = await csReq.close();
  final csBody = await csRes.transform(utf8.decoder).join();
  print('Client Statements JSON: $csBody\n');

  exit(0);
}

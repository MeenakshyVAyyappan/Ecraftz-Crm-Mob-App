import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  final apiKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJuanZ1Z3h2Y29xZ2Z2dnZ3cHpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMzMTA4NTMsImV4cCI6MjA5ODg4Njg1M30.Fe5COvy60ezaVwrrDOR_Ec-1wDRizd6FiPp9vtHy2O4';

  final email = 'schema_inspector_${DateTime.now().millisecondsSinceEpoch}@ecraftz.com';
  final password = 'Password123!';

  print('1. Signing up user: $email');
  final signupUrl = Uri.parse('https://bnjvugxvcoqgfvvvwpzc.supabase.co/auth/v1/signup');
  final signupReq = await client.postUrl(signupUrl);
  signupReq.headers.set('apikey', apiKey);
  signupReq.headers.set('Content-Type', 'application/json');
  signupReq.add(utf8.encode(jsonEncode({
    'email': email,
    'password': password,
    'data': {
      'name': 'Schema Inspector',
      'full_name': 'Schema Inspector',
      'role': 'employee',
      'organization_id': '00000000-0000-0000-0000-000000000000'
    }
  })));

  final signupRes = await signupReq.close();
  final signupBody = await signupRes.transform(utf8.decoder).join();
  final signupJson = jsonDecode(signupBody);
  
  if (signupRes.statusCode >= 300) {
    print('Signup failed: ${signupRes.statusCode} - $signupBody');
    client.close();
    return;
  }
  
  final accessToken = signupJson['access_token'] as String;
  final userId = signupJson['user']['id'] as String;
  print('Signed up! userId: $userId');

  print('2. Updating role to admin');
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
  final updateProfBody = await updateProfRes.transform(utf8.decoder).join();
  print('Update role response code: ${updateProfRes.statusCode}');

  // Query a valid client ID
  print('3. Fetching a valid client_id');
  final clientUrl = Uri.parse('https://bnjvugxvcoqgfvvvwpzc.supabase.co/rest/v1/clients?select=id&limit=1');
  final clientReq = await client.getUrl(clientUrl);
  clientReq.headers.set('apikey', apiKey);
  clientReq.headers.set('Authorization', 'Bearer $accessToken');
  final clientRes = await clientReq.close();
  final clientBody = await clientRes.transform(utf8.decoder).join();
  final clients = jsonDecode(clientBody) as List;
  String? firstClientId;
  if (clients.isNotEmpty) {
    firstClientId = clients.first['id'];
    print('Found client_id: $firstClientId');
  }

  // Renewals insert
  if (firstClientId != null) {
    try {
      print('\n--- Querying/Inserting renewals ---');
      final url = Uri.parse('https://bnjvugxvcoqgfvvvwpzc.supabase.co/rest/v1/renewals');
      final request = await client.postUrl(url);
      request.headers.set('apikey', apiKey);
      request.headers.set('Authorization', 'Bearer $accessToken');
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Prefer', 'return=representation');
      request.add(utf8.encode(jsonEncode({
        'client_id': firstClientId,
        'category': 'hosting',
        'expiry_date': '2026-06-06',
        'organization_id': '00000000-0000-0000-0000-000000000000'
      })));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      print('renewals response status: ${response.statusCode}');
      print(body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final list = jsonDecode(body) as List;
        final id = list.first['id'];
        final deleteReq = await client.deleteUrl(Uri.parse('https://bnjvugxvcoqgfvvvwpzc.supabase.co/rest/v1/renewals?id=eq.$id'));
        deleteReq.headers.set('apikey', apiKey);
        deleteReq.headers.set('Authorization', 'Bearer $accessToken');
        await deleteReq.close();
        print('Cleaned up renewals row with id=$id');
      }
    } catch (e) {
      print('renewals error: $e');
    }
  }

  client.close();
}

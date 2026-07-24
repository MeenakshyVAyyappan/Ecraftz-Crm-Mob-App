import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  
  final tables = ['form_templates', 'form_submissions', 'onboarding_templates', 'onboarding_submissions', 'requirements_submissions', 'intakes', 'form_submission_answers'];
  final result = <String, dynamic>{};
  
  for (final table in tables) {
    final url = Uri.parse('https://bnjvugxvcoqgfvvvwpzc.supabase.co/rest/v1/$table?select=*');
    final request = await client.getUrl(url);
    request.headers.set('apikey', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJuanZ1Z3h2Y29xZ2Z2dnZ3cHpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMzMTA4NTMsImV4cCI6MjA5ODg4Njg1M30.Fe5COvy60ezaVwrrDOR_Ec-1wDRizd6FiPp9vtHy2O4');
    
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    
    try {
      result[table] = jsonDecode(body);
    } catch (_) {
      result[table] = body;
    }
  }
  
  final file = File('lib/db_data.json');
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(result));
  print('Data written to lib/db_data.json');
  client.close();
}

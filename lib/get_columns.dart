import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  
  final tables = ['form_templates', 'form_submissions', 'onboarding_templates', 'onboarding_submissions', 'requirements_submissions', 'intakes', 'form_submission_answers'];
  final result = <String, dynamic>{};
  
  for (final table in tables) {
    final url = Uri.parse('https://vbosonyrosxfttyoengz.supabase.co/rest/v1/$table?select=*');
    final request = await client.getUrl(url);
    request.headers.set('apikey', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZib3Nvbnlyb3N4ZnR0eW9lbmd6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzczNTU3MDQsImV4cCI6MjA5MjkzMTcwNH0.OyJKw9QvXyp3DcnR_lYkc0ID9O64bnvk521hRtW1DcE');
    
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

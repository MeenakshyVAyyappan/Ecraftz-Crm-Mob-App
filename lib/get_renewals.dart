import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  final url = Uri.parse('https://vbosonyrosxfttyoengz.supabase.co/rest/v1/renewals?select=*&limit=3');
  final request = await client.getUrl(url);
  request.headers.set('apikey', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZib3Nvbnlyb3N4ZnR0eW9lbmd6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzczNTU3MDQsImV4cCI6MjA5MjkzMTcwNH0.OyJKw9QvXyp3DcnR_lYkc0ID9O64bnvk521hRtW1DcE');
  
  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  print(body);
  client.close();
}

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Inspect Zahn Dental Clinic in Supabase DB', () async {
    HttpOverrides.global = null;
    const MethodChannel('plugins.flutter.io/shared_preferences')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'getAll') return <String, Object>{};
      if (methodCall.method.startsWith('set')) return true;
      return null;
    });

    await Supabase.initialize(
      url: 'https://bnjvugxvcoqgfvvvwpzc.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJuanZ1Z3h2Y29xZ2Z2dnZ3cHpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMzMTA4NTMsImV4cCI6MjA5ODg4Njg1M30.Fe5COvy60ezaVwrrDOR_Ec-1wDRizd6FiPp9vtHy2O4',
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
      ),
    );

    final client = Supabase.instance.client;

    // Sign in using standard test credentials or create user with direct REST
    // Let's try signing in with test credentials if possible
    try {
      await client.auth.signInWithPassword(
        email: 'admin@ecraftz.com',
        password: 'Password123!',
      );
    } catch (e) {
      print('Sign in note: $e');
    }

    print('\n=== 1. FETCHING ALL CLIENTS FROM DB ===');
    try {
      final clients = await client.from('clients').select('id, name, email');
      print('Clients count: ${clients.length}');
      for (var c in clients) {
        print('CLIENT ID: ${c['id']} | Name: "${c['name']}" | Email: ${c['email']}');
      }
    } catch (e) {
      print('Clients query error: $e');
    }

    print('\n=== 2. FETCHING INVOICES FROM DB ===');
    try {
      final invoices = await client.from('invoices').select('*');
      print('Invoices count: ${invoices.length}');
      for (var inv in invoices) {
        print(
            'INVOICE ID: ${inv['id']} | Inv#: ${inv['invoice_number']} | ClientId: ${inv['client_id']} | Subtotal: ${inv['subtotal']} | GrandTotal: ${inv['grand_total']} | Status: ${inv['status']}');
      }
    } catch (e) {
      print('Invoices query error: $e');
    }

    print('\n=== 3. FETCHING CLIENT_STATEMENTS FROM DB ===');
    try {
      final cs = await client.from('client_statements').select('*');
      print('Client statements count: ${cs.length}');
      for (var st in cs) {
        print(
            'CS ID: ${st['id']} | ClientId: ${st['client_id']} | Debit: ${st['debit']} | Credit: ${st['credit']} | RunningBal: ${st['running_balance']} | Desc: ${st['description']}');
      }
    } catch (e) {
      print('Client statements query error: $e');
    }
  });
}

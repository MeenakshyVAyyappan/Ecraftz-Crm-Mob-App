import 'dart:convert';
import 'dart:io';

void main() async {
  final url = 'https://bnjvugxvcoqgfvvvwpzc.supabase.co/rest/v1';
  final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJuanZ1Z3h2Y29xZ2Z2dnZ3cHpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMzMTA4NTMsImV4cCI6MjA5ODg4Njg1M30.Fe5COvy60ezaVwrrDOR_Ec-1wDRizd6FiPp9vtHy2O4';

  final client = HttpClient();

  Future<List<dynamic>> queryTable(String table) async {
    try {
      final req = await client.getUrl(Uri.parse('$url/$table?select=*'));
      req.headers.set('apikey', anonKey);
      req.headers.set('Authorization', 'Bearer $anonKey');
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      final data = jsonDecode(body);
      if (data is List) return data;
      print('Error on $table: $body');
      return [];
    } catch (e) {
      print('Exception on $table: $e');
      return [];
    }
  }

  print('=== QUERYING SUPABASE REST API ===\n');

  final leads = await queryTable('leads');
  final nonDeletedLeads = leads.where((l) => l['deleted_at'] == null).toList();
  print('Leads count (total): ${leads.length}');
  print('Leads count (non-deleted): ${nonDeletedLeads.length}');
  int newLeads = 0;
  for (var l in nonDeletedLeads) {
    final st = l['status']?.toString().toLowerCase();
    if (st == 'new') newLeads++;
  }
  print('New leads (non-deleted): $newLeads\n');

  final invoices = await queryTable('invoices');
  final nonDeletedInvoices = invoices.where((i) => i['deleted_at'] == null).toList();
  print('Invoices count (total): ${invoices.length}');
  print('Invoices count (non-deleted): ${nonDeletedInvoices.length}');
  double grandTotalSum = 0;
  double amountPaidSum = 0;
  double amountDueSum = 0;
  for (var inv in nonDeletedInvoices) {
    final status = inv['status']?.toString().toLowerCase();
    final gt = double.tryParse(inv['grand_total']?.toString() ?? '') ??
               double.tryParse(inv['amount']?.toString() ?? '') ?? 0;
    final paid = double.tryParse(inv['amount_paid']?.toString() ?? '') ?? 0;
    final due = double.tryParse(inv['amount_due']?.toString() ?? '') ?? 0;
    if (status != 'cancelled') {
      grandTotalSum += gt;
      amountPaidSum += paid;
      amountDueSum += due;
    }
  }
  print('Invoices Grand Total (non-cancelled): $grandTotalSum');
  print('Invoices Amount Paid: $amountPaidSum');
  print('Invoices Amount Due: $amountDueSum\n');

  final payments = await queryTable('payments');
  final nonDeletedPayments = payments.where((p) => p['deleted_at'] == null).toList();
  print('Payments count (total): ${payments.length}');
  print('Payments count (non-deleted): ${nonDeletedPayments.length}');
  double paySumAll = 0;
  double paySumVerified = 0;
  for (var p in nonDeletedPayments) {
    final amt = double.tryParse(p['amount']?.toString() ?? '') ?? 0;
    final st = p['status']?.toString().toLowerCase() ?? '';
    paySumAll += amt;
    if (st == 'verified' || st == 'paid' || st == 'success' || st == 'completed' || st.isEmpty) {
      paySumVerified += amt;
    }
  }
  print('Payments sum (all): $paySumAll');
  print('Payments sum (verified/paid/success/empty): $paySumVerified\n');

  final incomeEntries = await queryTable('income_entries');
  print('Income Entries count: ${incomeEntries.length}');
  double incSum = 0;
  for (var i in incomeEntries) {
    final amt = double.tryParse(i['amount']?.toString() ?? '') ?? 0;
    incSum += amt;
  }
  print('Income Entries sum: $incSum\n');

  final salesEntries = await queryTable('sales_entries');
  print('Sales Entries count: ${salesEntries.length}');
  double salesSumFresh = 0;
  double salesSumAll = 0;
  for (var s in salesEntries) {
    final amt = double.tryParse(s['amount']?.toString() ?? '') ?? 0;
    final st = s['status']?.toString().toUpperCase() ?? '';
    salesSumAll += amt;
    if (st == 'FRESH') salesSumFresh += amt;
  }
  print('Sales Entries sum (all): $salesSumAll');
  print('Sales Entries sum (FRESH): $salesSumFresh\n');

  final clients = await queryTable('clients');
  final nonDeletedClients = clients.where((c) => c['deleted_at'] == null).toList();
  print('Clients count (total): ${clients.length}');
  print('Clients count (non-deleted): ${nonDeletedClients.length}');
  double clientVal = 0;
  for (var c in nonDeletedClients) {
    final val = double.tryParse(c['contract_value']?.toString() ?? '') ??
                double.tryParse(c['amount']?.toString() ?? '') ?? 0;
    clientVal += val;
  }
  print('Clients Contract Value sum: $clientVal\n');

  client.close();
}

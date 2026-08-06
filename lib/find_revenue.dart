import 'package:supabase_flutter/supabase_flutter.dart';

class EmptyLocalStorage extends LocalStorage {
  const EmptyLocalStorage();
  @override
  Future<void> initialize() async {}
  @override
  Future<String?> getString(String key) async => null;
  @override
  Future<void> setString(String key, String value) async {}
  @override
  Future<void> removeString(String key) async {}
  @override
  Future<bool> hasAccessToken() async => false;
  @override
  Future<String?> accessToken() async => null;
  @override
  Future<void> removeAccessToken() async {}
}

void main() async {
  await Supabase.initialize(
    url: 'https://bnjvugxvcoqgfvvvwpzc.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJuanZ1Z3h2Y29xZ2Z2dnZ3cHpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMzMTA4NTMsImV4cCI6MjA5ODg4Njg1M30.Fe5COvy60ezaVwrrDOR_Ec-1wDRizd6FiPp9vtHy2O4',
    authOptions: const FlutterAuthClientOptions(
      localStorage: EmptyLocalStorage(),
    ),
  );

  final client = Supabase.instance.client;

  print('--- LEADS ---');
  try {
    final leads = await client.from('leads').select();
    print('Total leads: ${leads.length}');
    int newLeads = 0;
    for (var l in leads) {
      if (l['status']?.toString().toLowerCase() == 'new') newLeads++;
    }
    print('New leads: $newLeads');
  } catch (e) {
    print('Leads error: $e');
  }

  print('\n--- CLIENTS ---');
  try {
    final clients = await client.from('clients').select();
    print('Total clients: ${clients.length}');
    double totalContractVal = 0;
    for (var c in clients) {
      final val = double.tryParse(c['contract_value']?.toString() ?? '') ??
                  double.tryParse(c['amount']?.toString() ?? '') ?? 0;
      totalContractVal += val;
    }
    print('Total Contract Value: $totalContractVal');
  } catch (e) {
    print('Clients error: $e');
  }

  print('\n--- INVOICES ---');
  try {
    final invoices = await client.from('invoices').select();
    print('Total invoices: ${invoices.length}');
    double grandTotalSum = 0;
    double paidSum = 0;
    for (var inv in invoices) {
      final status = inv['status']?.toString().toLowerCase();
      final gt = double.tryParse(inv['grand_total']?.toString() ?? '') ??
                 double.tryParse(inv['amount']?.toString() ?? '') ?? 0;
      final paid = double.tryParse(inv['amount_paid']?.toString() ?? '') ?? 0;
      if (status != 'cancelled') {
        grandTotalSum += gt;
        paidSum += paid;
      }
    }
    print('Invoices Grand Total (non-cancelled): $grandTotalSum');
    print('Invoices Amount Paid: $paidSum');
  } catch (e) {
    print('Invoices error: $e');
  }

  print('\n--- PAYMENTS ---');
  try {
    final payments = await client.from('payments').select();
    print('Total payments rows: ${payments.length}');
    double paySum = 0;
    for (var p in payments) {
      final amt = double.tryParse(p['amount']?.toString() ?? '') ?? 0;
      paySum += amt;
    }
    print('Payments total sum: $paySum');
  } catch (e) {
    print('Payments error: $e');
  }

  print('\n--- INCOME ENTRIES ---');
  try {
    final inc = await client.from('income_entries').select();
    print('Total income_entries rows: ${inc.length}');
    double incSum = 0;
    for (var i in inc) {
      final amt = double.tryParse(i['amount']?.toString() ?? '') ?? 0;
      incSum += amt;
    }
    print('Income entries total sum: $incSum');
  } catch (e) {
    print('Income entries error: $e');
  }

  print('\n--- SALES ENTRIES ---');
  try {
    final sales = await client.from('sales_entries').select();
    print('Total sales_entries rows: ${sales.length}');
    double salesSum = 0;
    for (var s in sales) {
      final amt = double.tryParse(s['amount']?.toString() ?? '') ?? 0;
      salesSum += amt;
    }
    print('Sales entries total sum: $salesSum');
  } catch (e) {
    print('Sales entries error: $e');
  }
}

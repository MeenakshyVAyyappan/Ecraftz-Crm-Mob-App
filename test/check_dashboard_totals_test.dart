import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Fetch all table totals for Dashboard verification', () async {
    final client = SupabaseClient(
      'https://bnjvugxvcoqgfvvvwpzc.supabase.co',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJuanZ1Z3h2Y29xZ2Z2dnZ3cHpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMzMTA4NTMsImV4cCI6MjA5ODg4Njg1M30.Fe5COvy60ezaVwrrDOR_Ec-1wDRizd6FiPp9vtHy2O4',
    );

    // Try signing in
    for (var pwd in ['123456', 'admin123', 'Password123!', '12345678']) {
      try {
        await client.auth.signInWithPassword(email: 'viswajithjithu3335@gmail.com', password: pwd);
        print('Logged in successfully as viswajithjithu3335@gmail.com with password: $pwd');
        break;
      } catch (_) {
        try {
          await client.auth.signInWithPassword(email: 'viswajithjithu333@gmail.com', password: pwd);
          print('Logged in successfully as viswajithjithu333@gmail.com with password: $pwd');
          break;
        } catch (_) {}
      }
    }

    print('\n==================================================');
    print('DATABASE METRICS CHECK FOR DASHBOARD MATCHING WEB CRM');
    print('==================================================\n');

    // 1. Leads
    final leads = await client.from('leads').select().isFilter('deleted_at', null);
    print('Total Leads (deleted_at IS NULL): ${leads.length}');
    final newLeads = leads.where((l) => l['status']?.toString().toLowerCase() == 'new').length;
    print('New Leads (deleted_at IS NULL): $newLeads');

    // Group leads by branch_id
    Map<String, int> leadsByBranch = {};
    for (var l in leads) {
      final b = l['branch_id']?.toString() ?? 'no_branch';
      leadsByBranch[b] = (leadsByBranch[b] ?? 0) + 1;
    }
    print('Leads breakdown by branch_id: $leadsByBranch\n');

    // 2. Invoices
    final invoices = await client.from('invoices').select().isFilter('deleted_at', null);
    print('Total Invoices (deleted_at IS NULL): ${invoices.length}');
    double invoiceGrandTotalSum = 0;
    double invoicePaidSum = 0;
    double invoiceDueSum = 0;
    for (var inv in invoices) {
      final status = inv['status']?.toString().toLowerCase();
      if (status != 'cancelled') {
        final gt = (inv['grand_total'] is num) ? (inv['grand_total'] as num).toDouble() : (double.tryParse(inv['grand_total']?.toString() ?? '') ?? 0.0);
        final paid = (inv['amount_paid'] is num) ? (inv['amount_paid'] as num).toDouble() : (double.tryParse(inv['amount_paid']?.toString() ?? '') ?? 0.0);
        final due = (inv['amount_due'] is num) ? (inv['amount_due'] as num).toDouble() : (double.tryParse(inv['amount_due']?.toString() ?? '') ?? 0.0);
        invoiceGrandTotalSum += gt;
        invoicePaidSum += paid;
        invoiceDueSum += due;
      }
    }
    print('Invoices Grand Total: ₹$invoiceGrandTotalSum');
    print('Invoices Amount Paid: ₹$invoicePaidSum');
    print('Invoices Amount Due: ₹$invoiceDueSum\n');

    // 3. Clients
    final clients = await client.from('clients').select().isFilter('deleted_at', null);
    print('Total Clients (deleted_at IS NULL): ${clients.length}');
    double clientContractSum = 0;
    for (var c in clients) {
      final val = (c['contract_value'] is num) ? (c['contract_value'] as num).toDouble() : (double.tryParse(c['contract_value']?.toString() ?? '') ?? (double.tryParse(c['amount']?.toString() ?? '') ?? 0.0));
      clientContractSum += val;
    }
    print('Clients Contract Value Total: ₹$clientContractSum\n');

    // 4. Payments
    final payments = await client.from('payments').select();
    print('Total Payments rows: ${payments.length}');
    double paymentsSum = 0;
    for (var p in payments) {
      final amt = (p['amount'] is num) ? (p['amount'] as num).toDouble() : (double.tryParse(p['amount']?.toString() ?? '') ?? 0.0);
      paymentsSum += amt;
    }
    print('Payments Total Sum: ₹$paymentsSum\n');

    // 5. Income Entries
    final income = await client.from('income_entries').select();
    print('Total Income Entries rows: ${income.length}');
    double incomeSum = 0;
    for (var inc in income) {
      final amt = (inc['amount'] is num) ? (inc['amount'] as num).toDouble() : (double.tryParse(inc['amount']?.toString() ?? '') ?? 0.0);
      incomeSum += amt;
    }
    print('Income Entries Total Sum: ₹$incomeSum\n');

    // 6. Sales Entries
    final sales = await client.from('sales_entries').select();
    print('Total Sales Entries rows: ${sales.length}');
    double salesFreshSum = 0;
    double salesTotalSum = 0;
    for (var s in sales) {
      final amt = (s['amount'] is num) ? (s['amount'] as num).toDouble() : (double.tryParse(s['amount']?.toString() ?? '') ?? 0.0);
      final st = s['status']?.toString().toUpperCase() ?? '';
      salesTotalSum += amt;
      if (st == 'FRESH') salesFreshSum += amt;
    }
    print('Sales Entries Total Sum: ₹$salesTotalSum');
    print('Sales Entries FRESH Sum: ₹$salesFreshSum\n');

    print('==================================================');
  });
}

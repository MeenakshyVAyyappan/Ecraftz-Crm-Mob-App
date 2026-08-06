import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/income_entry_model.dart';
import '../../models/expense_entry_model.dart';
import '../../models/financial_category_model.dart';
import '../../services/financials_service.dart';

class IncomeExpenseScreen extends StatefulWidget {
  const IncomeExpenseScreen({super.key});

  @override
  State<IncomeExpenseScreen> createState() => _IncomeExpenseScreenState();
}

class _IncomeExpenseScreenState extends State<IncomeExpenseScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<IncomeEntryModel> _incomeEntries = [];
  List<ExpenseEntryModel> _expenseEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFinancials();
  }

  Future<void> _loadFinancials() async {
    setState(() => _isLoading = true);
    final inc = await FinancialsService.getIncomeEntries();
    final exp = await FinancialsService.getExpenseEntries();

    if (mounted) {
      setState(() {
        _incomeEntries = inc;
        _expenseEntries = exp;
        _isLoading = false;
      });
    }
  }

  double get _totalIncome => _incomeEntries.fold(0.0, (s, e) => s + e.amount);
  double get _totalExpense => _expenseEntries.fold(0.0, (s, e) => s + e.amount);
  double get _netBalance => _totalIncome - _totalExpense;

  void _showAddIncomeDialog() {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String categoryName = 'Client Services';
    String method = 'Bank Transfer';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Income Entry (Cash Inflow)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Title / Product *', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (₹) *', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: categoryName,
                decoration: const InputDecoration(labelText: 'Income Category', border: OutlineInputBorder()),
                items: ['Client Services', 'Retainers', 'Consultation & Strategy', 'Digital Products', 'Other Income']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => categoryName = val!,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: method,
                decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
                items: ['Bank Transfer', 'UPI', 'Cash', 'Cheque']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (val) => method = val!,
              ),
              const SizedBox(height: 10),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amt = double.tryParse(amountCtrl.text) ?? 0.0;
              if (nameCtrl.text.trim().isEmpty || amt <= 0) return;
              Navigator.pop(ctx);

              final model = IncomeEntryModel(
                organizationId: '',
                date: DateTime.now(),
                categoryName: categoryName,
                name: nameCtrl.text.trim(),
                amount: amt,
                paymentMethod: method,
                notes: notesCtrl.text.trim(),
              );
              await FinancialsService.addIncomeEntry(model);
              _loadFinancials();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            child: const Text('Save Income'),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog() {
    final vendorCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String categoryName = 'Office Rent';
    String status = 'Paid';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Expense Entry (Cash Outflow)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: vendorCtrl, decoration: const InputDecoration(labelText: 'Vendor Name *', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (₹) *', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: categoryName,
                decoration: const InputDecoration(labelText: 'Expense Category', border: OutlineInputBorder()),
                items: ['Office Rent', 'Salaries & Payroll', 'Marketing & Ads', 'Software Tools', 'Travel & Conveyance', 'Hardware', 'Utilities', 'Supplies']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => categoryName = val!,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(labelText: 'Payment Status', border: OutlineInputBorder()),
                items: ['Paid', 'Pending']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) => status = val!,
              ),
              const SizedBox(height: 10),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amt = double.tryParse(amountCtrl.text) ?? 0.0;
              if (vendorCtrl.text.trim().isEmpty || amt <= 0) return;
              Navigator.pop(ctx);

              final model = ExpenseEntryModel(
                organizationId: '',
                date: DateTime.now(),
                categoryName: categoryName,
                vendorName: vendorCtrl.text.trim(),
                amount: amt,
                paymentStatus: status,
                notes: notesCtrl.text.trim(),
              );
              await FinancialsService.addExpenseEntry(model);
              _loadFinancials();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            child: const Text('Save Expense'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Overall Cash Flow Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: LayoutBuilder(builder: (context, constraints) {
                bool isWide = constraints.maxWidth > 500;
                return isWide
                    ? Row(
                        children: [
                          Expanded(child: _buildBalanceTile('Total Income Inflows', '₹${_totalIncome.toStringAsFixed(2)}', Colors.green)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildBalanceTile('Total Expense Outflows', '₹${_totalExpense.toStringAsFixed(2)}', Colors.red)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildBalanceTile('Net Balance', '₹${_netBalance.toStringAsFixed(2)}', _netBalance >= 0 ? Colors.teal : Colors.deepOrange)),
                        ],
                      )
                    : Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildBalanceTile('Inflows', '₹${_totalIncome.toStringAsFixed(2)}', Colors.green)),
                              const SizedBox(width: 8),
                              Expanded(child: _buildBalanceTile('Outflows', '₹${_totalExpense.toStringAsFixed(2)}', Colors.red)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildBalanceTile('Net Balance', '₹${_netBalance.toStringAsFixed(2)}', _netBalance >= 0 ? Colors.teal : Colors.deepOrange),
                        ],
                      );
              }),
            ),

            // Tab Bar
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Income Inflows', icon: Icon(Icons.arrow_downward, color: Colors.green)),
                Tab(text: 'Expense Outflows', icon: Icon(Icons.arrow_upward, color: Colors.red)),
              ],
            ),

            // Tab View Contents
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        // Income Tab
                        Stack(
                          children: [
                            ListView.builder(
                              itemCount: _incomeEntries.length,
                              padding: const EdgeInsets.all(16),
                              itemBuilder: (context, index) {
                                final item = _incomeEntries[index];
                                return Card(
                                  child: ListTile(
                                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('${item.categoryName} • ${item.paymentMethod} • ${DateFormat("dd MMM").format(item.date)}'),
                                    trailing: Text('₹${item.amount.toStringAsFixed(2)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                                  ),
                                );
                              },
                            ),
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: FloatingActionButton.extended(
                                onPressed: _showAddIncomeDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Income'),
                                backgroundColor: Colors.green,
                              ),
                            ),
                          ],
                        ),

                        // Expense Tab
                        Stack(
                          children: [
                            ListView.builder(
                              itemCount: _expenseEntries.length,
                              padding: const EdgeInsets.all(16),
                              itemBuilder: (context, index) {
                                final item = _expenseEntries[index];
                                return Card(
                                  child: ListTile(
                                    title: Text(item.vendorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('${item.categoryName} • Status: ${item.paymentStatus} • ${DateFormat("dd MMM").format(item.date)}'),
                                    trailing: Text('₹${item.amount.toStringAsFixed(2)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16)),
                                  ),
                                );
                              },
                            ),
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: FloatingActionButton.extended(
                                onPressed: _showAddExpenseDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Expense'),
                                backgroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceTile(String title, String value, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

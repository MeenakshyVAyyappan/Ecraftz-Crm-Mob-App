import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/expense_entry_model.dart';
import '../../services/financials_service.dart';

class ExpenseEntriesScreen extends StatefulWidget {
  const ExpenseEntriesScreen({super.key});

  @override
  State<ExpenseEntriesScreen> createState() => _ExpenseEntriesScreenState();
}

class _ExpenseEntriesScreenState extends State<ExpenseEntriesScreen> {
  List<ExpenseEntryModel> _entries = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await FinancialsService.getExpenseEntries();
    if (mounted) {
      setState(() {
        _entries = data;
        _isLoading = false;
      });
    }
  }

  List<ExpenseEntryModel> get _filteredEntries {
    return _entries.where((e) {
      final q = _searchQuery.toLowerCase();
      final matchQ = q.isEmpty || e.vendorName.toLowerCase().contains(q) || e.categoryName.toLowerCase().contains(q);
      final matchCat = _selectedCategory == null || e.categoryName == _selectedCategory;
      return matchQ && matchCat;
    }).toList();
  }

  double get _totalExpenses => _entries.fold(0.0, (s, e) => s + e.amount);

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
              TextField(
                controller: vendorCtrl,
                decoration: const InputDecoration(labelText: 'Vendor Name / Particulars *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount (₹) *', border: OutlineInputBorder()),
              ),
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
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
              ),
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
              _loadData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink.shade700, foregroundColor: Colors.white),
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
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: Column(
            children: [
              // Top Metric Cards (Screenshot 4)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: LayoutBuilder(builder: (context, constraints) {
                  bool isWide = constraints.maxWidth > 500;
                  return isWide
                      ? Row(
                          children: [
                            Expanded(child: _buildMetricCard('TOTAL EXPENSES', '₹${_totalExpenses.toStringAsFixed(2)}', Colors.pink)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildMetricCard('HIGHEST EXPENSE AREA', _entries.isEmpty ? 'N/A' : _entries.first.categoryName, Colors.orange)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildMetricCard('EXPENSE CATEGORIES', '9 Active Categories', Colors.purple)),
                          ],
                        )
                      : Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildMetricCard('TOTAL EXPENSES', '₹${_totalExpenses.toStringAsFixed(2)}', Colors.pink)),
                                const SizedBox(width: 8),
                                Expanded(child: _buildMetricCard('HIGHEST AREA', _entries.isEmpty ? 'N/A' : _entries.first.categoryName, Colors.orange)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildMetricCard('EXPENSE CATEGORIES', '9 Active Categories', Colors.purple),
                          ],
                        );
                }),
              ),

              // Filter Bar & Action Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search vendor / category...',
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _showAddExpenseDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('+ ADD EXPENSE ENTRY'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Expense Listing
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredEntries.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.info_outline, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                const Text('No expense entries recorded.', style: TextStyle(color: Colors.grey)),
                                const Text('Click "+ Add Expense Entry" to log a new expense.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredEntries.length,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemBuilder: (context, index) {
                              final item = _filteredEntries[index];
                              return Card(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  title: Text(item.vendorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Category: ${item.categoryName} • Status: ${item.paymentStatus} • ${DateFormat("dd MMM yyyy").format(item.date)}'),
                                  trailing: Text('₹${item.amount.toStringAsFixed(2)}',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.pink.shade700)),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String val, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(val, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

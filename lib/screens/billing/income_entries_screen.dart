import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/income_entry_model.dart';
import '../../services/financials_service.dart';

class IncomeEntriesScreen extends StatefulWidget {
  const IncomeEntriesScreen({super.key});

  @override
  State<IncomeEntriesScreen> createState() => _IncomeEntriesScreenState();
}

class _IncomeEntriesScreenState extends State<IncomeEntriesScreen> {
  List<IncomeEntryModel> _entries = [];
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
    final data = await FinancialsService.getIncomeEntries();
    if (mounted) {
      setState(() {
        _entries = data;
        _isLoading = false;
      });
    }
  }

  List<IncomeEntryModel> get _filteredEntries {
    return _entries.where((e) {
      final q = _searchQuery.toLowerCase();
      final matchQ = q.isEmpty || e.name.toLowerCase().contains(q) || e.categoryName.toLowerCase().contains(q);
      final matchCat = _selectedCategory == null || e.categoryName == _selectedCategory;
      return matchQ && matchCat;
    }).toList();
  }

  double get _totalIncome => _entries.fold(0.0, (s, e) => s + e.amount);

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
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Source Name / Particulars *', border: OutlineInputBorder()),
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
              _loadData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
            child: const Text('Save Income'),
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
              // Top Metric Cards (Screenshot 3)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: LayoutBuilder(builder: (context, constraints) {
                  bool isWide = constraints.maxWidth > 500;
                  return isWide
                      ? Row(
                          children: [
                            Expanded(child: _buildMetricCard('TOTAL INCOME', '₹${_totalIncome.toStringAsFixed(2)}', Colors.teal)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildMetricCard('TOP INCOME SOURCE', _entries.isEmpty ? 'N/A' : _entries.first.categoryName, Colors.blue)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildMetricCard('MANAGED CATEGORIES', '5 Active Categories', Colors.purple)),
                          ],
                        )
                      : Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildMetricCard('TOTAL INCOME', '₹${_totalIncome.toStringAsFixed(2)}', Colors.teal)),
                                const SizedBox(width: 8),
                                Expanded(child: _buildMetricCard('TOP SOURCE', _entries.isEmpty ? 'N/A' : _entries.first.categoryName, Colors.blue)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildMetricCard('MANAGED CATEGORIES', '5 Active Categories', Colors.purple),
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
                          hintText: 'Search source / category...',
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _showAddIncomeDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('+ ADD INCOME ENTRY'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Income Listing
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
                                const Text('No income entries recorded.', style: TextStyle(color: Colors.grey)),
                                const Text('Click "+ Add Income Entry" to log a new transaction.', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
                                  title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Category: ${item.categoryName} • ${item.paymentMethod} • ${DateFormat("dd MMM yyyy").format(item.date)}'),
                                  trailing: Text('₹${item.amount.toStringAsFixed(2)}',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal.shade700)),
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

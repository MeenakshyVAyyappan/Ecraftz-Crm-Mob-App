import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/sales_entry_model.dart';
import '../../services/sales_service.dart';

class SalesEntriesScreen extends StatefulWidget {
  const SalesEntriesScreen({super.key});

  @override
  State<SalesEntriesScreen> createState() => _SalesEntriesScreenState();
}

class _SalesEntriesScreenState extends State<SalesEntriesScreen> {
  List<SalesEntryModel> _entries = [];
  bool _isLoading = true;
  String _statusFilter = 'All';
  String _searchQuery = '';
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadSalesEntries();
  }

  Future<void> _loadSalesEntries() async {
    setState(() => _isLoading = true);
    final data = await SalesService.getSalesEntries(statusFilter: _statusFilter);
    if (mounted) {
      setState(() {
        _entries = data;
        _isLoading = false;
        _selectedIds.clear();
      });
    }
  }

  List<SalesEntryModel> get _filteredEntries {
    return _entries.where((entry) {
      final q = _searchQuery.toLowerCase();
      final matchQ = q.isEmpty ||
          entry.name.toLowerCase().contains(q) ||
          (entry.bdeName?.toLowerCase().contains(q) ?? false);
      final matchStatus = _statusFilter == 'All' || entry.status == _statusFilter;
      return matchQ && matchStatus;
    }).toList();
  }

  // Total Sales Entry — ALL entries (matches web CRM's TOTAL SALES ENTRY card)
  double get _totalSalesEntry => _entries.fold(0.0, (sum, e) => sum + e.amount);

  double get _totalFreshSales => _entries
      .where((e) => e.status == 'FRESH')
      .fold(0.0, (sum, item) => sum + item.amount);

  double get _totalOutstandingSales => _entries
      .where((e) => e.status == 'OUTSTANDING')
      .fold(0.0, (sum, item) => sum + item.amount);

  int get _freshCount => _entries.where((e) => e.status == 'FRESH').length;
  int get _outstandingCount => _entries.where((e) => e.status == 'OUTSTANDING').length;

  // ── Bulk Operations Modals (Specification Page 8) ────────────────────────
  void _showBulkDateDialog() {
    DateTime selectedDate = DateTime.now();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text('Bulk Update Date (${_selectedIds.length} items)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select new date for all selected entries:'),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (d != null) setModalState(() => selectedDate = d);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('dd MMM yyyy').format(selectedDate)),
                      const Icon(Icons.calendar_month),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await SalesService.bulkUpdateDate(_selectedIds.toList(), selectedDate);
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bulk date updated!')));
                  _loadSalesEntries();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              child: const Text('Apply Date'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkBdeReassignDialog() {
    final bdeNameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Bulk Reassign BDE (${_selectedIds.length} items)'),
        content: TextField(
          controller: bdeNameCtrl,
          decoration: const InputDecoration(
            labelText: 'New BDE Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (bdeNameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final ok = await SalesService.bulkReassignBde(_selectedIds.toList(), '', bdeNameCtrl.text.trim());
              if (ok) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bulk BDE reassigned!')));
                _loadSalesEntries();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            child: const Text('Reassign BDE'),
          ),
        ],
      ),
    );
  }

  void _showBulkStatusDialog() {
    String newStatus = 'FRESH';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text('Bulk Transition Status (${_selectedIds.length} items)'),
          content: DropdownButtonFormField<String>(
            value: newStatus,
            decoration: const InputDecoration(labelText: 'Target Status', border: OutlineInputBorder()),
            items: ['FRESH', 'OUTSTANDING']
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (val) => setModalState(() => newStatus = val!),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await SalesService.bulkUpdateStatus(_selectedIds.toList(), newStatus);
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bulk status updated!')));
                  _loadSalesEntries();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              child: const Text('Apply Status'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmBulkDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${_selectedIds.length} Entries?'),
        content: const Text('Are you sure you want to delete all selected sales entries? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await SalesService.bulkDelete(_selectedIds.toList());
              if (ok) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entries deleted successfully!')));
                _loadSalesEntries();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete All'),
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
          onRefresh: _loadSalesEntries,
          child: Column(
            children: [
              // Header Metrics Cards (matches web CRM layout)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    // Row 1: TOTAL SALES ENTRY (full-width, prominent) — matches web CRM
                    _buildMetricCard(
                      'TOTAL SALES ENTRY',
                      '₹${_totalSalesEntry.toStringAsFixed(2)}',
                      Colors.black87,
                      subtitle: '${_entries.length} transaction(s)',
                      icon: Icons.receipt_long,
                      isTotalCard: true,
                    ),
                    const SizedBox(height: 10),
                    // Row 2: FRESH + OUTSTANDING side by side
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'FRESH SALES',
                            '₹${_totalFreshSales.toStringAsFixed(2)}',
                            Colors.green.shade700,
                            subtitle: '$_freshCount fresh sale(s) tagged',
                            badgeLabel: 'FRESH',
                            badgeColor: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricCard(
                            'OUTSTANDING SALES',
                            '₹${_totalOutstandingSales.toStringAsFixed(2)}',
                            Colors.orange.shade700,
                            subtitle: '$_outstandingCount outstanding sale(s) pending',
                            badgeLabel: 'OUTSTANDING',
                            badgeColor: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Filter & Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search BDE name or contract...',
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _statusFilter,
                      items: ['All', 'FRESH', 'OUTSTANDING']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) => setState(() => _statusFilter = val!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Bulk Operations Toolbar (Appears when items are selected)
              if (_selectedIds.isNotEmpty)
                Container(
                  color: Colors.teal.shade100,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Text('${_selectedIds.length} Selected', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),
                        IconButton(icon: const Icon(Icons.calendar_month), onPressed: _showBulkDateDialog, tooltip: 'Bulk Date'),
                        IconButton(icon: const Icon(Icons.person_add), onPressed: _showBulkBdeReassignDialog, tooltip: 'Bulk BDE'),
                        IconButton(icon: const Icon(Icons.published_with_changes), onPressed: _showBulkStatusDialog, tooltip: 'Bulk Status'),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: _confirmBulkDelete, tooltip: 'Bulk Delete'),
                      ],
                    ),
                  ),
                ),

              // Entries Listing
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredEntries.isEmpty
                        ? const Center(child: Text('No sales entries found.'))
                        : ListView.builder(
                            itemCount: _filteredEntries.length,
                            padding: const EdgeInsets.all(16),
                            itemBuilder: (context, index) {
                              final entry = _filteredEntries[index];
                              final isSelected = _selectedIds.contains(entry.id);

                              return Card(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  leading: Checkbox(
                                    value: isSelected,
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true && entry.id != null) {
                                          _selectedIds.add(entry.id!);
                                        } else {
                                          _selectedIds.remove(entry.id);
                                        }
                                      });
                                    },
                                  ),
                                  title: Text(entry.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('BDE: ${entry.bdeName ?? "Unassigned"} • Date: ${DateFormat("dd MMM yyyy").format(entry.date)}'),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('₹${entry.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: entry.status == 'FRESH' ? Colors.green.shade100 : Colors.orange.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          entry.status,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: entry.status == 'FRESH' ? Colors.green.shade800 : Colors.orange.shade800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
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

  Widget _buildMetricCard(
    String label,
    String val,
    Color color, {
    String? subtitle,
    String? badgeLabel,
    MaterialColor? badgeColor,
    IconData? icon,
    bool isTotalCard = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.all(isTotalCard ? 14.0 : 12.0),
        child: isTotalCard
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5)),
                        const SizedBox(height: 6),
                        Text(val,
                            style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: color)),
                        if (subtitle != null) ...
                          [
                            const SizedBox(height: 4),
                            Text(subtitle,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                      ],
                    ),
                  ),
                  if (icon != null)
                    Icon(icon, size: 36, color: Colors.grey.shade300),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(label,
                            style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.4)),
                      ),
                      if (badgeLabel != null && badgeColor != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badgeLabel,
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: badgeColor.shade700),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(val,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  if (subtitle != null) ...
                    [
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 10, color: Colors.grey)),
                    ],
                ],
              ),
      ),
    );
  }
}

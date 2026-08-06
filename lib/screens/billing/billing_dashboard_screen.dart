import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/invoice_model.dart';
import '../../services/billing_service.dart';
import '../../widgets/app_drawer.dart';
import 'create_invoice_screen.dart';
import 'invoice_detail_screen.dart';
import 'sales_entries_screen.dart';
import 'income_entries_screen.dart';
import 'expense_entries_screen.dart';
import 'categories_management_screen.dart';
import 'client_statements_screen.dart';

class BillingDashboardScreen extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool showAppBar;

  const BillingDashboardScreen({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.showAppBar = true,
  });

  @override
  State<BillingDashboardScreen> createState() => _BillingDashboardScreenState();
}

class _BillingDashboardScreenState extends State<BillingDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _activeTabIndex = 0;

  List<InvoiceModel> _invoices = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'All Statuses';

  final List<Map<String, dynamic>> _tabs = [
    {'title': 'INVOICES & BILLING', 'icon': Icons.receipt_long},
    {'title': 'SALES ENTRIES', 'icon': Icons.monetization_on_outlined},
    {'title': 'INCOME ENTRIES', 'icon': Icons.arrow_circle_down_outlined},
    {'title': 'EXPENSE ENTRIES', 'icon': Icons.arrow_circle_up_outlined},
    {'title': 'CATEGORIES', 'icon': Icons.category_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);
    final data = await BillingService.getInvoices();
    if (mounted) {
      setState(() {
        _invoices = data;
        _isLoading = false;
      });
    }
  }

  List<InvoiceModel> get _filteredInvoices {
    return _invoices.where((inv) {
      final q = _searchQuery.toLowerCase();
      final matchQ = q.isEmpty ||
          inv.invoiceNumber.toLowerCase().contains(q) ||
          (inv.clientName?.toLowerCase().contains(q) ?? false);
      final matchStatus = _statusFilter == 'All Statuses' || inv.status.toLowerCase() == _statusFilter.toLowerCase();
      return matchQ && matchStatus;
    }).toList();
  }

  // Total Invoiced: sum grandTotal of ALL non-cancelled invoices (matches web CRM logic)
  double get _totalInvoiced => _invoices
      .where((i) => i.status.toLowerCase() != 'cancelled')
      .fold(0.0, (s, i) => s + i.effectiveGrandTotal);

  // Total Paid: sum amountPaid of ALL non-cancelled invoices
  double get _totalPaid => _invoices
      .where((i) => i.status.toLowerCase() != 'cancelled')
      .fold(0.0, (s, i) => s + i.effectiveAmountPaid);

  // Outstanding: sum amountDue per invoice directly (matches web CRM's outstanding column)
  double get _totalOutstanding => _invoices
      .where((i) => i.status.toLowerCase() != 'cancelled')
      .fold(0.0, (s, i) => s + i.effectiveAmountDue);

  void _openCreateInvoice() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateInvoiceScreen(onInvoiceCreated: _loadInvoices),
      ),
    );
  }

  void _openInvoiceDetail(InvoiceModel inv) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InvoiceDetailScreen(invoice: inv, onInvoiceUpdated: _loadInvoices),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: widget.showAppBar
          ? AppDrawer(
              selectedIndex: widget.selectedIndex,
              onItemSelected: widget.onItemSelected,
            )
          : null,
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Accounts & Financials', style: TextStyle(fontWeight: FontWeight.bold)),
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.description_outlined),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ClientStatementsScreen()),
                    );
                  },
                  tooltip: 'Client Statements',
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadInvoices,
                ),
              ],
            )
          : null,
      floatingActionButton: _activeTabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _openCreateInvoice,
              icon: const Icon(Icons.add),
              label: const Text('+ New Invoice'),
              backgroundColor: Colors.teal.shade700,
              foregroundColor: Colors.white,
            )
          : null,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Page Header Title & Subtitle (Web App style)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Accounts & Financials',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Comprehensive financial management: Invoices, Sales, Income, Expenses, and Category management.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),

            // Horizontal Pill Tabs Bar (Exact Web App Pill Navigation Bar)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _tabs.length,
                itemBuilder: (context, index) {
                  final isSelected = _activeTabIndex == index;
                  final tab = _tabs[index];

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: InkWell(
                      onTap: () => setState(() => _activeTabIndex = index),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.teal.shade700 : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: isSelected
                              ? [BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              tab['icon'] as IconData,
                              size: 18,
                              color: isSelected ? Colors.white : Colors.grey.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              tab['title'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),

            // Tab Content Body
            Expanded(
              child: IndexedStack(
                index: _activeTabIndex,
                children: [
                  // Tab 0: INVOICES & BILLING
                  _buildInvoicesTab(),

                  // Tab 1: SALES ENTRIES
                  const SalesEntriesScreen(),

                  // Tab 2: INCOME ENTRIES
                  const IncomeEntriesScreen(),

                  // Tab 3: EXPENSE ENTRIES
                  const ExpenseEntriesScreen(),

                  // Tab 4: CATEGORIES (Sub-tabs: Income Categories & Expense Categories)
                  const CategoriesManagementScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoicesTab() {
    return RefreshIndicator(
      onRefresh: _loadInvoices,
      child: Column(
        children: [
          // Top Metric Cards (Screenshot 1)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: LayoutBuilder(builder: (context, constraints) {
              bool isWide = constraints.maxWidth > 500;
              return isWide
                  ? Row(
                      children: [
                        Expanded(child: _buildMetricTile('TOTAL INVOICED', '₹${_totalInvoiced.toStringAsFixed(2)}', Colors.black87)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildMetricTile('TOTAL PAID', '₹${_totalPaid.toStringAsFixed(2)}', Colors.teal.shade700)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildMetricTile('OUTSTANDING', '₹${_totalOutstanding.toStringAsFixed(2)}', Colors.red.shade700)),
                      ],
                    )
                  : Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildMetricTile('TOTAL INVOICED', '₹${_totalInvoiced.toStringAsFixed(2)}', Colors.black87)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildMetricTile('TOTAL PAID', '₹${_totalPaid.toStringAsFixed(2)}', Colors.teal.shade700)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildMetricTile('OUTSTANDING', '₹${_totalOutstanding.toStringAsFixed(2)}', Colors.red.shade700),
                      ],
                    );
            }),
          ),

          // Filter Bar (Status & Search)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by invoice number or client...',
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
                  items: ['All Statuses', 'draft', 'sent', 'partially_paid', 'paid', 'overdue', 'cancelled']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s == 'All Statuses' ? s : s.toUpperCase())))
                      .toList(),
                  onChanged: (val) => setState(() => _statusFilter = val!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Invoices Listing
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredInvoices.isEmpty
                    ? const Center(child: Text('No invoices match filters.'))
                    : ListView.builder(
                        itemCount: _filteredInvoices.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemBuilder: (context, index) {
                          final inv = _filteredInvoices[index];
                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              onTap: () => _openInvoiceDetail(inv),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(inv.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                  _buildStatusChip(inv.status),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('Client: ${inv.clientName ?? "Operational Billing"}'),
                                  Text('Issued: ${DateFormat("dd MMM yyyy").format(inv.issuedAt)} | Due: ${DateFormat("dd MMM yyyy").format(inv.dueDate)}'),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('₹${inv.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text('Due: ₹${inv.amountDue.toStringAsFixed(2)}',
                                      style: TextStyle(color: inv.amountDue > 0 ? Colors.red : Colors.teal, fontSize: 12)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String val, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg = Colors.grey.shade200;
    Color fg = Colors.grey.shade800;

    switch (status.toLowerCase()) {
      case 'paid':
        bg = Colors.teal.shade100;
        fg = Colors.teal.shade800;
        break;
      case 'partially_paid':
        bg = Colors.orange.shade100;
        fg = Colors.orange.shade800;
        break;
      case 'overdue':
        bg = Colors.red.shade100;
        fg = Colors.red.shade800;
        break;
      case 'sent':
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade800;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}

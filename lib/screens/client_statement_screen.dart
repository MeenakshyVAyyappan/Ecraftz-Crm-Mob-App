import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/app_drawer.dart';


// ─── MODELS ───────────────────────────────────────────────────────────────────

enum TransactionType { debit, credit, advance, balance }

class Client {
  final String id;
  final String name;
  final String email;

  const Client({required this.id, required this.name, required this.email});
}

class Statement {
  final String id;
  final DateTime date;
  final String description;
  final TransactionType type;
  final double amount;
  final double runningBalance;
  final String? reference;
  final String? projectName;

  const Statement({
    required this.id,
    required this.date,
    required this.description,
    required this.type,
    required this.amount,
    required this.runningBalance,
    this.reference,
    this.projectName,
  });
}

// ─── SAMPLE DATA ──────────────────────────────────────────────────────────────

final List<Client> sampleClients = [
  Client(id: '1', name: 'arsenal', email: 'arsenal@gmail.com'),
  Client(id: '2', name: 'janani', email: 'livein@janani.in'),
  Client(id: '3', name: 'Steve rogers', email: 'viswajith.ecraftz@gmail.com'),
];

final Map<String, List<Statement>> clientStatements = {
  '1': [
    Statement(id: 's1', date: DateTime(2026, 1, 5), description: 'Invoice #INV-001 - Web Development', type: TransactionType.debit, amount: 50000, runningBalance: 50000, reference: 'INV-001', projectName: 'Arsenal Website'),
    Statement(id: 's2', date: DateTime(2026, 1, 20), description: 'Payment Received', type: TransactionType.credit, amount: 25000, runningBalance: 25000, reference: 'PAY-001', projectName: 'Arsenal Website'),
    Statement(id: 's3', date: DateTime(2026, 2, 10), description: 'Invoice #INV-002 - Digital Marketing', type: TransactionType.debit, amount: 20000, runningBalance: 45000, reference: 'INV-002', projectName: 'Arsenal Marketing'),
    Statement(id: 's4', date: DateTime(2026, 2, 28), description: 'Advance Payment', type: TransactionType.advance, amount: 10000, runningBalance: 35000, reference: 'ADV-001'),
    Statement(id: 's5', date: DateTime(2026, 3, 15), description: 'Invoice #INV-003 - SEO Services', type: TransactionType.debit, amount: 15000, runningBalance: 50000, reference: 'INV-003', projectName: 'Arsenal SEO'),
    Statement(id: 's6', date: DateTime(2026, 4, 1), description: 'Full Payment Received', type: TransactionType.credit, amount: 30000, runningBalance: 20000, reference: 'PAY-002'),
  ],
  '2': [
    Statement(id: 's7', date: DateTime(2026, 1, 10), description: 'Invoice #INV-004 - App Development', type: TransactionType.debit, amount: 80000, runningBalance: 80000, reference: 'INV-004', projectName: 'Janani App'),
    Statement(id: 's8', date: DateTime(2026, 2, 1), description: 'Advance Payment', type: TransactionType.advance, amount: 40000, runningBalance: 40000, reference: 'ADV-002'),
    Statement(id: 's9', date: DateTime(2026, 3, 5), description: 'Invoice #INV-005 - UI/UX Design', type: TransactionType.debit, amount: 25000, runningBalance: 65000, reference: 'INV-005', projectName: 'Janani Design'),
    Statement(id: 's10', date: DateTime(2026, 4, 10), description: 'Partial Payment', type: TransactionType.credit, amount: 30000, runningBalance: 35000, reference: 'PAY-003'),
    Statement(id: 's11', date: DateTime(2026, 5, 1), description: 'Invoice #INV-006 - Maintenance', type: TransactionType.debit, amount: 5000, runningBalance: 40000, reference: 'INV-006'),
  ],
  '3': [
    Statement(id: 's12', date: DateTime(2026, 2, 15), description: 'Invoice #INV-007 - Branding', type: TransactionType.debit, amount: 30000, runningBalance: 30000, reference: 'INV-007', projectName: 'Steve Branding'),
    Statement(id: 's13', date: DateTime(2026, 3, 20), description: 'Full Payment Received', type: TransactionType.credit, amount: 30000, runningBalance: 0, reference: 'PAY-004'),
    Statement(id: 's14', date: DateTime(2026, 4, 5), description: 'Invoice #INV-008 - Social Media', type: TransactionType.debit, amount: 12000, runningBalance: 12000, reference: 'INV-008'),
  ],
};

// ─── THEME ────────────────────────────────────────────────────────────────────

class CSTheme {
  static const Color primary = Color(0xFF06B6D4);
  static const Color primaryDark = Color(0xFF0891B2);
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color debitColor = Color(0xFFEF4444);
  static const Color creditColor = Color(0xFF10B981);
  static const Color advanceColor = Color(0xFF8B5CF6);
  static const Color balanceColor = Color(0xFF3B82F6);

  static Color typeColor(TransactionType t) {
    switch (t) {
      case TransactionType.debit: return debitColor;
      case TransactionType.credit: return creditColor;
      case TransactionType.advance: return advanceColor;
      case TransactionType.balance: return balanceColor;
    }
  }

  static String typeLabel(TransactionType t) {
    switch (t) {
      case TransactionType.debit: return 'DEBIT';
      case TransactionType.credit: return 'CREDIT';
      case TransactionType.advance: return 'ADVANCE';
      case TransactionType.balance: return 'BALANCE';
    }
  }

  static IconData typeIcon(TransactionType t) {
    switch (t) {
      case TransactionType.debit: return Icons.arrow_upward_rounded;
      case TransactionType.credit: return Icons.arrow_downward_rounded;
      case TransactionType.advance: return Icons.account_balance_wallet_rounded;
      case TransactionType.balance: return Icons.balance_rounded;
    }
  }
}

// ─── MAIN SCREEN ──────────────────────────────────────────────────────────────

class ClientStatementsScreen extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  const ClientStatementsScreen({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  State<ClientStatementsScreen> createState() => _ClientStatementsScreenState();
}

class _ClientStatementsScreenState extends State<ClientStatementsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Client? _selectedClient;
  bool _dropdownOpen = false;
  final _currencyFormatter = NumberFormat('#,##0.00', 'en_IN');

  List<Statement> get _statements =>
      _selectedClient == null ? [] : (clientStatements[_selectedClient!.id] ?? []);

  double get _totalDebit => _statements
      .where((s) => s.type == TransactionType.debit)
      .fold(0, (sum, s) => sum + s.amount);

  double get _totalCredit => _statements
      .where((s) => s.type == TransactionType.credit || s.type == TransactionType.advance)
      .fold(0, (sum, s) => sum + s.amount);

  double get _closingBalance =>
      _statements.isEmpty ? 0 : _statements.last.runningBalance;

  String _fmt(double v) => '₹${_currencyFormatter.format(v)}';

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isTablet = w >= 600;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: CSTheme.background,
      drawer: AppDrawer(
        selectedIndex: widget.selectedIndex,
        onItemSelected: (i) {
          widget.onItemSelected(i);
          Navigator.pop(context);
        },
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: isTablet
            ? null
            : IconButton(
                icon: const Icon(Icons.menu_rounded, color: Color(0xFF374151)),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Client Statements',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            Text(
              'Timeline ledger of debits, credits, and balances.',
              style: TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
            ),
          ],
        ),
        actions: isTablet
            ? [
                _TopBtn(Icons.print_outlined, 'Print Ledger', onTap: () {}),
                _TopBtn(Icons.download_outlined, 'Export CSV', onTap: _exportCSV),
                _TopBtn(Icons.email_outlined, 'Email', onTap: _emailStatement),
                Padding(
                  padding: const EdgeInsets.only(right: 12, left: 4),
                  child: ElevatedButton.icon(
                    onPressed: _showRecordPaymentDialog,
                    icon: const Icon(Icons.add, size: 14, color: Colors.white),
                    label: const Text('Record Payment', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CSTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      elevation: 0,
                    ),
                  ),
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF374151)),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (ctx) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.print_outlined, color: CSTheme.textPrimary),
                              title: const Text('Print Ledger'),
                              onTap: () { Navigator.pop(ctx); },
                            ),
                            ListTile(
                              leading: const Icon(Icons.download_outlined, color: CSTheme.textPrimary),
                              title: const Text('Export CSV'),
                              onTap: () { Navigator.pop(ctx); _exportCSV(); },
                            ),
                            ListTile(
                              leading: const Icon(Icons.email_outlined, color: CSTheme.textPrimary),
                              title: const Text('Email Statement'),
                              onTap: () { Navigator.pop(ctx); _emailStatement(); },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: CSTheme.primary, size: 28),
                  onPressed: _showRecordPaymentDialog,
                ),
              ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: CSTheme.primary,
        onPressed: () => _showRecordPaymentDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () { if (_dropdownOpen) setState(() => _dropdownOpen = false); },
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isTablet ? 20 : 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildClientSelector(isTablet),
                      const SizedBox(height: 20),
                      if (_selectedClient == null)
                        _buildEmptyState()
                      else ...[
                        _buildSummaryCards(isTablet),
                        const SizedBox(height: 16),
                        _buildStatementsList(isTablet),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // ── CLIENT SELECTOR ─────────────────────────────────────────────────────────

  Widget _buildClientSelector(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('SELECT ACTIVE CLIENT',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
              color: CSTheme.textSecondary, letterSpacing: 0.8)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _dropdownOpen = !_dropdownOpen),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _dropdownOpen ? CSTheme.primary : CSTheme.border,
                          width: _dropdownOpen ? 2 : 1,
                        ),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                      ),
                      child: Row(
                        children: [
                          if (_selectedClient != null) ...[
                            _avatar(_selectedClient!.name),
                            const SizedBox(width: 8),
                          ] else
                            const Icon(Icons.person_search_rounded, size: 16, color: CSTheme.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _selectedClient == null
                                  ? 'Choose a client...'
                                  : '${_selectedClient!.name} (${_selectedClient!.email})',
                              style: TextStyle(
                                fontSize: 14,
                                color: _selectedClient == null ? const Color(0xFF94A3B8) : CSTheme.textPrimary,
                                fontWeight: _selectedClient == null ? FontWeight.normal : FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          AnimatedRotation(
                            turns: _dropdownOpen ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: const Icon(Icons.keyboard_arrow_down_rounded, color: CSTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_dropdownOpen)
                    Positioned(
                      top: 52,
                      left: 0,
                      right: 0,
                      child: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(10),
                        shadowColor: Colors.black.withOpacity(0.12),
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 220),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: CSTheme.border),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              children: sampleClients.map((c) => _dropdownItem(c)).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_selectedClient != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() { _selectedClient = null; _dropdownOpen = false; }),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: CSTheme.border),
                  ),
                  child: const Icon(Icons.close_rounded, size: 16, color: CSTheme.textSecondary),
                ),
              ),
            ],
          ],
        ),
        if (_selectedClient == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Select a client context to generate double-entry ledgers.',
              style: TextStyle(fontSize: 11, color: CSTheme.textSecondary, fontStyle: FontStyle.italic)),
          ),
      ],
    );
  }

  Widget _dropdownItem(Client client) {
    final isSelected = _selectedClient?.id == client.id;
    return GestureDetector(
      onTap: () => setState(() { _selectedClient = client; _dropdownOpen = false; }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? CSTheme.primary.withOpacity(0.08) : Colors.transparent,
          borderRadius: isSelected ? BorderRadius.circular(8) : null,
        ),
        child: Row(
          children: [
            _avatar(client.name),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(client.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: isSelected ? CSTheme.primary : CSTheme.textPrimary)),
                  Text(client.email, style: TextStyle(fontSize: 11, color: CSTheme.textSecondary)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle_rounded, size: 16, color: CSTheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _avatar(String name) {
    final initials = name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join();
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [CSTheme.primary, CSTheme.primaryDark]),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(child: Text(initials, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700))),
    );
  }

  // ── EMPTY STATE ─────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        color: CSTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CSTheme.border),
      ),
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              border: Border.all(color: CSTheme.border, width: 2),
            ),
            child: const Icon(Icons.help_outline_rounded, size: 30, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 16),
          const Text('No Ledger Selected',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: CSTheme.textPrimary)),
          const SizedBox(height: 6),
          const Text(
            'Please choose a customer from the dropdown selector\nabove to analyze their real-time chronological\nERP accounting statements.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: CSTheme.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── SUMMARY CARDS ───────────────────────────────────────────────────────────

  Widget _buildSummaryCards(bool isTablet) {
    final cards = [
      _SummaryData('Total Debits', _fmt(_totalDebit), Icons.arrow_circle_up_rounded, CSTheme.debitColor),
      _SummaryData('Total Credits', _fmt(_totalCredit), Icons.arrow_circle_down_rounded, CSTheme.creditColor),
      _SummaryData('Closing Balance', _fmt(_closingBalance), Icons.account_balance_rounded, CSTheme.balanceColor),
      _SummaryData('Transactions', '${_statements.length}', Icons.receipt_long_rounded, CSTheme.primary),
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    double aspect = isTablet ? 1.6 : (screenWidth < 360 ? 1.25 : 1.4);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 4 : 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: aspect,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) => _summaryCard(cards[i]),
    );
  }

  Widget _summaryCard(_SummaryData d) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CSTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CSTheme.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: d.color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(d.icon, size: 18, color: d.color),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(d.value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: d.color), overflow: TextOverflow.ellipsis),
              Text(d.label, style: const TextStyle(fontSize: 11, color: CSTheme.textSecondary), overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }

  // ── STATEMENTS LIST ─────────────────────────────────────────────────────────

  Widget _buildStatementsList(bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: CSTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CSTheme.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        children: [
          _statementsHeader(),
          const Divider(height: 1, color: CSTheme.border),
          if (isTablet) _tableHeader(),
          if (isTablet) const Divider(height: 1, color: CSTheme.border),
          ..._statements.asMap().entries.map((entry) =>
              isTablet
                  ? _tableRow(entry.value, entry.key)
                  : _mobileStatementRow(entry.value, entry.key)),
          _balanceSummaryRow(),
        ],
      ),
    );
  }

  Widget _statementsHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: CSTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.receipt_long_rounded, color: CSTheme.primary, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_selectedClient!.name} — Ledger',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: CSTheme.textPrimary),
                  overflow: TextOverflow.ellipsis),
                Text('${_statements.length} transactions found',
                  style: const TextStyle(fontSize: 11, color: CSTheme.textSecondary),
                  overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          GestureDetector(
            onTap: _exportCSV,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(border: Border.all(color: CSTheme.border), borderRadius: BorderRadius.circular(8)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.download_outlined, size: 13, color: CSTheme.textSecondary),
                SizedBox(width: 4),
                Text('Export', style: TextStyle(fontSize: 11, color: CSTheme.textSecondary)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader() {
    final cols = ['Date', 'Description', 'Ref#', 'Type', 'Amount', 'Balance'];
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: cols.map((c) => Expanded(
          flex: c == 'Description' ? 3 : 2,
          child: Text(c, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
              color: CSTheme.textSecondary, letterSpacing: 0.5)),
        )).toList(),
      ),
    );
  }

  Widget _tableRow(Statement s, int index) {
    final color = CSTheme.typeColor(s.type);
    return GestureDetector(
      onTap: () => _showStatementDetail(s),
      child: Container(
        decoration: BoxDecoration(
          color: index.isEven ? Colors.white : const Color(0xFFFAFAFF),
          border: const Border(bottom: BorderSide(color: CSTheme.border)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(flex: 2, child: Text(DateFormat('dd MMM yy').format(s.date),
                style: const TextStyle(fontSize: 12, color: CSTheme.textSecondary))),
            Expanded(flex: 3, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.description, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CSTheme.textPrimary), overflow: TextOverflow.ellipsis),
                if (s.projectName != null)
                  Text(s.projectName!, style: const TextStyle(fontSize: 10, color: CSTheme.textSecondary), overflow: TextOverflow.ellipsis),
              ],
            )),
            Expanded(flex: 2, child: Text(s.reference ?? '—',
                style: const TextStyle(fontSize: 11, color: CSTheme.textSecondary), overflow: TextOverflow.ellipsis)),
            Expanded(flex: 2, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(CSTheme.typeLabel(s.type),
                  style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
            )),
            Expanded(flex: 2, child: Text(_fmt(s.amount),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis)),
            Expanded(flex: 2, child: Text(_fmt(s.runningBalance),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CSTheme.textPrimary), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }

  Widget _mobileStatementRow(Statement s, int index) {
    final color = CSTheme.typeColor(s.type);
    return GestureDetector(
      onTap: () => _showStatementDetail(s),
      child: Container(
        decoration: BoxDecoration(
          color: index.isEven ? Colors.white : const Color(0xFFFAFAFF),
          border: const Border(bottom: BorderSide(color: CSTheme.border)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(CSTheme.typeIcon(s.type), size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.description, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CSTheme.textPrimary), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text(CSTheme.typeLabel(s.type), style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w700)),
                      ),
                      Text(DateFormat('dd MMM yyyy').format(s.date), style: const TextStyle(fontSize: 10, color: CSTheme.textSecondary)),
                      if (s.reference != null)
                        Text('• ${s.reference}', style: const TextStyle(fontSize: 10, color: CSTheme.textSecondary), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_fmt(s.amount),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
                const SizedBox(height: 2),
                Text('Bal: ${_fmt(s.runningBalance)}',
                  style: const TextStyle(fontSize: 10, color: CSTheme.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _balanceSummaryRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        border: Border(top: BorderSide(color: CSTheme.primary.withOpacity(0.2), width: 1.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_rounded, size: 16, color: CSTheme.primary),
          const SizedBox(width: 8),
          const Expanded(child: Text('Closing Balance',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: CSTheme.textPrimary))),
          Text(_fmt(_closingBalance),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _closingBalance > 0 ? CSTheme.debitColor : CSTheme.creditColor,
            )),
        ],
      ),
    );
  }

  // ── STATEMENT DETAIL BOTTOM SHEET ───────────────────────────────────────────

  void _showStatementDetail(Statement s) {
    final color = CSTheme.typeColor(s.type);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: CSTheme.border, borderRadius: BorderRadius.circular(2))),
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(CSTheme.typeIcon(s.type), color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.description, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: CSTheme.textPrimary)),
                Text(DateFormat('EEEE, dd MMMM yyyy').format(s.date),
                  style: TextStyle(fontSize: 12, color: CSTheme.textSecondary)),
              ])),
            ]),
            const SizedBox(height: 20),
            _detailRow('Type', CSTheme.typeLabel(s.type), valueColor: color),
            _detailRow('Amount', _fmt(s.amount), valueColor: color),
            _detailRow('Running Balance', _fmt(s.runningBalance)),
            if (s.reference != null) _detailRow('Reference', s.reference!),
            if (s.projectName != null) _detailRow('Project', s.projectName!),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: CSTheme.textSecondary))),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
              color: valueColor ?? CSTheme.textPrimary)),
        ],
      ),
    );
  }

  // ── RECORD PAYMENT DIALOG ───────────────────────────────────────────────────

  void _showRecordPaymentDialog() {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    TransactionType selectedType = TransactionType.credit;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: CSTheme.border, borderRadius: BorderRadius.circular(2))),
                const Text('Record Payment', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: CSTheme.textPrimary)),
                const SizedBox(height: 16),
                // Type selector
                Wrap(spacing: 8, children: TransactionType.values.take(3).map((t) {
                  final c = CSTheme.typeColor(t);
                  final selected = selectedType == t;
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedType = t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected ? c.withOpacity(0.12) : Colors.white,
                        border: Border.all(color: selected ? c : CSTheme.border, width: selected ? 1.5 : 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(CSTheme.typeLabel(t),
                        style: TextStyle(fontSize: 12, color: selected ? c : CSTheme.textSecondary, fontWeight: FontWeight.w600)),
                    ),
                  );
                }).toList()),
                const SizedBox(height: 14),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount (₹)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: CSTheme.border)),
                    prefixIcon: const Icon(Icons.currency_rupee, size: 16),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: CSTheme.border)),
                    prefixIcon: const Icon(Icons.notes_rounded, size: 16),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CSTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      // TODO: connect to your API
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payment recorded successfully!'), backgroundColor: CSTheme.creditColor),
                      );
                    },
                    child: const Text('Record Payment', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _exportCSV() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV export initiated!'), backgroundColor: CSTheme.primary),
    );
  }

  void _emailStatement() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email statement sent!'), backgroundColor: CSTheme.primary),
    );
  }
}

// ─── HELPERS ──────────────────────────────────────────────────────────────────

class _SummaryData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _SummaryData(this.label, this.value, this.icon, this.color);
}

class _TopBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TopBtn(this.icon, this.label, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14, color: CSTheme.textPrimary),
      label: Text(label, style: const TextStyle(fontSize: 12, color: CSTheme.textPrimary, fontWeight: FontWeight.w600)),
      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../widgets/app_drawer.dart';
import '../../theme/app_theme.dart';
import '../../blocs/theme/theme_bloc.dart';


import '../../services/supabase_service.dart';

// ─── MODELS ───────────────────────────────────────────────────────────────────

enum TransactionType { debit, credit, advance, balance }

class Client {
  final String id;
  final String name;
  final String email;

  const Client({required this.id, required this.name, required this.email});

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      email: json['email']?.toString() ?? '',
    );
  }
}

TransactionType _parseType(String t) {
  switch (t.toLowerCase()) {
    case 'credit': return TransactionType.credit;
    case 'advance': return TransactionType.advance;
    case 'balance': return TransactionType.balance;
    case 'debit':
    default: return TransactionType.debit;
  }
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

  factory Statement.fromJson(Map<String, dynamic> json) {
    double debit = (json['debit'] ?? json['debit_amount'] ?? json['Debit'] ?? 0).toDouble();
    double credit = (json['credit'] ?? json['credit_amount'] ?? json['Credit'] ?? 0).toDouble();
    double advance = (json['advance'] ?? json['Advance'] ?? 0).toDouble();

    TransactionType type = TransactionType.debit;
    double amount = 0;

    if (debit > 0) {
      type = TransactionType.debit;
      amount = debit;
    } else if (credit > 0) {
      type = TransactionType.credit;
      amount = credit;
    } else if (advance > 0) {
      type = TransactionType.advance;
      amount = advance;
    } else if (json['amount'] != null) {
      amount = (json['amount']).toDouble();
      type = _parseType(json['type']?.toString() ?? 'debit');
    }

    return Statement(
      id: json['id']?.toString() ?? '',
      date: json['date'] != null || json['transaction_date'] != null
          ? DateTime.tryParse((json['date'] ?? json['transaction_date']).toString()) ?? DateTime.now()
          : DateTime.now(),
      description: json['description']?.toString() ?? '',
      type: type,
      amount: amount,
      runningBalance: (json['running_balance'] ?? json['balance'] ?? 0).toDouble(),
      reference: json['reference']?.toString(),
      projectName: json['project_name']?.toString() ?? json['project_id']?.toString() ?? json['associated_project']?.toString(),
    );
  }
}

// ─── THEME ────────────────────────────────────────────────────────────────────

class CSTheme {
  static const Color primary = Color(0xFF06B6D4);
  static const Color primaryDark = Color(0xFF0891B2);
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

  List<Client> _clients = [];
  List<Statement> _statements = [];
  bool _isLoadingClients = true;
  bool _isLoadingStatements = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchClients();
  }

  Future<void> _fetchClients() async {
    try {
      final data = await SupabaseService.client.from('clients').select('id, name, email').order('name');
      if (!mounted) return;
      setState(() {
        _clients = (data as List).map((e) => Client.fromJson(e)).toList();
        _isLoadingClients = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoadingClients = false);
    }
  }

  Future<void> _fetchStatements(String clientId) async {
    setState(() { _isLoadingStatements = true; _errorMessage = null; });
    try {
      List<dynamic> data = [];
      try {
        // Try joining clients table to get the true name
        data = await SupabaseService.client
            .from('client_statements')
            .select('*, clients(name)');
      } catch (_) {
        // Fallback without join
        data = await SupabaseService.client
            .from('client_statements')
            .select();
      }

      final clientName = _selectedClient?.name.toLowerCase().trim() ?? '';
      final clientMap = { for (var c in _clients) c.id: c.name.toLowerCase().trim() };
      
      final filtered = data.where((row) {
        final rId = row['client_id']?.toString();
        final rName = row['client_name']?.toString().toLowerCase().trim();
        
        // Extract joined name if available
        final joinedClient = row['clients'];
        final joinedName = (joinedClient is Map) ? joinedClient['name']?.toString().toLowerCase().trim() : null;

        final mappedName = clientMap[rId];
        
        return rId == clientId || 
               (rName != null && rName.isNotEmpty && rName == clientName) ||
               (joinedName != null && joinedName.isNotEmpty && joinedName == clientName) ||
               (mappedName != null && mappedName.isNotEmpty && mappedName == clientName);
      }).toList();

      if (!mounted) return;
      setState(() {
        _statements = filtered.map((e) => Statement.fromJson(e)).toList();
        _statements.sort((a, b) => a.date.compareTo(b.date));
        _isLoadingStatements = false;
        
        if (_statements.isEmpty) {
           final dbIds = data.map((e) => e['client_id']).toSet().take(3).toList();
           _errorMessage = "No statements found. Target name: $clientName | DB IDs: $dbIds";
        }
      });
    } catch (e) {
      print('=== ERROR FETCHING STATEMENTS: $e ===');
      if (mounted) setState(() { 
         _isLoadingStatements = false;
         _errorMessage = e.toString();
      });
    }
  }

  double get _totalDebit => _statements
      .where((s) => s.type == TransactionType.debit)
      .fold(0, (sum, s) => sum + s.amount);

  double get _totalCredit => _statements
      .where((s) => s.type == TransactionType.credit)
      .fold(0, (sum, s) => sum + s.amount);

  double get _totalAdvance => _statements
      .where((s) => s.type == TransactionType.advance)
      .fold(0, (sum, s) => sum + s.amount);

  double get _closingBalance =>
      _statements.isEmpty ? 0 : _statements.last.runningBalance;

  String _fmt(double v) => '₹${_currencyFormatter.format(v)}';

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isTablet = w >= 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: AppDrawer(
        selectedIndex: widget.selectedIndex,
        onItemSelected: (i) {
          widget.onItemSelected(i);
          Navigator.pop(context);
        },
      ),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: isTablet
            ? null
            : IconButton(
                icon: Icon(Icons.menu_rounded, color: isDark ? Colors.white : const Color(0xFF374151)),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Client Statements',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimaryOf(context),
              ),
            ),
            Text(
              'Timeline ledger of debits, credits, and balances.',
              style: TextStyle(fontSize: 10, color: AppTheme.textSecondaryOf(context)),
            ),
          ],
        ),
        actions: [
          BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, themeState) {
              final isDarkTheme = themeState.themeMode == ThemeMode.dark;
              return IconButton(
                icon: Icon(
                  isDarkTheme ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: isDarkTheme ? Colors.white : const Color(0xFF374151),
                ),
                onPressed: () {
                  context.read<ThemeBloc>().add(ToggleThemeEvent());
                },
              );
            },
          ),
          if (isWideAction(isTablet)) ...[
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
          ] else ...[
            IconButton(
              icon: Icon(Icons.more_vert_rounded, color: isDark ? Colors.white : const Color(0xFF374151)),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => SafeArea(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.bgCardDark : Colors.white,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: Icon(Icons.print_outlined, color: AppTheme.textPrimaryOf(context)),
                            title: Text('Print Ledger', style: TextStyle(color: AppTheme.textPrimaryOf(context))),
                            onTap: () { Navigator.pop(ctx); },
                          ),
                          ListTile(
                            leading: Icon(Icons.download_outlined, color: AppTheme.textPrimaryOf(context)),
                            title: Text('Export CSV', style: TextStyle(color: AppTheme.textPrimaryOf(context))),
                            onTap: () { Navigator.pop(ctx); _exportCSV(); },
                          ),
                          ListTile(
                            leading: Icon(Icons.email_outlined, color: AppTheme.textPrimaryOf(context)),
                            title: Text('Email Statement', style: TextStyle(color: AppTheme.textPrimaryOf(context))),
                            onTap: () { Navigator.pop(ctx); _emailStatement(); },
                          ),
                        ],
                      ),
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
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.borderOf(context)),
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

  bool isWideAction(bool isTablet) => isTablet;
  // ── CLIENT SELECTOR ─────────────────────────────────────────────────────────

  Widget _buildClientSelector(bool isTablet) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SELECT ACTIVE CLIENT',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
              color: AppTheme.textSecondaryOf(context), letterSpacing: 0.8)),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _dropdownOpen = !_dropdownOpen),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.bgCardDark : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _dropdownOpen ? CSTheme.primary : AppTheme.borderOf(context),
                          width: _dropdownOpen ? 2 : 1,
                        ),
                        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                      ),
                      child: Row(
                        children: [
                          if (_selectedClient != null) ...[
                            _avatar(_selectedClient!.name),
                            const SizedBox(width: 8),
                          ] else
                            Icon(Icons.person_search_rounded, size: 16, color: AppTheme.textSecondaryOf(context)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _selectedClient == null
                                  ? 'Choose a client...'
                                  : '${_selectedClient!.name} (${_selectedClient!.email})',
                              style: TextStyle(
                                fontSize: 14,
                                color: _selectedClient == null ? const Color(0xFF94A3B8) : AppTheme.textPrimaryOf(context),
                                fontWeight: _selectedClient == null ? FontWeight.normal : FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          AnimatedRotation(
                            turns: _dropdownOpen ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textSecondaryOf(context)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_dropdownOpen) ...[
                    const SizedBox(height: 6),
                    Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(10),
                      shadowColor: Colors.black.withOpacity(0.12),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 220),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.bgCardDark : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.borderOf(context)),
                        ),
                        child: SingleChildScrollView(
                          child: _isLoadingClients 
                              ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 2)))
                              : Column(
                                  children: _clients.map((c) => _dropdownItem(c)).toList(),
                                ),
                        ),
                      ),
                    ),
                  ],
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
                    color: isDark ? AppTheme.bgCardDark : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderOf(context)),
                  ),
                  child: Icon(Icons.close_rounded, size: 16, color: AppTheme.textSecondaryOf(context)),
                ),
              ),
            ],
          ],
        ),
        if (_selectedClient == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Select a client context to generate double-entry ledgers.',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryOf(context), fontStyle: FontStyle.italic)),
          ),
      ],
    );
  }

  Widget _dropdownItem(Client client) {
    final isSelected = _selectedClient?.id == client.id;
    return GestureDetector(
      onTap: () { 
        setState(() { _selectedClient = client; _dropdownOpen = false; }); 
        _fetchStatements(client.id);
      },
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
                      color: isSelected ? CSTheme.primary : AppTheme.textPrimaryOf(context))),
                  Text(client.email, style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryOf(context))),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.borderOf(context), width: 2),
            ),
            child: Icon(Icons.help_outline_rounded, size: 30, color: AppTheme.textMutedOf(context)),
          ),
          const SizedBox(height: 16),
          Text('No Ledger Selected',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryOf(context))),
          const SizedBox(height: 6),
          Text(
            'Please choose a customer from the dropdown selector\nabove to analyze their real-time chronological\nERP accounting statements.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryOf(context), height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── SUMMARY CARDS ───────────────────────────────────────────────────────────

  Widget _buildSummaryCards(bool isTablet) {
    if (_isLoadingStatements) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final double overdue = _totalDebit - _totalCredit - _totalAdvance;
    final overdueVal = overdue > 0 ? overdue : 0.0;

    final cards = [
      _SummaryData('Total Invoiced', _fmt(_totalDebit), Icons.arrow_circle_up_rounded, CSTheme.debitColor),
      _SummaryData('Total Received', _fmt(_totalCredit), Icons.arrow_circle_down_rounded, CSTheme.creditColor),
      _SummaryData('Advance Credit', _fmt(_totalAdvance), Icons.account_balance_wallet_rounded, CSTheme.advanceColor),
      _SummaryData('Overdue Unpaid', _fmt(overdueVal), Icons.warning_amber_rounded, const Color(0xFFEAB308)),
      _SummaryData('Outstanding Balance', _fmt(_closingBalance), Icons.account_balance_rounded, CSTheme.balanceColor),
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    double aspect = isTablet ? 1.6 : (screenWidth < 360 ? 1.25 : 1.4);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 5 : 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: aspect,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) => _summaryCard(cards[i]),
    );
  }

  Widget _summaryCard(_SummaryData d) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderOf(context)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
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
              Text(d.label, style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryOf(context)), overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }

  // ── STATEMENTS LIST ─────────────────────────────────────────────────────────

  Widget _buildStatementsList(bool isTablet) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_isLoadingStatements) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.bgCardDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderOf(context)),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderOf(context)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        children: [
          _statementsHeader(),
          Divider(height: 1, color: AppTheme.borderOf(context)),
          if (isTablet) _tableHeader(),
          if (isTablet) Divider(height: 1, color: AppTheme.borderOf(context)),
          if (_errorMessage != null)
             Padding(
               padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
               child: Center(child: Text('Error: $_errorMessage', style: const TextStyle(color: Colors.red))),
             ),
          if (_statements.isEmpty && _errorMessage == null)
             const Padding(
               padding: EdgeInsets.symmetric(vertical: 40),
               child: Center(child: Text('No statements found for this client.')),
             ),
          ..._statements.asMap().entries.map((entry) =>
              isTablet
                  ? _tableRow(entry.value, entry.key)
                  : _mobileStatementRow(entry.value, entry.key)),
          if (_statements.isNotEmpty)
            _balanceSummaryRow(),
        ],
      ),
    );
  }

  Widget _statementsHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryOf(context)),
                  overflow: TextOverflow.ellipsis),
                Text('${_statements.length} transactions found',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryOf(context)),
                  overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          GestureDetector(
            onTap: _exportCSV,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(border: Border.all(color: AppTheme.borderOf(context)), borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.download_outlined, size: 13, color: AppTheme.textSecondaryOf(context)),
                const SizedBox(width: 4),
                Text('Export', style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryOf(context))),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cols = ['Date', 'Description', 'Ref#', 'Type', 'Amount', 'Balance'];
    return Container(
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: cols.map((c) => Expanded(
          flex: c == 'Description' ? 3 : 2,
          child: Text(c, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
              color: AppTheme.textSecondaryOf(context), letterSpacing: 0.5)),
        )).toList(),
      ),
    );
  }

  Widget _tableRow(Statement s, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = CSTheme.typeColor(s.type);
    return GestureDetector(
      onTap: () => _showStatementDetail(s),
      child: Container(
        decoration: BoxDecoration(
          color: index.isEven
              ? (isDark ? AppTheme.bgCardDark : Colors.white)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFF)),
          border: Border(bottom: BorderSide(color: AppTheme.borderOf(context))),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(flex: 2, child: Text(DateFormat('dd MMM yy').format(s.date),
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryOf(context)))),
            Expanded(flex: 3, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.description, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimaryOf(context)), overflow: TextOverflow.ellipsis),
                if (s.projectName != null)
                  Text(s.projectName!, style: TextStyle(fontSize: 10, color: AppTheme.textSecondaryOf(context)), overflow: TextOverflow.ellipsis),
              ],
            )),
            Expanded(flex: 2, child: Text(s.reference ?? '—',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryOf(context)), overflow: TextOverflow.ellipsis)),
            Expanded(flex: 2, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(CSTheme.typeLabel(s.type),
                  style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
            )),
            Expanded(flex: 2, child: Text(_fmt(s.amount),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis)),
            Expanded(flex: 2, child: Text(_fmt(s.runningBalance),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimaryOf(context)), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }

  Widget _mobileStatementRow(Statement s, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = CSTheme.typeColor(s.type);
    return GestureDetector(
      onTap: () => _showStatementDetail(s),
      child: Container(
        decoration: BoxDecoration(
          color: index.isEven
              ? (isDark ? AppTheme.bgCardDark : Colors.white)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFF)),
          border: Border(bottom: BorderSide(color: AppTheme.borderOf(context))),
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
                  Text(s.description, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimaryOf(context)), overflow: TextOverflow.ellipsis),
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
                      Text(DateFormat('dd MMM yyyy').format(s.date), style: TextStyle(fontSize: 10, color: AppTheme.textSecondaryOf(context))),
                      if (s.reference != null)
                        Text('• ${s.reference}', style: TextStyle(fontSize: 10, color: AppTheme.textSecondaryOf(context)), overflow: TextOverflow.ellipsis),
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
                  style: TextStyle(fontSize: 10, color: AppTheme.textSecondaryOf(context))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _balanceSummaryRow() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0C2C30) : const Color(0xFFF0F9FF),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        border: Border(top: BorderSide(color: CSTheme.primary.withOpacity(0.2), width: 1.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_rounded, size: 16, color: CSTheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text('Closing Balance',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryOf(context)))),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.bgCardDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: AppTheme.borderOf(context), borderRadius: BorderRadius.circular(2))),
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(CSTheme.typeIcon(s.type), color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.description, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryOf(context))),
                Text(DateFormat('EEEE, dd MMMM yyyy').format(s.date),
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryOf(context))),
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
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryOf(context)))),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
              color: valueColor ?? AppTheme.textPrimaryOf(context))),
        ],
      ),
    );
  }

  // ── RECORD PAYMENT DIALOG ───────────────────────────────────────────────────

  void _showRecordPaymentDialog() {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    TransactionType selectedType = TransactionType.credit;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.bgCardDark : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: AppTheme.borderOf(context), borderRadius: BorderRadius.circular(2))),
                Text('Record Payment', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryOf(context))),
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
                        color: selected ? c.withOpacity(0.12) : (isDark ? AppTheme.bgCardDark : Colors.white),
                        border: Border.all(color: selected ? c : AppTheme.borderOf(context), width: selected ? 1.5 : 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(CSTheme.typeLabel(t),
                        style: TextStyle(fontSize: 12, color: selected ? c : AppTheme.textSecondaryOf(context), fontWeight: FontWeight.w600)),
                    ),
                  );
                }).toList()),
                const SizedBox(height: 14),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context)),
                  decoration: InputDecoration(
                    labelText: 'Amount (₹)',
                    labelStyle: TextStyle(color: AppTheme.textSecondaryOf(context), fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.borderOf(context))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.borderOf(context))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: CSTheme.primary, width: 1.5)),
                    prefixIcon: Icon(Icons.currency_rupee, size: 16, color: AppTheme.textSecondaryOf(context)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context)),
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(color: AppTheme.textSecondaryOf(context), fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.borderOf(context))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.borderOf(context))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: CSTheme.primary, width: 1.5)),
                    prefixIcon: Icon(Icons.notes_rounded, size: 16, color: AppTheme.textSecondaryOf(context)),
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
                      // TODO: connect to your ERP API
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
      icon: Icon(icon, size: 14, color: AppTheme.textPrimaryOf(context)),
      label: Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textPrimaryOf(context), fontWeight: FontWeight.w600)),
      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
    );
  }
}
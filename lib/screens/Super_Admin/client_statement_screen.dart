import 'package:ecraftz_crm/widgets/app_refresh_button.dart';
import 'package:ecraftz_crm/widgets/app_snackbar.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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
    case 'credit':
      return TransactionType.credit;
    case 'advance':
      return TransactionType.advance;
    case 'balance':
      return TransactionType.balance;
    case 'debit':
    default:
      return TransactionType.debit;
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
  final String? status;

  const Statement({
    required this.id,
    required this.date,
    required this.description,
    required this.type,
    required this.amount,
    required this.runningBalance,
    this.reference,
    this.projectName,
    this.status,
  });

  Statement copyWith({
    String? id,
    DateTime? date,
    String? description,
    TransactionType? type,
    double? amount,
    double? runningBalance,
    String? reference,
    String? projectName,
    String? status,
  }) {
    return Statement(
      id: id ?? this.id,
      date: date ?? this.date,
      description: description ?? this.description,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      runningBalance: runningBalance ?? this.runningBalance,
      reference: reference ?? this.reference,
      projectName: projectName ?? this.projectName,
      status: status ?? this.status,
    );
  }

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

    final docNum = json['document_number'] ?? json['reference'] ?? json['document_id'];

    return Statement(
      id: json['id']?.toString() ?? '',
      date: json['transaction_date'] != null || json['date'] != null || json['created_at'] != null
          ? DateTime.tryParse((json['transaction_date'] ?? json['date'] ?? json['created_at']).toString()) ?? DateTime.now()
          : DateTime.now(),
      description: json['description']?.toString() ?? '',
      type: type,
      amount: amount,
      runningBalance: (json['running_balance'] ?? json['balance'] ?? 0).toDouble(),
      reference: docNum?.toString(),
      projectName: json['project_name']?.toString() ?? json['project_id']?.toString() ?? json['associated_project']?.toString(),
      status: json['status']?.toString(),
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
      case TransactionType.debit:
        return debitColor;
      case TransactionType.credit:
        return creditColor;
      case TransactionType.advance:
        return advanceColor;
      case TransactionType.balance:
        return balanceColor;
    }
  }

  static String typeLabel(TransactionType t) {
    switch (t) {
      case TransactionType.debit:
        return 'DEBIT';
      case TransactionType.credit:
        return 'CREDIT';
      case TransactionType.advance:
        return 'ADVANCE';
      case TransactionType.balance:
        return 'BALANCE';
    }
  }

  static IconData typeIcon(TransactionType t) {
    switch (t) {
      case TransactionType.debit:
        return Icons.arrow_upward_rounded;
      case TransactionType.credit:
        return Icons.arrow_downward_rounded;
      case TransactionType.advance:
        return Icons.account_balance_wallet_rounded;
      case TransactionType.balance:
        return Icons.balance_rounded;
    }
  }
}

// ─── NUMBER TO RUPEE WORDS HELPER ─────────────────────────────────────────────

String _numberToRupeeWords(double amount) {
  if (amount <= 0) return 'Rupees Zero Only';
  int number = amount.floor();
  int paise = ((amount - number) * 100).round();

  String words = _convertChunk(number);
  String result = 'Rupees $words';
  if (paise > 0) {
    result += ' and ${_convertChunk(paise)} Paise';
  }
  return '$result Only';
}

String _convertChunk(int n) {
  if (n == 0) return 'Zero';
  final units = [
    '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
    'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
    'Seventeen', 'Eighteen', 'Nineteen'
  ];
  final tens = [
    '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
  ];

  if (n < 20) return units[n];
  if (n < 100) return '${tens[n ~/ 10]}${n % 10 != 0 ? " ${units[n % 10]}" : ""}';
  if (n < 1000) return '${units[n ~/ 100]} Hundred${n % 100 != 0 ? " ${_convertChunk(n % 100)}" : ""}';
  if (n < 100000) return '${_convertChunk(n ~/ 1000)} Thousand${n % 1000 != 0 ? " ${_convertChunk(n % 1000)}" : ""}';
  if (n < 10000000) return '${_convertChunk(n ~/ 100000)} Lakh${n % 100000 != 0 ? " ${_convertChunk(n % 100000)}" : ""}';
  return '${_convertChunk(n ~/ 10000000)} Crore${n % 10000000 != 0 ? " ${_convertChunk(n % 10000000)}" : ""}';
}

// ─── MAIN SCREEN ──────────────────────────────────────────────────────────────

class ClientStatementsScreen extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool showAppBar;
  const ClientStatementsScreen({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.showAppBar = true,
  });

  @override
  State<ClientStatementsScreen> createState() => _ClientStatementsScreenState();
}

class _ClientStatementsScreenState extends State<ClientStatementsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Client? _selectedClient;
  bool _dropdownOpen = false;
  final TextEditingController _clientSearchCtrl = TextEditingController();
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

  @override
  void dispose() {
    _clientSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchClients() async {
    try {
      final data = await SupabaseService.client
          .from('clients')
          .select('id, name, email')
          .order('name');
      if (!mounted) return;

      final loadedClients = (data as List).map((e) => Client.fromJson(e)).toList();

      final Map<String, Client> uniqueMap = {};
      for (final c in loadedClients) {
        final key = c.name.trim().toLowerCase();
        if (!uniqueMap.containsKey(key)) {
          uniqueMap[key] = c;
        }
      }

      setState(() {
        _clients = uniqueMap.values.toList();
        _clients.sort((a, b) => a.name.compareTo(b.name));
        _isLoadingClients = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingClients = false);
    }
  }

  Future<void> _fetchStatements(String clientId) async {
    setState(() {
      _isLoadingStatements = true;
      _errorMessage = null;
    });

    try {
      final selectedClient = _selectedClient;
      if (selectedClient == null) {
        if (mounted) {
          setState(() {
            _statements = [];
            _isLoadingStatements = false;
          });
        }
        return;
      }

      final clientName = selectedClient.name.trim().toLowerCase();

      final Set<String> matchingClientIds = {clientId};
      try {
        final dbClients = await SupabaseService.client
            .from('clients')
            .select('id, name');
        for (final c in dbClients) {
          final cName = c['name']?.toString().trim().toLowerCase() ?? '';
          if (cName == clientName) {
            matchingClientIds.add(c['id'].toString());
          }
        }
      } catch (_) {}

      List<dynamic> statementRows = [];
      try {
        final csData = await SupabaseService.client
            .from('client_statements')
            .select('*')
            .filter('deleted_at', 'is', null);
        statementRows = csData as List;
      } catch (_) {}

      final List<Statement> parsedStatements = [];
      final Set<String> existingDocNumbers = {};

      for (final row in statementRows) {
        final rId = row['client_id']?.toString();
        final rName = row['client_name']?.toString().toLowerCase().trim();
        final mappedName = _clients
            .firstWhere((c) => c.id == rId,
                orElse: () => const Client(id: '', name: '', email: ''))
            .name
            .toLowerCase()
            .trim();

        if (matchingClientIds.contains(rId) ||
            rId == clientId ||
            (rName != null && rName == clientName) ||
            (mappedName.isNotEmpty && mappedName == clientName)) {
          final st = Statement.fromJson(row);
          parsedStatements.add(st);
          if (st.reference != null && st.reference!.isNotEmpty) {
            existingDocNumbers.add(st.reference!.toLowerCase().trim());
          }
          if (row['document_number'] != null) {
            existingDocNumbers.add(row['document_number'].toString().toLowerCase().trim());
          }
        }
      }

      List<dynamic> invoiceRows = [];
      try {
        final invData = await SupabaseService.client
            .from('invoices')
            .select('*');
        invoiceRows = invData as List;
      } catch (_) {}

      for (final inv in invoiceRows) {
        final invClientId = inv['client_id']?.toString();
        final invClientName = inv['client_name']?.toString().toLowerCase().trim();
        final invNum = inv['invoice_number']?.toString() ?? '';
        final invStatus = inv['status']?.toString().toLowerCase() ?? '';

        final matchesClient = matchingClientIds.contains(invClientId) ||
            invClientId == clientId ||
            (invClientName != null && invClientName == clientName);

        if (matchesClient && invStatus != 'cancelled' && invStatus != 'draft') {
          final docKey = invNum.toLowerCase().trim();
          if (docKey.isNotEmpty && existingDocNumbers.contains(docKey)) {
            continue;
          }

          final double amount = (inv['grand_total'] ?? inv['subtotal'] ?? 0).toDouble();
          final DateTime invDate = DateTime.tryParse(
                  inv['date']?.toString() ?? inv['created_at']?.toString() ?? '') ??
              DateTime.now();

          parsedStatements.add(Statement(
            id: inv['id']?.toString() ?? '',
            date: invDate,
            description: 'Invoice generated: $invNum',
            type: TransactionType.debit,
            amount: amount,
            runningBalance: 0,
            reference: invNum,
            status: invStatus,
          ));
        }
      }

      parsedStatements.sort((a, b) => a.date.compareTo(b.date));

      double running = 0.0;
      final List<Statement> finalLedger = [];
      for (final s in parsedStatements) {
        if (s.type == TransactionType.debit) {
          running += s.amount;
        } else if (s.type == TransactionType.credit || s.type == TransactionType.advance) {
          running -= s.amount;
        }
        finalLedger.add(s.copyWith(runningBalance: running));
      }

      if (!mounted) return;
      setState(() {
        _statements = finalLedger;
        _isLoadingStatements = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStatements = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  double get _totalDebit => _statements
      .where((s) => s.type == TransactionType.debit)
      .fold(0.0, (sum, s) => sum + s.amount);

  double get _totalCredit => _statements
      .where((s) => s.type == TransactionType.credit)
      .fold(0.0, (sum, s) => sum + s.amount);

  double get _totalAdvance => _statements
      .where((s) => s.type == TransactionType.advance)
      .fold(0.0, (sum, s) => sum + s.amount);

  double get _closingBalance => _totalDebit - _totalCredit - _totalAdvance;

  String _fmt(double v) => '₹${_currencyFormatter.format(v)}';

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isTablet = w >= 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: widget.showAppBar
          ? AppDrawer(
              selectedIndex: widget.selectedIndex,
              onItemSelected: (i) {
                widget.onItemSelected(i);
                Navigator.pop(context);
              },
            )
          : null,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: Theme.of(context).colorScheme.surface,
              elevation: 0,
              leading: isTablet
                  ? null
                  : IconButton(
                      icon: Icon(Icons.menu_rounded,
                          color: isDark ? Colors.white : const Color(0xFF374151)),
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
                    style: TextStyle(
                        fontSize: 10, color: AppTheme.textSecondaryOf(context)),
                  ),
                ],
              ),
              actions: [
          AppRefreshButton(
            onRefresh: () async {
              await _fetchClients();
              if (_selectedClient != null) {
                await _fetchStatements(_selectedClient!.id);
              }
              await Future.delayed(const Duration(milliseconds: 600));
            },
          ),
          const SizedBox(width: 4),
                BlocBuilder<ThemeBloc, ThemeState>(
                  builder: (context, themeState) {
                    final isDarkTheme = themeState.themeMode == ThemeMode.dark;
                    return IconButton(
                      icon: Icon(
                        isDarkTheme
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        color: isDarkTheme ? Colors.white : const Color(0xFF374151),
                      ),
                      onPressed: () {
                        context.read<ThemeBloc>().add(ToggleThemeEvent());
                      },
                    );
                  },
                ),
                if (isWideAction(isTablet)) ...[
                  _TopBtn(Icons.print_outlined, 'Print Ledger', onTap: _showStatementTemplateDialog),
                  _TopBtn(Icons.download_outlined, 'Export', onTap: _showStatementTemplateDialog),
                  _TopBtn(Icons.email_outlined, 'Email', onTap: _emailStatement),
                  Padding(
                    padding: const EdgeInsets.only(right: 12, left: 4),
                    child: ElevatedButton.icon(
                      onPressed: _showRecordPaymentDialog,
                      icon: const Icon(Icons.add, size: 14, color: Colors.white),
                      label: const Text('Record Payment',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CSTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        elevation: 0,
                      ),
                    ),
                  ),
                ] else ...[
                  IconButton(
                    icon: Icon(Icons.more_vert_rounded,
                        color: isDark ? Colors.white : const Color(0xFF374151)),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => SafeArea(
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.bgCardDark : Colors.white,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(20)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: Icon(Icons.visibility_outlined,
                                      color: AppTheme.textPrimaryOf(context)),
                                  title: Text('View Statement Template',
                                      style: TextStyle(
                                          color: AppTheme.textPrimaryOf(context))),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _showStatementTemplateDialog();
                                  },
                                ),
                                ListTile(
                                  leading: Icon(Icons.print_outlined,
                                      color: AppTheme.textPrimaryOf(context)),
                                  title: Text('Print Ledger',
                                      style: TextStyle(
                                          color: AppTheme.textPrimaryOf(context))),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _printPdf();
                                  },
                                ),
                                ListTile(
                                  leading: Icon(Icons.download_outlined,
                                      color: AppTheme.textPrimaryOf(context)),
                                  title: Text('Export CSV',
                                      style: TextStyle(
                                          color: AppTheme.textPrimaryOf(context))),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _exportCSV();
                                  },
                                ),
                                ListTile(
                                  leading: Icon(Icons.email_outlined,
                                      color: AppTheme.textPrimaryOf(context)),
                                  title: Text('Email Statement',
                                      style: TextStyle(
                                          color: AppTheme.textPrimaryOf(context))),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _emailStatement();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle,
                        color: CSTheme.primary, size: 28),
                    onPressed: _showRecordPaymentDialog,
                  ),
                ],
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(height: 1, color: AppTheme.borderOf(context)),
              ),
            )
          : null,
      floatingActionButton: FloatingActionButton(
        backgroundColor: CSTheme.primary,
        onPressed: () => _showRecordPaymentDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            if (_dropdownOpen) setState(() => _dropdownOpen = false);
          },
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

  // ── CLIENT SELECTOR WITH SEARCH ─────────────────────────────────────────────

  Widget _buildClientSelector(bool isTablet) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final query = _clientSearchCtrl.text.trim().toLowerCase();
    final filteredClients = _clients.where((c) {
      return c.name.toLowerCase().contains(query) || c.email.toLowerCase().contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SELECT ACTIVE CLIENT',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondaryOf(context),
                letterSpacing: 0.8)),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.bgCardDark : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _dropdownOpen
                              ? CSTheme.primary
                              : AppTheme.borderOf(context),
                          width: _dropdownOpen ? 2 : 1,
                        ),
                        boxShadow: isDark
                            ? []
                            : [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8)
                              ],
                      ),
                      child: Row(
                        children: [
                          if (_selectedClient != null) ...[
                            _avatar(_selectedClient!.name),
                            const SizedBox(width: 8),
                          ] else
                            Icon(Icons.person_search_rounded,
                                size: 16,
                                color: AppTheme.textSecondaryOf(context)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _selectedClient == null
                                  ? 'Choose a client...'
                                  : _selectedClient!.email.isNotEmpty
                                      ? '${_selectedClient!.name} (${_selectedClient!.email})'
                                      : _selectedClient!.name,
                              style: TextStyle(
                                fontSize: 14,
                                color: _selectedClient == null
                                    ? const Color(0xFF94A3B8)
                                    : AppTheme.textPrimaryOf(context),
                                fontWeight: _selectedClient == null
                                    ? FontWeight.normal
                                    : FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          AnimatedRotation(
                            turns: _dropdownOpen ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(Icons.keyboard_arrow_down_rounded,
                                color: AppTheme.textSecondaryOf(context)),
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
                      shadowColor: Colors.black.withValues(alpha: 0.12),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 280),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.bgCardDark : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.borderOf(context)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 🔍 CLIENT SEARCH INPUT FIELD
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextField(
                                controller: _clientSearchCtrl,
                                onChanged: (_) => setState(() {}),
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textPrimaryOf(context)),
                                decoration: InputDecoration(
                                  hintText: 'Search client name or email...',
                                  hintStyle: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondaryOf(context)),
                                  prefixIcon: Icon(Icons.search,
                                      size: 18,
                                      color: AppTheme.textSecondaryOf(context)),
                                  suffixIcon: _clientSearchCtrl.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 16),
                                          onPressed: () {
                                            _clientSearchCtrl.clear();
                                            setState(() {});
                                          },
                                        )
                                      : null,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                          color: AppTheme.borderOf(context))),
                                  focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                          color: CSTheme.primary, width: 1.5)),
                                ),
                              ),
                            ),
                            Divider(height: 1, color: AppTheme.borderOf(context)),
                            Flexible(
                              child: SingleChildScrollView(
                                child: _isLoadingClients
                                    ? const Center(
                                        child: Padding(
                                            padding: EdgeInsets.all(20),
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2)))
                                    : filteredClients.isEmpty
                                        ? Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Text(
                                              'No matching clients found',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppTheme
                                                      .textSecondaryOf(context)),
                                            ),
                                          )
                                        : Column(
                                            children: filteredClients
                                                .map((c) => _dropdownItem(c))
                                                .toList(),
                                          ),
                              ),
                            ),
                          ],
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
                onTap: () => setState(() {
                  _selectedClient = null;
                  _dropdownOpen = false;
                  _clientSearchCtrl.clear();
                }),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.bgCardDark : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderOf(context)),
                  ),
                  child: Icon(Icons.close_rounded,
                      size: 16, color: AppTheme.textSecondaryOf(context)),
                ),
              ),
            ],
          ],
        ),
        if (_selectedClient == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
                'Select a client context to generate double-entry ledgers.',
                style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondaryOf(context),
                    fontStyle: FontStyle.italic)),
          ),
      ],
    );
  }

  Widget _dropdownItem(Client client) {
    final isSelected = _selectedClient?.id == client.id;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedClient = client;
          _dropdownOpen = false;
        });
        _fetchStatements(client.id);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? CSTheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
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
                  Text(client.name,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? CSTheme.primary
                              : AppTheme.textPrimaryOf(context))),
                  if (client.email.isNotEmpty)
                    Text(client.email,
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondaryOf(context))),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  size: 16, color: CSTheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _avatar(String name) {
    final initials = name.trim().isEmpty
        ? '?'
        : name
            .trim()
            .split(' ')
            .take(2)
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
            .join();
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [CSTheme.primary, CSTheme.primaryDark]),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
          child: Text(initials,
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w700))),
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
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.borderOf(context), width: 2),
            ),
            child: Icon(Icons.help_outline_rounded,
                size: 30, color: AppTheme.textMutedOf(context)),
          ),
          const SizedBox(height: 16),
          Text('No Ledger Selected',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryOf(context))),
          const SizedBox(height: 6),
          Text(
            'Please choose a customer from the dropdown selector\nabove to analyze their real-time chronological\nERP accounting statements.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryOf(context),
                height: 1.5),
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

    final double overdueVal = _closingBalance > 0 ? _closingBalance : 0.0;

    final cards = [
      _SummaryData('Total Invoiced', _fmt(_totalDebit),
          Icons.arrow_circle_up_rounded, CSTheme.debitColor),
      _SummaryData('Total Received', _fmt(_totalCredit),
          Icons.arrow_circle_down_rounded, CSTheme.creditColor),
      _SummaryData('Advance Credit', _fmt(_totalAdvance),
          Icons.account_balance_wallet_rounded, CSTheme.advanceColor),
      _SummaryData('Overdue Unpaid', _fmt(overdueVal),
          Icons.warning_amber_rounded, const Color(0xFFEAB308)),
      _SummaryData('Outstanding Balance', _fmt(_closingBalance),
          Icons.account_balance_rounded, CSTheme.balanceColor),
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
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: d.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(d.icon, size: 18, color: d.color),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(d.value,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: d.color),
                  overflow: TextOverflow.ellipsis),
              Text(d.label,
                  style: TextStyle(
                      fontSize: 11, color: AppTheme.textSecondaryOf(context)),
                  overflow: TextOverflow.ellipsis),
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
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
                ],
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
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
              ],
      ),
      child: Column(
        children: [
          _statementsHeader(),
          Divider(height: 1, color: AppTheme.borderOf(context)),
          if (isTablet) _tableHeader(),
          if (isTablet) Divider(height: 1, color: AppTheme.borderOf(context)),
          if (_errorMessage != null)
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Center(
                  child: Text('Error loading statements: $_errorMessage',
                      style: const TextStyle(color: Colors.red))),
            ),
          if (_statements.isEmpty && _errorMessage == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child:
                  Center(child: Text('No statements found for this client.')),
            ),
          ..._statements.asMap().entries.map((entry) => isTablet
              ? _tableRow(entry.value, entry.key)
              : _mobileStatementRow(entry.value, entry.key)),
          if (_statements.isNotEmpty) _balanceSummaryRow(),
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
            decoration: BoxDecoration(
                color: CSTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.receipt_long_rounded,
                color: CSTheme.primary, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_selectedClient!.name} — Ledger',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryOf(context)),
                    overflow: TextOverflow.ellipsis),
                Text('${_statements.length} transactions found',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondaryOf(context)),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _showStatementTemplateDialog,
            icon: const Icon(Icons.download_outlined, size: 14, color: CSTheme.primary),
            label: const Text('Export', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: CSTheme.primary)),
            style: ElevatedButton.styleFrom(
              backgroundColor: CSTheme.primary.withValues(alpha: 0.1),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: CSTheme.primary.withValues(alpha: 0.3))),
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
        children: cols
            .map((c) => Expanded(
                  flex: c == 'Description' ? 3 : 2,
                  child: Text(c,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondaryOf(context),
                          letterSpacing: 0.5)),
                ))
            .toList(),
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
            Expanded(
                flex: 2,
                child: Text(DateFormat('dd MMM yy').format(s.date),
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryOf(context)))),
            Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.description,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryOf(context)),
                        overflow: TextOverflow.ellipsis),
                    if (s.projectName != null)
                      Text(s.projectName!,
                          style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondaryOf(context)),
                          overflow: TextOverflow.ellipsis),
                  ],
                )),
            Expanded(
                flex: 2,
                child: Text(s.reference ?? '—',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondaryOf(context)),
                    overflow: TextOverflow.ellipsis)),
            Expanded(
                flex: 2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(CSTheme.typeLabel(s.type),
                      style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center),
                )),
            Expanded(
                flex: 2,
                child: Text(_fmt(s.amount),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis)),
            Expanded(
                flex: 2,
                child: Text(_fmt(s.runningBalance),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryOf(context)),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis)),
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
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(CSTheme.typeIcon(s.type), size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.description,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryOf(context)),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4)),
                        child: Text(CSTheme.typeLabel(s.type),
                            style: TextStyle(
                                fontSize: 9,
                                color: color,
                                fontWeight: FontWeight.w700)),
                      ),
                      Text(DateFormat('dd MMM yyyy').format(s.date),
                          style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondaryOf(context))),
                      if (s.reference != null)
                        Text('• ${s.reference}',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.textSecondaryOf(context)),
                            overflow: TextOverflow.ellipsis),
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
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: color)),
                const SizedBox(height: 2),
                Text('Bal: ${_fmt(s.runningBalance)}',
                    style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textSecondaryOf(context))),
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
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(12)),
        border: Border(
            top: BorderSide(
                color: CSTheme.primary.withValues(alpha: 0.2), width: 1.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_rounded,
              size: 16, color: CSTheme.primary),
          const SizedBox(width: 8),
          Expanded(
              child: Text('Closing Balance',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryOf(context)))),
          Text(_fmt(_closingBalance),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _closingBalance > 0
                    ? CSTheme.debitColor
                    : CSTheme.creditColor,
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
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: AppTheme.borderOf(context),
                    borderRadius: BorderRadius.circular(2))),
            Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(CSTheme.typeIcon(s.type), color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(s.description,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimaryOf(context))),
                    Text(DateFormat('EEEE, dd MMMM yyyy').format(s.date),
                        style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryOf(context))),
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
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondaryOf(context)))),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? AppTheme.textPrimaryOf(context))),
        ],
      ),
    );
  }

  // ── CORPORATE STATEMENT OF ACCOUNT TEMPLATE DIALOG (EXPORT MODAL) ───────────

  void _showStatementTemplateDialog() {
    if (_selectedClient == null) {
      AppSnackBar.showCustom(context, 
        const SnackBar(
            content: Text('Please select a client to view statement template.'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('dd MMM yyyy').format(DateTime.now());
    final monthYear = DateFormat('MMM yyyy').format(DateTime.now());
    final shortId = _selectedClient!.id.length >= 4
        ? _selectedClient!.id.substring(0, 4).toUpperCase()
        : 'E1AE';

    final statementNo = 'SOA/26/07/$shortId';
    final balanceWords = _numberToRupeeWords(_closingBalance);

    showDialog(
      context: context,
      builder: (ctx) {
        final screenWidth = MediaQuery.of(ctx).size.width;
        final isTablet = screenWidth >= 650;
        final modalWidth = isTablet ? 800.0 : screenWidth * 0.96;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: EdgeInsets.symmetric(
              horizontal: isTablet ? 20 : 8, vertical: isTablet ? 24 : 12),
          child: Container(
            width: modalWidth,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.92,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── TOP ACTION BAR (Header Title & Action Buttons)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    border: Border(bottom: BorderSide(color: AppTheme.borderOf(ctx))),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: CSTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.description_outlined,
                                color: CSTheme.primary, size: 18),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Corporate Statement of Account',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimaryOf(ctx)),
                                    overflow: TextOverflow.ellipsis),
                                Text(
                                    'Real-time ledger overview for ${_selectedClient!.name}',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.textSecondaryOf(ctx)),
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // HORIZONTALLY SCROLLABLE ACTION BUTTONS ROW
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _modalActionBtn(Icons.print_outlined, 'Print', _printPdf),
                            const SizedBox(width: 6),
                            _modalActionBtn(Icons.picture_as_pdf_outlined, 'Download PDF', _downloadPdf),
                            const SizedBox(width: 6),
                            _modalActionBtn(Icons.table_chart_outlined, 'CSV', _exportCSV),
                            const SizedBox(width: 6),
                            _modalActionBtn(Icons.email_outlined, 'Email', _emailStatement),
                            const SizedBox(width: 6),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _showRecordPaymentDialog();
                              },
                              icon: const Icon(Icons.add, size: 14, color: Colors.white),
                              label: const Text('+ Payment',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: CSTheme.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── STATEMENT BODY CONTENT
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isTablet ? 20 : 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // DARK CORPORATE HEADER BANNER
                        Container(
                          padding: EdgeInsets.all(isTablet ? 20 : 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('ECRAFTZ INFO SOLUTIONS LLP',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5),
                                            overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 2),
                                        Text('Head Office - Kozhikode, Kerala',
                                            style: TextStyle(
                                                color: Colors.grey.shade400,
                                                fontSize: 10),
                                            overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('STATEMENT OF ACCOUNT',
                                          style: TextStyle(
                                              color: Colors.grey.shade400,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1)),
                                      Text(monthYear,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: isTablet
                                    ? Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          _bannerMeta('STATEMENT #', statementNo),
                                          _bannerMeta('PERIOD', '01 Jul – $dateStr'),
                                          _bannerMeta('GENERATED', dateStr),
                                        ],
                                      )
                                    : Wrap(
                                        spacing: 12,
                                        runSpacing: 6,
                                        alignment: WrapAlignment.spaceAround,
                                        children: [
                                          _bannerMeta('STATEMENT #', statementNo),
                                          _bannerMeta('PERIOD', '01 Jul – $dateStr'),
                                          _bannerMeta('GENERATED', dateStr),
                                        ],
                                      ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // FROM & STATEMENT FOR ADDRESS BLOCK
                        if (isTablet)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _addressBlock(
                                  'FROM',
                                  'Ecraftz Info Solutions LLP',
                                  'A8, First Floor, NV Tower, M20/265, Kallai,\nKozhikode, Kerala 673003\nGSTIN: 32AAYFE1819K1Z4',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _addressBlock(
                                  'STATEMENT FOR',
                                  _selectedClient!.name,
                                  _selectedClient!.email.isNotEmpty
                                      ? _selectedClient!.email
                                      : 'Address Not Configured',
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              _addressBlock(
                                'FROM',
                                'Ecraftz Info Solutions LLP',
                                'A8, First Floor, NV Tower, M20/265, Kallai, Kozhikode, Kerala 673003\nGSTIN: 32AAYFE1819K1Z4',
                              ),
                              const SizedBox(height: 10),
                              _addressBlock(
                                'STATEMENT FOR',
                                _selectedClient!.name,
                                _selectedClient!.email.isNotEmpty
                                    ? _selectedClient!.email
                                    : 'Address Not Configured',
                              ),
                            ],
                          ),

                        const SizedBox(height: 16),

                        // KPI CARDS ROW (TOTAL BILLED, TOTAL RECEIVED, BALANCE DUE)
                        if (isTablet)
                          Row(
                            children: [
                              Expanded(
                                child: _kpiCard('TOTAL BILLED', _fmt(_totalDebit),
                                    CSTheme.debitColor, const Color(0xFFFEF2F2)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _kpiCard('TOTAL RECEIVED', _fmt(_totalCredit),
                                    CSTheme.creditColor, const Color(0xFFECFDF5)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _kpiCard('BALANCE DUE', _fmt(_closingBalance),
                                    const Color(0xFFD97706), const Color(0xFFFFFBEB)),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              _kpiCard('TOTAL BILLED', _fmt(_totalDebit),
                                  CSTheme.debitColor, const Color(0xFFFEF2F2)),
                              const SizedBox(height: 8),
                              _kpiCard('TOTAL RECEIVED', _fmt(_totalCredit),
                                  CSTheme.creditColor, const Color(0xFFECFDF5)),
                              const SizedBox(height: 8),
                              _kpiCard('BALANCE DUE', _fmt(_closingBalance),
                                  const Color(0xFFD97706), const Color(0xFFFFFBEB)),
                            ],
                          ),

                        const SizedBox(height: 16),

                        // OUTSTANDING BY AGE SECTION
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.borderOf(ctx)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('OUTSTANDING BY AGE',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textSecondaryOf(ctx))),
                                  Text('${_fmt(_closingBalance)} total outstanding',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimaryOf(ctx))),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _closingBalance > 0 ? 1.0 : 0.0,
                                  minHeight: 6,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      _closingBalance > 0
                                          ? CSTheme.debitColor
                                          : CSTheme.creditColor),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 10,
                                runSpacing: 4,
                                children: [
                                  _ageLegend('Current', Colors.grey.shade400),
                                  _ageLegend('1–30 days', Colors.amber),
                                  _ageLegend('31–60 days', Colors.orange),
                                  _ageLegend('60+ days', CSTheme.debitColor),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ITEM STATEMENT TABLE (HORIZONTALLY SCROLLABLE ON MOBILE FOR ZERO OVERFLOW)
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.borderOf(ctx)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: isTablet ? (modalWidth - 40) : 600.0,
                              ),
                              child: Column(
                                children: [
                                  // Table Header
                                  Container(
                                    color: isDark
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFF8FAFC),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                            width: 100,
                                            child: _tblHdr('INVOICE', ctx)),
                                        SizedBox(
                                            width: 200,
                                            child: _tblHdr('DESCRIPTION', ctx)),
                                        SizedBox(
                                            width: 90,
                                            child: _tblHdr('BILLED', ctx,
                                                align: TextAlign.right)),
                                        SizedBox(
                                            width: 90,
                                            child: _tblHdr('RECEIVED', ctx,
                                                align: TextAlign.right)),
                                        SizedBox(
                                            width: 120,
                                            child: _tblHdr('BALANCE / STATUS', ctx,
                                                align: TextAlign.right)),
                                      ],
                                    ),
                                  ),
                                  Divider(
                                      height: 1,
                                      color: AppTheme.borderOf(ctx)),
                                  if (_statements.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.all(20),
                                      child: Center(
                                          child: Text(
                                              'No transactions recorded for this client.')),
                                    )
                                  else
                                    ..._statements.map((s) {
                                      final isDebit =
                                          s.type == TransactionType.debit;
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 12),
                                        decoration: BoxDecoration(
                                            border: Border(
                                                bottom: BorderSide(
                                                    color: AppTheme.borderOf(
                                                        ctx)))),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 100,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                      s.reference ??
                                                          (s.id.length >= 6
                                                              ? s.id.substring(
                                                                  0, 6)
                                                              : s.id),
                                                      style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: AppTheme
                                                              .textPrimaryOf(
                                                                  ctx))),
                                                  Text(
                                                      DateFormat('dd MMM yyyy')
                                                          .format(s.date),
                                                      style: TextStyle(
                                                          fontSize: 9,
                                                          color: AppTheme
                                                              .textSecondaryOf(
                                                                  ctx))),
                                                ],
                                              ),
                                            ),
                                            SizedBox(
                                              width: 200,
                                              child: Text(s.description,
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          AppTheme.textPrimaryOf(
                                                              ctx)),
                                                  overflow:
                                                      TextOverflow.ellipsis),
                                            ),
                                            SizedBox(
                                              width: 90,
                                              child: Text(
                                                  isDebit ? _fmt(s.amount) : '—',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: isDebit
                                                          ? CSTheme.debitColor
                                                          : AppTheme
                                                              .textSecondaryOf(
                                                                  ctx)),
                                                  textAlign: TextAlign.right),
                                            ),
                                            SizedBox(
                                              width: 90,
                                              child: Text(
                                                  !isDebit
                                                      ? _fmt(s.amount)
                                                      : '0.00',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: !isDebit
                                                          ? CSTheme.creditColor
                                                          : AppTheme
                                                              .textSecondaryOf(
                                                                  ctx)),
                                                  textAlign: TextAlign.right),
                                            ),
                                            SizedBox(
                                              width: 120,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  Text(_fmt(s.runningBalance),
                                                      style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: AppTheme
                                                              .textPrimaryOf(
                                                                  ctx))),
                                                  if (s.status != null) ...[
                                                    const SizedBox(width: 4),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 4,
                                                          vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: s.status ==
                                                                'overdue'
                                                            ? Colors.red
                                                                .withValues(
                                                                    alpha: 0.1)
                                                            : Colors.green
                                                                .withValues(
                                                                    alpha: 0.1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(4),
                                                      ),
                                                      child: Text(
                                                        s.status!.toUpperCase(),
                                                        style: TextStyle(
                                                            fontSize: 8,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: s.status ==
                                                                    'overdue'
                                                                ? Colors.red
                                                                : Colors.green),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // BOTTOM SUMMARY & BALANCE IN WORDS
                        if (isTablet)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: AppTheme.borderOf(ctx)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('BALANCE IN WORDS',
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textSecondaryOf(
                                                  ctx))),
                                      const SizedBox(height: 4),
                                      Text(balanceWords,
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textPrimaryOf(
                                                  ctx))),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: AppTheme.borderOf(ctx)),
                                  ),
                                  child: Column(
                                    children: [
                                      _summaryRow(
                                          'Total billed', _fmt(_totalDebit), ctx),
                                      const SizedBox(height: 6),
                                      _summaryRow('Total received',
                                          '- ${_fmt(_totalCredit)}', ctx),
                                      const Divider(height: 16),
                                      _summaryRow(
                                          'Balance due', _fmt(_closingBalance), ctx,
                                          isBold: true,
                                          color: CSTheme.debitColor),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: AppTheme.borderOf(ctx)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('BALANCE IN WORDS',
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                AppTheme.textSecondaryOf(ctx))),
                                    const SizedBox(height: 4),
                                    Text(balanceWords,
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                AppTheme.textPrimaryOf(ctx))),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: AppTheme.borderOf(ctx)),
                                ),
                                child: Column(
                                  children: [
                                    _summaryRow(
                                        'Total billed', _fmt(_totalDebit), ctx),
                                    const SizedBox(height: 6),
                                    _summaryRow('Total received',
                                        '- ${_fmt(_totalCredit)}', ctx),
                                    const Divider(height: 14),
                                    _summaryRow(
                                        'Balance due', _fmt(_closingBalance), ctx,
                                        isBold: true,
                                        color: CSTheme.debitColor),
                                  ],
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 20),

                        // FOOTER BRANDING
                        Center(
                          child: Column(
                            children: [
                              Text('UK · UAE · India',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textSecondaryOf(ctx))),
                              const SizedBox(height: 2),
                              Text('www.ecraftz.com · mail@ecraftz.in',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.textSecondaryOf(ctx))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _modalActionBtn(IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 13, color: AppTheme.textPrimaryOf(context)),
      label: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryOf(context))),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        side: BorderSide(color: AppTheme.borderOf(context)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _bannerMeta(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _addressBlock(String title, String name, String details) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondaryOf(context))),
          const SizedBox(height: 4),
          Text(name,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryOf(context))),
          const SizedBox(height: 2),
          Text(details,
              style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondaryOf(context),
                  height: 1.4)),
        ],
      ),
    );
  }

  Widget _kpiCard(String label, String value, Color color, Color bgLight) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: 0.1) : bgLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _ageLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10, color: AppTheme.textSecondaryOf(context))),
      ],
    );
  }

  Widget _tblHdr(String title, BuildContext ctx, {TextAlign align = TextAlign.left}) {
    return Text(title,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondaryOf(ctx)),
        textAlign: align);
  }

  Widget _summaryRow(String label, String value, BuildContext ctx,
      {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: AppTheme.textSecondaryOf(ctx))),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: color ?? AppTheme.textPrimaryOf(ctx))),
      ],
    );
  }

  // ── PDF GENERATION & PRINTING ───────────────────────────────────────────────

  Future<void> _printPdf() async {
    if (_selectedClient == null) return;
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async {
          return _generateStatementPdf(format);
        },
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.showCustom(context, 
          SnackBar(content: Text('Print error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _downloadPdf() async {
    if (_selectedClient == null) return;
    try {
      final bytes = await _generateStatementPdf(PdfPageFormat.a4);
      final filename =
          'Statement_${_selectedClient!.name.replaceAll(' ', '_')}.pdf';
      await Printing.sharePdf(bytes: bytes, filename: filename);
    } catch (e) {
      if (mounted) {
        AppSnackBar.showCustom(context, 
          SnackBar(content: Text('PDF download error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<Uint8List> _generateStatementPdf(PdfPageFormat format) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd MMM yyyy').format(DateTime.now());
    final monthYear = DateFormat('MMM yyyy').format(DateTime.now());
    final shortId = _selectedClient!.id.length >= 4
        ? _selectedClient!.id.substring(0, 4).toUpperCase()
        : 'E1AE';

    final statementNo = 'SOA/26/07/$shortId';
    final balanceWords = _numberToRupeeWords(_closingBalance);

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Banner
              pw.Container(
                color: PdfColor.fromHex('#0F172A'),
                padding: const pw.EdgeInsets.all(16),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('ECRAFTZ INFO SOLUTIONS LLP',
                            style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 14)),
                        pw.Text('Head Office - Kozhikode, Kerala',
                            style: const pw.TextStyle(
                                color: PdfColors.grey300, fontSize: 9)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('STATEMENT OF ACCOUNT',
                            style: pw.TextStyle(
                                color: PdfColors.grey300,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 9)),
                        pw.Text(monthYear,
                            style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // Metadata Row
              pw.Container(
                color: PdfColors.grey100,
                padding: const pw.EdgeInsets.all(8),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Text('STATEMENT #: $statementNo',
                        style: pw.TextStyle(
                            fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.Text('PERIOD: 01 Jul - $dateStr',
                        style: pw.TextStyle(
                            fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.Text('GENERATED: $dateStr',
                        style: pw.TextStyle(
                            fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // Address Row
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('FROM:',
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Ecraftz Info Solutions LLP',
                            style: pw.TextStyle(
                                fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                            'A8, First Floor, NV Tower, M20/265, Kallai, Kozhikode 673003\nGSTIN: 32AAYFE1819K1Z4',
                            style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('STATEMENT FOR:',
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.Text(_selectedClient!.name,
                            style: pw.TextStyle(
                                fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.Text(_selectedClient!.email,
                            style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),

              // KPI Row
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL BILLED: ${_fmt(_totalDebit)}',
                      style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red700)),
                  pw.Text('TOTAL RECEIVED: ${_fmt(_totalCredit)}',
                      style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green700)),
                  pw.Text('BALANCE DUE: ${_fmt(_closingBalance)}',
                      style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue700)),
                ],
              ),
              pw.SizedBox(height: 12),

              // Ledger Table
              pw.TableHelper.fromTextArray(
                headers: ['INVOICE', 'DESCRIPTION', 'BILLED', 'RECEIVED', 'BALANCE'],
                data: _statements.map((s) {
                  final isDebit = s.type == TransactionType.debit;
                  return [
                    s.reference ?? (s.id.length >= 6 ? s.id.substring(0, 6) : s.id),
                    s.description,
                    isDebit ? _fmt(s.amount) : '—',
                    !isDebit ? _fmt(s.amount) : '0.00',
                    _fmt(s.runningBalance),
                  ];
                }).toList(),
                headerStyle:
                    pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                cellStyle: const pw.TextStyle(fontSize: 8),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                rowDecoration: const pw.BoxDecoration(
                    border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.grey300))),
              ),
              pw.SizedBox(height: 16),

              // Footer Totals & Balance in Words
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('BALANCE IN WORDS:',
                          style: pw.TextStyle(
                              fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text(balanceWords,
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Total Billed: ${_fmt(_totalDebit)}',
                          style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('Total Received: - ${_fmt(_totalCredit)}',
                          style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('Balance Due: ${_fmt(_closingBalance)}',
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // ── RECORD PAYMENT DIALOG ───────────────────────────────────────────────────

  void _showRecordPaymentDialog() {
    if (_selectedClient == null) {
      AppSnackBar.showCustom(context, 
        const SnackBar(
            content: Text('Please select a client before recording a payment.'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    TransactionType selectedType = TransactionType.credit;
    bool isSubmitting = false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.bgCardDark : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                        color: AppTheme.borderOf(context),
                        borderRadius: BorderRadius.circular(2))),
                Text('Record Payment / Transaction',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimaryOf(context))),
                const SizedBox(height: 16),
                Wrap(
                    spacing: 8,
                    children: TransactionType.values.take(3).map((t) {
                      final c = CSTheme.typeColor(t);
                      final selected = selectedType == t;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedType = t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: selected
                                ? c.withValues(alpha: 0.12)
                                : (isDark ? AppTheme.bgCardDark : Colors.white),
                            border: Border.all(
                                color: selected ? c : AppTheme.borderOf(context),
                                width: selected ? 1.5 : 1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(CSTheme.typeLabel(t),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: selected
                                      ? c
                                      : AppTheme.textSecondaryOf(context),
                                  fontWeight: FontWeight.w600)),
                        ),
                      );
                    }).toList()),
                const SizedBox(height: 14),
                TextField(
                  controller: amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                      fontSize: 13, color: AppTheme.textPrimaryOf(context)),
                  decoration: InputDecoration(
                    labelText: 'Amount (₹)',
                    labelStyle: TextStyle(
                        color: AppTheme.textSecondaryOf(context),
                        fontSize: 13),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: AppTheme.borderOf(context))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: AppTheme.borderOf(context))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: CSTheme.primary, width: 1.5)),
                    prefixIcon: Icon(Icons.currency_rupee,
                        size: 16, color: AppTheme.textSecondaryOf(context)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  style: TextStyle(
                      fontSize: 13, color: AppTheme.textPrimaryOf(context)),
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(
                        color: AppTheme.textSecondaryOf(context),
                        fontSize: 13),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: AppTheme.borderOf(context))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: AppTheme.borderOf(context))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: CSTheme.primary, width: 1.5)),
                    prefixIcon: Icon(Icons.notes_rounded,
                        size: 16, color: AppTheme.textSecondaryOf(context)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CSTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final parsedAmt =
                                double.tryParse(amountCtrl.text.trim());
                            if (parsedAmt == null || parsedAmt <= 0) {
                              AppSnackBar.showCustom(context, 
                                const SnackBar(
                                    content:
                                        Text('Please enter a valid amount.'),
                                    backgroundColor: Colors.orange),
                              );
                              return;
                            }

                            setModalState(() => isSubmitting = true);

                            try {
                              final nowStr = DateTime.now().toIso8601String();
                              final docNum =
                                  'PAY-${DateTime.now().millisecondsSinceEpoch}';
                              final desc = descCtrl.text.trim().isEmpty
                                  ? (selectedType == TransactionType.credit
                                      ? 'Payment Received'
                                      : selectedType == TransactionType.advance
                                          ? 'Advance Payment'
                                          : 'Debit Entry')
                                  : descCtrl.text.trim();

                              double debitVal = selectedType == TransactionType.debit
                                  ? parsedAmt
                                  : 0.0;
                              double creditVal = selectedType == TransactionType.credit
                                  ? parsedAmt
                                  : 0.0;
                              double advanceVal = selectedType == TransactionType.advance
                                  ? parsedAmt
                                  : 0.0;

                              final newBal = selectedType == TransactionType.debit
                                  ? _closingBalance + parsedAmt
                                  : _closingBalance - parsedAmt;

                              final payload = {
                                'client_id': _selectedClient!.id,
                                'transaction_date': nowStr.split('T')[0],
                                'document_type': selectedType == TransactionType.credit ? 'payment' : 'journal',
                                'document_number': docNum,
                                'description': desc,
                                'debit': debitVal,
                                'credit': creditVal > 0 ? creditVal : advanceVal,
                                'running_balance': newBal,
                                'created_at': nowStr,
                              };

                              await SupabaseService.client
                                  .from('client_statements')
                                  .insert(payload);

                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                AppSnackBar.showCustom(context, 
                                  const SnackBar(
                                      content:
                                          Text('Transaction recorded successfully!'),
                                      backgroundColor: CSTheme.creditColor),
                                );
                                _fetchStatements(_selectedClient!.id);
                              }
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                              if (mounted) {
                                AppSnackBar.showCustom(context, 
                                  SnackBar(
                                      content: Text('Failed to record transaction: $e'),
                                      backgroundColor: Colors.red),
                                );
                              }
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Record Transaction',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
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
    if (_selectedClient == null || _statements.isEmpty) {
      AppSnackBar.showCustom(context, 
        const SnackBar(
            content: Text('No client statements to export.'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    final StringBuffer csv = StringBuffer();
    csv.writeln('Date,Invoice Ref,Description,Type,Amount,Running Balance,Status');
    for (final s in _statements) {
      csv.writeln(
          '${DateFormat('yyyy-MM-dd').format(s.date)},"${s.reference ?? ''}","${s.description}",${CSTheme.typeLabel(s.type)},${s.amount},${s.runningBalance},"${s.status ?? ''}"');
    }

    AppSnackBar.showCustom(context, 
      SnackBar(
        content: Text(
            'CSV exported for ${_selectedClient!.name}! (${_statements.length} transactions)'),
        backgroundColor: CSTheme.primary,
      ),
    );
  }

  void _emailStatement() {
    if (_selectedClient == null) return;
    AppSnackBar.showCustom(context, 
      SnackBar(
        content: Text(
            'Email statement sent to ${_selectedClient!.email.isNotEmpty ? _selectedClient!.email : _selectedClient!.name}!'),
        backgroundColor: CSTheme.primary,
      ),
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
      label: Text(label,
          style: TextStyle(
              fontSize: 12,
              color: AppTheme.textPrimaryOf(context),
              fontWeight: FontWeight.w600)),
      style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8)),
    );
  }
}

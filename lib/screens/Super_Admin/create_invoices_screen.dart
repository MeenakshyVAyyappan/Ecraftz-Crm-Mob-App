import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../blocs/billing/billing_bloc.dart';
import '../../blocs/branch/branch_cubit.dart';
import '../../blocs/client/client_bloc.dart';
import '../../blocs/project/project_bloc.dart';
import '../../blocs/theme/theme_bloc.dart';
import '../../models/billing_model.dart';
import '../../models/client_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/branch_switcher.dart';

const _kPrimary = Color(0xFF00BCD4);
const _kDarkHeader = Color(0xFF0F172A);

class CreateInvoicesPage extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool showAppBar;

  const CreateInvoicesPage({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.showAppBar = true,
  });

  @override
  State<CreateInvoicesPage> createState() => _CreateInvoicesPageState();
}

class _CreateInvoicesPageState extends State<CreateInvoicesPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final branchState = context.read<BranchCubit>().state;
    context.read<BillingBloc>().add(LoadInvoicesEvent(branchState: branchState));
    context.read<ClientBloc>().add(LoadClientsEvent(branchState: branchState));
    context.read<ProjectBloc>().add(LoadProjectsEvent(branchState: branchState));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Invoice> _filterInvoices(List<Invoice> invoices) {
    return invoices.where((inv) {
      final q = _searchQuery.trim().toLowerCase();
      final matchSearch = q.isEmpty ||
          inv.invoiceNumber.toLowerCase().contains(q) ||
          inv.clientName.toLowerCase().contains(q) ||
          inv.clientEntity.toLowerCase().contains(q);

      bool matchStatus = true;
      if (_statusFilter != 'ALL') {
        final statusLabel = inv.status.label.toUpperCase();
        matchStatus = statusLabel == _statusFilter;
      }
      return matchSearch && matchStatus;
    }).toList();
  }

  double _calcTotalInvoiced(List<Invoice> list) =>
      list.fold(0.0, (sum, item) => sum + item.grossAmount);

  double _calcReceived(List<Invoice> list) =>
      list.fold(0.0, (sum, item) => sum + item.dbAmountPaid);

  double _calcOutstanding(List<Invoice> list) =>
      list.fold(0.0, (sum, item) => sum + item.dbAmountDue);

  double _calcOverdue(List<Invoice> list) => list
      .where((i) => i.status == InvoiceStatus.overdue)
      .fold(0.0, (sum, item) => sum + item.dbAmountDue);

  String _fmtMoney(double amount) {
    final formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width > 800;

    return BlocListener<BranchCubit, BranchState>(
      listener: (context, branchState) {
        _loadData();
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: widget.showAppBar
            ? AppDrawer(
                selectedIndex: widget.selectedIndex,
                onItemSelected: (index) {
                  widget.onItemSelected(index);
                  Navigator.pop(context);
                },
              )
            : null,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: widget.showAppBar
            ? AppBar(
                backgroundColor: Theme.of(context).colorScheme.surface,
                elevation: 0,
                leading: isWide
                    ? null
                    : IconButton(
                        icon: Icon(
                          Icons.menu_rounded,
                          color: isDark ? Colors.white : const Color(0xFF374151),
                        ),
                        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                      ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Invoices',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimaryOf(context),
                      ),
                    ),
                    Text(
                      'Manage, generate and track client invoices.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: BranchSwitcher(compact: true),
                  ),
                  BlocBuilder<ThemeBloc, ThemeState>(
                    builder: (context, themeState) {
                      final isDarkTheme =
                          themeState.themeMode == ThemeMode.dark;
                      return IconButton(
                        icon: Icon(
                          isDarkTheme
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          color: isDarkTheme
                              ? Colors.white
                              : const Color(0xFF374151),
                        ),
                        onPressed: () {
                          context.read<ThemeBloc>().add(ToggleThemeEvent());
                        },
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(
                    height: 1,
                    color: AppTheme.borderOf(context),
                  ),
                ),
              )
            : null,
        body: BlocBuilder<BillingBloc, BillingState>(
          builder: (context, state) {
            final allInvoices = state.invoices;
            final filteredInvoices = _filterInvoices(allInvoices);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. ECRAFTZ STANDARD HEADER BANNER
                  _buildHeaderBanner(context, state.gstProfile),

                  const SizedBox(height: 16),

                  // 2. METRICS CARDS ROW
                  _buildMetricsRow(context, allInvoices, isWide),

                  const SizedBox(height: 20),

                  // 3. SEARCH & STATUS FILTER BAR
                  _buildFilterBar(context, isWide),

                  const SizedBox(height: 16),

                  // 4. INVOICES DATA TABLE / CARDS
                  _buildInvoicesSection(
                    context,
                    filteredInvoices,
                    state.gstProfile,
                    isWide,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openCreateInvoiceModal(context),
          backgroundColor: _kPrimary,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  // ─── 1. HEADER BANNER ────────────────────────────────────────────────────────

  Widget _buildHeaderBanner(BuildContext context, GstProfile profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        color: _kDarkHeader,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          return Flex(
            direction: isNarrow ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: isNarrow
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: isNarrow ? 0 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF312E81),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFF4338CA), width: 1),
                      ),
                      child: const Text(
                        '# ECRAFTZ STANDARD',
                        style: TextStyle(
                          color: Color(0xFFA5B4FC),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Create Invoices',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Issue tax-compliant GST invoices, manage invoice revisions, and generate PDFs using the organizational standard.',
                      style: TextStyle(
                        color: const Color(0xFF94A3B8),
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (isNarrow) const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _openCreateInvoiceModal(context),
                icon: const Icon(Icons.add_rounded, size: 18, color: _kDarkHeader),
                label: const Text(
                  'Create Invoice',
                  style: TextStyle(
                    color: _kDarkHeader,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _kDarkHeader,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── 2. METRICS CARDS ───────────────────────────────────────────────────────

  Widget _buildMetricsRow(
      BuildContext context, List<Invoice> invoices, bool isWide) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cards = [
      _MetricCard(
        title: 'TOTAL INVOICED',
        value: _fmtMoney(_calcTotalInvoiced(invoices)),
        icon: Icons.description_outlined,
        iconBg: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        iconColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        valueColor: AppTheme.textPrimaryOf(context),
      ),
      _MetricCard(
        title: 'RECEIVED',
        value: _fmtMoney(_calcReceived(invoices)),
        icon: Icons.check_circle_outline_rounded,
        iconBg: isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
        iconColor: const Color(0xFF10B981),
        valueColor: const Color(0xFF10B981),
      ),
      _MetricCard(
        title: 'OUTSTANDING',
        value: _fmtMoney(_calcOutstanding(invoices)),
        icon: Icons.access_time_rounded,
        iconBg: isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7),
        iconColor: const Color(0xFFF59E0B),
        valueColor: const Color(0xFFF59E0B),
      ),
      _MetricCard(
        title: 'OVERDUE',
        value: _fmtMoney(_calcOverdue(invoices)),
        icon: Icons.error_outline_rounded,
        iconBg: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2),
        iconColor: const Color(0xFFEF4444),
        valueColor: const Color(0xFFEF4444),
      ),
    ];

    if (isWide) {
      return Row(
        children: cards
            .map((c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: c,
                  ),
                ))
            .toList(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 500) {
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: cards,
          );
        }
        return Column(
          children: cards
              .map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: c,
                  ))
              .toList(),
        );
      },
    );
  }

  // ─── 3. FILTER BAR ──────────────────────────────────────────────────────────

  Widget _buildFilterBar(BuildContext context, bool isWide) {
    final filters = ['ALL', 'DRAFT', 'SENT', 'PAID', 'OVERDUE', 'CANCELLED'];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;

        return Column(
          children: [
            if (isMobile) ...[
              // Mobile search
              _buildSearchInput(context),
              const SizedBox(height: 12),
              // Mobile filter pills scroll
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: filters
                      .map((f) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _buildFilterPill(f),
                          ))
                      .toList(),
                ),
              ),
            ] else ...[
              // Desktop/Tablet horizontal row
              Row(
                children: [
                  Expanded(
                    child: _buildSearchInput(context),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: filters
                        .map((f) => Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: _buildFilterPill(f),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSearchInput(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (val) => setState(() => _searchQuery = val),
        style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context)),
        decoration: InputDecoration(
          hintText: 'Search by client or invoice number...',
          hintStyle: TextStyle(
            fontSize: 12.5,
            color: AppTheme.textMutedOf(context),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 18,
            color: AppTheme.textMutedOf(context),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close, size: 16, color: AppTheme.textSecondaryOf(context)),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildFilterPill(String filter) {
    final isSelected = _statusFilter == filter;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _statusFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white : const Color(0xFF0F172A))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                : AppTheme.borderOf(context),
          ),
        ),
        child: Text(
          filter,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected
                ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                : AppTheme.textSecondaryOf(context),
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  // ─── 4. INVOICES DATA TABLE ─────────────────────────────────────────────────

  Widget _buildInvoicesSection(
    BuildContext context,
    List<Invoice> invoices,
    GstProfile profile,
    bool isWide,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (invoices.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.bgCardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderOf(context)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: AppTheme.textMutedOf(context),
            ),
            const SizedBox(height: 12),
            Text(
              'No Invoices Found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Create a new invoice or adjust your filter criteria.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryOf(context),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openCreateInvoiceModal(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Create Invoice'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!isWide) {
      return Column(
        children: invoices
            .map((inv) => _buildInvoiceMobileCard(context, inv, profile))
            .toList(),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(
                bottom: BorderSide(color: AppTheme.borderOf(context)),
              ),
            ),
            child: Row(
              children: const [
                Expanded(flex: 2, child: _TableHeaderCell('DOC NUMBER')),
                Expanded(flex: 3, child: _TableHeaderCell('CLIENT')),
                Expanded(flex: 2, child: _TableHeaderCell('DATE')),
                Expanded(flex: 2, child: _TableHeaderCell('DUE DATE')),
                Expanded(flex: 2, child: _TableHeaderCell('TOTAL AMOUNT')),
                Expanded(flex: 2, child: _TableHeaderCell('STATUS')),
                SizedBox(width: 140, child: _TableHeaderCell('ACTIONS', alignRight: true)),
              ],
            ),
          ),
          // Table Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: invoices.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: AppTheme.borderOf(context)),
            itemBuilder: (context, index) {
              final inv = invoices[index];
              return _buildInvoiceTableRow(context, inv, profile);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceTableRow(
    BuildContext context,
    Invoice inv,
    GstProfile profile,
  ) {
    final branchState = context.watch<BranchCubit>().state;
    final selectedBranch = branchState.selectedBranch;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // Doc Number + Branch tag
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inv.invoiceNumber,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A84FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        radius: 2.5,
                        backgroundColor: Color(0xFF0A84FF),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        selectedBranch.shortName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0A84FF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Client Name & Project
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inv.clientName.isEmpty ? 'Unassigned Client' : inv.clientName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryOf(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  inv.clientEntity.isEmpty ? 'No project' : inv.clientEntity,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondaryOf(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Date
          Expanded(
            flex: 2,
            child: Text(
              DateFormat('dd/MM/yyyy').format(inv.issuedDate),
              style: TextStyle(
                fontSize: 12.5,
                color: AppTheme.textSecondaryOf(context),
              ),
            ),
          ),

          // Due Date
          Expanded(
            flex: 2,
            child: Text(
              DateFormat('dd/MM/yyyy').format(inv.dueDate),
              style: TextStyle(
                fontSize: 12.5,
                color: AppTheme.textSecondaryOf(context),
              ),
            ),
          ),

          // Total Amount
          Expanded(
            flex: 2,
            child: Text(
              _fmtMoney(inv.grossAmount),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryOf(context),
              ),
            ),
          ),

          // Status Badge
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildStatusPill(inv.status),
            ),
          ),

          // Actions
          SizedBox(
            width: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // View PDF / Details
                _buildActionButton(
                  icon: Icons.visibility_outlined,
                  color: const Color(0xFF3B82F6),
                  tooltip: 'View Invoice',
                  onTap: () => _showInvoiceDetail(context, inv, profile),
                ),
                // Edit
                _buildActionButton(
                  icon: Icons.edit_outlined,
                  color: const Color(0xFFF59E0B),
                  tooltip: 'Edit Invoice',
                  onTap: () => _openEditInvoiceModal(context, inv, profile),
                ),
                // Download PDF
                _buildActionButton(
                  icon: Icons.download_outlined,
                  color: const Color(0xFF10B981),
                  tooltip: 'Download PDF',
                  onTap: () => _generateAndDownloadPdf(inv, profile),
                ),
                // Record Payment
                _buildActionButton(
                  icon: Icons.attach_money_rounded,
                  color: const Color(0xFF8B5CF6),
                  tooltip: 'Record Payment',
                  onTap: () => _recordPaymentDialog(context, inv),
                ),
                // Delete
                _buildActionButton(
                  icon: Icons.delete_outline_rounded,
                  color: const Color(0xFFEF4444),
                  tooltip: 'Delete',
                  onTap: () => _confirmDelete(context, inv.id),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceMobileCard(
    BuildContext context,
    Invoice inv,
    GstProfile profile,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                inv.invoiceNumber,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryOf(context),
                ),
              ),
              _buildStatusPill(inv.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            inv.clientName.isEmpty ? 'Unassigned Client' : inv.clientName,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryOf(context),
            ),
          ),
          Text(
            inv.clientEntity.isEmpty ? 'No project' : inv.clientEntity,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Date: ${DateFormat('dd/MM/yyyy').format(inv.issuedDate)}',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondaryOf(context),
                ),
              ),
              Text(
                _fmtMoney(inv.grossAmount),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimaryOf(context),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility_outlined,
                    size: 18, color: Color(0xFF3B82F6)),
                onPressed: () => _showInvoiceDetail(context, inv, profile),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    size: 18, color: Color(0xFFF59E0B)),
                onPressed: () => _openEditInvoiceModal(context, inv, profile),
              ),
              IconButton(
                icon: const Icon(Icons.download_outlined,
                    size: 18, color: Color(0xFF10B981)),
                onPressed: () => _generateAndDownloadPdf(inv, profile),
              ),
              IconButton(
                icon: const Icon(Icons.attach_money_rounded,
                    size: 18, color: Color(0xFF8B5CF6)),
                onPressed: () => _recordPaymentDialog(context, inv),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: Color(0xFFEF4444)),
                onPressed: () => _confirmDelete(context, inv.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(InvoiceStatus status) {
    Color border;
    Color text;
    Color bg;

    switch (status) {
      case InvoiceStatus.paid:
        border = const Color(0xFF10B981);
        text = const Color(0xFF10B981);
        bg = const Color(0xFF10B981).withOpacity(0.08);
        break;
      case InvoiceStatus.overdue:
        border = const Color(0xFFF59E0B);
        text = const Color(0xFFF59E0B);
        bg = const Color(0xFFF59E0B).withOpacity(0.08);
        break;
      case InvoiceStatus.draft:
        border = const Color(0xFF6B7280);
        text = const Color(0xFF6B7280);
        bg = const Color(0xFF6B7280).withOpacity(0.08);
        break;
      case InvoiceStatus.sent:
        border = const Color(0xFF3B82F6);
        text = const Color(0xFF3B82F6);
        bg = const Color(0xFF3B82F6).withOpacity(0.08);
        break;
      case InvoiceStatus.cancelled:
        border = const Color(0xFFEF4444);
        text = const Color(0xFFEF4444);
        bg = const Color(0xFFEF4444).withOpacity(0.08);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: text,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon, size: 17, color: color),
        ),
      ),
    );
  }

  // ─── CRUD OPERATIONS & MODALS ───────────────────────────────────────────────

  void _openCreateInvoiceModal(BuildContext context) {
    final profile = context.read<BillingBloc>().state.gstProfile;
    final branchState = context.read<BranchCubit>().state;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InvoiceFormModal(
        gstProfile: profile,
        onSave: (inv) {
          context.read<BillingBloc>().add(AddInvoiceEvent(inv, branchState: branchState));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invoice created successfully!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        },
      ),
    );
  }

  void _openEditInvoiceModal(
      BuildContext context, Invoice inv, GstProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InvoiceFormModal(
        existingInvoice: inv,
        gstProfile: profile,
        onSave: (updatedInv) {
          // Update status & details
          context.read<BillingBloc>().add(
                UpdateInvoiceStatusEvent(inv.id, updatedInv.status),
              );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invoice updated successfully!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        },
      ),
    );
  }

  void _showInvoiceDetail(
      BuildContext context, Invoice inv, GstProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.bgCardDark
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Invoice Details — ${inv.invoiceNumber}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimaryOf(context),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    title: const Text('Client Name'),
                    subtitle: Text(inv.clientName),
                  ),
                  ListTile(
                    title: const Text('Project / Entity'),
                    subtitle: Text(inv.clientEntity),
                  ),
                  ListTile(
                    title: const Text('Issued Date'),
                    subtitle:
                        Text(DateFormat('dd/MM/yyyy').format(inv.issuedDate)),
                  ),
                  ListTile(
                    title: const Text('Due Date'),
                    subtitle:
                        Text(DateFormat('dd/MM/yyyy').format(inv.dueDate)),
                  ),
                  ListTile(
                    title: const Text('Total Amount'),
                    subtitle: Text(_fmtMoney(inv.grossAmount)),
                  ),
                  ListTile(
                    title: const Text('Status'),
                    subtitle: _buildStatusPill(inv.status),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _recordPaymentDialog(BuildContext context, Invoice inv) {
    final statusOptions = InvoiceStatus.values;
    InvoiceStatus selected = inv.status;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update Payment Status — ${inv.invoiceNumber}'),
        content: StatefulBuilder(
          builder: (ctx, setSt) => Column(
            mainAxisSize: MainAxisSize.min,
            children: statusOptions
                .map(
                  (s) => RadioListTile<InvoiceStatus>(
                    title: Text(s.label.toUpperCase()),
                    value: s,
                    groupValue: selected,
                    onChanged: (val) => setSt(() => selected = val!),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context
                  .read<BillingBloc>()
                  .add(UpdateInvoiceStatusEvent(inv.id, selected));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Payment status updated to ${selected.label}'),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
            },
            child: const Text('Save Status'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String invoiceId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: const Text('Are you sure you want to delete this invoice?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<BillingBloc>().add(DeleteInvoiceEvent(invoiceId));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Invoice deleted.'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _generateAndDownloadPdf(Invoice inv, GstProfile profile) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('INVOICE ${inv.invoiceNumber}',
                style: pw.TextStyle(
                    fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text('Client: ${inv.clientName}'),
            pw.Text('Project: ${inv.clientEntity}'),
            pw.Text('Date: ${DateFormat('dd/MM/yyyy').format(inv.issuedDate)}'),
            pw.Text('Due Date: ${DateFormat('dd/MM/yyyy').format(inv.dueDate)}'),
            pw.SizedBox(height: 20),
            pw.Text('Total Amount: ₹${inv.grossAmount.toStringAsFixed(2)}',
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Invoice_${inv.invoiceNumber}.pdf',
    );
  }
}

// ─── HELPER WIDGETS ──────────────────────────────────────────────────────────

class _TableHeaderCell extends StatelessWidget {
  final String label;
  final bool alignRight;
  const _TableHeaderCell(this.label, {this.alignRight = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppTheme.textSecondaryOf(context),
        letterSpacing: 0.5,
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final Color valueColor;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondaryOf(context),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
        ],
      ),
    );
  }
}

// ─── INVOICE FORM MODAL ───────────────────────────────────────────────────────

class _InvoiceFormModal extends StatefulWidget {
  final Invoice? existingInvoice;
  final GstProfile gstProfile;
  final Function(Invoice) onSave;

  const _InvoiceFormModal({
    this.existingInvoice,
    required this.gstProfile,
    required this.onSave,
  });

  @override
  State<_InvoiceFormModal> createState() => _InvoiceFormModalState();
}

class _InvoiceFormModalState extends State<_InvoiceFormModal> {
  final _formKey = GlobalKey<FormState>();

  late String _invoiceNum;
  String? _selectedClient;
  String? _selectedProject;
  DateTime _issueDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 15));
  InvoiceStatus _status = InvoiceStatus.draft;

  final List<InvoiceItem> _items = [];
  double _discount = 0.0;
  double _taxRate = 18.0;

  @override
  void initState() {
    super.initState();
    if (widget.existingInvoice != null) {
      final inv = widget.existingInvoice!;
      _invoiceNum = inv.invoiceNumber;
      _selectedClient = inv.clientName;
      _selectedProject = inv.clientEntity;
      _issueDate = inv.issuedDate;
      _dueDate = inv.dueDate;
      _status = inv.status;
      _items.addAll(inv.items);
    } else {
      _invoiceNum = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      _items.add(InvoiceItem(description: 'Services', quantity: 1, unitPrice: 10000));
    }
  }

  double get subtotal => _items.fold(0.0, (sum, i) => sum + i.total);
  double get taxAmount => (subtotal - _discount) * (_taxRate / 100);
  double get grandTotal => (subtotal - _discount) + taxAmount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clientState = context.watch<ClientBloc>().state;
    final projectState = context.watch<ProjectBloc>().state;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.existingInvoice == null ? 'Create Invoice' : 'Edit Invoice',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimaryOf(context),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView(
                children: [
                  // Invoice Number
                  TextFormField(
                    initialValue: _invoiceNum,
                    decoration: const InputDecoration(labelText: 'Invoice Number'),
                    onChanged: (val) => _invoiceNum = val,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  // Client Selection Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedClient,
                    decoration: const InputDecoration(labelText: 'Select Client'),
                    items: clientState.clients
                        .map((c) => DropdownMenuItem(
                              value: c.name,
                              child: Text(c.name),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedClient = val),
                    validator: (v) => v == null || v.isEmpty ? 'Please select a client' : null,
                  ),
                  const SizedBox(height: 12),

                  // Project Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedProject,
                    decoration: const InputDecoration(labelText: 'Select Project'),
                    items: projectState.projects
                        .map((p) => DropdownMenuItem(
                              value: p.name,
                              child: Text(p.name),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedProject = val),
                  ),
                  const SizedBox(height: 12),

                  // Line items header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Line Items', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Item'),
                        onPressed: () {
                          setState(() {
                            _items.add(InvoiceItem(description: '', quantity: 1, unitPrice: 0));
                          });
                        },
                      ),
                    ],
                  ),
                  ..._items.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    return Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            initialValue: item.description,
                            decoration: const InputDecoration(hintText: 'Item Description'),
                            onChanged: (v) => item.description = v,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            initialValue: item.quantity.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: 'Qty'),
                            onChanged: (v) => setState(() => item.quantity = double.tryParse(v) ?? 1.0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: item.unitPrice.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: 'Price'),
                            onChanged: (v) => setState(() => item.unitPrice = double.tryParse(v) ?? 0),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            if (_items.length > 1) {
                              setState(() => _items.removeAt(idx));
                            }
                          },
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 20),

                  // Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal'),
                            Text('₹${subtotal.toStringAsFixed(2)}'),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('GST Tax ($_taxRate%)'),
                            Text('₹${taxAmount.toStringAsFixed(2)}'),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('₹${grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final invoice = Invoice(
                      id: widget.existingInvoice?.id ?? '',
                      invoiceNumber: _invoiceNum,
                      clientName: _selectedClient ?? '',
                      clientEntity: _selectedProject ?? 'No project',
                      issuedDate: _issueDate,
                      dueDate: _dueDate,
                      dbGrandTotal: grandTotal,
                      status: _status,
                      items: _items,
                    );
                    widget.onSave(invoice);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save Invoice', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

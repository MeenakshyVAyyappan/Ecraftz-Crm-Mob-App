import 'package:ecraftz_crm/widgets/app_snackbar.dart';
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
          AppSnackBar.showCustom(context, 
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
          AppSnackBar.showCustom(context, 
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
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final screenWidth = MediaQuery.of(ctx).size.width;
        final isCompact = screenWidth < 600;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isCompact ? 6 : 16,
            vertical: isCompact ? 10 : 24,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 900,
              maxHeight: MediaQuery.of(ctx).size.height * 0.94,
            ),
            decoration: BoxDecoration(
              color: Theme.of(ctx).brightness == Brightness.dark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                )
              ],
            ),
            child: Column(
              children: [
                // Top Action Header Bar (Responsive for Mobile & Desktop)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 12 : 20,
                    vertical: isCompact ? 10 : 14,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).brightness == Brightness.dark
                        ? AppTheme.bgCardDark
                        : Colors.white,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    border: Border(
                      bottom: BorderSide(color: AppTheme.borderOf(ctx)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Invoice PREVIEW',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: isCompact ? 15 : 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimaryOf(ctx),
                              ),
                            ),
                            if (!isCompact) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Review and print or export this document to standard PDF.',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondaryOf(ctx),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (isCompact) ...[
                        IconButton(
                          icon: const Icon(Icons.download_rounded,
                              color: Color(0xFF0F172A), size: 20),
                          tooltip: 'Export PDF',
                          onPressed: () =>
                              _generateAndDownloadPdf(inv, profile),
                        ),
                        IconButton(
                          icon: const Icon(Icons.print_outlined,
                              color: Color(0xFF0F172A), size: 20),
                          tooltip: 'Print',
                          onPressed: () => _printInvoice(inv, profile),
                        ),
                      ] else ...[
                        ElevatedButton.icon(
                          onPressed: () =>
                              _generateAndDownloadPdf(inv, profile),
                          icon: const Icon(Icons.download_rounded, size: 16),
                          label: const Text('Export PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _printInvoice(inv, profile),
                          icon: const Icon(Icons.print_outlined, size: 16),
                          label: const Text('Print'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textPrimaryOf(ctx),
                            side: BorderSide(color: AppTheme.borderOf(ctx)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),

                // Scrollable Document Canvas (Supports Horizontal + Vertical Scrolling on Mobile)
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isCompact ? 8 : 20),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Center(
                        child: Container(
                          width: isCompact ? 680.0 : 820.0,
                          padding: EdgeInsets.all(isCompact ? 18 : 32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Company Header Banner
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Logo
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E293B),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'E',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 26,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  // Company Address
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Ecraftz Info Solutions LLP',
                                          style: TextStyle(
                                            color: Color(0xFF0F172A),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          profile.brandName.isNotEmpty
                                              ? profile.brandName
                                              : 'Head Office',
                                          style: const TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          profile.address.isNotEmpty
                                              ? profile.address
                                              : 'Ecraftz, A9, First floor, NV Tower, M20/265, Kallai, Kozhikode, Kerala 673003',
                                          style: const TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Flags & Contact
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Text('🇬🇧 UK  ',
                                              style: TextStyle(fontSize: 10)),
                                          Text('🇦🇪 UAE  ',
                                              style: TextStyle(fontSize: 10)),
                                          Text('🇮🇳 INDIA',
                                              style: TextStyle(fontSize: 10)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        profile.website.isNotEmpty
                                            ? profile.website
                                            : 'www.vbecraftz.com',
                                        style: const TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 10),
                                      ),
                                      Text(
                                        profile.email.isNotEmpty
                                            ? profile.email
                                            : 'mail@ecraftz.in',
                                        style: const TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 18),
                              const Divider(
                                  height: 1, color: Color(0xFFE2E8F0)),
                              const SizedBox(height: 14),

                              // 2. Invoice Meta Bar
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Invoice #  ${inv.invoiceNumber}',
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    'Place Of Supply  ${inv.placeOfSupply ?? "32"}',
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Invoice Date  ${DateFormat("dd-MM-yyyy").format(inv.issuedDate)}',
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // 3. BILLED BY & BILLED TO Section
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(4),
                                  border:
                                      Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      color: const Color(0xFFF1F5F9),
                                      child: Row(
                                        children: const [
                                          Expanded(
                                            child: Text(
                                              'BILLED BY',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF475569),
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              'BILLED TO',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF475569),
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // From (Billed By)
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text('From:',
                                                    style: TextStyle(
                                                        fontSize: 10,
                                                        color: Color(0xFF64748B))),
                                                Text(
                                                  profile.legalName.isNotEmpty
                                                      ? profile.legalName
                                                      : 'Ecraftz Info Solutions LLP',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w800,
                                                    color: Color(0xFF0F172A),
                                                  ),
                                                ),
                                                Text(
                                                  profile.address.isNotEmpty
                                                      ? profile.address
                                                      : 'Ecraftz, A9, First floor, NV Tower, M20/265, Kallai, Kozhikode, Kerala 673003',
                                                  style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Color(0xFF64748B)),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'GSTIN: ${profile.gstin.isNotEmpty ? profile.gstin : "32AAYFE1819K1Z4"}',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF0F172A),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          // To (Billed To)
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text('To:',
                                                    style: TextStyle(
                                                        fontSize: 10,
                                                        color: Color(0xFF64748B))),
                                                Text(
                                                  inv.clientName.isNotEmpty
                                                      ? inv.clientName
                                                          .toUpperCase()
                                                      : 'CLIENT NAME',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w800,
                                                    color: Color(0xFF0F172A),
                                                  ),
                                                ),
                                                Text(
                                                  inv.clientAddress?.isNotEmpty ==
                                                          true
                                                      ? inv.clientAddress!
                                                      : (inv.clientEntity
                                                              .isNotEmpty
                                                          ? inv.clientEntity
                                                          : 'INDIA'),
                                                  style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Color(0xFF64748B)),
                                                ),
                                                if (inv.clientPhone != null)
                                                  Text(
                                                      'Phone: ${inv.clientPhone}',
                                                      style: const TextStyle(
                                                          fontSize: 10,
                                                          color:
                                                              Color(0xFF64748B))),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 18),

                              // 4. Products / Services Itemized Table
                              Table(
                                border: TableBorder.all(
                                  color: const Color(0xFFCBD5E1),
                                  width: 0.8,
                                ),
                                columnWidths: const {
                                  0: FlexColumnWidth(0.6), // S.No
                                  1: FlexColumnWidth(2.6), // Description
                                  2: FlexColumnWidth(1.1), // HSN/SAC
                                  3: FlexColumnWidth(0.8), // Unit
                                  4: FlexColumnWidth(1.2), // Rate
                                  5: FlexColumnWidth(0.8), // Disc
                                  6: FlexColumnWidth(0.8), // SGST %
                                  7: FlexColumnWidth(1.0), // SGST Amt
                                  8: FlexColumnWidth(0.8), // CGST %
                                  9: FlexColumnWidth(1.0), // CGST Amt
                                  10: FlexColumnWidth(1.3), // Net Amt
                                },
                                children: [
                                  // Table Header
                                  TableRow(
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF1F5F9),
                                    ),
                                    children: const [
                                      _DocTableCell('S.No', isHeader: true),
                                      _DocTableCell('Description',
                                          isHeader: true),
                                      _DocTableCell('HSN/SAC CODE',
                                          isHeader: true),
                                      _DocTableCell('Unit', isHeader: true),
                                      _DocTableCell('Rate',
                                          isHeader: true, alignRight: true),
                                      _DocTableCell('Disc',
                                          isHeader: true, alignRight: true),
                                      _DocTableCell('SGST',
                                          isHeader: true, alignRight: true),
                                      _DocTableCell('Amount',
                                          isHeader: true, alignRight: true),
                                      _DocTableCell('CGST',
                                          isHeader: true, alignRight: true),
                                      _DocTableCell('Amount',
                                          isHeader: true, alignRight: true),
                                      _DocTableCell('Net Amt',
                                          isHeader: true, alignRight: true),
                                    ],
                                  ),
                                  // Table Rows
                                  ...inv.items.asMap().entries.map((entry) {
                                    final idx = entry.key + 1;
                                    final item = entry.value;
                                    return TableRow(
                                      children: [
                                        _DocTableCell('$idx',
                                            alignCenter: true),
                                        _DocTableCell(item.description,
                                            isBold: true),
                                        _DocTableCell(item.hsnSac ?? '-'),
                                        _DocTableCell(item.category ?? 'Nos'),
                                        _DocTableCell(
                                            item.unitPrice.toStringAsFixed(2),
                                            alignRight: true),
                                        _DocTableCell(
                                          item.discountAmount > 0
                                              ? '₹${item.discountAmount.toStringAsFixed(0)}'
                                              : '0.0%',
                                          alignRight: true,
                                        ),
                                        _DocTableCell(
                                            '${item.sgstRate.toStringAsFixed(1)}%',
                                            alignRight: true),
                                        _DocTableCell(
                                            item.sgstAmount.toStringAsFixed(2),
                                            alignRight: true),
                                        _DocTableCell(
                                            '${item.cgstRate.toStringAsFixed(1)}%',
                                            alignRight: true),
                                        _DocTableCell(
                                            item.cgstAmount.toStringAsFixed(2),
                                            alignRight: true),
                                        _DocTableCell(
                                            item.total.toStringAsFixed(2),
                                            alignRight: true,
                                            isBold: true),
                                      ],
                                    );
                                  }),
                                ],
                              ),

                              const SizedBox(height: 22),

                              // 5. Totals & Words & Bank Account Details
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left: Words & Bank Account Details
                                  Expanded(
                                    flex: 6,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'TOTAL IN WORDS',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF64748B),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _numberToWordsIndian(
                                              inv.grossAmount),
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            fontStyle: FontStyle.italic,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        const Text(
                                          'BANK ACCOUNT DETAILS:',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF0F172A),
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        _buildBankDetailRow('Company Name',
                                            ': ECRAFTZ TECHNOLOGIES PVT LTD'),
                                        _buildBankDetailRow(
                                            'Account No', ': 751405500282'),
                                        _buildBankDetailRow(
                                            'IFSC Code', ': ICIC0007514'),
                                        _buildBankDetailRow(
                                            'Bank', ': ICICI Bank (ICIC1)'),
                                        _buildBankDetailRow('Branch',
                                            ': Calicut, Medical College'),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Right: Calculation Summary Table
                                  Expanded(
                                    flex: 5,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: const Color(0xFFE2E8F0)),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: Column(
                                        children: [
                                          _buildDocSummaryRow('Sub Total',
                                              inv.subtotal.toStringAsFixed(2)),
                                          if (inv.totalDiscount > 0)
                                            _buildDocSummaryRow(
                                                'Discount',
                                                '- ${inv.totalDiscount.toStringAsFixed(2)}'),
                                          if (inv.totalCgst > 0 ||
                                              inv.totalTax == 0)
                                            _buildDocSummaryRow(
                                                'CGST (${(inv.items.firstOrNull?.cgstRate ?? 0.0).toStringAsFixed(1)}%)',
                                                inv.totalCgst
                                                    .toStringAsFixed(2)),
                                          if (inv.totalSgst > 0 ||
                                              inv.totalTax == 0)
                                            _buildDocSummaryRow(
                                                'SGST (${(inv.items.firstOrNull?.sgstRate ?? 0.0).toStringAsFixed(1)}%)',
                                                inv.totalSgst
                                                    .toStringAsFixed(2)),
                                          if (inv.totalIgst > 0)
                                            _buildDocSummaryRow(
                                                'IGST (${(inv.items.firstOrNull?.igstRate ?? 0.0).toStringAsFixed(1)}%)',
                                                inv.totalIgst
                                                    .toStringAsFixed(2)),
                                          if (inv.totalCess > 0)
                                            _buildDocSummaryRow('Cess',
                                                inv.totalCess.toStringAsFixed(2)),
                                          if (inv.roundOff != 0)
                                            _buildDocSummaryRow(
                                                'Round Off',
                                                inv.roundOff.toStringAsFixed(2)),
                                          const Divider(
                                              height: 12,
                                              color: Color(0xFFCBD5E1)),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'Total',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w900,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                              Text(
                                                _fmtMoney(inv.grossAmount),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w900,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (inv.amountPaid > 0) ...[
                                            const SizedBox(height: 4),
                                            _buildDocSummaryRow('Amount Paid',
                                                _fmtMoney(inv.amountPaid)),
                                            _buildDocSummaryRow('Amount Due',
                                                _fmtMoney(inv.amountDue),
                                                isBold: true),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 36),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Column(
                                  children: [
                                    Container(
                                      width: 140,
                                      height: 1,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Authorized Signature',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

  static Widget _buildBankDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildDocSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
              color: const Color(0xFF475569),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  static String _numberToWordsIndian(double amount) {
    final int val = amount.round();
    if (val <= 0) return 'Rupees Zero Only';

    final units = [
      '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
      'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
      'Seventeen', 'Eighteen', 'Nineteen'
    ];
    final tens = [
      '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
    ];

    String convertBelowThousand(int n) {
      if (n == 0) return '';
      if (n < 20) return units[n];
      if (n < 100) {
        final t = tens[n ~/ 10];
        final u = units[n % 10];
        return u.isEmpty ? t : '$t $u';
      }
      final h = units[n ~/ 100];
      final rem = convertBelowThousand(n % 100);
      return rem.isEmpty ? '$h Hundred' : '$h Hundred $rem';
    }

    int temp = val;
    int crore = temp ~/ 10000000;
    temp %= 10000000;
    int lakh = temp ~/ 100000;
    temp %= 100000;
    int thousand = temp ~/ 1000;
    temp %= 1000;
    int remainder = temp;

    List<String> parts = [];
    if (crore > 0) parts.add('${convertBelowThousand(crore)} Crore');
    if (lakh > 0) parts.add('${convertBelowThousand(lakh)} Lakh');
    if (thousand > 0) parts.add('${convertBelowThousand(thousand)} Thousand');
    if (remainder > 0) parts.add(convertBelowThousand(remainder));

    return 'Rupees ${parts.join(' ')} Only';
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
              AppSnackBar.showCustom(context, 
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
              AppSnackBar.showCustom(context, 
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
    try {
      final String fileName =
          'Invoice_${inv.invoiceNumber.replaceAll('/', '_')}.pdf';

      if (mounted) {
        AppSnackBar.showCustom(context, 
          SnackBar(
            content: Text('Generating PDF for Invoice #${inv.invoiceNumber}...'),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF0F172A),
          ),
        );
      }

      final pdfBytes = await _buildInvoicePdfBytes(inv, profile);

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: fileName,
      );

      if (mounted) {
        AppSnackBar.showCustom(context, 
          SnackBar(
            content: Text('PDF Ready: $fileName'),
            duration: const Duration(seconds: 3),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showCustom(context, 
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _printInvoice(Invoice inv, GstProfile profile) async {
    final pdfBytes = await _buildInvoicePdfBytes(inv, profile);
    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: 'Invoice_${inv.invoiceNumber}',
    );
  }

  Future<Uint8List> _buildInvoicePdfBytes(Invoice inv, GstProfile profile) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Company Header
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 45,
                  height: 45,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blueGrey900,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'E',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(width: 14),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        profile.legalName.isNotEmpty
                            ? profile.legalName
                            : 'Ecraftz Info Solutions LLP',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey900,
                        ),
                      ),
                      pw.Text(
                        profile.address.isNotEmpty
                            ? profile.address
                            : 'Ecraftz, A9, First floor, NV Tower, M20/265, Kallai, Kozhikode, Kerala 673003',
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('UK | UAE | INDIA',
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey800)),
                    pw.Text(profile.website.isNotEmpty ? profile.website : 'www.vbecraftz.com',
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey700)),
                    pw.Text(profile.email.isNotEmpty ? profile.email : 'mail@ecraftz.in',
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey700)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 14),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 10),

            // Meta bar
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Invoice #: ${inv.invoiceNumber}',
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.Text('Place Of Supply: ${inv.placeOfSupply ?? "32"}',
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.Text(
                'Invoice Date: ${DateFormat("dd-MM-yyyy").format(inv.issuedDate)}',
                style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 14),

            // Billed By / To Box
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                children: [
                  pw.Container(
                    color: PdfColors.grey200,
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                            child: pw.Text('BILLED BY',
                                style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold))),
                        pw.Expanded(
                            child: pw.Text('BILLED TO',
                                style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(12),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Ecraftz Info Solutions LLP',
                                  style: pw.TextStyle(
                                      fontSize: 10,
                                      fontWeight: pw.FontWeight.bold)),
                              pw.Text(
                                profile.address.isNotEmpty
                                    ? profile.address
                                    : 'Ecraftz, A9, First floor, NV Tower, Kallai, Kozhikode 673003',
                                style: const pw.TextStyle(
                                    fontSize: 8, color: PdfColors.grey700),
                              ),
                              pw.Text(
                                'GSTIN: ${profile.gstin.isNotEmpty ? profile.gstin : "32AAYFE1819K1Z4"}',
                                style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 12),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                inv.clientName.isNotEmpty
                                    ? inv.clientName
                                    : 'CLIENT NAME',
                                style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold),
                              ),
                              pw.Text(
                                inv.clientAddress?.isNotEmpty == true
                                    ? inv.clientAddress!
                                    : 'INDIA',
                                style: const pw.TextStyle(
                                    fontSize: 8, color: PdfColors.grey700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // Itemized Table
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              headerStyle: pw.TextStyle(
                  fontSize: 8, fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey200),
              headers: [
                'S.No',
                'Description',
                'HSN/SAC',
                'Unit',
                'Rate',
                'Disc',
                'SGST %',
                'SGST Amt',
                'CGST %',
                'CGST Amt',
                'Net Amt'
              ],
              data: inv.items.asMap().entries.map((e) {
                final idx = e.key + 1;
                final item = e.value;
                return [
                  '$idx',
                  item.description,
                  item.hsnSac ?? '-',
                  item.category ?? 'Nos',
                  item.unitPrice.toStringAsFixed(2),
                  item.discountAmount > 0
                      ? item.discountAmount.toStringAsFixed(0)
                      : '0.0%',
                  '${item.sgstRate.toStringAsFixed(1)}%',
                  item.sgstAmount.toStringAsFixed(2),
                  '${item.cgstRate.toStringAsFixed(1)}%',
                  item.cgstAmount.toStringAsFixed(2),
                  item.total.toStringAsFixed(2),
                ];
              }).toList(),
            ),

            pw.SizedBox(height: 16),

            // Totals and Bank Details
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 6,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('TOTAL IN WORDS:',
                          style: pw.TextStyle(
                              fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text(_numberToWordsIndian(inv.grossAmount),
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              fontStyle: pw.FontStyle.italic)),
                      pw.SizedBox(height: 14),
                      pw.Text('BANK ACCOUNT DETAILS:',
                          style: pw.TextStyle(
                              fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Company: ECRAFTZ TECHNOLOGIES PVT LTD',
                          style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('Account No: 751405500282',
                          style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('IFSC Code: ICIC0007514',
                          style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('Bank: ICICI Bank (ICIC1)',
                          style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('Branch: Calicut, Medical College',
                          style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  flex: 4,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Sub Total',
                                style: const pw.TextStyle(fontSize: 8)),
                            pw.Text(inv.subtotal.toStringAsFixed(2),
                                style: const pw.TextStyle(fontSize: 8)),
                          ],
                        ),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                                'CGST (${(inv.items.firstOrNull?.cgstRate ?? 0.0).toStringAsFixed(1)}%)',
                                style: const pw.TextStyle(fontSize: 8)),
                            pw.Text(inv.totalCgst.toStringAsFixed(2),
                                style: const pw.TextStyle(fontSize: 8)),
                          ],
                        ),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                                'SGST (${(inv.items.firstOrNull?.sgstRate ?? 0.0).toStringAsFixed(1)}%)',
                                style: const pw.TextStyle(fontSize: 8)),
                            pw.Text(inv.totalSgst.toStringAsFixed(2),
                                style: const pw.TextStyle(fontSize: 8)),
                          ],
                        ),
                        pw.Divider(color: PdfColors.grey400),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Total',
                                style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold)),
                            pw.Text('₹${inv.grossAmount.toStringAsFixed(2)}',
                                style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                children: [
                  pw.Container(width: 120, height: 0.5, color: PdfColors.grey700),
                  pw.SizedBox(height: 2),
                  pw.Text('Authorized Signature',
                      style: pw.TextStyle(
                          fontSize: 8, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }
}

class _DocTableCell extends StatelessWidget {
  final String text;
  final bool isHeader;
  final bool isBold;
  final bool alignRight;
  final bool alignCenter;

  const _DocTableCell(
    this.text, {
    this.isHeader = false,
    this.isBold = false,
    this.alignRight = false,
    this.alignCenter = false,
  });

  @override
  Widget build(BuildContext context) {
    TextAlign align = TextAlign.left;
    if (alignRight) align = TextAlign.right;
    if (alignCenter) align = TextAlign.center;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: isHeader ? 9.5 : 9.0,
          fontWeight: isHeader || isBold ? FontWeight.w800 : FontWeight.w500,
          color: isHeader ? const Color(0xFF334155) : const Color(0xFF0F172A),
        ),
      ),
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

  late String _documentType;
  late String _branch;
  late String _invoiceNum;
  late DateTime _issueDate;
  late DateTime _dueDate;
  late String _placeOfSupply;
  String? _selectedCrmClient;
  late TextEditingController _clientNameCtrl;
  late TextEditingController _clientAddressCtrl;
  String? _selectedProject;
  late InvoiceStatus _status;

  late TextEditingController _notesCtrl;
  late TextEditingController _termsCtrl;

  final List<InvoiceItem> _items = [];

  final List<String> _docTypeOptions = [
    'Invoice',
    'Proforma Invoice',
    'Estimate',
    'Credit Note'
  ];
  final List<String> _branchOptions = [
    'Head Office (HO)',
    'Calicut Branch',
    'Cochin Branch'
  ];
  final List<String> _stateCodeOptions = [
    '(32) Kerala',
    '(33) Tamil Nadu',
    '(27) Maharashtra',
    '(29) Karnataka',
    '(07) Delhi',
    'Outside India'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingInvoice != null) {
      final inv = widget.existingInvoice!;
      _documentType = inv.documentType ?? 'Invoice';
      _branch = inv.branchId ?? 'Head Office (HO)';
      _invoiceNum = inv.invoiceNumber;
      _issueDate = inv.issuedDate;
      _dueDate = inv.dueDate;
      _placeOfSupply = inv.placeOfSupply ?? '(32) Kerala';
      _selectedCrmClient = inv.clientName.isNotEmpty ? inv.clientName : null;
      _clientNameCtrl = TextEditingController(text: inv.clientName);
      _clientAddressCtrl =
          TextEditingController(text: inv.clientAddress ?? '');
      _selectedProject =
          inv.clientEntity.isNotEmpty ? inv.clientEntity : null;
      _status = inv.status;
      _notesCtrl = TextEditingController(
          text: (inv.notes != null && inv.notes!.isNotEmpty)
              ? inv.notes!
              : 'Thank you for your business!');
      _termsCtrl = TextEditingController(
          text: (inv.terms != null && inv.terms!.isNotEmpty)
              ? inv.terms!
              : '1. Payment should be made to our official bank account.\n2. Invoices are subject to 18% GST.');

      if (inv.items.isNotEmpty) {
        for (final item in inv.items) {
          _items.add(InvoiceItem(
            id: item.id,
            invoiceId: item.invoiceId,
            itemName: item.itemName,
            description: item.description,
            hsnSac: item.hsnSac,
            category: item.category ?? 'Nos',
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            discountAmount: item.discountAmount,
            taxableValue: item.taxableValue,
            taxRuleId: item.taxRuleId,
            cgstAmount: item.cgstAmount,
            sgstAmount: item.sgstAmount,
            igstAmount: item.igstAmount,
            cessAmount: item.cessAmount,
            totalAmount: item.totalAmount,
            taxPercent: item.taxPercent,
          ));
        }
      } else {
        _items.add(InvoiceItem(
          description: 'Services',
          quantity: 1,
          unitPrice: 10000,
          cgstAmount: 900,
          sgstAmount: 900,
        ));
      }
    } else {
      _documentType = 'Invoice';
      _branch = 'Head Office (HO)';
      _invoiceNum =
          'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      _issueDate = DateTime.now();
      _dueDate = DateTime.now().add(const Duration(days: 15));
      _placeOfSupply = '(32) Kerala';
      _clientNameCtrl = TextEditingController();
      _clientAddressCtrl = TextEditingController();
      _status = InvoiceStatus.draft;
      _notesCtrl = TextEditingController(text: 'Thank you for your business!');
      _termsCtrl = TextEditingController(
          text:
              '1. Payment should be made to our official bank account.\n2. Invoices are subject to 18% GST.');
      _items.add(InvoiceItem(
        description: 'Web Development Services',
        quantity: 1,
        unitPrice: 10000,
        cgstAmount: 900,
        sgstAmount: 900,
      ));
    }
  }

  @override
  void dispose() {
    _clientNameCtrl.dispose();
    _clientAddressCtrl.dispose();
    _notesCtrl.dispose();
    _termsCtrl.dispose();
    super.dispose();
  }

  double get subtotal =>
      _items.fold(0.0, (sum, i) => sum + (i.quantity * i.unitPrice));
  double get totalDiscount =>
      _items.fold(0.0, (sum, i) => sum + i.discountAmount);
  double get taxableValue => subtotal - totalDiscount;
  double get totalCgst => _items.fold(0.0, (sum, i) => sum + i.cgstAmount);
  double get totalSgst => _items.fold(0.0, (sum, i) => sum + i.sgstAmount);
  double get totalIgst => _items.fold(0.0, (sum, i) => sum + i.igstAmount);
  double get totalTax => totalCgst + totalSgst + totalIgst;
  double get grandTotal => taxableValue + totalTax;

  void _recalculateItemTax(InvoiceItem item, double taxPercent) {
    item.taxPercent = taxPercent;
    final itemTaxable =
        (item.quantity * item.unitPrice) - item.discountAmount;
    if (taxPercent > 0) {
      item.cgstAmount = itemTaxable * ((taxPercent / 2) / 100);
      item.sgstAmount = itemTaxable * ((taxPercent / 2) / 100);
      item.igstAmount = 0.0;
    } else {
      item.cgstAmount = 0.0;
      item.sgstAmount = 0.0;
      item.igstAmount = 0.0;
    }
  }

  Future<void> _pickDate(
      BuildContext context, DateTime initial, Function(DateTime) onPicked) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      onPicked(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 768;

    final clientState = context.watch<ClientBloc>().state;
    final projectState = context.watch<ProjectBloc>().state;

    // Build CRM client choices
    final List<String> crmClientOptions = clientState.clients
        .map((c) => c.name)
        .where((n) => n.trim().isNotEmpty)
        .toSet()
        .toList();
    if (_selectedCrmClient != null &&
        _selectedCrmClient!.trim().isNotEmpty &&
        !crmClientOptions.contains(_selectedCrmClient)) {
      crmClientOptions.insert(0, _selectedCrmClient!);
    }

    // Build project choices
    final List<String> projectOptions = projectState.projects
        .map((p) => p.name)
        .where((n) => n.trim().isNotEmpty)
        .toSet()
        .toList();
    if (_selectedProject != null &&
        _selectedProject!.trim().isNotEmpty &&
        !projectOptions.contains(_selectedProject)) {
      projectOptions.insert(0, _selectedProject!);
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.94,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Modal Top Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.bgCardDark : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                  bottom: BorderSide(color: AppTheme.borderOf(context)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.existingInvoice == null
                              ? 'Create Invoice'
                              : 'Edit Invoice',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimaryOf(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'ECRAFTZ TEMPLATE BUILDER',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form Body (Responsive Layout)
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 24 : 14,
                  vertical: 16,
                ),
                children: [
                  // SECTION 1: Document Details Card
                  _buildFormSectionCard(
                    context,
                    title: 'DOCUMENT & CLIENT METADATA',
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Document Type, Branch, Invoice #
                        _buildResponsiveFieldGrid(
                          isWide: isWide,
                          children: [
                            DropdownButtonFormField<String>(
                              value: _docTypeOptions.contains(_documentType)
                                  ? _documentType
                                  : _docTypeOptions.first,
                              decoration: _formInputDec(context, 'DOCUMENT TYPE', isDark: isDark),
                              items: _docTypeOptions
                                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                                  .toList(),
                              onChanged: (v) => setState(() => _documentType = v!),
                            ),
                            DropdownButtonFormField<String>(
                              value: _branchOptions.contains(_branch)
                                  ? _branch
                                  : _branchOptions.first,
                              decoration: _formInputDec(context, 'BRANCH', isDark: isDark),
                              items: _branchOptions
                                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                                  .toList(),
                              onChanged: (v) => setState(() => _branch = v!),
                            ),
                            TextFormField(
                              initialValue: _invoiceNum,
                              decoration: _formInputDec(context, 'INVOICE/ESTIMATE #', isDark: isDark),
                              onChanged: (v) => _invoiceNum = v,
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Row 2: Issue Date, Due Date, Place of Supply
                        _buildResponsiveFieldGrid(
                          isWide: isWide,
                          children: [
                            InkWell(
                              onTap: () => _pickDate(context, _issueDate,
                                  (d) => setState(() => _issueDate = d)),
                              child: IgnorePointer(
                                child: TextFormField(
                                  controller: TextEditingController(
                                      text: DateFormat('dd-MM-yyyy')
                                          .format(_issueDate)),
                                  decoration: _formInputDec(
                                    context,
                                    'ISSUE DATE',
                                    isDark: isDark,
                                    suffixIcon: Icons.calendar_today_outlined,
                                  ),
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => _pickDate(context, _dueDate,
                                  (d) => setState(() => _dueDate = d)),
                              child: IgnorePointer(
                                child: TextFormField(
                                  controller: TextEditingController(
                                      text: DateFormat('dd-MM-yyyy')
                                          .format(_dueDate)),
                                  decoration: _formInputDec(
                                    context,
                                    'DUE DATE',
                                    isDark: isDark,
                                    suffixIcon: Icons.calendar_today_outlined,
                                  ),
                                ),
                              ),
                            ),
                            DropdownButtonFormField<String>(
                              value: _stateCodeOptions.contains(_placeOfSupply)
                                  ? _placeOfSupply
                                  : _stateCodeOptions.first,
                              decoration: _formInputDec(context, 'PLACE OF SUPPLY', isDark: isDark),
                              items: _stateCodeOptions
                                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                  .toList(),
                              onChanged: (v) => setState(() => _placeOfSupply = v!),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Row 3: Link CRM Client & Client Name & Address
                        _buildResponsiveFieldGrid(
                          isWide: isWide,
                          children: [
                            DropdownButtonFormField<String>(
                              value: _selectedCrmClient,
                              decoration: _formInputDec(
                                  context, 'LINK CRM CLIENT (OPTIONAL)',
                                  isDark: isDark),
                              items: crmClientOptions
                                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedCrmClient = val;
                                  if (val != null) {
                                    _clientNameCtrl.text = val;
                                  }
                                });
                              },
                            ),
                            TextFormField(
                              controller: _clientNameCtrl,
                              decoration: _formInputDec(context, 'CLIENT NAME', isDark: isDark),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                            TextFormField(
                              controller: _clientAddressCtrl,
                              decoration: _formInputDec(context, 'CLIENT ADDRESS', isDark: isDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Row 4: Project & Status
                        _buildResponsiveFieldGrid(
                          isWide: isWide,
                          children: [
                            DropdownButtonFormField<String>(
                              value: _selectedProject,
                              decoration: _formInputDec(context, 'PROJECT (OPTIONAL)', isDark: isDark),
                              items: projectOptions
                                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                                  .toList(),
                              onChanged: (v) => setState(() => _selectedProject = v),
                            ),
                            DropdownButtonFormField<InvoiceStatus>(
                              value: _status,
                              decoration: _formInputDec(context, 'STATUS', isDark: isDark),
                              items: InvoiceStatus.values
                                  .map((s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s.label.toUpperCase()),
                                      ))
                                  .toList(),
                              onChanged: (v) => setState(() => _status = v!),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // SECTION 2: Line Items Card
                  _buildFormSectionCard(
                    context,
                    title: 'LINE ITEMS',
                    isDark: isDark,
                    headerAction: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _items.add(InvoiceItem(
                            description: '',
                            quantity: 1,
                            unitPrice: 0,
                            cgstAmount: 0,
                            sgstAmount: 0,
                          ));
                        });
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Row'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    child: Column(
                      children: _items.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final item = entry.value;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.borderOf(context)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'ITEM #${idx + 1}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: _kPrimary,
                                    ),
                                  ),
                                  if (_items.length > 1)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                      onPressed: () {
                                        setState(() => _items.removeAt(idx));
                                      },
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildResponsiveFieldGrid(
                                isWide: isWide,
                                children: [
                                  TextFormField(
                                    initialValue: item.itemName ?? item.description,
                                    decoration: _formInputDec(context, 'Item Name', isDark: isDark),
                                    onChanged: (v) {
                                      item.itemName = v;
                                      if (item.description.isEmpty) item.description = v;
                                    },
                                  ),
                                  TextFormField(
                                    initialValue: item.hsnSac ?? '',
                                    decoration: _formInputDec(context, 'HSN/SAC Code', isDark: isDark),
                                    onChanged: (v) => item.hsnSac = v,
                                  ),
                                  TextFormField(
                                    initialValue: item.description,
                                    decoration: _formInputDec(context, 'Description / Category', isDark: isDark),
                                    onChanged: (v) => item.description = v,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _buildResponsiveFieldGrid(
                                isWide: isWide,
                                children: [
                                  TextFormField(
                                    initialValue: item.quantity.toString(),
                                    keyboardType: TextInputType.number,
                                    decoration: _formInputDec(context, 'Quantity', isDark: isDark),
                                    onChanged: (v) {
                                      setState(() {
                                        item.quantity = double.tryParse(v) ?? 1.0;
                                        _recalculateItemTax(item, item.taxPercent);
                                      });
                                    },
                                  ),
                                  TextFormField(
                                    initialValue: item.unitPrice.toString(),
                                    keyboardType: TextInputType.number,
                                    decoration: _formInputDec(context, 'Unit Price (₹)', isDark: isDark),
                                    onChanged: (v) {
                                      setState(() {
                                        item.unitPrice = double.tryParse(v) ?? 0.0;
                                        _recalculateItemTax(item, item.taxPercent);
                                      });
                                    },
                                  ),
                                  TextFormField(
                                    initialValue: item.discountAmount.toString(),
                                    keyboardType: TextInputType.number,
                                    decoration: _formInputDec(context, 'Discount (₹)', isDark: isDark),
                                    onChanged: (v) {
                                      setState(() {
                                        item.discountAmount = double.tryParse(v) ?? 0.0;
                                        _recalculateItemTax(item, item.taxPercent);
                                      });
                                    },
                                  ),
                                  DropdownButtonFormField<double>(
                                    value: item.taxPercent,
                                    decoration: _formInputDec(context, 'GST Slab', isDark: isDark),
                                    items: const [
                                      DropdownMenuItem(value: 0.0, child: Text('Exempt (0%)')),
                                      DropdownMenuItem(value: 5.0, child: Text('GST 5%')),
                                      DropdownMenuItem(value: 12.0, child: Text('GST 12%')),
                                      DropdownMenuItem(value: 18.0, child: Text('GST 18% (Standard)')),
                                      DropdownMenuItem(value: 28.0, child: Text('GST 28%')),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) {
                                        setState(() {
                                          _recalculateItemTax(item, v);
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // SECTION 3: Remarks, Terms & Conditions
                  _buildFormSectionCard(
                    context,
                    title: 'REMARKS & TERMS',
                    isDark: isDark,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _notesCtrl,
                          maxLines: 2,
                          decoration: _formInputDec(context, 'REMARKS / NOTES', isDark: isDark),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _termsCtrl,
                          maxLines: 3,
                          decoration: _formInputDec(context, 'TERMS & CONDITIONS', isDark: isDark),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // SECTION 4: Financial Summary Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.bgCardDark : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kPrimary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        _formSummaryRow('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
                        if (totalDiscount > 0)
                          _formSummaryRow('Total Discount', '- ₹${totalDiscount.toStringAsFixed(2)}'),
                        _formSummaryRow('Taxable Value', '₹${taxableValue.toStringAsFixed(2)}'),
                        _formSummaryRow('CGST Amount', '₹${totalCgst.toStringAsFixed(2)}'),
                        _formSummaryRow('SGST Amount', '₹${totalSgst.toStringAsFixed(2)}'),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Grand Total',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimaryOf(context),
                              ),
                            ),
                            Text(
                              '₹${grandTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: _kPrimary,
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

            // Bottom Action Controls
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.bgCardDark : Colors.white,
                border: Border(
                  top: BorderSide(color: AppTheme.borderOf(context)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: AppTheme.borderOf(context)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final invoice = Invoice(
                            id: widget.existingInvoice?.id ?? '',
                            invoiceNumber: _invoiceNum,
                            clientName: _clientNameCtrl.text.trim().isNotEmpty
                                ? _clientNameCtrl.text.trim()
                                : (_selectedCrmClient ?? 'Client'),
                            clientEntity: _selectedProject ?? 'No project',
                            clientAddress: _clientAddressCtrl.text.trim(),
                            issuedDate: _issueDate,
                            dueDate: _dueDate,
                            placeOfSupply: _placeOfSupply,
                            documentType: _documentType,
                            branchId: _branch,
                            status: _status,
                            notes: _notesCtrl.text.trim(),
                            terms: _termsCtrl.text.trim(),
                            dbGrandTotal: grandTotal,
                            items: _items,
                          );
                          widget.onSave(invoice);
                          Navigator.pop(context);
                          AppSnackBar.showCustom(context, 
                            SnackBar(
                              content: Text(
                                  'Invoice #${invoice.invoiceNumber} saved successfully!'),
                              backgroundColor: const Color(0xFF10B981),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text(
                        'SAVE & GENERATE',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildFormSectionCard(
    BuildContext context, {
    required String title,
    required Widget child,
    required bool isDark,
    Widget? headerAction,
  }) {
    return Container(
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
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textSecondaryOf(context),
                  letterSpacing: 0.8,
                ),
              ),
              if (headerAction != null) headerAction,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  static Widget _buildResponsiveFieldGrid({
    required bool isWide,
    required List<Widget> children,
  }) {
    if (isWide && children.length > 1) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children
            .map((c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: c,
                  ),
                ))
            .toList(),
      );
    }

    return Column(
      children: children
          .map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: c,
              ))
          .toList(),
    );
  }

  static InputDecoration _formInputDec(BuildContext context, String label,
      {required bool isDark, IconData? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle:
          TextStyle(fontSize: 11, color: AppTheme.textSecondaryOf(context)),
      suffixIcon: suffixIcon != null ? Icon(suffixIcon, size: 18) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppTheme.borderOf(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppTheme.borderOf(context)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: _kPrimary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
    );
  }

  static Widget _formSummaryRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          Text(val,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A))),
        ],
      ),
    );
  }
}

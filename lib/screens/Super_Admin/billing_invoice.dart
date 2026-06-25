// billing_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../blocs/billing/billing_bloc.dart';
import '../../models/billing_model.dart';
import '../../widgets/app_drawer.dart';
import '../../theme/app_theme.dart';
import '../../blocs/theme/theme_bloc.dart';

const _indianStates = [
  'Andhra Pradesh','Arunachal Pradesh','Assam','Bihar','Chhattisgarh',
  'Goa','Gujarat','Haryana','Himachal Pradesh','Jharkhand','Karnataka',
  'Kerala','Madhya Pradesh','Maharashtra','Manipur','Meghalaya','Mizoram',
  'Nagaland','Odisha','Punjab','Rajasthan','Sikkim','Tamil Nadu',
  'Telangana','Tripura','Uttar Pradesh','Uttarakhand','West Bengal',
  'Delhi','Jammu & Kashmir','Ladakh',
];

const _kPrimary = Color(0xFF00BCD4);
const _kAccent  = Color(0xFF1A2B4A);

// ─── MAIN PAGE ────────────────────────────────────────────────────────────────

class BillingPage extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  const BillingPage({super.key, required this.selectedIndex, required this.onItemSelected});

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchCtrl = TextEditingController();
  String _search = '';
  String _statusFilter = 'All';
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    context.read<BillingBloc>().add(LoadInvoicesEvent());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Invoice> _filtered(List<Invoice> invoices) {
    return invoices.where((inv) {
      final q = _search.toLowerCase();
      final matchSearch = q.isEmpty ||
          inv.invoiceNumber.toLowerCase().contains(q) ||
          inv.clientName.toLowerCase().contains(q) ||
          inv.clientEntity.toLowerCase().contains(q);
      final matchStatus = _statusFilter == 'All' || inv.status.label == _statusFilter;
      final matchFrom = _fromDate == null || !inv.issuedDate.isBefore(_fromDate!);
      final matchTo   = _toDate   == null || !inv.issuedDate.isAfter(_toDate!);
      return matchSearch && matchStatus && matchFrom && matchTo;
    }).toList();
  }

  double _totalInvoiced(List<Invoice> inv) => inv.fold(0, (s, i) => s + i.dbGrandTotal);
  double _totalPaid(List<Invoice> inv) => inv.fold(0, (s, i) => s + i.dbAmountPaid);
  double _outstanding(List<Invoice> inv) => inv.fold(0, (s, i) => s + i.dbAmountDue);

  void _showGstSettings(GstProfile profile) {
    showDialog(
      context: context,
      builder: (_) => _GstSettingsDialog(
        profile: profile,
        onSave: (p) => context.read<BillingBloc>().add(SaveGstProfileEvent(p)),
      ),
    );
  }

  void _showNewInvoice(GstProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewInvoiceSheet(
        gstProfile: profile,
        onSave: (inv) => context.read<BillingBloc>().add(AddInvoiceEvent(inv)),
      ),
    );
  }

  void _showInvoiceDetail(Invoice inv, GstProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InvoiceDetailSheet(
        invoice: inv,
        gstProfile: profile,
        onStatusChange: (s) =>
            context.read<BillingBloc>().add(UpdateInvoiceStatusEvent(inv.id, s)),
        onDelete: () =>
            context.read<BillingBloc>().add(DeleteInvoiceEvent(inv.id)),
      ),
    );
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _kPrimary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => isFrom ? _fromDate = picked : _toDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 650;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<BillingBloc, BillingState>(
      builder: (context, state) {
        final filtered = _filtered(state.invoices);
        return Scaffold(
          key: _scaffoldKey,
          drawer: AppDrawer(
            selectedIndex: widget.selectedIndex,
            onItemSelected: (i) {
              widget.onItemSelected(i);
              Navigator.pop(context);
            },
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            leading: isWide
                ? null
                : IconButton(
                    icon: Icon(Icons.menu_rounded,
                        color: isDark ? Colors.white : const Color(0xFF374151)),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Billing & Invoices',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimaryOf(context))),
                Text('Manage client invoicing, payments, and financial records.',
                    style: TextStyle(fontSize: 10, color: AppTheme.textSecondaryOf(context))),
              ],
            ),
            actions: [
              // GST settings
              IconButton(
                icon: Icon(Icons.shield_outlined,
                    color: isDark ? Colors.white : const Color(0xFF374151), size: 20),
                tooltip: 'GST Settings',
                onPressed: () => _showGstSettings(state.gstProfile),
              ),
              // Theme toggle
              BlocBuilder<ThemeBloc, ThemeState>(
                builder: (context, themeState) {
                  final isDarkTheme = themeState.themeMode == ThemeMode.dark;
                  return IconButton(
                    icon: Icon(
                      isDarkTheme ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      color: isDarkTheme ? Colors.white : const Color(0xFF374151),
                      size: 20,
                    ),
                    onPressed: () => context.read<ThemeBloc>().add(ToggleThemeEvent()),
                  );
                },
              ),
              // New Invoice button
              Padding(
                padding: const EdgeInsets.only(right: 12, left: 4),
                child: ElevatedButton.icon(
                  onPressed: () => _showNewInvoice(state.gstProfile),
                  icon: const Icon(Icons.add, size: 15),
                  label: const Text('New Invoice',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    elevation: 0,
                  ),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: AppTheme.borderOf(context)),
            ),
          ),
          body: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Stats cards
                    _buildStatsRow(state.invoices, isWide),
                    const SizedBox(height: 16),
                    // Filter section
                    _buildFilters(isWide),
                    const SizedBox(height: 12),
                    // Search bar
                    _buildSearch(),
                    const SizedBox(height: 6),
                    Text('${filtered.length} invoice${filtered.length == 1 ? '' : 's'} found',
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryOf(context))),
                    const SizedBox(height: 12),
                    // Invoice table
                    _buildTable(filtered, isWide, state.gstProfile),
                    const SizedBox(height: 32),
                  ],
                ),
        );
      },
    );
  }

  // ── STATS ────────────────────────────────────────────────────────────────────

  Widget _buildStatsRow(List<Invoice> invoices, bool isWide) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cards = [
      _StatCard(
        title: 'TOTAL INVOICED',
        value: _fmtAmount(invoices.fold(0.0, (s, i) => s + i.grossAmount)),
        icon: Icons.receipt_long_outlined,
        iconColor: _kAccent,
        bgColor: isDark ? AppTheme.bgCardDark : Colors.white,
        textColor: AppTheme.textPrimaryOf(context),
        count: '${invoices.length} invoices',
      ),
      _StatCard(
        title: 'AMOUNT PAID',
        value: _fmtAmount(_totalPaid(invoices)),
        icon: Icons.check_circle_outline_rounded,
        iconColor: const Color(0xFF10B981),
        bgColor: isDark ? const Color(0xFF08271C) : const Color(0xFFF0FDF4),
        textColor: const Color(0xFF10B981),
        count: '${invoices.where((i) => i.status == InvoiceStatus.paid).length} paid',
      ),
      _StatCard(
        title: 'OUTSTANDING',
        value: _fmtAmount(_outstanding(invoices)),
        icon: Icons.pending_outlined,
        iconColor: const Color(0xFFEF4444),
        bgColor: isDark ? const Color(0xFF2E0F12) : const Color(0xFFFEF2F2),
        textColor: const Color(0xFFEF4444),
        count: '${invoices.where((i) => i.status == InvoiceStatus.overdue || i.status == InvoiceStatus.sent).length} pending',
      ),
    ];

    return isWide
        ? Row(children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 10), child: c))).toList())
        : Column(children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 10), child: c)).toList());
  }

  // ── SEARCH ───────────────────────────────────────────────────────────────────

  Widget _buildSearch() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        border: Border.all(color: AppTheme.borderOf(context)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _search = v),
        style: TextStyle(color: AppTheme.textPrimaryOf(context), fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search by invoice #, client name, or project...',
          hintStyle: TextStyle(color: AppTheme.textMutedOf(context), fontSize: 12),
          prefixIcon: Icon(Icons.search, color: AppTheme.textMutedOf(context), size: 18),
          suffixIcon: _search.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close, size: 16, color: AppTheme.textSecondaryOf(context)),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _search = '');
                  })
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // ── FILTERS ──────────────────────────────────────────────────────────────────

  Widget _buildFilters(bool isWide) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statuses = ['All', ...InvoiceStatus.values.map((s) => s.label)];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_alt_outlined, size: 14, color: _kPrimary),
              const SizedBox(width: 6),
              Text('Filter Invoices',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryOf(context))),
              const Spacer(),
              if (_statusFilter != 'All' || _fromDate != null || _toDate != null)
                GestureDetector(
                  onTap: () => setState(() {
                    _statusFilter = 'All';
                    _fromDate = null;
                    _toDate = null;
                  }),
                  child: const Text('Clear All',
                      style: TextStyle(fontSize: 11, color: Color(0xFFEF4444),
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          isWide
              ? Row(
                  children: [
                    Expanded(child: _buildStatusFilter(statuses, isDark)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildDateBtn(true)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildDateBtn(false)),
                  ],
                )
              : Column(
                  children: [
                    _buildStatusFilter(statuses, isDark),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: _buildDateBtn(true)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildDateBtn(false)),
                    ]),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter(List<String> statuses, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
            color: AppTheme.textSecondaryOf(context), letterSpacing: 0.4)),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.bgCardDark : Colors.white,
            border: Border.all(color: AppTheme.borderOf(context)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _statusFilter,
              isExpanded: true,
              style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context)),
              dropdownColor: isDark ? AppTheme.bgCardDark : Colors.white,
              items: statuses
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s,
                            style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context))),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _statusFilter = v!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateBtn(bool isFrom) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final date = isFrom ? _fromDate : _toDate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isFrom ? 'FROM DATE' : 'TO DATE',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                color: AppTheme.textSecondaryOf(context), letterSpacing: 0.4)),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: () => _pickDate(isFrom),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.bgCardDark : Colors.white,
              border: Border.all(color: AppTheme.borderOf(context)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 13, color: AppTheme.textMutedOf(context)),
                const SizedBox(width: 6),
                Text(
                  date == null
                      ? (isFrom ? 'From Date' : 'To Date')
                      : DateFormat('dd MMM yyyy').format(date),
                  style: TextStyle(
                      fontSize: 12,
                      color: date == null
                          ? AppTheme.textMutedOf(context)
                          : AppTheme.textPrimaryOf(context)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── TABLE ────────────────────────────────────────────────────────────────────

  Widget _buildTable(List<Invoice> invoices, bool isWide, GstProfile gstProfile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Header row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            border: Border.all(color: AppTheme.borderOf(context)),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(
            children: [
              const Expanded(flex: 5, child: _TH('INVOICE #')),
              const Expanded(flex: 5, child: _TH('CLIENT')),
              const Expanded(flex: 4, child: _TH('AMOUNT')),
              if (isWide) const Expanded(flex: 4, child: _TH('DATES')),
              const Expanded(flex: 3, child: _TH('STATUS')),
              const SizedBox(width: 72),  // actions
            ],
          ),
        ),
        if (invoices.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.bgCardDark : Colors.white,
              border: Border(
                left: BorderSide(color: AppTheme.borderOf(context)),
                right: BorderSide(color: AppTheme.borderOf(context)),
                bottom: BorderSide(color: AppTheme.borderOf(context)),
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Center(
              child: Column(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                        color: _kPrimary.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.receipt_long_outlined, color: _kPrimary, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text('No invoices found',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryOf(context))),
                  const SizedBox(height: 4),
                  Text('Create your first invoice to get started.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryOf(context))),
                ],
              ),
            ),
          )
        else
          ...invoices.asMap().entries.map((e) => _InvoiceRow(
                invoice: e.value,
                isLast: e.key == invoices.length - 1,
                isWide: isWide,
                onTap: () => _showInvoiceDetail(e.value, gstProfile),
                onExportPdf: () => _exportPdf(e.value, gstProfile),
              )),
      ],
    );
  }

  // ── PDF EXPORT ────────────────────────────────────────────────────────────────

  Future<void> _exportPdf(Invoice inv, GstProfile gst) async {
    final pdfBytes = await _generateInvoicePdf(inv, gst);
    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: '${inv.invoiceNumber}.pdf',
    );
  }

  static String _fmtAmount(double v) {
    final f = NumberFormat('#,##,##0.00', 'en_IN');
    return '₹${f.format(v)}';
  }
}

// ─── PDF GENERATION ───────────────────────────────────────────────────────────

Future<Uint8List> _generateInvoicePdf(Invoice inv, GstProfile gst) async {
  final pdf = pw.Document();

  // Load logo from assets
  pw.MemoryImage? logoImage;
  try {
    final bytes = await rootBundle.load('assets/ecraftzlogolight.png');
    logoImage = pw.MemoryImage(bytes.buffer.asUint8List());
  } catch (_) {}

  const brandDark = PdfColor.fromInt(0xFF1A2B4A);
  const brandCyan = PdfColor.fromInt(0xFF00BCD4);
  const grey      = PdfColor.fromInt(0xFF6B7280);
  const lightGrey = PdfColor.fromInt(0xFFF1F5F9);
  const white     = PdfColors.white;

  final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  String fmtDate(DateTime d) => '${d.day} ${months[d.month - 1]} ${d.year}';

  String fmtMoney(double v) {
    final f = NumberFormat('#,##,##0.00', 'en_IN');
    return '₹${f.format(v)}';
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 48),
      header: (ctx) => pw.Column(
        children: [
          // Top header: logo + company info
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Logo
              if (logoImage != null)
                pw.Container(
                  width: 80,
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                )
              else
                pw.Container(
                  width: 80, height: 40,
                  color: brandCyan,
                  child: pw.Center(
                    child: pw.Text('ECRAFTZ',
                        style: pw.TextStyle(color: white, fontSize: 12,
                            fontWeight: pw.FontWeight.bold)),
                  ),
                ),
              pw.Spacer(),
              // Company info
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    gst.brandName.isNotEmpty ? gst.brandName : 'Ecraftz',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: brandDark),
                  ),
                  if (gst.address.isNotEmpty)
                    pw.Text(gst.address, style: pw.TextStyle(fontSize: 8, color: grey)),
                  pw.SizedBox(height: 2),
                  pw.Text(gst.phone, style: pw.TextStyle(fontSize: 8, color: grey)),
                  pw.Text(gst.email, style: pw.TextStyle(fontSize: 8, color: grey)),
                  if (gst.gstin.isNotEmpty)
                    pw.Text('GSTIN: ${gst.gstin}', style: pw.TextStyle(fontSize: 8, color: grey)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Divider(color: brandCyan, thickness: 1.5),
          pw.SizedBox(height: 4),
        ],
      ),
      build: (ctx) => [
        // ── Invoice header ──────────────────────────────────────────────────────
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('TAX INVOICE',
                      style: pw.TextStyle(fontSize: 8, letterSpacing: 2, color: brandCyan,
                          fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(inv.invoiceNumber,
                      style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: brandDark)),
                  pw.SizedBox(height: 6),
                  _pdfStatusBadge(inv.status),
                ],
              ),
            ),
            pw.SizedBox(width: 20),
            // Dates grid
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: lightGrey,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _pdfDetailRow('Issued On', fmtDate(inv.issuedDate), brandDark, grey),
                  pw.SizedBox(height: 6),
                  _pdfDetailRow('Due By', fmtDate(inv.dueDate), brandDark, grey),
                  pw.SizedBox(height: 6),
                  _pdfDetailRow('Currency', inv.currency, brandDark, grey),
                ],
              ),
            ),
          ],
        ),

        pw.SizedBox(height: 24),

        // ── Client info ────────────────────────────────────────────────────────
        pw.Container(
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: brandCyan, width: 0.8),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('BILLED TO',
                  style: pw.TextStyle(fontSize: 7, letterSpacing: 1.5, color: brandCyan,
                      fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Text(inv.clientName,
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: brandDark)),
              if (inv.clientEntity.isNotEmpty)
                pw.Text(inv.clientEntity,
                    style: pw.TextStyle(fontSize: 9, color: grey)),
              if (inv.clientEmail != null && inv.clientEmail!.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text(inv.clientEmail!,
                    style: pw.TextStyle(fontSize: 9, color: grey)),
              ],
              if (inv.clientPhone != null && inv.clientPhone!.isNotEmpty)
                pw.Text(inv.clientPhone!,
                    style: pw.TextStyle(fontSize: 9, color: grey)),
              if (inv.clientAddress != null && inv.clientAddress!.isNotEmpty)
                pw.Text(inv.clientAddress!,
                    style: pw.TextStyle(fontSize: 9, color: grey)),
            ],
          ),
        ),

        pw.SizedBox(height: 24),

        // ── Line items table ───────────────────────────────────────────────────
        pw.Text('ITEMS & SERVICES',
            style: pw.TextStyle(fontSize: 8, letterSpacing: 1.5, color: brandCyan,
                fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder(
            horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
            bottom: pw.BorderSide(color: brandCyan, width: 1),
          ),
          columnWidths: {
            0: const pw.FlexColumnWidth(4),
            1: const pw.FlexColumnWidth(1.2),
            2: const pw.FlexColumnWidth(1.8),
            3: const pw.FlexColumnWidth(1.2),
            4: const pw.FlexColumnWidth(1.8),
          },
          children: [
            // Table header
            pw.TableRow(
              decoration: pw.BoxDecoration(color: brandDark),
              children: [
                _pdfTH('DESCRIPTION', white),
                _pdfTH('QTY', white, align: pw.TextAlign.center),
                _pdfTH('UNIT PRICE', white, align: pw.TextAlign.right),
                _pdfTH('TAX', white, align: pw.TextAlign.center),
                _pdfTH('TOTAL', white, align: pw.TextAlign.right),
              ],
            ),
            // Items
            ...inv.items.map((item) => pw.TableRow(
              children: [
                _pdfTD(item.description, brandDark),
                _pdfTD('${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity}',
                    grey, align: pw.TextAlign.center),
                _pdfTD(fmtMoney(item.unitPrice), grey, align: pw.TextAlign.right),
                _pdfTD('${item.taxPercent.toStringAsFixed(0)}%', grey, align: pw.TextAlign.center),
                _pdfTD(fmtMoney(item.total), brandDark, align: pw.TextAlign.right,
                    bold: true),
              ],
            )),
          ],
        ),

        pw.SizedBox(height: 16),

        // ── Totals ────────────────────────────────────────────────────────────
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Container(
            width: 220,
            child: pw.Column(
              children: [
                _pdfTotalRow('Subtotal', fmtMoney(inv.subtotal), grey, brandDark),
                pw.Divider(color: PdfColors.grey300, height: 0.5),
                _pdfTotalRow('Tax', fmtMoney(inv.totalTax), grey, brandDark),
                pw.Divider(color: brandCyan, height: 1),
                pw.Container(
                  color: brandDark,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('TOTAL DUE',
                          style: pw.TextStyle(fontSize: 9, color: white,
                              fontWeight: pw.FontWeight.bold, letterSpacing: 0.5)),
                      pw.Text(fmtMoney(inv.grossAmount),
                          style: pw.TextStyle(fontSize: 13, color: brandCyan,
                              fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        pw.SizedBox(height: 28),

        // ── Notes ─────────────────────────────────────────────────────────────
        if (inv.notes.isNotEmpty) ...[
          pw.Text('NOTES',
              style: pw.TextStyle(fontSize: 8, letterSpacing: 1.5, color: brandCyan,
                  fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(inv.notes, style: pw.TextStyle(fontSize: 9, color: grey)),
          pw.SizedBox(height: 20),
        ],

        // ── Footer ────────────────────────────────────────────────────────────
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Thank you for your business!',
                style: pw.TextStyle(fontSize: 9, color: brandDark,
                    fontWeight: pw.FontWeight.bold, fontStyle: pw.FontStyle.italic)),
            pw.Text(gst.website,
                style: pw.TextStyle(fontSize: 8, color: brandCyan)),
          ],
        ),
      ],
    ),
  );

  return pdf.save();
}

pw.Widget _pdfStatusBadge(InvoiceStatus status) {
  final PdfColor c;
  final PdfColor bg;
  switch (status) {
    case InvoiceStatus.paid: c = const PdfColor.fromInt(0xFF10B981); bg = const PdfColor.fromInt(0xFFD1FAE5); break;
    case InvoiceStatus.overdue: c = const PdfColor.fromInt(0xFFEF4444); bg = const PdfColor.fromInt(0xFFFEE2E2); break;
    case InvoiceStatus.draft: c = const PdfColor.fromInt(0xFF6B7280); bg = const PdfColor.fromInt(0xFFF3F4F6); break;
    case InvoiceStatus.sent: c = const PdfColor.fromInt(0xFF3B82F6); bg = const PdfColor.fromInt(0xFFDEEBFF); break;
    case InvoiceStatus.cancelled: c = const PdfColor.fromInt(0xFF9CA3AF); bg = const PdfColor.fromInt(0xFFF9FAFB); break;
  }
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: pw.BoxDecoration(
      color: bg,
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
    ),
    child: pw.Text(status.label,
        style: pw.TextStyle(fontSize: 8, color: c, fontWeight: pw.FontWeight.bold)),
  );
}

pw.Widget _pdfDetailRow(String label, String value, PdfColor textColor, PdfColor labelColor) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text('$label  ', style: pw.TextStyle(fontSize: 8, color: labelColor)),
      pw.Text(value, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: textColor)),
    ],
  );
}

pw.Widget _pdfTH(String text, PdfColor color, {pw.TextAlign align = pw.TextAlign.left}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    child: pw.Text(text,
        textAlign: align,
        style: pw.TextStyle(fontSize: 7.5, color: color, fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.3)),
  );
}

pw.Widget _pdfTD(String text, PdfColor color,
    {pw.TextAlign align = pw.TextAlign.left, bool bold = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    child: pw.Text(text,
        textAlign: align,
        style: pw.TextStyle(
            fontSize: 8.5, color: color,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
  );
}

pw.Widget _pdfTotalRow(String label, String value, PdfColor labelColor, PdfColor valueColor) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 8.5, color: labelColor)),
        pw.Text(value, style: pw.TextStyle(fontSize: 8.5, color: valueColor, fontWeight: pw.FontWeight.bold)),
      ],
    ),
  );
}

// ─── STAT CARD ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color textColor;
  final String count;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.textColor,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? AppTheme.borderOf(context) : iconColor.withValues(alpha: 0.15)),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondaryOf(context), letterSpacing: 0.5)),
                const SizedBox(height: 6),
                Text(value,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textColor)),
                const SizedBox(height: 2),
                Text(count, style: TextStyle(fontSize: 10, color: AppTheme.textMutedOf(context))),
              ],
            ),
          ),
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
        ],
      ),
    );
  }
}

// ─── INVOICE ROW ─────────────────────────────────────────────────────────────

class _InvoiceRow extends StatelessWidget {
  final Invoice invoice;
  final bool isLast;
  final bool isWide;
  final VoidCallback onTap;
  final VoidCallback onExportPdf;

  const _InvoiceRow({
    required this.invoice,
    required this.isLast,
    required this.isWide,
    required this.onTap,
    required this.onExportPdf,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.bgCardDark : Colors.white,
          border: Border(
            left: BorderSide(color: AppTheme.borderOf(context)),
            right: BorderSide(color: AppTheme.borderOf(context)),
            bottom: BorderSide(color: AppTheme.borderOf(context)),
          ),
          borderRadius: isLast
              ? const BorderRadius.vertical(bottom: Radius.circular(12))
              : BorderRadius.zero,
        ),
        child: Row(
          children: [
            // Invoice #
            Expanded(
              flex: 5,
              child: Text(invoice.invoiceNumber,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            // Client
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(invoice.clientName,
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryOf(context)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (invoice.clientEntity.isNotEmpty)
                    Text(invoice.clientEntity,
                        style: TextStyle(fontSize: 10, color: AppTheme.textSecondaryOf(context)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            // Amount
            Expanded(
              flex: 4,
              child: Text(
                _fmtShort(invoice.grossAmount),
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryOf(context)),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ),
            // Dates (wide only)
            if (isWide)
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(invoice.formattedDue,
                        style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w600,
                            color: invoice.status == InvoiceStatus.overdue
                                ? const Color(0xFFEF4444)
                                : AppTheme.textSecondaryOf(context))),
                    Text(invoice.formattedIssued,
                        style: TextStyle(fontSize: 10, color: AppTheme.textMutedOf(context))),
                  ],
                ),
              ),
            // Status
            Expanded(
              flex: 3,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _StatusBadge(status: invoice.status),
              ),
            ),
            // Actions
            SizedBox(
              width: 72,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: onExportPdf,
                    child: const Icon(Icons.picture_as_pdf_outlined, size: 18, color: _kPrimary),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded,
                      size: 18, color: AppTheme.textMutedOf(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtShort(double v) {
    final f = NumberFormat('#,##,##0', 'en_IN');
    return '₹${f.format(v)}';
  }
}

// ─── INVOICE DETAIL SHEET ─────────────────────────────────────────────────────

class _InvoiceDetailSheet extends StatelessWidget {
  final Invoice invoice;
  final GstProfile gstProfile;
  final Function(InvoiceStatus) onStatusChange;
  final VoidCallback onDelete;

  const _InvoiceDetailSheet({
    required this.invoice,
    required this.gstProfile,
    required this.onStatusChange,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DraggableScrollableSheet(
      initialChildSize: 0.80,
      maxChildSize: 0.96,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.bgCardDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.borderOf(context),
                  borderRadius: BorderRadius.circular(2)),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(invoice.invoiceNumber,
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimaryOf(context))),
                        Text(invoice.clientName,
                            style: TextStyle(
                                fontSize: 13, color: AppTheme.textSecondaryOf(context))),
                      ],
                    ),
                  ),
                  _StatusBadge(status: invoice.status),
                  const SizedBox(width: 6),
                  // PDF export
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf_outlined, color: _kPrimary, size: 22),
                    tooltip: 'Export PDF',
                    onPressed: () async {
                      final pdfBytes = await _generateInvoicePdf(invoice, gstProfile);
                      await Printing.layoutPdf(
                        onLayout: (_) async => pdfBytes,
                        name: '${invoice.invoiceNumber}.pdf',
                      );
                    },
                  ),
                  // Status change menu
                  PopupMenuButton<InvoiceStatus>(
                    icon: Icon(Icons.more_vert, color: AppTheme.textSecondaryOf(context)),
                    tooltip: 'Change Status',
                    itemBuilder: (_) => InvoiceStatus.values
                        .map((s) => PopupMenuItem(
                              value: s,
                              child: Text(s.label,
                                  style: TextStyle(color: s.color, fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ))
                        .toList(),
                    onSelected: (s) {
                      onStatusChange(s);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            Divider(height: 20, color: AppTheme.borderOf(context)),
            // Body
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Date meta
                  Row(
                    children: [
                      Expanded(
                        child: _MetaBlock(
                            label: 'ISSUED ON',
                            value: DateFormat('dd MMM yyyy').format(invoice.issuedDate)),
                      ),
                      Expanded(
                        child: _MetaBlock(
                            label: 'DUE BY',
                            value: DateFormat('dd MMM yyyy').format(invoice.dueDate),
                            valueColor: invoice.status == InvoiceStatus.overdue
                                ? const Color(0xFFEF4444)
                                : null),
                      ),
                      if (invoice.clientEntity.isNotEmpty)
                        Expanded(
                          child: _MetaBlock(label: 'PROJECT', value: invoice.clientEntity),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Items table
                  _buildItemsTable(context, isDark),
                  const SizedBox(height: 16),

                  // Totals
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0C2C2F) : const Color(0xFFF0FDFE),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _kPrimary.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      children: [
                        _TotalRow('Subtotal', invoice.subtotal),
                        if (invoice.totalTax > 0) ...[
                          const SizedBox(height: 4),
                          _TotalRow('Tax', invoice.totalTax),
                        ],
                        const Divider(height: 16),
                        Row(
                          children: [
                            Text('Total Due',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimaryOf(context))),
                            const Spacer(),
                            Text(
                              _fmtAmount(invoice.grossAmount),
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w900, color: _kPrimary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  if (invoice.notes.isNotEmpty) ...[
                    Text('Notes',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondaryOf(context), letterSpacing: 0.4)),
                    const SizedBox(height: 6),
                    Text(invoice.notes,
                        style: TextStyle(
                            fontSize: 13, color: AppTheme.textPrimaryOf(context), height: 1.5)),
                    const SizedBox(height: 16),
                  ],

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            onDelete();
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFEF4444)),
                          label: const Text('Delete',
                              style: TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFEF4444)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final pdfBytes = await _generateInvoicePdf(invoice, gstProfile);
                            await Printing.layoutPdf(
                              onLayout: (_) async => pdfBytes,
                              name: '${invoice.invoiceNumber}.pdf',
                            );
                          },
                          icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                          label: const Text('Export PDF', style: TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsTable(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderOf(context)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? _kAccent.withValues(alpha: 0.5) : _kAccent,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                Expanded(flex: 4, child: Text('Description',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: Colors.white))),
                Expanded(flex: 1, child: Text('Qty',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: Colors.white), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('Price',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: Colors.white), textAlign: TextAlign.right)),
                Expanded(flex: 2, child: Text('Total',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: Colors.white), textAlign: TextAlign.right)),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.borderOf(context)),
          // Items
          ...invoice.items.asMap().entries.map((e) {
            final item = e.value;
            final isLast = e.key == invoice.items.length - 1;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.description,
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimaryOf(context))),
                            if (item.category != null && item.category!.isNotEmpty)
                              Text(item.category!,
                                  style: TextStyle(
                                      fontSize: 10, color: AppTheme.textMutedOf(context))),
                            if (item.taxPercent > 0)
                              Text('Tax: ${item.taxPercent.toStringAsFixed(0)}%',
                                  style: const TextStyle(fontSize: 10, color: _kPrimary)),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text('${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity}',
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.textSecondaryOf(context)),
                            textAlign: TextAlign.center),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(_fmtAmount(item.unitPrice),
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.textSecondaryOf(context)),
                            textAlign: TextAlign.right),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(_fmtAmount(item.total),
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimaryOf(context)),
                            textAlign: TextAlign.right),
                      ),
                    ],
                  ),
                ),
                if (!isLast) Divider(height: 1, color: AppTheme.borderOf(context)),
              ],
            );
          }),
        ],
      ),
    );
  }

  static String _fmtAmount(double v) {
    final f = NumberFormat('#,##,##0.00', 'en_IN');
    return '₹${f.format(v)}';
  }
}

// ─── NEW INVOICE SHEET ────────────────────────────────────────────────────────

class _NewInvoiceSheet extends StatefulWidget {
  final GstProfile gstProfile;
  final Function(Invoice) onSave;

  const _NewInvoiceSheet({required this.gstProfile, required this.onSave});

  @override
  State<_NewInvoiceSheet> createState() => _NewInvoiceSheetState();
}

class _NewInvoiceSheetState extends State<_NewInvoiceSheet> {
  final _clientCtrl  = TextEditingController();
  final _entityCtrl  = TextEditingController();
  final _notesCtrl   = TextEditingController();
  InvoiceStatus _status = InvoiceStatus.draft;
  DateTime _issuedDate = DateTime.now();
  DateTime _dueDate    = DateTime.now().add(const Duration(days: 30));
  final List<InvoiceItem> _items = [InvoiceItem(description: '', unitPrice: 0)];

  double get _subtotal  => _items.fold(0, (s, i) => s + i.subtotal);
  double get _totalTax  => _items.fold(0, (s, i) => s + i.taxAmount);
  double get _grandTotal => _subtotal + _totalTax;

  void _addItem() => setState(() => _items.add(InvoiceItem(description: '', unitPrice: 0)));

  String _generateInvoiceNumber() {
    final now = DateTime.now();
    return 'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.millisecond}';
  }

  void _save() {
    if (_clientCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client name is required'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_items.every((i) => i.description.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one line item'), backgroundColor: Colors.red),
      );
      return;
    }

    final validItems = _items.where((i) => i.description.isNotEmpty).toList();

    final inv = Invoice(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      invoiceNumber: _generateInvoiceNumber(),
      clientName: _clientCtrl.text.trim(),
      clientEntity: _entityCtrl.text.trim(),
      items: validItems,
      status: _status,
      issuedDate: _issuedDate,
      dueDate: _dueDate,
      notes: _notesCtrl.text.trim(),
    );
    widget.onSave(inv);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invoice created successfully!'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  Future<void> _pickDate(bool isIssued) async {
    final d = await showDatePicker(
      context: context,
      initialDate: isIssued ? _issuedDate : _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: _kPrimary)),
        child: child!,
      ),
    );
    if (d != null) setState(() => isIssued ? _issuedDate = d : _dueDate = d);
  }

  @override
  void dispose() {
    _clientCtrl.dispose();
    _entityCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.97,
      minChildSize: 0.5,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.bgCardDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.borderOf(context), borderRadius: BorderRadius.circular(2)),
            ),
            // Sheet header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('New Invoice',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimaryOf(context))),
                      Text('Fill in the details to create a new invoice.',
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.textSecondaryOf(context))),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: AppTheme.textSecondaryOf(context)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(height: 16, color: AppTheme.borderOf(context)),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // ── Client info ──────────────────────────────────────────────
                  _SheetSection(label: 'CLIENT INFORMATION', icon: Icons.person_outline),
                  const SizedBox(height: 10),
                  _FormField('Client Name', _clientCtrl, hint: 'Enter client name'),
                  const SizedBox(height: 10),
                  _FormField('Project / Entity', _entityCtrl, hint: 'Enter project or entity name'),
                  const SizedBox(height: 16),

                  // ── Status + Dates ───────────────────────────────────────────
                  _SheetSection(label: 'INVOICE DETAILS', icon: Icons.receipt_outlined),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusDropdown(isDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildDatePicker('ISSUE DATE', _issuedDate, true)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildDatePicker('DUE DATE', _dueDate, false)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Line items ───────────────────────────────────────────────
                  Row(
                    children: [
                      _SheetSection(label: 'LINE ITEMS', icon: Icons.list_alt_outlined),
                      const Spacer(),
                      GestureDetector(
                        onTap: _addItem,
                        child: const Row(
                          children: [
                            Icon(Icons.add, size: 14, color: _kPrimary),
                            SizedBox(width: 4),
                            Text('Add Item',
                                style: TextStyle(
                                    fontSize: 12, color: _kPrimary,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._items.asMap().entries.map((e) => _LineItemRow(
                        item: e.value,
                        index: e.key,
                        canDelete: _items.length > 1,
                        onDelete: () => setState(() => _items.removeAt(e.key)),
                        onChanged: () => setState(() {}),
                      )),

                  // Grand total
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0C2C2F) : const Color(0xFFF0FDFE),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _kPrimary.withValues(alpha: isDark ? 0.4 : 0.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Subtotal',
                                style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryOf(context))),
                            Text('₹${_subtotal.toStringAsFixed(2)}',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimaryOf(context))),
                          ],
                        ),
                        if (_totalTax > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Tax',
                                  style: TextStyle(fontSize: 12,
                                      color: AppTheme.textSecondaryOf(context))),
                              Text('₹${_totalTax.toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimaryOf(context))),
                            ],
                          ),
                        ],
                        const Divider(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Grand Total',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimaryOf(context))),
                            Text('₹${_grandTotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w900, color: _kPrimary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Notes ────────────────────────────────────────────────────
                  _SheetSection(label: 'NOTES', icon: Icons.notes_outlined),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    style: TextStyle(color: AppTheme.textPrimaryOf(context), fontSize: 13),
                    decoration: _inputDec(context, 'Payment terms, thank you note...',
                        isDark: isDark),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text('Create Invoice',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdown(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('STATUS',
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: AppTheme.textSecondaryOf(context), letterSpacing: 0.4)),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.bgCardDark : Colors.white,
            border: Border.all(color: AppTheme.borderOf(context)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<InvoiceStatus>(
              value: _status,
              isExpanded: true,
              dropdownColor: isDark ? AppTheme.bgCardDark : Colors.white,
              style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context)),
              items: InvoiceStatus.values
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.label,
                            style: TextStyle(
                                fontSize: 13, color: AppTheme.textPrimaryOf(context))),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(String label, DateTime date, bool isIssued) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: AppTheme.textSecondaryOf(context), letterSpacing: 0.4)),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: () => _pickDate(isIssued),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderOf(context)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 13, color: _kPrimary),
                const SizedBox(width: 8),
                Text(DateFormat('dd MMM yyyy').format(date),
                    style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── LINE ITEM ROW ────────────────────────────────────────────────────────────

class _LineItemRow extends StatefulWidget {
  final InvoiceItem item;
  final int index;
  final bool canDelete;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const _LineItemRow({
    required this.item,
    required this.index,
    required this.canDelete,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  State<_LineItemRow> createState() => _LineItemRowState();
}

class _LineItemRowState extends State<_LineItemRow> {
  late TextEditingController _descCtrl, _categoryCtrl, _qtyCtrl, _priceCtrl, _taxCtrl;

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(text: widget.item.description);
    _categoryCtrl = TextEditingController(text: widget.item.category ?? '');
    _qtyCtrl = TextEditingController(text: widget.item.quantity.toString());
    _priceCtrl = TextEditingController(
        text: widget.item.unitPrice > 0 ? widget.item.unitPrice.toString() : '');
    _taxCtrl = TextEditingController(
        text: widget.item.taxPercent > 0 ? widget.item.taxPercent.toString() : '');
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _categoryCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _taxCtrl.dispose();
    super.dispose();
  }

  void _update() {
    widget.item.description = _descCtrl.text;
    widget.item.category    = _categoryCtrl.text.isEmpty ? null : _categoryCtrl.text;
    widget.item.quantity    = double.tryParse(_qtyCtrl.text) ?? 1;
    widget.item.unitPrice   = double.tryParse(_priceCtrl.text) ?? 0;
    widget.item.taxPercent  = double.tryParse(_taxCtrl.text) ?? 0;
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderOf(context)),
        borderRadius: BorderRadius.circular(10),
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('${widget.index + 1}',
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700, color: _kPrimary)),
                ),
              ),
              const SizedBox(width: 6),
              Text('Item ${widget.index + 1}',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondaryOf(context))),
              const Spacer(),
              if (widget.canDelete)
                GestureDetector(
                  onTap: widget.onDelete,
                  child: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFEF4444)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            onChanged: (_) => _update(),
            decoration: _lineInputDec(context, 'Item description', isDark: isDark),
            style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _categoryCtrl,
            onChanged: (_) => _update(),
            decoration: _lineInputDec(context, 'Category (optional)', isDark: isDark),
            style: TextStyle(fontSize: 12, color: AppTheme.textPrimaryOf(context)),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _qtyCtrl,
                  onChanged: (_) => _update(),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  decoration: _lineInputDec(context, 'Qty', isDark: isDark),
                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _priceCtrl,
                  onChanged: (_) => _update(),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  decoration: _lineInputDec(context, 'Unit Price (₹)', isDark: isDark),
                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _taxCtrl,
                  onChanged: (_) => _update(),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  decoration: _lineInputDec(context, 'Tax %', isDark: isDark),
                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Total: ₹${widget.item.total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _lineInputDec(BuildContext context, String hint, {required bool isDark}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppTheme.textMutedOf(context), fontSize: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: AppTheme.borderOf(context))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: AppTheme.borderOf(context))),
      focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
          borderSide: BorderSide(color: _kPrimary, width: 1.5)),
      filled: true,
      fillColor: isDark ? AppTheme.bgCardDark : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      isDense: true,
    );
  }
}

// ─── GST SETTINGS DIALOG ─────────────────────────────────────────────────────

class _GstSettingsDialog extends StatefulWidget {
  final GstProfile profile;
  final Function(GstProfile) onSave;

  const _GstSettingsDialog({required this.profile, required this.onSave});

  @override
  State<_GstSettingsDialog> createState() => _GstSettingsDialogState();
}

class _GstSettingsDialogState extends State<_GstSettingsDialog> {
  late TextEditingController _gstinCtrl, _legalCtrl, _brandCtrl, _panCtrl;
  late TextEditingController _addrCtrl, _phoneCtrl, _emailCtrl, _websiteCtrl;
  String _state = '';

  @override
  void initState() {
    super.initState();
    _gstinCtrl   = TextEditingController(text: widget.profile.gstin);
    _legalCtrl   = TextEditingController(text: widget.profile.legalName);
    _brandCtrl   = TextEditingController(text: widget.profile.brandName);
    _panCtrl     = TextEditingController(text: widget.profile.panNumber);
    _addrCtrl    = TextEditingController(text: widget.profile.address);
    _phoneCtrl   = TextEditingController(text: widget.profile.phone);
    _emailCtrl   = TextEditingController(text: widget.profile.email);
    _websiteCtrl = TextEditingController(text: widget.profile.website);
    _state       = widget.profile.state;
  }

  @override
  void dispose() {
    _gstinCtrl.dispose(); _legalCtrl.dispose(); _brandCtrl.dispose(); _panCtrl.dispose();
    _addrCtrl.dispose(); _phoneCtrl.dispose(); _emailCtrl.dispose(); _websiteCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.onSave(GstProfile(
      gstin:     _gstinCtrl.text.trim(),
      legalName: _legalCtrl.text.trim(),
      brandName: _brandCtrl.text.trim(),
      panNumber: _panCtrl.text.trim(),
      state:     _state,
      address:   _addrCtrl.text.trim(),
      phone:     _phoneCtrl.text.trim(),
      email:     _emailCtrl.text.trim(),
      website:   _websiteCtrl.text.trim(),
    ));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Company profile saved!'),
          backgroundColor: Color(0xFF10B981)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: isDark ? AppTheme.bgCardDark : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.business_outlined, color: Color(0xFF10B981), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('COMPANY PROFILE',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimaryOf(context), letterSpacing: 0.3)),
                      Text('Used in PDF invoices and GST calculations.',
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.textSecondaryOf(context))),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: AppTheme.textSecondaryOf(context)),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Brand name
            _dlgRow([
              _dlgField('BRAND / TRADE NAME', _brandCtrl, 'Ecraftz', isDark),
              _dlgField('GSTIN', _gstinCtrl, 'E.G. 32AAAAA0000A1Z5', isDark),
            ]),
            const SizedBox(height: 14),
            _dlgRow([
              _dlgField('LEGAL BUSINESS NAME', _legalCtrl, 'As per GST registration', isDark),
              _dlgField('PAN NUMBER', _panCtrl, 'E.G. AAAAA0000A', isDark),
            ]),
            const SizedBox(height: 14),
            // Address (full width)
            _dlgLabel('ADDRESS'),
            const SizedBox(height: 5),
            dlgInput(context, _addrCtrl, '20/265, Kallai, Kozhikode, Kerala 673003',
                isDark: isDark),
            const SizedBox(height: 14),
            _dlgRow([
              _dlgField('PHONE', _phoneCtrl, '+91 79949 71118', isDark),
              _dlgField('EMAIL', _emailCtrl, 'contact@vbecraftz.com', isDark),
            ]),
            const SizedBox(height: 14),
            _dlgRow([
              _dlgField('WEBSITE', _websiteCtrl, 'www.vbecraftz.com', isDark),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dlgLabel('STATE OF REGISTRATION'),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.bgCardDark : Colors.white,
                      border: Border.all(color: AppTheme.borderOf(context)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _state.isEmpty ? null : _state,
                        hint: Text('Select state',
                            style: TextStyle(color: AppTheme.textMutedOf(context), fontSize: 13)),
                        isExpanded: true,
                        dropdownColor: isDark ? AppTheme.bgCardDark : Colors.white,
                        style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context)),
                        items: _indianStates
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s,
                                      style: TextStyle(
                                          fontSize: 13, color: AppTheme.textPrimaryOf(context))),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _state = v ?? ''),
                      ),
                    ),
                  ),
                ],
              ),
            ]),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined, size: 16),
                label: const Text('SAVE PROFILE',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dlgRow(List<Widget> children) {
    return Row(
      children: children.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 10), child: c))).toList(),
    );
  }

  Widget _dlgField(String label, TextEditingController ctrl, String hint, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _dlgLabel(label),
        const SizedBox(height: 5),
        dlgInput(context, ctrl, hint, isDark: isDark),
      ],
    );
  }

  Widget _dlgLabel(String text) {
    return Text(text,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700,
            color: AppTheme.textSecondaryOf(context), letterSpacing: 0.4));
  }
}

// ─── SHARED SMALL WIDGETS ─────────────────────────────────────────────────────

class _TH extends StatelessWidget {
  final String text;
  const _TH(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w700,
          color: AppTheme.textSecondaryOf(context), letterSpacing: 0.4));
}

class _StatusBadge extends StatelessWidget {
  final InvoiceStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: status.bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(status.label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w800,
              color: status.color, letterSpacing: 0.3)),
    );
  }
}

class _MetaBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _MetaBlock({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5,
                color: AppTheme.textMutedOf(context))),
        const SizedBox(height: 3),
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: valueColor ?? AppTheme.textPrimaryOf(context))),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double amount;

  const _TotalRow(this.label, this.amount);

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat('#,##,##0.00', 'en_IN');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryOf(context))),
        Text('₹${f.format(amount)}',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryOf(context))),
      ],
    );
  }
}

class _SheetSection extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SheetSection({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _kPrimary),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: _kPrimary, letterSpacing: 0.5)),
      ],
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final String hint;

  const _FormField(this.label, this.ctrl, {this.hint = ''});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: AppTheme.textSecondaryOf(context), letterSpacing: 0.4)),
        const SizedBox(height: 5),
        TextField(
          controller: ctrl,
          style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context)),
          decoration: _inputDec(context, hint, isDark: isDark),
        ),
      ],
    );
  }
}

InputDecoration _inputDec(BuildContext context, String hint, {required bool isDark}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: AppTheme.textMutedOf(context), fontSize: 13),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppTheme.borderOf(context))),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppTheme.borderOf(context))),
    focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: _kPrimary, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    filled: true,
    fillColor: isDark ? AppTheme.bgCardDark : Colors.white,
  );
}

Widget dlgInput(BuildContext context, TextEditingController ctrl, String hint,
    {required bool isDark}) {
  return TextField(
    controller: ctrl,
    style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context)),
    decoration: _inputDec(context, hint, isDark: isDark),
  );
}

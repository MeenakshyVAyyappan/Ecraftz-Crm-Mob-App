// billing_page.dart
import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

// ─── DATA MODELS ─────────────────────────────────────────────────────────────

enum InvoiceStatus { sent, paid, draft, overdue, cancelled }

extension InvoiceStatusExt on InvoiceStatus {
  String get label {
    switch (this) {
      case InvoiceStatus.sent: return 'SENT';
      case InvoiceStatus.paid: return 'PAID';
      case InvoiceStatus.draft: return 'DRAFT';
      case InvoiceStatus.overdue: return 'OVERDUE';
      case InvoiceStatus.cancelled: return 'CANCELLED';
    }
  }

  Color get color {
    switch (this) {
      case InvoiceStatus.sent: return const Color(0xFF3B82F6);
      case InvoiceStatus.paid: return const Color(0xFF10B981);
      case InvoiceStatus.draft: return const Color(0xFF6B7280);
      case InvoiceStatus.overdue: return const Color(0xFFEF4444);
      case InvoiceStatus.cancelled: return const Color(0xFF9CA3AF);
    }
  }
}

class InvoiceItem {
  String description;
  double quantity;
  double unitPrice;
  double taxPercent;

  InvoiceItem({
    required this.description,
    this.quantity = 1,
    required this.unitPrice,
    this.taxPercent = 0,
  });

  double get subtotal => quantity * unitPrice;
  double get taxAmount => subtotal * taxPercent / 100;
  double get total => subtotal + taxAmount;
}

class Invoice {
  final String id;
  final String invoiceNumber;
  String clientName;
  String clientEntity;
  List<InvoiceItem> items;
  InvoiceStatus status;
  final DateTime issuedDate;
  DateTime dueDate;
  String notes;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.clientName,
    required this.clientEntity,
    required this.items,
    required this.status,
    required this.issuedDate,
    required this.dueDate,
    this.notes = '',
  });

  double get grossAmount => items.fold(0, (s, i) => s + i.total);

  String get formattedDue {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return 'DUE: ${m[dueDate.month-1].toUpperCase()} ${dueDate.day}, ${dueDate.year}';
  }

  String get formattedIssued {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return 'Issued: ${m[issuedDate.month-1]} ${issuedDate.day}, ${issuedDate.year}';
  }
}

// ─── GST PROFILE MODEL ────────────────────────────────────────────────────────

class GstProfile {
  String gstin;
  String legalName;
  String brandName;
  String panNumber;
  String state;

  GstProfile({
    this.gstin = '',
    this.legalName = '',
    this.brandName = '',
    this.panNumber = '',
    this.state = '',
  });
}

const _indianStates = [
  'Andhra Pradesh','Arunachal Pradesh','Assam','Bihar','Chhattisgarh',
  'Goa','Gujarat','Haryana','Himachal Pradesh','Jharkhand','Karnataka',
  'Kerala','Madhya Pradesh','Maharashtra','Manipur','Meghalaya','Mizoram',
  'Nagaland','Odisha','Punjab','Rajasthan','Sikkim','Tamil Nadu',
  'Telangana','Tripura','Uttar Pradesh','Uttarakhand','West Bengal',
  'Delhi','Jammu & Kashmir','Ladakh',
];

// ─── MAIN PAGE ────────────────────────────────────────────────────────────────

class BillingPage extends StatefulWidget {
   final int selectedIndex;
  final Function(int) onItemSelected;  
  const BillingPage({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    });


  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchCtrl = TextEditingController();
  String _search = '';
  String _statusFilter = 'All Statuses';
  DateTime? _fromDate;
  DateTime? _toDate;
  GstProfile _gstProfile = GstProfile();

  final List<Invoice> _invoices = [
    Invoice(id:'1', invoiceNumber:'INV-432', clientName:'janani', clientEntity:'JANANI - WEB DEVELOPMENT DYNAMIC SPECIFICATION V1', items:[InvoiceItem(description:'Web Development', unitPrice:2000)], status:InvoiceStatus.sent, issuedDate:DateTime(2026,5,23), dueDate:DateTime(2026,5,23)),
    Invoice(id:'2', invoiceNumber:'INV-5446', clientName:'Steve rogers', clientEntity:'ARSENAL', items:[InvoiceItem(description:'Design', unitPrice:300)], status:InvoiceStatus.paid, issuedDate:DateTime(2026,5,12), dueDate:DateTime(2026,5,12)),
    Invoice(id:'3', invoiceNumber:'INV-5904', clientName:'shock stark', clientEntity:'ALIYA', items:[InvoiceItem(description:'Digital Marketing', unitPrice:300)], status:InvoiceStatus.paid, issuedDate:DateTime(2026,5,12), dueDate:DateTime(2026,5,12)),
    Invoice(id:'4', invoiceNumber:'INV-7344', clientName:'meethu', clientEntity:'CIVICEYE', items:[InvoiceItem(description:'SEO Services', unitPrice:200)], status:InvoiceStatus.sent, issuedDate:DateTime(2026,5,12), dueDate:DateTime(2026,5,12)),
    Invoice(id:'5', invoiceNumber:'INV-8821', clientName:'arsenal', clientEntity:'ARSENAL', items:[InvoiceItem(description:'Content Creation', unitPrice:500)], status:InvoiceStatus.draft, issuedDate:DateTime(2026,5,10), dueDate:DateTime(2026,5,30)),
    Invoice(id:'6', invoiceNumber:'INV-9012', clientName:'Viswajith e', clientEntity:'ECRAFTZ', items:[InvoiceItem(description:'Branding', unitPrice:1700)], status:InvoiceStatus.overdue, issuedDate:DateTime(2026,5,1), dueDate:DateTime(2026,5,15)),
  ];

  List<Invoice> get _filtered {
    return _invoices.where((inv) {
      final matchSearch = _search.isEmpty ||
          inv.invoiceNumber.toLowerCase().contains(_search.toLowerCase()) ||
          inv.clientName.toLowerCase().contains(_search.toLowerCase()) ||
          inv.clientEntity.toLowerCase().contains(_search.toLowerCase());
      final matchStatus = _statusFilter == 'All Statuses' ||
          inv.status.label == _statusFilter;
      final matchFrom = _fromDate == null || !inv.issuedDate.isBefore(_fromDate!);
      final matchTo = _toDate == null || !inv.issuedDate.isAfter(_toDate!);
      return matchSearch && matchStatus && matchFrom && matchTo;
    }).toList();
  }

  double get _totalInvoiced => _invoices.fold(0, (s, i) => s + i.grossAmount);
  double get _totalPaid => _invoices.where((i) => i.status == InvoiceStatus.paid).fold(0, (s, i) => s + i.grossAmount);
  double get _outstanding => _totalInvoiced - _totalPaid;

  void _showGstSettings() {
    showDialog(
      context: context,
      builder: (_) => _GstSettingsDialog(
        profile: _gstProfile,
        onSave: (p) => setState(() => _gstProfile = p),
      ),
    );
  }

  void _showNewInvoice() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewInvoiceSheet(
        gstProfile: _gstProfile,
        onSave: (inv) => setState(() => _invoices.insert(0, inv)),
      ),
    );
  }

  void _showInvoiceDetail(Invoice inv) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InvoiceDetailSheet(
        invoice: inv,
        onStatusChange: (s) => setState(() => inv.status = s),
        onDelete: () => setState(() => _invoices.removeWhere((x) => x.id == inv.id)),
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
          colorScheme: const ColorScheme.light(primary: Color(0xFF00BCD4)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => isFrom ? _fromDate = picked : _toDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 650;
    final filtered = _filtered;

    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(
        selectedIndex: widget.selectedIndex,
        onItemSelected: (i) {
          widget.onItemSelected(i);
          Navigator.pop(context);
        },
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: isWide
            ? null
            : IconButton(
                icon: const Icon(Icons.menu_rounded, color: Color(0xFF374151)),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Billing & Invoices',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
            Text('Manage client invoicing, payments, and financial history.',
                style: TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
          ],
        ),
        actions: isWide
            ? [
                _TopBtn(Icons.upload_file_outlined, 'Bulk Import', onTap: () {}),
                _TopBtn(Icons.shield_outlined, 'GST Settings', onTap: _showGstSettings),
                _TopBtn(Icons.trending_up_rounded, 'Profitability', onTap: () {}),
                _TopBtn(Icons.download_outlined, 'Export CSV', onTap: () {}),
                Padding(
                  padding: const EdgeInsets.only(right: 12, left: 4),
                  child: ElevatedButton.icon(
                    onPressed: _showNewInvoice,
                    icon: const Icon(Icons.add, size: 15),
                    label: const Text('New Invoice', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BCD4),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
                ),
              ]
            : [
                IconButton(
                    icon: const Icon(Icons.shield_outlined, color: Color(0xFF374151)),
                    onPressed: _showGstSettings),
                IconButton(
                    icon: const Icon(Icons.add_circle, color: Color(0xFF00BCD4), size: 28),
                    onPressed: _showNewInvoice),
              ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats cards
          _buildStatsRow(isWide),
          const SizedBox(height: 16),
          // Filter section
          _buildFilters(isWide),
          const SizedBox(height: 12),
          // Search + sort
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Search by invoice number or client...',
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 18),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 16, color: Color(0xFF6B7280)),
                            onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); })
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _FilterChip(Icons.filter_list_rounded, 'Quick Sort', onTap: () {}),
            ],
          ),
          const SizedBox(height: 4),
          Text('Filtering ${filtered.length} total records',
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 12),
          // Table
          _buildTable(filtered, isWide),
        ],
      ),
    );
  }

  // ── STATS ────────────────────────────────────────────────────────────────────

  Widget _buildStatsRow(bool isWide) {
    final cards = [
      _StatCard(title: 'TOTAL INVOICED', value: '₹${_fmt(_totalInvoiced)}', icon: Icons.trending_up_rounded, color: const Color(0xFF374151), bgColor: Colors.white, valueColor: const Color(0xFF111827)),
      _StatCard(title: 'TOTAL PAID', value: '₹${_fmt(_totalPaid)}', icon: Icons.check_circle_outline, color: const Color(0xFF10B981), bgColor: const Color(0xFFF0FDF4), valueColor: const Color(0xFF10B981)),
      _StatCard(title: 'OUTSTANDING', value: '₹${_fmt(_outstanding)}', icon: Icons.circle, color: const Color(0xFFEF4444), bgColor: const Color(0xFFFEF2F2), valueColor: const Color(0xFFEF4444)),
    ];

    return isWide
        ? Row(children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 8), child: c))).toList())
        : Column(children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 8), child: c)).toList());
  }

  // ── FILTERS ──────────────────────────────────────────────────────────────────

  Widget _buildFilters(bool isWide) {
    final statusItems = ['All Statuses', ...InvoiceStatus.values.map((s) => s.label)];

    final statusDd = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _statusFilter,
          isExpanded: true,
          style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
          items: statusItems.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: (v) => setState(() => _statusFilter = v!),
        ),
      ),
    );

    final fromBtn = GestureDetector(
      onTap: () => _pickDate(true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF9CA3AF)),
            const SizedBox(width: 6),
            Text(
              _fromDate == null ? 'From Date' : '${_fromDate!.day}/${_fromDate!.month}/${_fromDate!.year}',
              style: TextStyle(fontSize: 12, color: _fromDate == null ? const Color(0xFF9CA3AF) : const Color(0xFF111827)),
            ),
          ],
        ),
      ),
    );

    final toBtn = GestureDetector(
      onTap: () => _pickDate(false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF9CA3AF)),
            const SizedBox(width: 6),
            Text(
              _toDate == null ? 'To Date' : '${_toDate!.day}/${_toDate!.month}/${_toDate!.year}',
              style: TextStyle(fontSize: 12, color: _toDate == null ? const Color(0xFF9CA3AF) : const Color(0xFF111827)),
            ),
          ],
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.filter_alt_outlined, size: 14, color: Color(0xFF00BCD4)),
              SizedBox(width: 6),
              Text('Filter Invoices',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            ],
          ),
          const SizedBox(height: 12),
          isWide
              ? Row(
                  children: [
                    Expanded(child: _FilterLabel('STATUS', statusDd)),
                    const SizedBox(width: 10),
                    Expanded(child: _FilterLabel('FROM DATE', fromBtn)),
                    const SizedBox(width: 10),
                    Expanded(child: _FilterLabel('TO DATE', toBtn)),
                    if (_fromDate != null || _toDate != null || _statusFilter != 'All Statuses') ...[
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => setState(() {
                          _fromDate = null;
                          _toDate = null;
                          _statusFilter = 'All Statuses';
                        }),
                        child: const Text('Clear', style: TextStyle(fontSize: 12, color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
                      ),
                    ]
                  ],
                )
              : Column(
                  children: [
                    _FilterLabel('STATUS', statusDd),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: _FilterLabel('FROM DATE', fromBtn)),
                      const SizedBox(width: 8),
                      Expanded(child: _FilterLabel('TO DATE', toBtn)),
                    ]),
                  ],
                ),
        ],
      ),
    );
  }

  // ── TABLE ────────────────────────────────────────────────────────────────────

  Widget _buildTable(List<Invoice> invoices, bool isWide) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: Row(
            children: [
              const Expanded(flex: 2, child: _TH('INVOICE #')),
              const Expanded(flex: 3, child: _TH('CLIENT ENTITY')),
              const Expanded(flex: 2, child: _TH('GROSS AMOUNT')),
              if (isWide) const Expanded(flex: 3, child: _TH('SCHEDULE')),
              const Expanded(flex: 2, child: _TH('STATUS')),
              const Expanded(flex: 1, child: _TH('ACTIONS')),
            ],
          ),
        ),
        if (invoices.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                left: BorderSide(color: Color(0xFFE5E7EB)),
                right: BorderSide(color: Color(0xFFE5E7EB)),
                bottom: BorderSide(color: Color(0xFFE5E7EB)),
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
            ),
            child: const Center(
              child: Text('No invoices found', style: TextStyle(color: Color(0xFF6B7280))),
            ),
          )
        else
          ...invoices.asMap().entries.map((e) => _InvoiceRow(
            invoice: e.value,
            isLast: e.key == invoices.length - 1,
            isWide: isWide,
            onTap: () => _showInvoiceDetail(e.value),
          )),
      ],
    );
  }

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ─── STAT CARD ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color valueColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF6B7280), letterSpacing: 0.5)),
              const SizedBox(height: 6),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: valueColor)),
            ],
          ),
          Icon(icon, size: 22, color: color.withOpacity(0.6)),
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

  const _InvoiceRow({required this.invoice, required this.isLast, required this.isWide, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            left: const BorderSide(color: Color(0xFFE5E7EB)),
            right: const BorderSide(color: Color(0xFFE5E7EB)),
            bottom: BorderSide(color: isLast ? Colors.transparent : const Color(0xFFE5E7EB)),
          ),
          borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(10)) : BorderRadius.zero,
        ),
        child: Row(
          children: [
            // Invoice #
            Expanded(
              flex: 2,
              child: Text(invoice.invoiceNumber,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF00BCD4))),
            ),
            // Client
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(invoice.clientName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(invoice.clientEntity,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            // Amount
            Expanded(
              flex: 2,
              child: Text('₹${invoice.grossAmount.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            ),
            // Schedule (wide only)
            if (isWide)
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(invoice.formattedDue,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                    Text(invoice.formattedIssued,
                        style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                  ],
                ),
              ),
            // Status
            Expanded(
              flex: 2,
              child: _StatusBadge(status: invoice.status),
            ),
            // Actions
            Expanded(
              flex: 1,
              child: Icon(Icons.more_horiz, size: 18, color: const Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── INVOICE DETAIL SHEET ─────────────────────────────────────────────────────

class _InvoiceDetailSheet extends StatelessWidget {
  final Invoice invoice;
  final Function(InvoiceStatus) onStatusChange;
  final VoidCallback onDelete;

  const _InvoiceDetailSheet({required this.invoice, required this.onStatusChange, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(invoice.invoiceNumber,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                        Text(invoice.clientName,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                      ],
                    ),
                  ),
                  _StatusBadge(status: invoice.status),
                  const SizedBox(width: 8),
                  PopupMenuButton<InvoiceStatus>(
                    icon: const Icon(Icons.more_vert, color: Color(0xFF6B7280)),
                    tooltip: 'Change Status',
                    itemBuilder: (_) => InvoiceStatus.values.map((s) =>
                        PopupMenuItem(value: s, child: Text(s.label, style: TextStyle(color: s.color, fontSize: 13)))).toList(),
                    onSelected: (s) { onStatusChange(s); Navigator.pop(context); },
                  ),
                ],
              ),
            ),
            const Divider(height: 20),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Items table
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                          ),
                          child: const Row(
                            children: [
                              Expanded(flex: 4, child: Text('Description', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)))),
                              Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)))),
                              Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)), textAlign: TextAlign.end)),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFE5E7EB)),
                        ...invoice.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              Expanded(flex: 4, child: Text(item.description, style: const TextStyle(fontSize: 13, color: Color(0xFF111827)))),
                              Expanded(flex: 1, child: Text('${item.quantity.toInt()}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
                              Expanded(flex: 2, child: Text('₹${item.total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)), textAlign: TextAlign.end)),
                            ],
                          ),
                        )),
                        const Divider(height: 1, color: Color(0xFFE5E7EB)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: Row(
                            children: [
                              const Expanded(flex: 5, child: Text('Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)))),
                              Text('₹${invoice.grossAmount.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF00BCD4))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () { onDelete(); Navigator.pop(context); },
                          icon: const Icon(Icons.delete_outline, size: 15, color: Colors.red),
                          label: const Text('Delete', style: TextStyle(color: Colors.red, fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.send_outlined, size: 15),
                          label: const Text('Send Invoice', style: TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00BCD4),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
  final _clientCtrl = TextEditingController();
  final _entityCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  InvoiceStatus _status = InvoiceStatus.draft;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  final List<InvoiceItem> _items = [InvoiceItem(description: '', unitPrice: 0)];

  double get _grandTotal => _items.fold(0, (s, i) => s + i.total);

  void _addItem() => setState(() => _items.add(InvoiceItem(description: '', unitPrice: 0)));

  void _save() {
    if (_clientCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client name is required'), backgroundColor: Colors.red),
      );
      return;
    }
    final inv = Invoice(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      invoiceNumber: 'INV-${(1000 + DateTime.now().millisecond).toString()}',
      clientName: _clientCtrl.text.trim(),
      clientEntity: _entityCtrl.text.trim(),
      items: _items,
      status: _status,
      issuedDate: DateTime.now(),
      dueDate: _dueDate,
      notes: _notesCtrl.text.trim(),
    );
    widget.onSave(inv);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invoice created!'), backgroundColor: Color(0xFF10B981)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.97,
      minChildSize: 0.5,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 0),
              child: Row(
                children: [
                  const Text('New Invoice',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close, color: Color(0xFF6B7280)), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(height: 16),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Client info
                  _SectionHead('CLIENT INFORMATION'),
                  const SizedBox(height: 10),
                  _FormField('Client Name', _clientCtrl, hint: 'e.g. janani'),
                  const SizedBox(height: 10),
                  _FormField('Client Entity / Project', _entityCtrl, hint: 'e.g. JANANI - WEB DEVELOPMENT'),
                  const SizedBox(height: 16),
                  // Status & Due date
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionHead('STATUS'),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<InvoiceStatus>(
                                  value: _status,
                                  isExpanded: true,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
                                  items: InvoiceStatus.values.map((s) =>
                                      DropdownMenuItem(value: s, child: Text(s.label, style: const TextStyle(fontSize: 13)))).toList(),
                                  onChanged: (v) => setState(() => _status = v!),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionHead('DUE DATE'),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: _dueDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2030),
                                  builder: (ctx, child) => Theme(
                                    data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF00BCD4))),
                                    child: child!,
                                  ),
                                );
                                if (d != null) setState(() => _dueDate = d);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF9CA3AF)),
                                    const SizedBox(width: 6),
                                    Text('${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF111827))),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Line items
                  Row(
                    children: [
                      _SectionHead('LINE ITEMS'),
                      const Spacer(),
                      GestureDetector(
                        onTap: _addItem,
                        child: const Row(
                          children: [
                            Icon(Icons.add, size: 14, color: Color(0xFF00BCD4)),
                            SizedBox(width: 4),
                            Text('Add Item', style: TextStyle(fontSize: 12, color: Color(0xFF00BCD4), fontWeight: FontWeight.w600)),
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
                  // Total
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFE),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Grand Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                        Text('₹${_grandTotal.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF00BCD4))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Notes
                  _SectionHead('NOTES (OPTIONAL)'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Payment terms, thank you note...',
                      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 1.5)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00BCD4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Create Invoice', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
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

  const _LineItemRow({required this.item, required this.index, required this.canDelete, required this.onDelete, required this.onChanged});

  @override
  State<_LineItemRow> createState() => _LineItemRowState();
}

class _LineItemRowState extends State<_LineItemRow> {
  late TextEditingController _descCtrl, _qtyCtrl, _priceCtrl, _taxCtrl;

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(text: widget.item.description);
    _qtyCtrl = TextEditingController(text: widget.item.quantity.toString());
    _priceCtrl = TextEditingController(text: widget.item.unitPrice > 0 ? widget.item.unitPrice.toString() : '');
    _taxCtrl = TextEditingController(text: widget.item.taxPercent > 0 ? widget.item.taxPercent.toString() : '');
  }

  @override
  void dispose() {
    _descCtrl.dispose(); _qtyCtrl.dispose(); _priceCtrl.dispose(); _taxCtrl.dispose();
    super.dispose();
  }

  void _update() {
    widget.item.description = _descCtrl.text;
    widget.item.quantity = double.tryParse(_qtyCtrl.text) ?? 1;
    widget.item.unitPrice = double.tryParse(_priceCtrl.text) ?? 0;
    widget.item.taxPercent = double.tryParse(_taxCtrl.text) ?? 0;
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFFFAFAFA),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('Item ${widget.index + 1}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
              const Spacer(),
              if (widget.canDelete)
                GestureDetector(
                  onTap: widget.onDelete,
                  child: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            onChanged: (_) => _update(),
            decoration: _lineInputDec('Description'),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: TextField(controller: _qtyCtrl, onChanged: (_) => _update(), keyboardType: TextInputType.number, decoration: _lineInputDec('Qty'), style: const TextStyle(fontSize: 13))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _priceCtrl, onChanged: (_) => _update(), keyboardType: TextInputType.number, decoration: _lineInputDec('Unit Price (₹)'), style: const TextStyle(fontSize: 13))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _taxCtrl, onChanged: (_) => _update(), keyboardType: TextInputType.number, decoration: _lineInputDec('Tax %'), style: const TextStyle(fontSize: 13))),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text('Total: ₹${widget.item.total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
          ),
        ],
      ),
    );
  }

  InputDecoration _lineInputDec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 1.5)),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    isDense: true,
  );
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
  String _state = '';

  @override
  void initState() {
    super.initState();
    _gstinCtrl = TextEditingController(text: widget.profile.gstin);
    _legalCtrl = TextEditingController(text: widget.profile.legalName);
    _brandCtrl = TextEditingController(text: widget.profile.brandName);
    _panCtrl = TextEditingController(text: widget.profile.panNumber);
    _state = widget.profile.state.isEmpty ? '' : widget.profile.state;
  }

  @override
  void dispose() {
    _gstinCtrl.dispose(); _legalCtrl.dispose(); _brandCtrl.dispose(); _panCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.onSave(GstProfile(
      gstin: _gstinCtrl.text.trim(),
      legalName: _legalCtrl.text.trim(),
      brandName: _brandCtrl.text.trim(),
      panNumber: _panCtrl.text.trim(),
      state: _state,
    ));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('GST Profile saved!'), backgroundColor: Color(0xFF10B981)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('GST PROFILE SETUP',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF111827), letterSpacing: 0.3)),
                      Text("Your organization's tax identity. Used to auto-calculate CGST/SGST vs IGST on invoices.",
                          style: TextStyle(fontSize: 11, color: Color(0xFF6B7280), height: 1.4)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Color(0xFF6B7280)),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // GSTIN
            _DlgLabel('GSTIN', sub: '(15-digit GST Identification Number)'),
            const SizedBox(height: 6),
            _DlgInput(_gstinCtrl, 'E.G. 32AAAAA0000A1Z5'),
            const SizedBox(height: 14),
            // Legal + Brand
            Row(
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _DlgLabel('LEGAL BUSINESS NAME'),
                  const SizedBox(height: 6),
                  _DlgInput(_legalCtrl, 'As per GST registration'),
                ])),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _DlgLabel('TRADE / BRAND NAME'),
                  const SizedBox(height: 6),
                  _DlgInput(_brandCtrl, 'Optional'),
                ])),
              ],
            ),
            const SizedBox(height: 14),
            // PAN + State
            Row(
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _DlgLabel('PAN NUMBER'),
                  const SizedBox(height: 6),
                  _DlgInput(_panCtrl, 'E.G. AAAAA0000A'),
                ])),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _DlgLabel('STATE OF REGISTRATION'),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _state.isEmpty ? null : _state,
                        hint: const Text('Select state...', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                        isExpanded: true,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
                        items: _indianStates.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (v) => setState(() => _state = v ?? ''),
                      ),
                    ),
                  ),
                ])),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined, size: 16),
                label: const Text('SAVE GST PROFILE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BCD4),
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
}

// ─── SMALL REUSABLE WIDGETS ───────────────────────────────────────────────────

class _TH extends StatelessWidget {
  final String text;
  const _TH(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF6B7280), letterSpacing: 0.4));
}

class _StatusBadge extends StatelessWidget {
  final InvoiceStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(status.label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: status.color, letterSpacing: 0.3)),
    );
  }
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
      icon: Icon(icon, size: 14, color: const Color(0xFF374151)),
      label: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF374151), fontWeight: FontWeight.w600)),
      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FilterChip(this.icon, this.label, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF374151)),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
          ],
        ),
      ),
    );
  }
}

class _FilterLabel extends StatelessWidget {
  final String label;
  final Widget child;

  const _FilterLabel(this.label, this.child);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF6B7280), letterSpacing: 0.4)),
        const SizedBox(height: 5),
        child,
      ],
    );
  }
}

class _SectionHead extends StatelessWidget {
  final String text;
  const _SectionHead(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF6B7280), letterSpacing: 0.5));
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final String hint;

  const _FormField(this.label, this.ctrl, {this.hint = ''});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHead(label),
        const SizedBox(height: 5),
        TextField(
          controller: ctrl,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true, fillColor: const Color(0xFFF9FAFB),
          ),
        ),
      ],
    );
  }
}

class _DlgLabel extends StatelessWidget {
  final String text;
  final String? sub;

  const _DlgLabel(this.text, {this.sub});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF374151), letterSpacing: 0.3),
        children: sub != null
            ? [TextSpan(text: ' $sub', style: const TextStyle(fontWeight: FontWeight.w400, color: Color(0xFF9CA3AF), fontSize: 10))]
            : null,
      ),
    );
  }
}

Widget _DlgInput(TextEditingController ctrl, String hint) {
  return TextField(
    controller: ctrl,
    style: const TextStyle(fontSize: 13),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
  );
}
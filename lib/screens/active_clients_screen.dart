// active_clients_page.dart
import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

// ─── DATA MODELS ─────────────────────────────────────────────────────────────

class ActiveClient {
  final String id;
  final String name;
  final String email;
  final List<String> services;
  final double contractValue;
  final DateTime onboardedAt;
  final String templateUsed;

  const ActiveClient({
    required this.id,
    required this.name,
    required this.email,
    required this.services,
    required this.contractValue,
    required this.onboardedAt,
    required this.templateUsed,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

// ─── SERVICE COLORS ───────────────────────────────────────────────────────────

Color _serviceColor(String service) {
  final s = service.toLowerCase();
  if (s.contains('digital') || s.contains('marketing')) return const Color(0xFFF59E0B);
  if (s.contains('web') || s.contains('development')) return const Color(0xFF3B82F6);
  if (s.contains('seo')) return const Color(0xFF10B981);
  if (s.contains('design')) return const Color(0xFF8B5CF6);
  if (s.contains('content')) return const Color(0xFFEC4899);
  if (s.contains('social')) return const Color(0xFFF97316);
  if (s.contains('branding')) return const Color(0xFFEF4444);
  return const Color(0xFF6B7280);
}

// ─── MAIN PAGE ────────────────────────────────────────────────────────────────

class ActiveClientsPage extends StatefulWidget {
  // Pass submitted onboarding data from ClientOnboardingPage here
  final List<ActiveClient> externalClients;
  final int selectedIndex;
  final Function(int) onItemSelected;

  const ActiveClientsPage({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.externalClients = const [],
  });

  @override
  State<ActiveClientsPage> createState() => _ActiveClientsPageState();
}

class _ActiveClientsPageState extends State<ActiveClientsPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Sample clients (from onboarding submissions)
  final List<ActiveClient> _clients = [
    ActiveClient(
      id: '1',
      name: 'arsenal',
      email: 'arsenal@gmail.com',
      services: ['Digital Marketing'],
      contractValue: 30000,
      onboardedAt: DateTime.now().subtract(const Duration(days: 3)),
      templateUsed: 'Digital Marketing Premium Intake v1',
    ),
    ActiveClient(
      id: '2',
      name: 'janani',
      email: 'livein@janani.in',
      services: ['Web Development', 'SEO Services'],
      contractValue: 20000,
      onboardedAt: DateTime.now().subtract(const Duration(days: 6)),
      templateUsed: 'Web Development Dynamic Specification v1',
    ),
    ActiveClient(
      id: '3',
      name: 'Steve rogers',
      email: 'viswajith.ecraftz@gmail.com',
      services: ['Design'],
      contractValue: 0,
      onboardedAt: DateTime.now().subtract(const Duration(days: 1)),
      templateUsed: 'Content Creation Requirements Questionnaire',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Add any externally passed clients (from onboarding submissions)
    for (final c in widget.externalClients) {
      if (!_clients.any((x) => x.id == c.id)) {
        _clients.add(c);
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ActiveClient> get _filtered {
    if (_searchQuery.isEmpty) return _clients;
    final q = _searchQuery.toLowerCase();
    return _clients.where((c) =>
        c.name.toLowerCase().contains(q) ||
        c.email.toLowerCase().contains(q) ||
        c.services.any((s) => s.toLowerCase().contains(q))).toList();
  }

  void _showBulkImport() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BulkImportSheet(
        onImport: (clients) {
          setState(() => _clients.addAll(clients));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${clients.length} client(s) imported successfully'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        },
      ),
    );
  }

  void _showClientDetail(ActiveClient client) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ClientDetailSheet(client: client),
    );
  }

  void _showInvoice(ActiveClient client) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InvoiceSheet(client: client),
    );
  }

  void _deleteClient(ActiveClient client) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Client'),
        content: Text('Remove "${client.name}" from active clients?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() => _clients.removeWhere((c) => c.id == client.id));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Client removed'), backgroundColor: Colors.red),
              );
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clients = _filtered;
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F7FA),
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
        leading: isWide
            ? null
            : IconButton(
                icon: const Icon(Icons.menu_rounded, color: Color(0xFF374151)),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Active Clients',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827))),
            Text('Manage your active customer relationships and contracts.',
                style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OutlinedButton.icon(
              onPressed: _showBulkImport,
              icon: const Icon(Icons.upload_file_outlined, size: 15, color: Color(0xFF374151)),
              label: Text(
                isWide ? 'Bulk Import' : 'Import',
                style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: Column(
        children: [
          // Stats strip
          _buildStatsStrip(),
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search active clients...',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 16, color: Color(0xFF6B7280)),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        })
                    : null,
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          // Table
          Expanded(
            child: clients.isEmpty
                ? _buildEmpty()
                : _buildTable(clients, isWide),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsStrip() {
    final total = _clients.length;
    final totalValue = _clients.fold<double>(0, (s, c) => s + c.contractValue);
    final services = _clients.expand((c) => c.services).toSet().length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      width: double.infinity,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _statChip('Total Clients', '$total', const Color(0xFF00BCD4)),
          _statChip('Contract Value', '\$${_formatValue(totalValue)}', const Color(0xFF10B981)),
          _statChip('Services', '$services active', const Color(0xFF8B5CF6)),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w700)),
          Text(label,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_outline, size: 48, color: Color(0xFFD1D5DB)),
          const SizedBox(height: 12),
          const Text('No active clients found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
          const SizedBox(height: 6),
          const Text('Clients appear here after submitting onboarding forms\nor via bulk import.',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _showBulkImport,
            icon: const Icon(Icons.upload_file_outlined, size: 16),
            label: const Text('Bulk Import'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BCD4),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<ActiveClient> clients, bool isWide) {
    if (!isWide) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: clients.length,
        itemBuilder: (_, i) => _ClientRow(
          client: clients[i],
          isLast: i == clients.length - 1,
          isWide: isWide,
          onDetails: () => _showClientDetail(clients[i]),
          onInvoice: () => _showInvoice(clients[i]),
          onDelete: () => _deleteClient(clients[i]),
        ),
      );
    }
    return Column(
      children: [
        // Table header
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              const Expanded(flex: 3, child: _TableHeader('Client Name')),
              const Expanded(flex: 3, child: _TableHeader('Service')),
              const Expanded(flex: 2, child: _TableHeader('Contract Value')),
              Expanded(flex: isWide ? 3 : 2, child: const _TableHeader('Actions')),
            ],
          ),
        ),
        // Rows
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: clients.length,
            itemBuilder: (_, i) => _ClientRow(
              client: clients[i],
              isLast: i == clients.length - 1,
              isWide: isWide,
              onDetails: () => _showClientDetail(clients[i]),
              onInvoice: () => _showInvoice(clients[i]),
              onDelete: () => _deleteClient(clients[i]),
            ),
          ),
        ),
      ],
    );
  }

  String _formatValue(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

// ─── TABLE HEADER ─────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280)));
  }
}

// ─── CLIENT ROW ───────────────────────────────────────────────────────────────

class _ClientRow extends StatelessWidget {
  final ActiveClient client;
  final bool isLast;
  final bool isWide;
  final VoidCallback onDetails;
  final VoidCallback onInvoice;
  final VoidCallback onDelete;

  const _ClientRow({
    required this.client,
    required this.isLast,
    required this.isWide,
    required this.onDetails,
    required this.onInvoice,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (!isWide) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Avatar + Info + Popup Menu
            Row(
              children: [
                _Avatar(initials: client.initials),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        client.email,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18, color: Color(0xFF9CA3AF)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Remove Client', style: TextStyle(color: Colors.red, fontSize: 13)),
                    ),
                  ],
                  onSelected: (v) {
                    if (v == 'delete') onDelete();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Services
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: client.services.map((s) => _ServiceBadge(service: s)).toList(),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 12),
            // Value + Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CONTRACT VALUE',
                      style: TextStyle(fontSize: 9, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      client.contractValue > 0
                          ? '\$${client.contractValue.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}'
                          : '\$0',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: client.contractValue > 0 ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _ActionBtn(
                      icon: Icons.info_outline_rounded,
                      label: 'Details',
                      onTap: onDetails,
                      color: const Color(0xFF00BCD4),
                    ),
                    const SizedBox(width: 8),
                    _ActionBtn(
                      icon: Icons.receipt_long_outlined,
                      label: 'Invoice',
                      onTap: onInvoice,
                      color: const Color(0xFF00BCD4),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: const BorderSide(color: Color(0xFFE5E7EB)),
          right: const BorderSide(color: Color(0xFFE5E7EB)),
          bottom: BorderSide(
              color: isLast ? Colors.transparent : const Color(0xFFE5E7EB)),
        ),
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(12))
            : BorderRadius.zero,
      ),
      child: Row(
        children: [
          // Client name + email
          Expanded(
            flex: 3,
            child: Row(
              children: [
                _Avatar(initials: client.initials),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(client.name,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(client.email,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF6B7280)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Services
          Expanded(
            flex: 3,
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: client.services.map((s) => _ServiceBadge(service: s)).toList(),
            ),
          ),
          // Contract value
          Expanded(
            flex: 2,
            child: Text(
              client.contractValue > 0
                  ? '\$${client.contractValue.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}'
                  : '\$0',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: client.contractValue > 0
                      ? const Color(0xFF111827)
                      : const Color(0xFF9CA3AF)),
            ),
          ),
          // Actions
          Expanded(
            flex: isWide ? 3 : 2,
            child: Row(
              children: [
                _ActionBtn(
                  icon: Icons.info_outline_rounded,
                  label: 'Details',
                  onTap: onDetails,
                  color: const Color(0xFF00BCD4),
                ),
                const SizedBox(width: 6),
                _ActionBtn(
                  icon: Icons.receipt_long_outlined,
                  label: 'Invoice',
                  onTap: onInvoice,
                  color: const Color(0xFF00BCD4),
                ),
                const SizedBox(width: 2),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz,
                      size: 18, color: Color(0xFF9CA3AF)),
                  padding: EdgeInsets.zero,
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'delete',
                        child: Text('Remove Client',
                            style: TextStyle(color: Colors.red, fontSize: 13))),
                  ],
                  onSelected: (v) {
                    if (v == 'delete') onDelete();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CLIENT DETAIL SHEET ──────────────────────────────────────────────────────

class _ClientDetailSheet extends StatelessWidget {
  final ActiveClient client;
  const _ClientDetailSheet({required this.client});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  _Avatar(initials: client.initials, size: 48),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(client.name,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111827))),
                        Text(client.email,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF6B7280))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: Color(0xFF10B981)),
                        SizedBox(width: 5),
                        Text('Active',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF10B981))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _DetailSection(
                    title: 'Services',
                    icon: Icons.work_outline_rounded,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: client.services
                          .map((s) => _ServiceBadge(service: s, large: true))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _DetailSection(
                    title: 'Contract Details',
                    icon: Icons.attach_money_rounded,
                    child: Column(
                      children: [
                        _DetailRow(
                            'Contract Value',
                            client.contractValue > 0
                                ? '\$${client.contractValue.toStringAsFixed(0)}'
                                : 'Not set'),
                        _DetailRow('Onboarded',
                            _formatDate(client.onboardedAt)),
                        _DetailRow('Template Used', client.templateUsed),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _DetailSection(
                    title: 'Contact Information',
                    icon: Icons.person_outline_rounded,
                    child: Column(
                      children: [
                        _DetailRow('Email', client.email),
                        _DetailRow('Client Name', client.name),
                      ],
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

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

// ─── INVOICE SHEET ────────────────────────────────────────────────────────────

class _InvoiceSheet extends StatelessWidget {
  final ActiveClient client;
  const _InvoiceSheet({required this.client});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  const Text('Invoice',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827))),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFE),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
                    ),
                    child: const Text('DRAFT',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF00BCD4),
                            letterSpacing: 0.5)),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Client info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Bill To',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF6B7280),
                                    letterSpacing: 0.5)),
                            const SizedBox(height: 4),
                            Text(client.name,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111827))),
                            Text(client.email,
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF6B7280))),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Invoice Date',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF6B7280),
                                    letterSpacing: 0.5)),
                            const SizedBox(height: 4),
                            Text(
                              '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF111827)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Services table
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF9FAFB),
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(10)),
                          ),
                          child: const Row(
                            children: [
                              Expanded(flex: 4, child: Text('Service', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)))),
                              Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)))),
                              Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)), textAlign: TextAlign.end)),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFE5E7EB)),
                        ...client.services.asMap().entries.map((e) {
                          final perService = client.services.isEmpty
                              ? 0.0
                              : client.contractValue / client.services.length;
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: Text(e.value,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF111827))),
                                    ),
                                    const Expanded(
                                      flex: 1,
                                      child: Text('1',
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF6B7280))),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '\$${perService.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF111827)),
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (e.key < client.services.length - 1)
                                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                            ],
                          );
                        }).toList(),
                        const Divider(height: 1, color: Color(0xFFE5E7EB)),
                        // Total
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              const Expanded(
                                  flex: 4,
                                  child: Text('Total',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF111827)))),
                              const Expanded(flex: 1, child: SizedBox()),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '\$${client.contractValue.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF00BCD4)),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.download_outlined, size: 16, color: Color(0xFF374151)),
                          label: const Text('Download PDF', style: TextStyle(color: Color(0xFF374151), fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.send_outlined, size: 16),
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

// ─── BULK IMPORT SHEET ────────────────────────────────────────────────────────

class _BulkImportSheet extends StatefulWidget {
  final Function(List<ActiveClient>) onImport;
  const _BulkImportSheet({required this.onImport});

  @override
  State<_BulkImportSheet> createState() => _BulkImportSheetState();
}

class _BulkImportSheetState extends State<_BulkImportSheet> {
  final TextEditingController _csvCtrl = TextEditingController();
  bool _isParsed = false;
  List<ActiveClient> _parsedClients = [];
  String? _error;

  void _parse() {
    final lines = _csvCtrl.text.trim().split('\n');
    final clients = <ActiveClient>[];
    String? err;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final cols = line.split(',').map((s) => s.trim()).toList();
      if (cols.length < 3) {
        err = 'Row ${i + 1}: Need at least 3 columns (name, email, service)';
        break;
      }
      clients.add(ActiveClient(
        id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
        name: cols[0],
        email: cols[1],
        services: cols[2].split(';').map((s) => s.trim()).toList(),
        contractValue: cols.length > 3 ? double.tryParse(cols[3]) ?? 0 : 0,
        onboardedAt: DateTime.now(),
        templateUsed: 'Bulk Import',
      ));
    }

    setState(() {
      _error = err;
      _parsedClients = err == null ? clients : [];
      _isParsed = err == null && clients.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Text('Bulk Import Clients',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827))),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                    onPressed: () => Navigator.pop(context),
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
                  // Format guide
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFE),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFF00BCD4).withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 14, color: Color(0xFF00BCD4)),
                            SizedBox(width: 6),
                            Text('CSV Format Guide',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0284C7))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                            'Each row: Name, Email, Service(s separated by ;), ContractValue\n'
                            'Example:\narsenal, arsenal@gmail.com, Digital Marketing, 30000\njanani, livein@janani.in, Web Development;SEO Services, 20000',
                            style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF0369A1),
                                fontFamily: 'monospace')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Paste CSV Data',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _csvCtrl,
                    maxLines: 8,
                    style: const TextStyle(
                        fontSize: 12, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      hintText:
                          'arsenal, arsenal@gmail.com, Digital Marketing, 30000\njanani, livein@janani.in, Web Development;SEO, 20000',
                      hintStyle: const TextStyle(
                          color: Color(0xFFD1D5DB), fontSize: 11),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E7EB))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E7EB))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFF00BCD4), width: 1.5)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    onChanged: (_) => setState(() {
                      _isParsed = false;
                      _error = null;
                    }),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.red)),
                  ],
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _parse,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF374151),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Parse & Preview',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  // Preview
                  if (_isParsed) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.check_circle,
                            size: 16, color: Color(0xFF10B981)),
                        const SizedBox(width: 6),
                        Text('${_parsedClients.length} clients ready to import',
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._parsedClients.map((c) => Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              _Avatar(initials: c.initials, size: 32),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(c.name,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF111827))),
                                    Text(c.email,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF6B7280))),
                                  ],
                                ),
                              ),
                              Text(
                                c.contractValue > 0
                                    ? '\$${c.contractValue.toStringAsFixed(0)}'
                                    : '\$0',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF374151)),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () {
                        widget.onImport(_parsedClients);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.upload_rounded, size: 16),
                      label: Text('Import ${_parsedClients.length} Clients',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00BCD4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
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

// ─── REUSABLE WIDGETS ─────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String initials;
  final double size;

  const _Avatar({required this.initials, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF00BCD4).withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(
            color: const Color(0xFF00BCD4).withOpacity(0.3), width: 1.5),
      ),
      child: Center(
        child: Text(initials,
            style: TextStyle(
                fontSize: size * 0.33,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF00BCD4))),
      ),
    );
  }
}

class _ServiceBadge extends StatelessWidget {
  final String service;
  final bool large;

  const _ServiceBadge({required this.service, this.large = false});

  @override
  Widget build(BuildContext context) {
    final color = _serviceColor(service);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: large ? 10 : 7, vertical: large ? 5 : 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(service,
          style: TextStyle(
              fontSize: large ? 12 : 10,
              fontWeight: FontWeight.w600,
              color: color)),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(7),
          color: color.withOpacity(0.05),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _DetailSection(
      {required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: const Color(0xFF00BCD4)),
              const SizedBox(width: 6),
              Text(title,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF374151))),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF111827)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
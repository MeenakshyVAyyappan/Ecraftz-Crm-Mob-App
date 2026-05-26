// crm_leads_page.dart
import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

// ─── DATA MODELS ─────────────────────────────────────────────────────────────

enum LeadStatus {
  newLead,
  contacted,
  qualified,
  proposalSent,
  negotiation,
  awaitingPayment,
  convertedClient,
  closedLost,
}

extension LeadStatusExtension on LeadStatus {
  String get label {
    switch (this) {
      case LeadStatus.newLead: return 'NEW LEAD';
      case LeadStatus.contacted: return 'CONTACTED';
      case LeadStatus.qualified: return 'QUALIFIED';
      case LeadStatus.proposalSent: return 'PROPOSAL SENT';
      case LeadStatus.negotiation: return 'NEGOTIATION';
      case LeadStatus.awaitingPayment: return 'AWAITING PAYMENT';
      case LeadStatus.convertedClient: return 'ACTIVE CLIENT';
      case LeadStatus.closedLost: return 'CLOSED LOST';
    }
  }

  Color get color {
    switch (this) {
      case LeadStatus.newLead: return const Color(0xFF6B7280);
      case LeadStatus.contacted: return const Color(0xFFF59E0B);
      case LeadStatus.qualified: return const Color(0xFF8B5CF6);
      case LeadStatus.proposalSent: return const Color(0xFF3B82F6);
      case LeadStatus.negotiation: return const Color(0xFFF97316);
      case LeadStatus.awaitingPayment: return const Color(0xFFEF4444);
      case LeadStatus.convertedClient: return const Color(0xFF10B981);
      case LeadStatus.closedLost: return const Color(0xFF374151);
    }
  }

  Color get bgColor => color.withOpacity(0.12);
}

enum AcquisitionSource { website, referral, socialMedia, coldCall, email, other }

extension AcquisitionSourceExt on AcquisitionSource {
  String get label {
    switch (this) {
      case AcquisitionSource.website: return 'Website';
      case AcquisitionSource.referral: return 'Referral';
      case AcquisitionSource.socialMedia: return 'Social Media';
      case AcquisitionSource.coldCall: return 'Cold Call';
      case AcquisitionSource.email: return 'Email';
      case AcquisitionSource.other: return 'Other';
    }
  }
}

class Lead {
  final String id;
  String firstName;
  String lastName;
  String email;
  String companyName;
  String jobTitle;
  String phone;
  LeadStatus status;
  AcquisitionSource source;
  double value;
  final DateTime createdAt;

  Lead({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.companyName = '',
    this.jobTitle = '',
    this.phone = '',
    required this.status,
    this.source = AcquisitionSource.website,
    this.value = 0,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName'.trim();
  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l'.isEmpty ? '?' : '$f$l';
  }
}

// ─── MAIN PAGE ────────────────────────────────────────────────────────────────

class CRMLeadsPage extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const CRMLeadsPage({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  State<CRMLeadsPage> createState() => _CRMLeadsPageState();
}

class _CRMLeadsPageState extends State<CRMLeadsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isKanban = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Lead> _leads = [
    Lead(id: '1', firstName: 'shock', lastName: 'stark', email: 'ananthu890@gmail.com', companyName: 'TALKIOS', status: LeadStatus.newLead, value: 200, createdAt: DateTime.now()),
    Lead(id: '2', firstName: 'Viswajith', lastName: 'e', email: 'viswajith.lcs@gmail.com', companyName: 'JANANI', status: LeadStatus.newLead, value: 100, createdAt: DateTime.now()),
    Lead(id: '3', firstName: 'amegh', lastName: 'kp', email: 'ameghkp111@gmail.com', companyName: 'ECARFTZ', status: LeadStatus.contacted, value: 0, createdAt: DateTime.now()),
    Lead(id: '4', firstName: 'viswajith', lastName: '', email: 'viswajith802@gmail.com', companyName: 'ARSENAL', status: LeadStatus.qualified, value: 150, createdAt: DateTime.now()),
    Lead(id: '5', firstName: 'sasi', lastName: 'jith', email: 'sasi@gmail.com', companyName: 'ANUGRAHA', status: LeadStatus.proposalSent, value: 100, createdAt: DateTime.now()),
    Lead(id: '6', firstName: 'meethu', lastName: '', email: 'meethu@gmail.com', companyName: 'IOSS', status: LeadStatus.negotiation, value: 150, createdAt: DateTime.now()),
    Lead(id: '7', firstName: 'Hari', lastName: '', email: 'hari@gmail.com', companyName: '', status: LeadStatus.awaitingPayment, value: 200, createdAt: DateTime.now()),
    Lead(id: '8', firstName: 'Steve', lastName: 'rogers', email: 'viswajith.ecraftz@gmail.com', companyName: 'ECRAFTZ', status: LeadStatus.convertedClient, value: 0, createdAt: DateTime.now()),
    Lead(id: '9', firstName: 'Chimbu', lastName: '', email: 'chimbu@gmail.com', companyName: '', status: LeadStatus.closedLost, value: 100, createdAt: DateTime.now()),
  ];

  List<Lead> get _filteredLeads {
    if (_searchQuery.isEmpty) return _leads;
    final q = _searchQuery.toLowerCase();
    return _leads.where((l) =>
      l.fullName.toLowerCase().contains(q) ||
      l.email.toLowerCase().contains(q) ||
      l.companyName.toLowerCase().contains(q)).toList();
  }

  Map<LeadStatus, List<Lead>> get _leadsByStatus {
    final map = <LeadStatus, List<Lead>>{};
    for (final s in LeadStatus.values) {
      map[s] = _filteredLeads.where((l) => l.status == s).toList();
    }
    return map;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: LeadStatus.values.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showAddLeadDialog({Lead? existing}) {
    showDialog(
      context: context,
      builder: (_) => _AddLeadDialog(
        existing: existing,
        onSave: (lead) {
          setState(() {
            if (existing != null) {
              final idx = _leads.indexWhere((l) => l.id == existing.id);
              if (idx != -1) _leads[idx] = lead;
            } else {
              _leads.add(lead);
            }
          });
        },
      ),
    );
  }

  void _deleteLead(Lead lead) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Lead'),
        content: Text('Remove ${lead.fullName} from CRM?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() => _leads.removeWhere((l) => l.id == lead.id));
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _changeStatus(Lead lead, LeadStatus newStatus) {
    setState(() => lead.status = newStatus);
  }

  @override
  Widget build(BuildContext context) {
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lead Management',
                style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            if (!isWide)
              const Text('Manage your pipeline',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isKanban ? Icons.view_list_rounded : Icons.view_kanban_rounded,
              color: const Color(0xFF00BCD4),
            ),
            onPressed: () => setState(() => _isKanban = !_isKanban),
            tooltip: _isKanban ? 'List View' : 'Kanban View',
          ),
          if (isWide)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ElevatedButton.icon(
                onPressed: () => _showAddLeadDialog(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Lead'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BCD4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.add_circle, color: Color(0xFF00BCD4), size: 28),
                onPressed: () => _showAddLeadDialog(),
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
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search leads by name, email or company…',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Color(0xFF6B7280)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        })
                    : null,
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          // Stats strip
          _buildStatsStrip(),
          // Content
          Expanded(
            child: _isKanban ? _buildKanban() : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsStrip() {
    final total = _filteredLeads.length;
    final totalValue = _filteredLeads.fold<double>(0, (s, l) => s + l.value);
    final converted = _filteredLeads.where((l) => l.status == LeadStatus.convertedClient).length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _statChip('Total Leads', '$total', const Color(0xFF6B7280)),
          const SizedBox(width: 12),
          _statChip('Pipeline Value', '₹${totalValue.toStringAsFixed(0)}', const Color(0xFF00BCD4)),
          const SizedBox(width: 12),
          _statChip('Converted', '$converted', const Color(0xFF10B981)),
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
                  color: color, fontSize: 14, fontWeight: FontWeight.w700)),
          Text(label,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10)),
        ],
      ),
    );
  }

  // ── KANBAN ──────────────────────────────────────────────────────────────────

  Widget _buildKanban() {
    final byStatus = _leadsByStatus;
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      itemCount: LeadStatus.values.length,
      itemBuilder: (_, i) {
        final status = LeadStatus.values[i];
        final leads = byStatus[status] ?? [];
        return _KanbanColumn(
          status: status,
          leads: leads,
          onAddLead: () => _showAddLeadDialog(),
          onTap: (l) => _showLeadDetail(l),
          onDelete: _deleteLead,
          onStatusChange: _changeStatus,
        );
      },
    );
  }

  // ── LIST ────────────────────────────────────────────────────────────────────

  Widget _buildList() {
    final leads = _filteredLeads;
    if (leads.isEmpty) {
      return const Center(
        child: Text('No leads found', style: TextStyle(color: Color(0xFF6B7280))),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: leads.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        if (i == leads.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Showing 1–${leads.length} of ${leads.length} leads',
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          );
        }
        final lead = leads[i];
        return _LeadListTile(
          lead: lead,
          onTap: () => _showLeadDetail(lead),
          onDelete: () => _deleteLead(lead),
          onEdit: () => _showAddLeadDialog(existing: lead),
          onStatusChange: (s) => _changeStatus(lead, s),
        );
      },
    );
  }

  // ── LEAD DETAIL ─────────────────────────────────────────────────────────────

  void _showLeadDetail(Lead lead) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LeadDetailSheet(
        lead: lead,
        onEdit: () {
          Navigator.pop(context);
          _showAddLeadDialog(existing: lead);
        },
        onDelete: () {
          Navigator.pop(context);
          _deleteLead(lead);
        },
        onStatusChange: (s) {
          setState(() => lead.status = s);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ─── KANBAN COLUMN ────────────────────────────────────────────────────────────

class _KanbanColumn extends StatelessWidget {
  final LeadStatus status;
  final List<Lead> leads;
  final VoidCallback onAddLead;
  final Function(Lead) onTap;
  final Function(Lead) onDelete;
  final Function(Lead, LeadStatus) onStatusChange;

  const _KanbanColumn({
    required this.status,
    required this.leads,
    required this.onAddLead,
    required this.onTap,
    required this.onDelete,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: status.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(status.label,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF374151),
                          letterSpacing: 0.3)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: status.bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${leads.length}',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: status.color)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Cards
          Expanded(
            child: leads.isEmpty
                ? Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFE5E7EB), style: BorderStyle.solid),
                    ),
                    child: const Center(
                      child: Text('No leads',
                          style: TextStyle(
                              color: Color(0xFFD1D5DB), fontSize: 12)),
                    ),
                  )
                : ListView.separated(
                    itemCount: leads.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _KanbanCard(
                      lead: leads[i],
                      onTap: () => onTap(leads[i]),
                      onDelete: () => onDelete(leads[i]),
                      onStatusChange: (s) => onStatusChange(leads[i], s),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── KANBAN CARD ──────────────────────────────────────────────────────────────

class _KanbanCard extends StatelessWidget {
  final Lead lead;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Function(LeadStatus) onStatusChange;

  const _KanbanCard({
    required this.lead,
    required this.onTap,
    required this.onDelete,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Avatar(name: lead.initials, color: lead.status.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lead.fullName,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (lead.companyName.isNotEmpty)
                        Text('@ ${lead.companyName.toLowerCase()}',
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF6B7280)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz,
                      size: 16, color: Color(0xFF9CA3AF)),
                  padding: EdgeInsets.zero,
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red, fontSize: 13))),
                  ],
                  onSelected: (v) {
                    if (v == 'delete') onDelete();
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('GENERAL',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                          letterSpacing: 0.5)),
                ),
                const SizedBox(width: 6),
                if (lead.value > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('₹${lead.value.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF059669))),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── LIST TILE ────────────────────────────────────────────────────────────────

class _LeadListTile extends StatelessWidget {
  final Lead lead;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final Function(LeadStatus) onStatusChange;

  const _LeadListTile({
    required this.lead,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 3,
              offset: const Offset(0, 1),
            )
          ],
        ),
        child: Row(
          children: [
            _Avatar(name: lead.initials, color: lead.status.color, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lead.fullName,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827))),
                  Text(lead.email,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF6B7280)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _StatusBadge(status: lead.status),
                if (lead.value > 0) ...[
                  const SizedBox(height: 4),
                  Text('\$${lead.value.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151))),
                ],
              ],
            ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert,
                  size: 18, color: Color(0xFF9CA3AF)),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(fontSize: 13))),
                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red, fontSize: 13))),
              ],
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── LEAD DETAIL BOTTOM SHEET ─────────────────────────────────────────────────

class _LeadDetailSheet extends StatelessWidget {
  final Lead lead;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(LeadStatus) onStatusChange;

  const _LeadDetailSheet({
    required this.lead,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  _Avatar(name: lead.initials, color: lead.status.color, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lead.fullName,
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827))),
                        if (lead.jobTitle.isNotEmpty || lead.companyName.isNotEmpty)
                          Text(
                            [lead.jobTitle, lead.companyName]
                                .where((s) => s.isNotEmpty)
                                .join(' @ '),
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF6B7280)),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: Color(0xFF00BCD4), size: 20),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 20),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _StatusBadge(status: lead.status, large: true),
                  const SizedBox(height: 16),
                  // Change status
                  const Text('Move to Stage',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                          letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: LeadStatus.values.map((s) {
                      final isActive = s == lead.status;
                      return GestureDetector(
                        onTap: () => onStatusChange(s),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isActive ? s.color : s.bgColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: s.color.withOpacity(0.3)),
                          ),
                          child: Text(s.label,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isActive ? Colors.white : s.color,
                                  letterSpacing: 0.3)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  // Contact info
                  _DetailSection(
                    title: 'Contact Information',
                    icon: Icons.person_outline,
                    children: [
                      _DetailRow(Icons.email_outlined, 'Email', lead.email),
                      if (lead.phone.isNotEmpty)
                        _DetailRow(Icons.phone_outlined, 'Phone', lead.phone),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (lead.companyName.isNotEmpty || lead.jobTitle.isNotEmpty)
                    _DetailSection(
                      title: 'Company Details',
                      icon: Icons.business_outlined,
                      children: [
                        if (lead.companyName.isNotEmpty)
                          _DetailRow(Icons.apartment_outlined, 'Company', lead.companyName),
                        if (lead.jobTitle.isNotEmpty)
                          _DetailRow(Icons.work_outline, 'Job Title', lead.jobTitle),
                      ],
                    ),
                  const SizedBox(height: 16),
                  _DetailSection(
                    title: 'Pipeline',
                    icon: Icons.bar_chart_outlined,
                    children: [
                      _DetailRow(Icons.source_outlined, 'Source', lead.source.label),
                      _DetailRow(Icons.currency_rupee, 'Value', lead.value > 0 ? '₹${lead.value.toStringAsFixed(0)}' : 'Not set'),
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

class _DetailSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _DetailSection({
    required this.title,
    required this.icon,
    required this.children,
  });

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
                      color: Color(0xFF374151),
                      letterSpacing: 0.3)),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF9CA3AF)),
          const SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 12, color: Color(0xFF111827)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// ─── ADD / EDIT LEAD DIALOG ───────────────────────────────────────────────────

class _AddLeadDialog extends StatefulWidget {
  final Lead? existing;
  final Function(Lead) onSave;

  const _AddLeadDialog({this.existing, required this.onSave});

  @override
  State<_AddLeadDialog> createState() => _AddLeadDialogState();
}

class _AddLeadDialogState extends State<_AddLeadDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstName, _lastName, _email,
      _company, _jobTitle, _phone, _value;
  late LeadStatus _status;
  late AcquisitionSource _source;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _firstName = TextEditingController(text: e?.firstName ?? '');
    _lastName = TextEditingController(text: e?.lastName ?? '');
    _email = TextEditingController(text: e?.email ?? '');
    _company = TextEditingController(text: e?.companyName ?? '');
    _jobTitle = TextEditingController(text: e?.jobTitle ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _value = TextEditingController(text: e?.value.toString() ?? '0');
    _status = e?.status ?? LeadStatus.newLead;
    _source = e?.source ?? AcquisitionSource.website;
  }

  @override
  void dispose() {
    for (final c in [_firstName, _lastName, _email, _company, _jobTitle, _phone, _value]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final lead = Lead(
      id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      email: _email.text.trim(),
      companyName: _company.text.trim(),
      jobTitle: _jobTitle.text.trim(),
      phone: _phone.text.trim(),
      status: _status,
      source: _source,
      value: double.tryParse(_value.text) ?? 0,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
    widget.onSave(lead);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  children: [
                    Expanded(
                      child: Text(isEdit ? 'Edit Lead' : 'Add New Lead',
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827))),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                Text(
                  isEdit ? 'Update lead details.' : 'Fill in the details to add a new lead to your CRM.',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 20),
                _sectionHeader(Icons.person_outline, 'CONTACT INFORMATION'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _field(_firstName, 'First Name', hint: 'John', required: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _field(_lastName, 'Last Name', hint: 'Doe')),
                  ],
                ),
                const SizedBox(height: 12),
                _field(_email, 'Email Address',
                    hint: 'john@example.com',
                    keyboardType: TextInputType.emailAddress,
                    required: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email required';
                      if (!v.contains('@')) return 'Invalid email';
                      return null;
                    }),
                const SizedBox(height: 20),
                _sectionHeader(Icons.business_outlined, 'COMPANY DETAILS'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _field(_company, 'Company Name', hint: 'Acme Inc')),
                    const SizedBox(width: 12),
                    Expanded(child: _field(_jobTitle, 'Job Title', hint: 'CEO')),
                  ],
                ),
                const SizedBox(height: 12),
                _field(_phone, 'Phone Number',
                    hint: '+1 (555) 000-0000',
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 20),
                _sectionHeader(Icons.bar_chart_outlined, 'PIPELINE STRATEGY'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Lead Status',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF374151))),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<LeadStatus>(
                                value: _status,
                                isExpanded: true,
                                style: const TextStyle(
                                    fontSize: 13, color: Color(0xFF111827)),
                                items: LeadStatus.values.map((s) {
                                  return DropdownMenuItem(
                                    value: s,
                                    child: Text(s.label,
                                        style: const TextStyle(fontSize: 12)),
                                  );
                                }).toList(),
                                onChanged: (v) =>
                                    setState(() => _status = v!),
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
                          const Text('Acquisition Source',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF374151))),
                          const SizedBox(height: 6),
                          Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<AcquisitionSource>(
                                value: _source,
                                isExpanded: true,
                                style: const TextStyle(
                                    fontSize: 13, color: Color(0xFF111827)),
                                items: AcquisitionSource.values.map((s) {
                                  return DropdownMenuItem(
                                    value: s,
                                    child: Text(s.label,
                                        style: const TextStyle(fontSize: 12)),
                                  );
                                }).toList(),
                                onChanged: (v) => setState(() => _source = v!),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _field(_value, 'Lead Value (₹)',
                    hint: '0',
                    keyboardType: TextInputType.number),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BCD4),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      isEdit ? 'UPDATE LEAD' : 'CREATE LEAD',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF00BCD4)),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
                letterSpacing: 0.5)),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String hint = '',
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151))),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          validator: validator ??
              (required
                  ? (v) => (v == null || v.isEmpty) ? '$label is required' : null
                  : null),
        ),
      ],
    );
  }
}

// ─── REUSABLE WIDGETS ─────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  final Color color;
  final double size;

  const _Avatar({required this.name, required this.color, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Center(
        child: Text(name,
            style: TextStyle(
                fontSize: size * 0.35,
                fontWeight: FontWeight.w700,
                color: color)),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final LeadStatus status;
  final bool large;

  const _StatusBadge({required this.status, this.large = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: large ? 12 : 8, vertical: large ? 6 : 3),
      decoration: BoxDecoration(
        color: status.bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withOpacity(0.25)),
      ),
      child: Text(status.label,
          style: TextStyle(
              fontSize: large ? 12 : 9,
              fontWeight: FontWeight.w700,
              color: status.color,
              letterSpacing: 0.3)),
    );
  }
}
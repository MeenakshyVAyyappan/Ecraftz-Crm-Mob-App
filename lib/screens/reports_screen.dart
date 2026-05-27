import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';


// ─── THEME ────────────────────────────────────────────────────────────────────

class RTheme {
  static const Color primary = Color(0xFF06B6D4);
  static const Color primaryDark = Color(0xFF0891B2);
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color indigo = Color(0xFF6366F1);

  static Color statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'active': case 'paid': case 'approved': case 'present': case 'done': return success;
      case 'sent': case 'in progress': case 'review': case 'planning': return primary;
      case 'pending': case 'draft': case 'medium': return warning;
      case 'denied': case 'rejected': case 'urgent': case 'overdue': return danger;
      case 'high': return danger;
      case 'low': return const Color(0xFF64748B);
      case 'clarification_required': return purple;
      default: return textSecondary;
    }
  }
}

// ─── MODELS ───────────────────────────────────────────────────────────────────

class ReportCategory {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final List<ReportItem> items;
  const ReportCategory({required this.title, required this.subtitle,
      required this.color, required this.icon, required this.items});
}

class ReportItem {
  final String title;
  final String type;
  final IconData icon;
  final String route;
  const ReportItem({required this.title, required this.type,
      required this.icon, required this.route});
}

// ─── SAMPLE DATA ──────────────────────────────────────────────────────────────

// Employee Directory
final empDirStats = {'workforce': 9, 'operators': 8, 'admins': 1, 'avgRate': 0.0};
final List<Map<String, dynamic>> empDirData = [
  {'initials': 'HI', 'name': 'hina', 'email': 'HANNA.ECRAFTZ@GMAIL.COM', 'role': 'MANAGER', 'rate': 0.0, 'status': 'ACTIVE'},
  {'initials': 'RO', 'name': 'Roronoa', 'email': 'RORONOAZORO8025@GMAIL.COM', 'role': 'EMPLOYEE', 'rate': 0.0, 'status': 'ACTIVE'},
  {'initials': 'FA', 'name': 'Fathima Safa', 'email': 'FATHIMASAFA.WORK@GMAIL.COM', 'role': 'EMPLOYEE', 'rate': 0.0, 'status': 'ACTIVE'},
  {'initials': 'TO', 'name': 'Tony Stark', 'email': 'VISWAJITH.ECRAFTZ@GMAIL.COM', 'role': 'EMPLOYEE', 'rate': 0.0, 'status': 'ACTIVE'},
  {'initials': 'CH', 'name': 'Chimbu', 'email': 'HACKERHACKER0424@GMAIL.COM', 'role': 'EMPLOYEE', 'rate': 0.0, 'status': 'ACTIVE'},
  {'initials': 'RO', 'name': 'Roopesh', 'email': 'LIVEIN@JANANILIFESTYLE.IN', 'role': 'EMPLOYEE', 'rate': 0.0, 'status': 'DENIED'},
];

// Attendance Logs
final attStats = {'sessions': 4, 'onTime': 100.0, 'late': 0, 'break': 94.0};
final List<Map<String, dynamic>> attData = [
  {'name': 'Sasi', 'date': '2026-05-12', 'in': '02:52 PM', 'out': '---', 'duration': '---', 'status': 'PRESENT'},
  {'name': 'viswajith e', 'date': '2026-05-12', 'in': '05:53 PM', 'out': '05:53 PM', 'duration': '0h 0m', 'status': 'PRESENT'},
  {'name': 'viswajith e', 'date': '2026-05-09', 'in': '12:21 PM', 'out': '12:21 PM', 'duration': '0h 0m', 'status': 'PRESENT'},
  {'name': 'viswajith e', 'date': '2026-05-09', 'in': '12:21 PM', 'out': '12:21 PM', 'duration': '0h 0m', 'status': 'PRESENT'},
];

// Leave Management
final leaveStats = {'total': 2, 'approved': 1, 'pending': 0, 'rejRate': 0.0};
final List<Map<String, dynamic>> leaveData = [
  {'name': 'Chimbu', 'start': 'May 20, 2026', 'end': 'May 21, 2026', 'reason': 'High fever', 'status': 'APPROVED'},
  {'name': 'Tony Stark', 'start': 'May 19, 2026', 'end': 'May 19, 2026', 'reason': 'brother wedding', 'status': 'CLARIFICATION_REQUIRED'},
];

// Invoice Audit
final invAuditStats = {'total': 17, 'reconciled': 12, 'voided': 0, 'integrity': 71.0};
final List<Map<String, dynamic>> invAuditData = [
  {'inv': 'INV-701', 'client': 'janani', 'id': 'ID: 005A6216...', 'date': 'May 23, 2026 16:59', 'face': '\$0', 'rec': '\$0', 'status': 'PAID'},
  {'inv': 'INV-432', 'client': 'janani', 'id': 'ID: 005A6216...', 'date': 'May 23, 2026 14:32', 'face': '\$0', 'rec': '\$0', 'status': 'SENT'},
  {'inv': 'INV-3762', 'client': 'Steve rogers', 'id': 'ID: 3DC5E428...', 'date': 'May 12, 2026 11:24', 'face': '\$0', 'rec': '\$0', 'status': 'SENT'},
  {'inv': 'INV-5446', 'client': 'Steve rogers', 'id': 'ID: 3DC5E428...', 'date': 'May 12, 2026 11:22', 'face': '\$0', 'rec': '\$0', 'status': 'PAID'},
  {'inv': 'INV-5904', 'client': 'shock stark', 'id': 'ID: 352864A8...', 'date': 'May 12, 2026 11:18', 'face': '\$0', 'rec': '\$0', 'status': 'PAID'},
];

// Financial Invoices
final finInvStats = {'total': 17, 'verified': '₹0', 'awaiting': '₹0', 'overdue': 0};
final List<Map<String, dynamic>> finInvData = [
  {'inv': 'INV-701', 'client': 'janani', 'due': 'May 23, 2026', 'amount': '₹0', 'paid': '₹0', 'status': 'PAID'},
  {'inv': 'INV-432', 'client': 'janani', 'due': 'May 23, 2026', 'amount': '₹0', 'paid': '₹0', 'status': 'SENT'},
  {'inv': 'INV-3762', 'client': 'Steve rogers', 'due': 'May 12, 2026', 'amount': '₹0', 'paid': '₹0', 'status': 'SENT'},
  {'inv': 'INV-5446', 'client': 'Steve rogers', 'due': 'May 12, 2026', 'amount': '₹0', 'paid': '₹0', 'status': 'PAID'},
  {'inv': 'INV-5904', 'client': 'shock stark', 'due': 'May 12, 2026', 'amount': '₹0', 'paid': '₹0', 'status': 'PAID'},
  {'inv': 'INV-7344', 'client': 'meethu', 'due': 'May 12, 2026', 'amount': '₹0', 'paid': '₹0', 'status': 'SENT'},
];

// Expense Report
final expStats = {'outflow': '\$50', 'volume': 1, 'awaiting': '\$50', 'deviation': 2.1};
final List<Map<String, dynamic>> expData = [
  {'date': 'May 26, 2026', 'desc': 'asdfghjkfghjukilo', 'project': 'JANANI - WEB DEVELOPMENT DYNAMIC SPECIFICATION V1', 'amount': '-\$50', 'cat': 'HOSTING', 'status': 'PENDING'},
];

// Payment Records
final payStats = {'collected': '₹0', 'transit': '₹0', 'attempts': 0, 'failed': 0};
final List<Map<String, dynamic>> payData = [];

// Client Insights
final clientStats = {'portfolio': 11, 'active': 11, 'footprint': 5, 'velocity': '98%'};
final List<Map<String, dynamic>> clientData = [
  {'name': 'Asgti Glo', 'industry': 'GENERAL INDUSTRY', 'email': 'asgtglobal@gmail.com', 'phone': '9874563210', 'location': 'calicut', 'joined': 'May 26, 2026', 'status': 'ACTIVE'},
  {'name': 'arsenal', 'industry': 'GENERAL INDUSTRY', 'email': 'arsenal@gmail.com', 'phone': '1234567895', 'location': 'hello 1234', 'joined': 'May 21, 2026', 'status': 'ACTIVE'},
  {'name': 'janani', 'industry': 'GENERAL INDUSTRY', 'email': 'livein@janani.in', 'phone': '', 'location': 'Global', 'joined': 'May 20, 2026', 'status': 'ACTIVE'},
  {'name': 'ecocraft', 'industry': 'GENERAL INDUSTRY', 'email': '', 'phone': '', 'location': 'Global', 'joined': 'May 20, 2026', 'status': 'ACTIVE'},
  {'name': 'Steve rogers', 'industry': 'GENERAL INDUSTRY', 'email': 'viswajith.ecraftz@gmail.com', 'phone': '+917736958025', 'location': 'Global', 'joined': 'May 6, 2026', 'status': 'ACTIVE'},
];

// Project Lifecycle
final projStats = {'portfolio': 13, 'active': 3, 'value': '₹72,446', 'delivery': '15%'};
final List<Map<String, dynamic>> projData = [
  {'name': 'arsenal - Digital Marketing Premium Intake v1', 'client': 'ARSENAL', 'timeline': 'May 21, 26 - Cont.', 'budget': '₹30,000', 'stage': 'PLANNING'},
  {'name': 'janani - Web Development Dynamic Specification v1', 'client': 'JANANI', 'timeline': 'May 20, 26 - Cont.', 'budget': '₹20,000', 'stage': 'PLANNING'},
  {'name': 'janani', 'client': 'JANANI', 'timeline': 'May 20, 26 - May 21, 26', 'budget': '₹0', 'stage': 'PLANNING'},
  {'name': 'ecocraft', 'client': 'ECOCRAFT', 'timeline': 'May 4, 26 - Cont.', 'budget': '₹100', 'stage': 'IN PROGRESS'},
];

// Task Performance
final taskStats = {'total': 6, 'velocity': '67%', 'overdue': 1, 'backlog': 0};
final List<Map<String, dynamic>> taskData = [
  {'task': 'develop ecraftz', 'project': 'JANANI - WEB DEVELOPMENT DYNAMIC SPECIFICATION V1', 'assignee': 'hina', 'due': 'May 28, 2026', 'priority': 'URGENT', 'status': 'REVIEW', 'overdue': false},
  {'task': 'design this', 'project': 'JANANI - WEB DEVELOPMENT DYNAMIC SPECIFICATION V1', 'assignee': 'Fathima Safa', 'due': 'May 27, 2026', 'priority': 'URGENT', 'status': 'DONE', 'overdue': false},
  {'task': 'landing page', 'project': 'ARSENAL - DIGITAL MARKETING PREMIUM INTAKE V1', 'assignee': 'Chimbu', 'due': 'May 27, 2026', 'priority': 'LOW', 'status': 'IN PROGRESS', 'overdue': true},
  {'task': 'hello brooo', 'project': 'ARSENAL - DIGITAL MARKETING PREMIUM INTAKE V1', 'assignee': 'Tony Stark', 'due': 'May 28, 2026', 'priority': 'MEDIUM', 'status': 'DONE', 'overdue': false},
  {'task': 'design dashboard', 'project': 'ARSENAL - DIGITAL MARKETING PREMIUM INTAKE V1', 'assignee': 'Chimbu', 'due': 'May 23, 2026', 'priority': 'HIGH', 'status': 'DONE', 'overdue': false},
  {'task': 'develop this', 'project': 'JANANI - WEB DEVELOPMENT DYNAMIC SPECIFICATION V1', 'assignee': 'Chimbu', 'due': 'May 22, 2026', 'priority': 'HIGH', 'status': 'DONE', 'overdue': false},
];

// Renewals Matrix
final renewStats = {'matrix': 1, 'pipeline': '₹0', 'critical': 0, 'collection': '0%'};
final List<Map<String, dynamic>> renewData = [
  {'service': 'swderfssdd', 'client': 'CHIMBU • JANANI', 'category': 'HOSTING & DOMAIN', 'expiry': 'May 15, 2026', 'value': '₹50', 'reminders': '2 SENT', 'status': 'PAID'},
];

// Sales Pipeline Leads
final leadsStats = {'velocity': 0, 'pipeline': '₹0', 'conversion': '0%', 'avgAge': '12 DAYS'};
final List<Map<String, dynamic>> leadsData = [];

// System Activity Feed
final sysStats = {'events': 0, 'alerts': 0, 'users': 0, 'integrity': '100%'};
final List<Map<String, dynamic>> sysData = [];

// ─── REPORT CATEGORIES DATA ───────────────────────────────────────────────────

final List<ReportCategory> reportCategories = [
  ReportCategory(
    title: 'HR & PEOPLE',
    subtitle: 'Workforce analytics, attendance, and leave tracking.',
    color: RTheme.primary,
    icon: Icons.people_alt_rounded,
    items: [
      ReportItem(title: 'Employee Directory', type: 'OPERATIONAL REPORT', icon: Icons.badge_rounded, route: 'emp_dir'),
      ReportItem(title: 'Attendance Logs', type: 'OPERATIONAL REPORT', icon: Icons.access_time_rounded, route: 'att_logs'),
      ReportItem(title: 'Leave Management', type: 'OPERATIONAL REPORT', icon: Icons.event_busy_rounded, route: 'leave_mgmt'),
    ],
  ),
  ReportCategory(
    title: 'FINANCE & ACCOUNTING',
    subtitle: 'Revenue tracking, expenses, and financial audits.',
    color: RTheme.success,
    icon: Icons.account_balance_rounded,
    items: [
      ReportItem(title: 'Income Report', type: 'OPERATIONAL REPORT', icon: Icons.trending_up_rounded, route: 'income'),
      ReportItem(title: 'Expense Report', type: 'OPERATIONAL REPORT', icon: Icons.trending_down_rounded, route: 'expense'),
      ReportItem(title: 'Invoice Audit', type: 'OPERATIONAL REPORT', icon: Icons.description_rounded, route: 'inv_audit'),
      ReportItem(title: 'Payment Records', type: 'OPERATIONAL REPORT', icon: Icons.payment_rounded, route: 'payments'),
    ],
  ),
  ReportCategory(
    title: 'OPERATIONS & CRM',
    subtitle: 'Project progress, tasks, and sales pipeline.',
    color: RTheme.purple,
    icon: Icons.business_center_rounded,
    items: [
      ReportItem(title: 'Client Insights', type: 'OPERATIONAL REPORT', icon: Icons.people_rounded, route: 'clients'),
      ReportItem(title: 'Project Lifecycle', type: 'OPERATIONAL REPORT', icon: Icons.folder_special_rounded, route: 'projects'),
      ReportItem(title: 'Task Performance', type: 'OPERATIONAL REPORT', icon: Icons.task_alt_rounded, route: 'tasks'),
      ReportItem(title: 'Asset Renewals Matrix', type: 'OPERATIONAL REPORT', icon: Icons.autorenew_rounded, route: 'renewals'),
      ReportItem(title: 'Sales Pipeline (Leads)', type: 'OPERATIONAL REPORT', icon: Icons.leaderboard_rounded, route: 'leads'),
    ],
  ),
  ReportCategory(
    title: 'SECURITY & AUDIT',
    subtitle: 'System integrity and chronological audit logs.',
    color: RTheme.warning,
    icon: Icons.security_rounded,
    items: [
      ReportItem(title: 'System Activity Feed', type: 'OPERATIONAL REPORT', icon: Icons.shield_rounded, route: 'system'),
    ],
  ),
];

// ─── REPORTS HUB SCREEN ───────────────────────────────────────────────────────

class ReportsScreen extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const ReportsScreen({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isTablet = w >= 600;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: RTheme.background,
      drawer: AppDrawer(
        selectedIndex: widget.selectedIndex,
        onItemSelected: (i) {
          widget.onItemSelected(i);
          Navigator.pop(context);
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: RTheme.primary,
        onPressed: () {},
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isTablet),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isTablet ? 20 : 14),
                child: Column(
                  children: [
                    isTablet
                        ? _buildTabletGrid(context)
                        : _buildMobileList(context),
                    const SizedBox(height: 16),
                    _buildComplianceBanner(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isTablet) {
    return Container(
      color: RTheme.cardBg,
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (!isTablet) ...[
              IconButton(
                icon: const Icon(Icons.menu_rounded, color: RTheme.textSecondary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              const SizedBox(width: 10),
            ],
            const Icon(Icons.grid_view_rounded, size: 13, color: RTheme.textSecondary),
            const SizedBox(width: 4),
            _crumb('Dashboard', false),
            const Icon(Icons.chevron_right, size: 15, color: RTheme.textSecondary),
            _crumb('Reports', true),
          ]),
          const SizedBox(height: 8),
          const Text('ERP Reporting Center',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: RTheme.textPrimary)),
          const SizedBox(height: 3),
          Text('Centralized access to professional enterprise reports and operational data audits.',
              style: TextStyle(fontSize: 12, color: RTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _crumb(String label, bool active) => Text(label,
      style: TextStyle(fontSize: 12,
          color: active ? RTheme.primary : RTheme.textSecondary,
          fontWeight: active ? FontWeight.w600 : FontWeight.normal));

  Widget _buildTabletGrid(BuildContext context) {
    return Column(
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _categoryCard(context, reportCategories[0])),
          const SizedBox(width: 14),
          Expanded(child: _categoryCard(context, reportCategories[1])),
        ]),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _categoryCard(context, reportCategories[2])),
          const SizedBox(width: 14),
          Expanded(child: _categoryCard(context, reportCategories[3])),
        ]),
      ],
    );
  }

  Widget _buildMobileList(BuildContext context) {
    return Column(
      children: reportCategories.map((cat) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: _categoryCard(context, cat),
      )).toList(),
    );
  }

  Widget _categoryCard(BuildContext context, ReportCategory cat) {
    return Container(
      decoration: BoxDecoration(
        color: RTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RTheme.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cat.color.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: RTheme.border)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                    color: cat.color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: Icon(cat.icon, size: 16, color: cat.color),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(cat.title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                    color: cat.color, letterSpacing: 0.3), overflow: TextOverflow.ellipsis, maxLines: 1),
                Text(cat.subtitle, style: const TextStyle(fontSize: 11, color: RTheme.textSecondary), overflow: TextOverflow.ellipsis, maxLines: 1),
              ])),
            ]),
          ),
          ...cat.items.asMap().entries.map((e) =>
              _reportRow(context, e.value, e.key == cat.items.length - 1, cat.color)),
        ],
      ),
    );
  }

  Widget _reportRow(BuildContext context, ReportItem item, bool isLast, Color accentColor) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => ReportDetailScreen(route: item.route, title: item.title))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: RTheme.border)),
          borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(12)) : null,
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: accentColor.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
            child: Icon(item.icon, size: 14, color: accentColor),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: RTheme.textPrimary), overflow: TextOverflow.ellipsis, maxLines: 1),
            Text(item.type, style: const TextStyle(fontSize: 10, color: RTheme.textSecondary,
                letterSpacing: 0.3), overflow: TextOverflow.ellipsis, maxLines: 1),
          ])),
          const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: RTheme.textSecondary),
        ]),
      ),
    );
  }

  Widget _buildComplianceBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: RTheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: RTheme.primary.withOpacity(0.2)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.verified_user_rounded, size: 16, color: RTheme.primary),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('COMPLIANCE & AUDIT INTEGRITY',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                  color: RTheme.primary, letterSpacing: 0.3)),
          const SizedBox(height: 3),
          Text('All reports are generated in real-time and comply with organization-level access control policies. '
              'Exported documents contain encrypted audit signatures for institutional record verification.',
              style: TextStyle(fontSize: 11, color: RTheme.textSecondary, height: 1.4)),
        ])),
      ]),
    );
  }
}

// ─── REPORT DETAIL SCREEN ─────────────────────────────────────────────────────

class ReportDetailScreen extends StatefulWidget {
  final String route;
  final String title;
  const ReportDetailScreen({super.key, required this.route, required this.title});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  String _search = '';
  String _statusFilter = 'ALL';
  int _page = 1;
  final int _perPage = 10;

  List<Map<String, dynamic>> get _rawData {
    switch (widget.route) {
      case 'emp_dir': return empDirData;
      case 'att_logs': return attData;
      case 'leave_mgmt': return leaveData;
      case 'inv_audit': return invAuditData;
      case 'income': case 'payments': return payData;
      case 'expense': return expData;
      case 'clients': return clientData;
      case 'projects': return projData;
      case 'tasks': return taskData;
      case 'renewals': return renewData;
      case 'leads': return leadsData;
      default: return finInvData;
    }
  }

  List<Map<String, dynamic>> get _filtered {
    return _rawData.where((row) {
      final q = _search.toLowerCase();
      final matchSearch = q.isEmpty || row.values.any((v) => v.toString().toLowerCase().contains(q));
      final matchStatus = _statusFilter == 'ALL' ||
          (row['status']?.toString().toUpperCase() == _statusFilter.toUpperCase());
      return matchSearch && matchStatus;
    }).toList();
  }

  List<Map<String, dynamic>> get _paged {
    final start = (_page - 1) * _perPage;
    final end = (start + _perPage).clamp(0, _filtered.length);
    return start >= _filtered.length ? [] : _filtered.sublist(start, end);
  }

  int get _totalPages => (_filtered.length / _perPage).ceil().clamp(1, 999);

  Map<String, dynamic> get _stats {
    switch (widget.route) {
      case 'emp_dir': return empDirStats;
      case 'att_logs': return attStats;
      case 'leave_mgmt': return leaveStats;
      case 'inv_audit': return invAuditStats;
      case 'expense': return expStats;
      case 'payments': case 'income': return payStats;
      case 'clients': return clientStats;
      case 'projects': return projStats;
      case 'tasks': return taskStats;
      case 'renewals': return renewStats;
      case 'leads': return leadsStats;
      default: return finInvStats;
    }
  }

  List<_StatCard> get _statCards {
    final s = _stats;
    switch (widget.route) {
      case 'emp_dir':
        return [
          _StatCard('TOTAL WORKFORCE', '${s['workforce']}', 'TOTAL ACTIVE PROFILES', Icons.people_alt_rounded),
          _StatCard('ACTIVE OPERATORS', '${s['operators']}', 'VERIFIED IDENTITIES', Icons.verified_user_rounded),
          _StatCard('ADMIN STRENGTH', '${s['admins']}', 'SYSTEM GOVERNANCE', Icons.admin_panel_settings_rounded),
          _StatCard('AVERAGE RATE', '\$${s['avgRate']?.toStringAsFixed(2)}', 'RESOURCE VALUATION', Icons.access_time_rounded),
        ];
      case 'att_logs':
        return [
          _StatCard('TOTAL SESSIONS', '${s['sessions']}', 'AGGREGATE ATTENDANCE ENTRIES', Icons.timer_rounded),
          _StatCard('ON-TIME RATE', '${s['onTime']}%', 'PUNCTUALITY EFFICIENCY', Icons.people_alt_rounded),
          _StatCard('LATE ARRIVALS', '${s['late']}', 'SCHEDULE DEVIATIONS', Icons.info_rounded),
          _StatCard('BREAK COMPLIANCE', '${s['break']}%', 'OPERATIONAL HEALTH', Icons.watch_rounded),
        ];
      case 'leave_mgmt':
        return [
          _StatCard('TOTAL REQUESTS', '${s['total']}', 'AGGREGATE LEAVE INTAKE', Icons.calendar_month_rounded),
          _StatCard('APPROVED LEAVES', '${s['approved']}', 'AUTHORIZED ABSENCES', Icons.check_circle_rounded),
          _StatCard('PENDING APPROVAL', '${s['pending']}', 'AWAITING HR VERIFICATION', Icons.pending_rounded),
          _StatCard('REJECTION RATE', '${s['rejRate']}%', 'POLICY COMPLIANCE', Icons.warning_rounded),
        ];
      case 'inv_audit':
        return [
          _StatCard('TOTAL AUDIT LOG', '${s['total']}', 'AGGREGATE DOCUMENT COUNT', Icons.description_rounded),
          _StatCard('RECONCILED DOCS', '${s['reconciled']}', 'SETTLED ACCOUNTS', Icons.check_circle_rounded),
          _StatCard('VOIDED INVOICES', '${s['voided']}', 'CANCELLED LIABILITIES', Icons.info_rounded),
          _StatCard('INTEGRITY SCORE', '${s['integrity']}%', 'REVENUE REALIZATION', Icons.verified_rounded),
        ];
      case 'expense':
        return [
          _StatCard('TOTAL OUTFLOW', '${s['outflow']}', 'AGGREGATE VERIFIED EXPENSES', Icons.trending_down_rounded),
          _StatCard('EXPENSE VOLUME', '${s['volume']}', 'TOTAL VOUCHERS RECORDED', Icons.receipt_rounded),
          _StatCard('AWAITING REVIEW', '${s['awaiting']}', 'UNRECONCILED LIABILITIES', Icons.shopping_cart_rounded),
          _StatCard('POLICY DEVIATION', '${s['deviation']}%', 'UNCATEGORIZED SPEND RATE', Icons.info_rounded),
        ];
      case 'payments': case 'income':
        return [
          _StatCard('TOTAL COLLECTED', '${s['collected']}', 'VERIFIED FUNDS', Icons.check_circle_rounded),
          _StatCard('IN-TRANSIT', '${s['transit']}', 'PENDING VERIFICATION', Icons.pending_rounded),
          _StatCard('PAYMENT ATTEMPTS', '${s['attempts']}', 'TOTAL TRANSACTIONS', Icons.credit_card_rounded),
          _StatCard('FAILED DEPOSITS', '${s['failed']}', 'BOUNCED OR DECLINED', Icons.info_rounded),
        ];
      case 'clients':
        return [
          _StatCard('TOTAL PORTFOLIO', '${s['portfolio']}', 'AGGREGATE INSTITUTIONAL CLIENTS', Icons.people_alt_rounded),
          _StatCard('ACTIVE PARTNERS', '${s['active']}', 'VERIFIED ACTIVE ACCOUNTS', Icons.business_rounded),
          _StatCard('GLOBAL FOOTPRINT', '${s['footprint']}', 'DISTINCT TERRITORIES', Icons.public_rounded),
          _StatCard('ACCOUNT VELOCITY', '${s['velocity']}', 'RETENTION PERFORMANCE', Icons.people_rounded),
        ];
      case 'projects':
        return [
          _StatCard('PROJECT PORTFOLIO', '${s['portfolio']}', 'TOTAL ACTIVE ENGAGEMENTS', Icons.folder_rounded),
          _StatCard('ACTIVE DELIVERY', '${s['active']}', 'CURRENTLY IN PRODUCTION', Icons.trending_up_rounded),
          _StatCard('PORTFOLIO VALUE', '${s['value']}', 'MANAGED ASSET TOTAL', Icons.attach_money_rounded),
          _StatCard('DELIVERY RATE', '${s['delivery']}', 'PORTFOLIO EFFICIENCY', Icons.track_changes_rounded),
        ];
      case 'tasks':
        return [
          _StatCard('TOTAL TASKS', '${s['total']}', 'AGGREGATE WORKLOAD VOLUME', Icons.task_alt_rounded),
          _StatCard('VELOCITY RATE', '${s['velocity']}', 'THROUGHPUT EFFICIENCY', Icons.flash_on_rounded),
          _StatCard('OVERDUE SLIPPAGE', '${s['overdue']}', 'TIMELINE DEVIATIONS', Icons.info_rounded),
          _StatCard('ACTIVE BACKLOG', '${s['backlog']}', 'QUEUE DEPTH', Icons.pending_rounded),
        ];
      case 'renewals':
        return [
          _StatCard('RENEWAL MATRIX', '${s['matrix']}', 'TOTAL ACTIVE ASSETS', Icons.autorenew_rounded),
          _StatCard('PIPELINE VALUE', '${s['pipeline']}', 'MANAGED ASSET VOLUME', Icons.attach_money_rounded),
          _StatCard('CRITICAL WINDOW', '${s['critical']}', 'EXPIRING < 30 DAYS', Icons.info_rounded),
          _StatCard('COLLECTION RATE', '${s['collection']}', 'CURRENT PERIOD HEALTH', Icons.check_circle_rounded),
        ];
      case 'leads':
        return [
          _StatCard('LEAD VELOCITY', '${s['velocity']}', 'NEW PROSPECTS CAPTURED', Icons.track_changes_rounded),
          _StatCard('PIPELINE VALUE', '${s['pipeline']}', 'PROJECTED REVENUE', Icons.trending_up_rounded),
          _StatCard('CONVERSION RATE', '${s['conversion']}', 'LEAD TO CLIENT SUCCESS', Icons.people_rounded),
          _StatCard('AVERAGE AGE', '${s['avgAge']}', 'RESPONSE LATENCY', Icons.pending_rounded),
        ];
      default:
        return [
          _StatCard('TOTAL BILLING', '${s['total']}', 'TOTAL INVOICES GENERATED', Icons.description_rounded),
          _StatCard('VERIFIED REVENUE', '${s['verified']}', 'SETTLED ACCOUNTS', Icons.attach_money_rounded),
          _StatCard('AWAITING PAYMENT', '${s['awaiting']}', 'PROJECTED CASHFLOW', Icons.pending_rounded),
          _StatCard('CRITICAL OVERDUE', '${s['overdue']}', 'IMMEDIATE ACTION REQUIRED', Icons.warning_rounded),
        ];
    }
  }

  String get _reportTitle {
    switch (widget.route) {
      case 'emp_dir': return 'EMPLOYEE DIRECTORY';
      case 'att_logs': return 'HR: ATTENDANCE LOGS';
      case 'leave_mgmt': return 'HR: LEAVE MANAGEMENT';
      case 'inv_audit': return 'FINANCE: INVOICE AUDIT';
      case 'expense': return 'FINANCIAL CENTER: EXPENSE REPORTS';
      case 'payments': case 'income': return 'FINANCIAL CENTER: PAYMENT RECORDS';
      case 'clients': return 'CLIENT INSIGHTS REPORT';
      case 'projects': return 'OPERATIONS: PROJECT LIFECYCLE';
      case 'tasks': return 'OPERATIONS: TASK PERFORMANCE';
      case 'renewals': return 'OPERATIONS: RENEWALS MATRIX';
      case 'leads': return 'SALES PIPELINE: LEADS';
      default: return 'FINANCIAL CENTER: INVOICES';
    }
  }

  String get _reportSubtitle {
    switch (widget.route) {
      case 'emp_dir': return 'CHRONOLOGICAL AUDIT OF ALL ORGANIZATION MEMBERS, ACCESS ROLES, AND WORKFORCE FINANCIAL METRICS.';
      case 'att_logs': return 'COMPREHENSIVE AUDIT OF INSTITUTIONAL ATTENDANCE SESSIONS, PUNCTUALITY METRICS, AND LABOR DURATION TRACKING.';
      case 'leave_mgmt': return 'COMPREHENSIVE AUDIT OF INSTITUTIONAL LEAVE REQUESTS, ABSENCE TRENDS, AND WORKFORCE CAPACITY PLANNING.';
      case 'inv_audit': return 'FORENSIC REVIEW OF ALL FINANCIAL DOCUMENTS, MUTATION HISTORY, AND INSTITUTIONAL REVENUE INTEGRITY.';
      case 'expense': return 'COMPREHENSIVE AUDIT OF ALL OPERATIONAL EXPENDITURES, PROJECT-LINKED DISBURSEMENTS, AND INSTITUTIONAL CASH OUTFLOW.';
      case 'payments': case 'income': return 'AUDIT-READY PAYMENT RECONCILIATION LOGS, VERIFICATION TIMESTAMPS, AND INSTITUTIONAL CASHFLOW TRACKING.';
      case 'clients': return 'COMPREHENSIVE AUDIT OF ORGANIZATION PARTNERS, ACQUISITION TIMESTAMPS, AND MULTI-TERRITORY ACCOUNT STATUS.';
      case 'projects': return 'CHRONOLOGICAL AUDIT OF PROJECT STATUS, TIMELINE DEVIATIONS, AND BUDGET UTILIZATION ACROSS THE ENTERPRISE.';
      case 'tasks': return 'INSTITUTIONAL AUDIT OF TASK LIFECYCLES, DELIVERY SPEED, AND INDIVIDUAL ACCOUNTABILITY METRICS.';
      case 'renewals': return 'FORENSIC TRACKING OF SERVICE LIFECYCLES, RENEWAL COLLECTION RATES, AND PROACTIVE NOTIFICATION AUDITING.';
      case 'leads': return 'CHRONOLOGICAL AUDIT OF PROSPECTING EFFORTS, ESTIMATED PIPELINE VALUE, AND CONVERSION STATUS ACROSS TERRITORIES.';
      default: return 'COMPREHENSIVE AUDIT OF ALL ACCOUNTS RECEIVABLE, PARTIAL PAYMENTS, AND OVERDUE LIABILITY TRACKING.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isTablet = w >= 600;

    return Scaffold(
      backgroundColor: RTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildDetailHeader(isTablet),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isTablet ? 16 : 12),
                child: Column(
                  children: [
                    _buildStatGrid(isTablet),
                    const SizedBox(height: 14),
                    _buildSearchBar(isTablet),
                    const SizedBox(height: 10),
                    _buildTable(isTablet),
                    const SizedBox(height: 10),
                    _buildPagination(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailHeader(bool isTablet) {
    return Container(
      color: RTheme.cardBg,
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(border: Border.all(color: RTheme.border), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: RTheme.textSecondary),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(_reportTitle,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: RTheme.textPrimary),
                overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 6),
          Text(_reportSubtitle, style: const TextStyle(fontSize: 11, color: RTheme.textSecondary, height: 1.4)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 6, children: [
            _actionBtn(Icons.print_rounded, 'PRINT'),
            _actionBtn(Icons.grid_on_rounded, 'CSV'),
            _exportPdfBtn(),
          ]),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(border: Border.all(color: RTheme.border), borderRadius: BorderRadius.circular(7)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: RTheme.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: RTheme.textSecondary, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _exportPdfBtn() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [RTheme.primary, RTheme.primaryDark]),
          borderRadius: BorderRadius.circular(7),
          boxShadow: [BoxShadow(color: RTheme.primary.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.download_rounded, size: 13, color: Colors.white),
          SizedBox(width: 4),
          Text('EXPORT PDF', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  Widget _buildStatGrid(bool isTablet) {
    final w = MediaQuery.of(context).size.width;
    final double aspectRatio = isTablet 
        ? (w > 900 ? 2.2 : 1.6) 
        : (w < 360 ? 1.3 : 1.6);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 4 : 2,
        mainAxisSpacing: 10, crossAxisSpacing: 10,
        childAspectRatio: aspectRatio,
      ),
      itemCount: _statCards.length,
      itemBuilder: (_, i) => _statCardWidget(_statCards[i]),
    );
  }

  Widget _statCardWidget(_StatCard c) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RTheme.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: RTheme.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Text(c.label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                color: RTheme.textSecondary, letterSpacing: 0.3), overflow: TextOverflow.ellipsis)),
            Icon(c.icon, size: 14, color: RTheme.textSecondary),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: RTheme.textPrimary),
                overflow: TextOverflow.ellipsis),
            Text(c.sublabel, style: const TextStyle(fontSize: 9, color: RTheme.textSecondary, letterSpacing: 0.2),
                overflow: TextOverflow.ellipsis),
          ]),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isTablet) {
    return Row(children: [
      Expanded(
        child: Container(
          decoration: BoxDecoration(
            color: RTheme.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: RTheme.border),
          ),
          child: TextField(
            onChanged: (v) => setState(() { _search = v; _page = 1; }),
            decoration: InputDecoration(
              hintText: _searchHint,
              hintStyle: const TextStyle(fontSize: 12, color: RTheme.textSecondary),
              prefixIcon: const Icon(Icons.search_rounded, size: 16, color: RTheme.textSecondary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      _filterBtn('STATUS'),
      if (_hasSecondFilter) ...[const SizedBox(width: 6), _filterBtn(_secondFilterLabel)],
    ]);
  }

  bool get _hasSecondFilter => ['att_logs', 'expense', 'clients', 'tasks', 'renewals', 'payments', 'income'].contains(widget.route);
  String get _secondFilterLabel {
    switch (widget.route) {
      case 'att_logs': return 'DATE';
      case 'expense': return 'CATEGORY';
      case 'clients': return 'TYPE';
      case 'tasks': return 'PRIORITY';
      case 'renewals': return 'CATEGORY';
      default: return 'METHOD';
    }
  }

  String get _searchHint {
    switch (widget.route) {
      case 'emp_dir': return 'Search by name, email, or role...';
      case 'att_logs': return 'Search attendance by employee name...';
      case 'leave_mgmt': return 'Search leave requests by employee name...';
      case 'inv_audit': return 'Search audit log by invoice number or status...';
      case 'expense': return 'Search expenses by description or project...';
      case 'clients': return 'Search clients by name, industry, or location...';
      case 'projects': return 'Search projects by name or client...';
      case 'tasks': return 'Search tasks by title, project, or assignee...';
      case 'renewals': return 'Search renewals by service, client, or project...';
      case 'leads': return 'Search leads by name, email, or company...';
      default: return 'Search by invoice number or client...';
    }
  }

  Widget _filterBtn(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: RTheme.cardBg,
        border: Border.all(color: RTheme.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.filter_list_rounded, size: 13, color: RTheme.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: RTheme.textSecondary, fontWeight: FontWeight.w500)),
        const SizedBox(width: 3),
        const Icon(Icons.keyboard_arrow_down_rounded, size: 13, color: RTheme.textSecondary),
      ]),
    );
  }

  Widget _buildTable(bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: RTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RTheme.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(children: [
        if (isTablet) _tableHeaderRow(),
        if (isTablet) const Divider(height: 1, color: RTheme.border),
        _paged.isEmpty
            ? _emptyState()
            : Column(children: _paged.asMap().entries.map((e) =>
                isTablet ? _tableRow(e.value, e.key) : _mobileCard(e.value, e.key)).toList()),
      ]),
    );
  }

  List<String> get _columns {
    switch (widget.route) {
      case 'emp_dir': return ['EMPLOYEE', 'POSITION / ROLE', 'HOURLY RATE', 'STATUS'];
      case 'att_logs': return ['EMPLOYEE', 'CLOCK IN', 'CLOCK OUT', 'DURATION', 'STATUS'];
      case 'leave_mgmt': return ['EMPLOYEE', 'START DATE', 'END DATE', 'REASON', 'STATUS'];
      case 'inv_audit': return ['INVOICE #', 'CLIENT PORTFOLIO', 'AUDIT DATE', 'FACE VALUE', 'RECONCILED', 'STATUS'];
      case 'expense': return ['DATE', 'DESCRIPTION', 'AMOUNT', 'CATEGORY', 'STATUS'];
      case 'payments': case 'income': return ['PAYMENT DATE', 'REFERENCE', 'AMOUNT', 'METHOD', 'STATUS'];
      case 'clients': return ['CLIENT / COMPANY', 'CONTACT INFO', 'LOCATION', 'JOINED DATE', 'STATUS'];
      case 'projects': return ['PROJECT NAME', 'TIMELINE', 'BUDGET ALLOCATION', 'STAGE'];
      case 'tasks': return ['TASK / PROJECT', 'ASSIGNEE', 'DUE DATE', 'PRIORITY', 'STATUS'];
      case 'renewals': return ['SERVICE DETAIL', 'CATEGORY', 'EXPIRY DATE', 'VALUE', 'REMINDERS', 'STATUS'];
      case 'leads': return ['LEAD / COMPANY', 'EMAIL', 'VALUE', 'STATUS', 'CREATED'];
      default: return ['INVOICE #', 'CLIENT', 'DUE DATE', 'TOTAL AMOUNT', 'PAID', 'STATUS'];
    }
  }

  Widget _tableHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: _columns.map((c) => Expanded(
          child: Text(c, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
              color: RTheme.textSecondary, letterSpacing: 0.4)),
        )).toList(),
      ),
    );
  }

  Widget _tableRow(Map<String, dynamic> row, int index) {
    final cells = _getCells(row);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: index.isEven ? Colors.white : const Color(0xFFFAFAFF),
        border: const Border(bottom: BorderSide(color: RTheme.border)),
      ),
      child: Row(
        children: cells.asMap().entries.map((e) => Expanded(child: _cellWidget(e.value))).toList(),
      ),
    );
  }

  Widget _mobileCard(Map<String, dynamic> row, int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: index.isEven ? Colors.white : const Color(0xFFFAFAFF),
        border: const Border(bottom: BorderSide(color: RTheme.border)),
      ),
      child: _buildMobileCardContent(row),
    );
  }

  Widget _buildMobileCardContent(Map<String, dynamic> row) {
    switch (widget.route) {
      case 'emp_dir':
        return Row(children: [
          _initAvatar(row['initials'] ?? '', 36),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(row['name'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: RTheme.textPrimary)),
            Text(row['email'] ?? '', style: const TextStyle(fontSize: 10, color: RTheme.textSecondary), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Wrap(spacing: 6, children: [
              _statusChip(row['role'] ?? ''),
              _statusChip(row['status'] ?? ''),
              Text('\$${row['rate']?.toStringAsFixed(2)}/hr', style: const TextStyle(fontSize: 11, color: RTheme.textSecondary)),
            ]),
          ])),
        ]);
      case 'att_logs':
        return Row(children: [
          _initAvatar((row['name'] ?? '').substring(0, (row['name'] ?? ' ').length > 1 ? 2 : 1).toUpperCase(), 36),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(row['name'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: RTheme.textPrimary)),
            Text(row['date'] ?? '', style: const TextStyle(fontSize: 10, color: RTheme.textSecondary)),
            const SizedBox(height: 4),
            Wrap(spacing: 8, children: [
              Text('IN: ${row['in']}', style: const TextStyle(fontSize: 11, color: RTheme.success, fontWeight: FontWeight.w600)),
              Text('OUT: ${row['out']}', style: TextStyle(fontSize: 11,
                  color: row['out'] == '---' ? RTheme.textSecondary : RTheme.danger, fontWeight: FontWeight.w600)),
              _statusChip(row['status'] ?? ''),
            ]),
          ])),
        ]);
      case 'tasks':
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(row['task'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: RTheme.textPrimary))),
            _statusChip(row['status'] ?? ''),
          ]),
          const SizedBox(height: 2),
          Text(row['project'] ?? '', style: const TextStyle(fontSize: 10, color: RTheme.textSecondary), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Wrap(spacing: 8, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.person_rounded, size: 11, color: RTheme.textSecondary),
              const SizedBox(width: 3),
              Text(row['assignee'] ?? '', style: const TextStyle(fontSize: 11, color: RTheme.textSecondary)),
            ]),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.calendar_today_rounded, size: 11,
                  color: (row['overdue'] == true) ? RTheme.danger : RTheme.textSecondary),
              const SizedBox(width: 3),
              Text(row['due'] ?? '', style: TextStyle(fontSize: 11,
                  color: (row['overdue'] == true) ? RTheme.danger : RTheme.textSecondary,
                  fontWeight: (row['overdue'] == true) ? FontWeight.w700 : FontWeight.normal)),
            ]),
            _statusChip(row['priority'] ?? ''),
          ]),
        ]);
      default:
        final keys = row.keys.toList();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (keys.isNotEmpty) Text(row[keys[0]]?.toString() ?? '',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: RTheme.textPrimary),
              overflow: TextOverflow.ellipsis),
          if (keys.length > 1) ...[
            const SizedBox(height: 3),
            Text(row[keys[1]]?.toString() ?? '', style: const TextStyle(fontSize: 11, color: RTheme.textSecondary),
                overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 6),
          Wrap(spacing: 8, children: [
            for (int i = 2; i < keys.length && i < 5; i++)
              if (keys[i] == 'status' || keys[i] == 'stage' || keys[i] == 'priority' || keys[i] == 'role')
                _statusChip(row[keys[i]]?.toString() ?? '')
              else
                Text(row[keys[i]]?.toString() ?? '', style: const TextStyle(fontSize: 11, color: RTheme.textSecondary)),
          ]),
        ]);
    }
  }

  List<_CellData> _getCells(Map<String, dynamic> row) {
    switch (widget.route) {
      case 'emp_dir':
        return [
          _CellData.widget(Row(children: [
            _initAvatar(row['initials'] ?? '', 26),
            const SizedBox(width: 6),
            Expanded(child: Text(row['name'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: RTheme.textPrimary), overflow: TextOverflow.ellipsis)),
          ])),
          _CellData.chip(row['role'] ?? ''),
          _CellData.text('\$${row['rate']?.toStringAsFixed(2)}/hr', color: RTheme.success, bold: true),
          _CellData.chip(row['status'] ?? ''),
        ];
      case 'att_logs':
        return [
          _CellData.widget(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(row['name'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: RTheme.textPrimary), overflow: TextOverflow.ellipsis),
            Text(row['date'] ?? '', style: const TextStyle(fontSize: 10, color: RTheme.textSecondary), overflow: TextOverflow.ellipsis),
          ])),
          _CellData.text(row['in'] ?? '', color: RTheme.success, bold: true),
          _CellData.text(row['out'] ?? '', color: row['out'] == '---' ? RTheme.textSecondary : RTheme.danger, bold: true),
          _CellData.text(row['duration'] ?? ''),
          _CellData.chip(row['status'] ?? ''),
        ];
      case 'leave_mgmt':
        return [
          _CellData.text(row['name'] ?? '', bold: true),
          _CellData.text(row['start'] ?? ''),
          _CellData.text(row['end'] ?? ''),
          _CellData.text(row['reason'] ?? '', italic: true),
          _CellData.chip(row['status'] ?? ''),
        ];
      case 'inv_audit':
        return [
          _CellData.text(row['inv'] ?? '', bold: true, color: RTheme.primary),
          _CellData.widget(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(row['client'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: RTheme.textPrimary), overflow: TextOverflow.ellipsis),
            Text(row['id'] ?? '', style: const TextStyle(fontSize: 10, color: RTheme.textSecondary), overflow: TextOverflow.ellipsis),
          ])),
          _CellData.text(row['date'] ?? ''),
          _CellData.text(row['face'] ?? ''),
          _CellData.text(row['rec'] ?? '', color: RTheme.success),
          _CellData.chip(row['status'] ?? ''),
        ];
      case 'expense':
        return [
          _CellData.text(row['date'] ?? ''),
          _CellData.widget(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(row['desc'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: RTheme.textPrimary), overflow: TextOverflow.ellipsis),
            Text(row['project'] ?? '', style: const TextStyle(fontSize: 10, color: RTheme.textSecondary), overflow: TextOverflow.ellipsis),
          ])),
          _CellData.text(row['amount'] ?? '', color: RTheme.danger, bold: true),
          _CellData.chip(row['cat'] ?? ''),
          _CellData.chip(row['status'] ?? ''),
        ];
      case 'clients':
        return [
          _CellData.widget(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(row['name'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: RTheme.textPrimary), overflow: TextOverflow.ellipsis),
            Text(row['industry'] ?? '', style: const TextStyle(fontSize: 10, color: RTheme.textSecondary), overflow: TextOverflow.ellipsis),
          ])),
          _CellData.widget(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if ((row['email'] ?? '').isNotEmpty) Text(row['email'] ?? '', style: const TextStyle(fontSize: 10, color: RTheme.textSecondary), overflow: TextOverflow.ellipsis),
            if ((row['phone'] ?? '').isNotEmpty) Text(row['phone'] ?? '', style: const TextStyle(fontSize: 10, color: RTheme.textSecondary), overflow: TextOverflow.ellipsis),
          ])),
          _CellData.text(row['location'] ?? ''),
          _CellData.text(row['joined'] ?? ''),
          _CellData.chip(row['status'] ?? ''),
        ];
      case 'projects':
        return [
          _CellData.widget(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(row['name'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: RTheme.textPrimary), overflow: TextOverflow.ellipsis),
            Text(row['client'] ?? '', style: const TextStyle(fontSize: 10, color: RTheme.textSecondary), overflow: TextOverflow.ellipsis),
          ])),
          _CellData.text(row['timeline'] ?? ''),
          _CellData.text(row['budget'] ?? '', bold: true, color: RTheme.success),
          _CellData.chip(row['stage'] ?? ''),
        ];
      case 'tasks':
        return [
          _CellData.widget(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(row['task'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: RTheme.textPrimary), overflow: TextOverflow.ellipsis),
            Text(row['project'] ?? '', style: const TextStyle(fontSize: 9, color: RTheme.textSecondary), overflow: TextOverflow.ellipsis),
          ])),
          _CellData.text(row['assignee'] ?? ''),
          _CellData.text(row['due'] ?? '', color: (row['overdue'] == true) ? RTheme.danger : null),
          _CellData.chip(row['priority'] ?? ''),
          _CellData.chip(row['status'] ?? ''),
        ];
      case 'renewals':
        return [
          _CellData.widget(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(row['service'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: RTheme.textPrimary), overflow: TextOverflow.ellipsis),
            Text(row['client'] ?? '', style: const TextStyle(fontSize: 10, color: RTheme.textSecondary), overflow: TextOverflow.ellipsis),
          ])),
          _CellData.chip(row['category'] ?? ''),
          _CellData.text(row['expiry'] ?? ''),
          _CellData.text(row['value'] ?? '', bold: true),
          _CellData.chip(row['reminders'] ?? ''),
          _CellData.chip(row['status'] ?? ''),
        ];
      default:
        return [
          _CellData.text(row['inv'] ?? '', bold: true, color: RTheme.primary),
          _CellData.text(row['client'] ?? ''),
          _CellData.text(row['due'] ?? ''),
          _CellData.text(row['amount'] ?? ''),
          _CellData.text(row['paid'] ?? '', color: RTheme.success),
          _CellData.chip(row['status'] ?? ''),
        ];
    }
  }

  Widget _cellWidget(_CellData c) {
    if (c.isWidget) return c.widget!;
    if (c.isChip) return _statusChip(c.text ?? '');
    return Text(c.text ?? '',
        style: TextStyle(
          fontSize: 12,
          fontWeight: c.bold ? FontWeight.w700 : FontWeight.normal,
          color: c.color ?? RTheme.textPrimary,
          fontStyle: c.italic ? FontStyle.italic : FontStyle.normal,
        ),
        overflow: TextOverflow.ellipsis);
  }

  Widget _statusChip(String label) {
    if (label.isEmpty) return const SizedBox.shrink();
    final color = RTheme.statusColor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
    );
  }

  Widget _initAvatar(String initials, double size) {
    final colors = [RTheme.primary, RTheme.purple, RTheme.success, RTheme.warning, RTheme.indigo];
    final color = initials.isNotEmpty ? colors[initials.codeUnitAt(0) % colors.length] : RTheme.primary;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(size * 0.25)),
      child: Center(child: Text(
        initials.length > 2 ? initials.substring(0, 2) : initials,
        style: TextStyle(fontSize: size * 0.32, fontWeight: FontWeight.w800, color: color),
      )),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), shape: BoxShape.circle),
          child: const Icon(Icons.search_off_rounded, size: 24, color: Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 12),
        const Text('No records found for this criteria.',
            style: TextStyle(fontSize: 13, color: RTheme.textSecondary)),
      ]),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: RTheme.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: RTheme.border),
      ),
      child: Row(children: [
        Expanded(child: Text(
          'SHOWING ${_filtered.isEmpty ? "1-0" : "${(_page - 1) * _perPage + 1}-${((_page * _perPage).clamp(0, _filtered.length))}"} OF ${_filtered.length} INSTITUTIONAL RECORDS',
          style: const TextStyle(fontSize: 10, color: RTheme.textSecondary, letterSpacing: 0.3),
        )),
        GestureDetector(
          onTap: _page > 1 ? () => setState(() => _page--) : null,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _page > 1 ? RTheme.cardBg : const Color(0xFFF1F5F9),
              border: Border.all(color: RTheme.border),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.chevron_left, size: 16,
                color: _page > 1 ? RTheme.textPrimary : RTheme.textSecondary),
          ),
        ),
        const SizedBox(width: 8),
        Text('PAGE $_page / $_totalPages',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RTheme.textPrimary)),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _page < _totalPages ? () => setState(() => _page++) : null,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _page < _totalPages ? RTheme.cardBg : const Color(0xFFF1F5F9),
              border: Border.all(color: RTheme.border),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.chevron_right, size: 16,
                color: _page < _totalPages ? RTheme.textPrimary : RTheme.textSecondary),
          ),
        ),
      ]),
    );
  }
}

// ─── HELPERS ──────────────────────────────────────────────────────────────────

class _StatCard {
  final String label, value, sublabel;
  final IconData icon;
  const _StatCard(this.label, this.value, this.sublabel, this.icon);
}

class _CellData {
  final String? text;
  final Color? color;
  final bool bold, italic, isChip, isWidget;
  final Widget? widget;

  const _CellData._({this.text, this.color, this.bold = false, this.italic = false,
      this.isChip = false, this.isWidget = false, this.widget});

  factory _CellData.text(String t, {Color? color, bool bold = false, bool italic = false}) =>
      _CellData._(text: t, color: color, bold: bold, italic: italic);

  factory _CellData.chip(String t) => _CellData._(text: t, isChip: true);

  factory _CellData.widget(Widget w) => _CellData._(isWidget: true, widget: w);
}
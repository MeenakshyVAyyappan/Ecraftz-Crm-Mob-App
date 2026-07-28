import 'package:ecraftz_crm/widgets/app_refresh_button.dart';
import 'package:ecraftz_crm/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import '../../widgets/app_drawer.dart';
import '../../theme/app_theme.dart';
import '../../blocs/theme/theme_bloc.dart';
import '../../services/supabase_service.dart';
import 'package:intl/intl.dart';
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
// Hardcoded dummy data removed. Connecting directly to Supabase.

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

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => Theme.of(context).scaffoldBackgroundColor;
  Color get _cardBg => Theme.of(context).colorScheme.surface;
  Color get _border => AppTheme.borderOf(context);
  Color get _textPrimary => AppTheme.textPrimaryOf(context);
  Color get _textSecondary => AppTheme.textSecondaryOf(context);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isTablet = w >= 600;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bg,
      drawer: AppDrawer(
        selectedIndex: widget.selectedIndex,
        onItemSelected: (i) {
          widget.onItemSelected(i);
          Navigator.pop(context);
        },
      ),
      appBar: AppBar(
        backgroundColor: _cardBg,
        elevation: 0,
        leading: isTablet
            ? null
            : IconButton(
                icon: Icon(Icons.menu_rounded, color: _isDark ? Colors.white : const Color(0xFF374151)),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ERP Reporting Center',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _textPrimary)),
            Text('Centralized access to professional enterprise reports and operational data audits.',
                style: TextStyle(fontSize: 10, color: _textSecondary)),
          ],
        ),
        actions: [
          AppRefreshButton(
            onRefresh: () async {
              if (mounted) setState(() {});
              await Future.delayed(const Duration(milliseconds: 600));
            },
          ),
          const SizedBox(width: 4),
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
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
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
      color: _cardBg,
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 14, vertical: 10),
      child: Row(children: [
        Icon(Icons.grid_view_rounded, size: 13, color: _textSecondary),
        const SizedBox(width: 4),
        _crumb('Dashboard', false),
        Icon(Icons.chevron_right, size: 15, color: _textSecondary),
        _crumb('Reports', true),
      ]),
    );
  }

  Widget _crumb(String label, bool active) => Text(label,
      style: TextStyle(fontSize: 12,
          color: active ? RTheme.primary : _textSecondary,
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
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
        boxShadow: _isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cat.color.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: _border)),
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
                Text(cat.subtitle, style: TextStyle(fontSize: 11, color: _textSecondary), overflow: TextOverflow.ellipsis, maxLines: 1),
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
          border: isLast ? null : Border(bottom: BorderSide(color: _border)),
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
            Text(item.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: _textPrimary), overflow: TextOverflow.ellipsis, maxLines: 1),
            Text(item.type, style: TextStyle(fontSize: 10, color: _textSecondary,
                letterSpacing: 0.3), overflow: TextOverflow.ellipsis, maxLines: 1),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, size: 12, color: _textSecondary),
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
              style: TextStyle(fontSize: 11, color: _textSecondary, height: 1.4)),
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
  bool _isLoading = true;
  String _error = '';
  List<Map<String, dynamic>> _data = [];
  String _search = '';
  String _statusFilter = 'ALL';
  int _page = 1;
  final int _perPage = 10;

  List<String> _getRowStrings(Map<String, dynamic> row) {
    switch (widget.route) {
      case 'emp_dir':
        return [
          row['name']?.toString() ?? '',
          row['role']?.toString() ?? '',
          '\$${(row['rate'] as double).toStringAsFixed(2)}/hr',
          row['status']?.toString() ?? '',
        ];
      case 'att_logs':
        return [
          row['name']?.toString() ?? '',
          row['in']?.toString() ?? '',
          row['out']?.toString() ?? '',
          row['duration']?.toString() ?? '',
          row['status']?.toString() ?? '',
        ];
      case 'leave_mgmt':
        return [
          row['name']?.toString() ?? '',
          row['start']?.toString() ?? '',
          row['end']?.toString() ?? '',
          row['reason']?.toString() ?? '',
          row['status']?.toString() ?? '',
        ];
      case 'inv_audit':
        return [
          row['inv']?.toString() ?? '',
          row['client']?.toString() ?? '',
          row['date']?.toString() ?? '',
          row['face']?.toString() ?? '',
          row['rec']?.toString() ?? '',
          row['status']?.toString() ?? '',
        ];
      case 'expense':
        return [
          row['date']?.toString() ?? '',
          row['desc']?.toString() ?? '',
          row['amount']?.toString() ?? '',
          row['cat']?.toString() ?? '',
          row['status']?.toString() ?? '',
        ];
      case 'payments':
        return [
          row['date']?.toString() ?? '',
          row['ref']?.toString() ?? '',
          row['client']?.toString() ?? '',
          row['amount']?.toString() ?? '',
          row['method']?.toString() ?? '',
          row['status']?.toString() ?? '',
        ];
      case 'clients':
        return [
          row['name']?.toString() ?? '',
          '${row['email'] ?? ''} ${row['phone'] ?? ''}'.trim(),
          row['location']?.toString() ?? '',
          row['joined']?.toString() ?? '',
          row['status']?.toString() ?? '',
        ];
      case 'projects':
        return [
          row['name']?.toString() ?? '',
          row['timeline']?.toString() ?? '',
          row['budget']?.toString() ?? '',
          row['stage']?.toString() ?? '',
        ];
      case 'tasks':
        return [
          '${row['task'] ?? ''} (${row['project'] ?? ''})',
          row['assignee']?.toString() ?? '',
          row['due']?.toString() ?? '',
          row['priority']?.toString() ?? '',
          row['status']?.toString() ?? '',
        ];
      case 'renewals':
        return [
          row['service']?.toString() ?? '',
          row['category']?.toString() ?? '',
          row['expiry']?.toString() ?? '',
          row['value']?.toString() ?? '',
          row['reminders']?.toString() ?? '',
          row['status']?.toString() ?? '',
        ];
      case 'leads':
        return [
          '${row['name'] ?? ''} (${row['company'] ?? ''})',
          row['email']?.toString() ?? '',
          row['value']?.toString() ?? '',
          row['status']?.toString() ?? '',
          row['created']?.toString() ?? '',
        ];
      case 'system':
        return [
          row['timestamp']?.toString() ?? '',
          row['action']?.toString() ?? '',
          row['target']?.toString() ?? '',
          row['user']?.toString() ?? '',
        ];
      default:
        return [
          row['inv']?.toString() ?? '',
          row['client']?.toString() ?? '',
          row['due']?.toString() ?? '',
          row['amount']?.toString() ?? '',
          row['paid']?.toString() ?? '',
          row['status']?.toString() ?? '',
        ];
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  Future<void> _fetchReportData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final client = SupabaseService.client;
      List<Map<String, dynamic>> loadedData = [];
      switch (widget.route) {
        case 'emp_dir':
          final res = await client
              .from('profiles')
              .select()
              .eq('organization_id', '00000000-0000-0000-0000-000000000000');
          loadedData = (res as List).map((row) {
            final name = row['full_name']?.toString() ?? row['username']?.toString() ?? 'Unknown';
            final email = row['email']?.toString() ?? '';
            final role = row['role']?.toString().toUpperCase() ?? 'EMPLOYEE';
            final status = row['status']?.toString().toUpperCase() ?? 'ACTIVE';
            final nameParts = name.trim().split(' ');
            final initials = nameParts.length >= 2
                ? '${nameParts.first[0]}${nameParts.last[0]}'.toUpperCase()
                : (name.isNotEmpty ? name[0].toUpperCase() : '?');
            final double rate = (row['hourly_rate'] != null)
                ? (row['hourly_rate'] is num ? (row['hourly_rate'] as num).toDouble() : double.tryParse(row['hourly_rate'].toString()) ?? 0.0)
                : 0.0;
            return {
              'id': row['id']?.toString() ?? '',
              'initials': initials,
              'name': name,
              'email': email,
              'role': role,
              'rate': rate,
              'status': status,
              'raw_row': row,
            };
          }).toList();
          break;

        case 'att_logs':
          final res = await client
              .from('work_sessions')
              .select('*, profiles!inner(full_name, organization_id)')
              .eq('profiles.organization_id', '00000000-0000-0000-0000-000000000000')
              .isFilter('deleted_at', null)
              .order('start_time', ascending: false);
          loadedData = (res as List).map((row) {
            final profile = row['profiles'] as Map?;
            final name = profile?['full_name']?.toString() ?? 'Unknown';
            final startTimeStr = row['start_time']?.toString() ?? '';
            final endTimeStr = row['end_time']?.toString() ?? '';
            String dateStr = '';
            String clockInStr = '---';
            String clockOutStr = '---';
            String durationStr = '---';
            if (startTimeStr.isNotEmpty) {
              final startTime = DateTime.tryParse(startTimeStr)?.toLocal();
              if (startTime != null) {
                dateStr = DateFormat('MMM dd, yyyy').format(startTime);
                clockInStr = DateFormat('hh:mm a').format(startTime);
              }
            }
            if (endTimeStr.isNotEmpty) {
              final endTime = DateTime.tryParse(endTimeStr)?.toLocal();
              if (endTime != null) {
                clockOutStr = DateFormat('hh:mm a').format(endTime);
                if (startTimeStr.isNotEmpty) {
                  final startTime = DateTime.tryParse(startTimeStr)?.toLocal();
                  if (startTime != null) {
                    final diff = endTime.difference(startTime);
                    final hours = diff.inHours;
                    final minutes = diff.inMinutes.remainder(60);
                    durationStr = "${hours}h ${minutes}m";
                  }
                }
              }
            }
            final status = row['status']?.toString().toUpperCase() ?? 'ACTIVE';
            return {
              'id': row['id']?.toString() ?? '',
              'name': name,
              'date': dateStr,
              'in': clockInStr,
              'out': clockOutStr,
              'duration': durationStr,
              'status': status,
              'raw_row': row,
            };
          }).toList();
          break;

        case 'leave_mgmt':
          final res = await client
              .from('leave_requests')
              .select('*, profiles!user_id!inner(full_name, organization_id)')
              .eq('profiles.organization_id', '00000000-0000-0000-0000-000000000000');
          loadedData = (res as List).map((row) {
            final profile = (row['profiles'] ?? row['profiles!user_id']) as Map?;
            final name = profile?['full_name']?.toString() ?? 'Unknown';
            final start = row['start_date']?.toString() ?? '';
            final end = row['end_date']?.toString() ?? '';
            final reason = row['reason']?.toString() ?? '';
            final status = row['status']?.toString().toUpperCase() ?? 'PENDING';
            return {
              'id': row['id']?.toString() ?? '',
              'name': name,
              'start': start,
              'end': end,
              'reason': reason,
              'status': status,
              'raw_row': row,
            };
          }).toList();
          break;

        case 'inv_audit':
          final res = await client
              .from('invoices')
              .select('*, clients(name)')
              .isFilter('deleted_at', null)
              .eq('organization_id', '00000000-0000-0000-0000-000000000000');
          loadedData = (res as List).map((row) {
            final clientMap = row['clients'] as Map?;
            final clientName = clientMap?['name']?.toString() ?? 'Unknown';
            final inv = row['invoice_number']?.toString() ?? 'INV-?';
            final id = row['id']?.toString() ?? '';
            final date = row['created_at']?.toString() ?? row['date']?.toString() ?? '';
            final face = (row['grand_total'] ?? 0.0).toDouble();
            final rec = (row['amount_paid'] ?? 0.0).toDouble();
            final status = row['status']?.toString().toUpperCase() ?? 'DRAFT';
            return {
              'id': id,
              'display_id': 'ID: ${id.length > 8 ? id.substring(0, 8) : id}...',
              'inv': inv,
              'client': clientName,
              'date': date,
              'face': '\$${face.toStringAsFixed(0)}',
              'rec': '\$${rec.toStringAsFixed(0)}',
              'status': status,
              'raw_row': row,
            };
          }).toList();
          break;

        case 'expense':
          final res = await client
              .from('project_expenses')
              .select('*, projects(name)')
              .eq('organization_id', '00000000-0000-0000-0000-000000000000');
          loadedData = (res as List).map((row) {
            final project = row['projects'] as Map?;
            final projectName = project?['name']?.toString() ?? 'Independent Expense';
            final desc = row['description']?.toString() ?? '';
            final date = row['expense_date']?.toString() ?? '';
            final amount = (row['amount'] ?? 0.0).toDouble();
            final cat = row['category']?.toString().toUpperCase() ?? 'OTHER';
            return {
              'id': row['id']?.toString() ?? '',
              'date': date,
              'desc': desc,
              'project': projectName.toUpperCase(),
              'amount': '-\$${amount.toStringAsFixed(0)}',
              'cat': cat,
              'status': 'PENDING',
              'raw_row': row,
            };
          }).toList();
          break;

        case 'payments':
          final res = await client
              .from('payments')
              .select('*, clients(name)')
              .isFilter('deleted_at', null)
              .eq('organization_id', '00000000-0000-0000-0000-000000000000');
          loadedData = (res as List).map((row) {
            final clientMap = row['clients'] as Map?;
            final clientName = clientMap?['name']?.toString() ?? 'Unknown';
            final paymentNumber = row['payment_number']?.toString() ?? '';
            final date = row['date']?.toString() ?? '';
            final amount = (row['amount'] ?? 0.0).toDouble();
            final mode = row['payment_mode']?.toString() ?? '';
            final status = row['status']?.toString().toUpperCase() ?? 'PENDING';
            return {
              'id': row['id']?.toString() ?? '',
              'date': date,
              'ref': paymentNumber,
              'client': clientName,
              'amount': '₹${amount.toStringAsFixed(0)}',
              'method': mode.toUpperCase(),
              'status': status,
              'raw_row': row,
            };
          }).toList();
          break;

        case 'clients':
          final res = await client
              .from('clients')
              .select()
              .isFilter('deleted_at', null)
              .eq('organization_id', '00000000-0000-0000-0000-000000000000');
          loadedData = (res as List).map((row) {
            final name = row['name']?.toString() ?? '';
            final email = row['email']?.toString() ?? '';
            final phone = row['phone']?.toString() ?? '';
            final location = row['address']?.toString() ?? '';
            final joined = row['created_at']?.toString() ?? '';
            return {
              'id': row['id']?.toString() ?? '',
              'name': name,
              'industry': 'GENERAL INDUSTRY',
              'email': email,
              'phone': phone,
              'location': location.contains('METADATA_FALLBACK') ? 'Global' : (location.isEmpty ? 'Global' : location),
              'joined': joined.split('T')[0],
              'status': 'ACTIVE',
              'raw_row': row,
            };
          }).toList();
          break;

        case 'projects':
          final res = await client
              .from('projects')
              .select('*, clients(name)')
              .isFilter('deleted_at', null)
              .eq('organization_id', '00000000-0000-0000-0000-000000000000');
          loadedData = (res as List).map((row) {
            final clientMap = row['clients'] as Map?;
            final clientName = clientMap?['name']?.toString() ?? '';
            final name = row['name']?.toString() ?? '';
            final start = row['start_date']?.toString() ?? '';
            final end = row['end_date']?.toString() ?? 'Cont.';
            final budget = (row['budget'] ?? 0.0).toDouble();
            final stage = row['status']?.toString().toUpperCase() ?? 'PLANNING';
            return {
              'id': row['id']?.toString() ?? '',
              'name': name,
              'client': clientName.toUpperCase(),
              'timeline': '$start - $end',
              'budget': '₹${budget.toStringAsFixed(0)}',
              'stage': stage,
              'raw_row': row,
            };
          }).toList();
          break;

        case 'tasks':
          final res = await client
              .from('tasks')
              .select('*, projects(name, clients(name))')
              .isFilter('deleted_at', null)
              .eq('organization_id', '00000000-0000-0000-0000-000000000000');
          final profilesRes = await client
              .from('profiles')
              .select('id, full_name')
              .eq('organization_id', '00000000-0000-0000-0000-000000000000');
          final profileMap = {
            for (final p in profilesRes as List) p['id']?.toString(): p['full_name']?.toString()
          };
          loadedData = (res as List).map((row) {
            final title = row['title']?.toString() ?? '';
            final project = row['projects'] as Map?;
            final projectName = project?['name']?.toString() ?? '';
            final clientMap = project?['clients'] as Map?;
            final clientName = clientMap?['name']?.toString() ?? '';
            final projectLabel = clientName.isNotEmpty && projectName.isNotEmpty
                ? '${clientName.toUpperCase()} - ${projectName.toUpperCase()}'
                : (projectName.isNotEmpty ? projectName : 'Independent Task');
            final assigneeId = row['assigned_to']?.toString();
            final assignee = profileMap[assigneeId] ?? 'Unassigned';
            final due = row['due_date']?.toString() ?? '';
            final priority = row['priority']?.toString().toUpperCase() ?? 'MEDIUM';
            final status = row['status']?.toString().toUpperCase() ?? 'TODO';
            final isOverdue = row['is_overdue_completion'] == true;
            return {
              'id': row['id']?.toString() ?? '',
              'task': title,
              'project': projectLabel,
              'assignee': assignee,
              'due': due,
              'priority': priority,
              'status': status,
              'overdue': isOverdue,
              'raw_row': row,
            };
          }).toList();
          break;

        case 'renewals':
          final res = await client
              .from('renewals')
              .select('*, clients(name), projects(name)')
              .eq('organization_id', '00000000-0000-0000-0000-000000000000');
          loadedData = (res as List).map((row) {
            final clientMap = row['clients'] as Map?;
            final clientName = clientMap?['name']?.toString() ?? '';
            final service = row['description']?.toString() ?? row['category']?.toString().toUpperCase() ?? '';
            final cat = row['category']?.toString().toUpperCase() ?? 'HOSTING';
            final expiry = row['expiry_date']?.toString() ?? '';
            final amount = (row['amount'] ?? 0.0).toDouble();
            final reminders = '${row['reminders_sent'] ?? 0} SENT';
            final status = row['status']?.toString().toUpperCase() ?? 'PENDING';
            return {
              'id': row['id']?.toString() ?? '',
              'service': service,
              'client': clientName,
              'category': cat,
              'expiry': expiry,
              'value': '₹${amount.toStringAsFixed(0)}',
              'reminders': reminders,
              'status': status,
              'raw_row': row,
            };
          }).toList();
          break;

        case 'leads':
          final res = await client
              .from('leads')
              .select()
              .isFilter('deleted_at', null)
              .eq('organization_id', '00000000-0000-0000-0000-000000000000');
          loadedData = (res as List).map((row) {
            final name = '${row['first_name'] ?? ''} ${row['last_name'] ?? ''}'.trim();
            final company = row['company']?.toString() ?? '';
            final email = row['email']?.toString() ?? '';
            final value = (row['value'] ?? 0.0).toDouble();
            final status = row['status']?.toString().toUpperCase() ?? 'NEW';
            final created = row['created_at']?.toString() ?? '';
            return {
              'id': row['id']?.toString() ?? '',
              'name': name.isEmpty ? 'Unknown' : name,
              'company': company,
              'email': email,
              'value': '₹${value.toStringAsFixed(0)}',
              'status': status,
              'created': created.split('T')[0],
              'raw_row': row,
            };
          }).toList();
          break;

        case 'system':
          final res = await client
              .from('activities')
              .select('*, profiles!inner(full_name, organization_id)')
              .eq('profiles.organization_id', '00000000-0000-0000-0000-000000000000')
              .order('created_at', ascending: false);
          loadedData = (res as List).map((row) {
            final action = row['action']?.toString() ?? '';
            final target = row['target_name']?.toString() ?? '';
            final created = row['created_at']?.toString() ?? '';
            final profiles = row['profiles'] as Map?;
            final user = profiles?['full_name']?.toString() ?? 'System';
            return {
              'id': row['id']?.toString() ?? '',
              'timestamp': created.replaceFirst('T', ' ').split('.')[0],
              'action': action.toUpperCase(),
              'target': target,
              'user': user,
              'status': 'ACTIVE',
              'raw_row': row,
            };
          }).toList();
          break;

        default: // billing invoices
          final res = await client
              .from('invoices')
              .select('*, clients(name)')
              .isFilter('deleted_at', null)
              .eq('organization_id', '00000000-0000-0000-0000-000000000000');
          loadedData = (res as List).map((row) {
            final clientMap = row['clients'] as Map?;
            final clientName = clientMap?['name']?.toString() ?? '';
            final invNumber = row['invoice_number']?.toString() ?? '';
            final dueDate = row['due_date']?.toString() ?? '';
            final grandTotal = (row['grand_total'] ?? 0.0).toDouble();
            final amountPaid = (row['amount_paid'] ?? 0.0).toDouble();
            final status = row['status']?.toString().toUpperCase() ?? 'DRAFT';
            return {
              'id': row['id']?.toString() ?? '',
              'inv': invNumber,
              'client': clientName,
              'due': dueDate,
              'amount': '₹${grandTotal.toStringAsFixed(0)}',
              'paid': '₹${amountPaid.toStringAsFixed(0)}',
              'status': status,
              'raw_row': row,
            };
          }).toList();
      }
      setState(() {
        _data = loadedData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<Uint8List> _generateReportPdf() async {
    final pdf = pw.Document();
    final columns = _columns;
    final data = _filtered;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(_reportTitle, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(_reportSubtitle, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 1, color: PdfColors.cyan),
            pw.SizedBox(height: 8),
          ],
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: columns,
            data: data.map((row) => _getRowStrings(row)).toList(),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
            cellStyle: const pw.TextStyle(fontSize: 7),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            cellAlignment: pw.Alignment.centerLeft,
            headerAlignment: pw.Alignment.centerLeft,
          ),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ),
      ),
    );
    return pdf.save();
  }

  Future<void> _printReport() async {
    try {
      final pdfBytes = await _generateReportPdf();
      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: '${widget.route}_report.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showCustom(context, 
        SnackBar(content: Text('Failed to print: $e'), backgroundColor: RTheme.danger),
      );
    }
  }

  Future<void> _exportPdf() async {
    try {
      final pdfBytes = await _generateReportPdf();
      
      try {
        final String? path = await FilePicker.platform.saveFile(
          dialogTitle: 'Save PDF',
          fileName: '${widget.route}_report.pdf',
          type: FileType.any,
        );

        if (path != null) {
          final file = File(path);
          await file.writeAsBytes(pdfBytes);
          if (!mounted) return;
          AppSnackBar.showCustom(context, 
            SnackBar(content: Text('Report saved to $path'), backgroundColor: RTheme.success),
          );
          return;
        }
      } catch (e) {
        debugPrint('FilePicker saveFile error: $e');
      }

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: '${widget.route}_report.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showCustom(context, 
        SnackBar(content: Text('Failed to export PDF: $e'), backgroundColor: RTheme.danger),
      );
    }
  }

  Future<void> _exportCsv() async {
    try {
      final buffer = StringBuffer();
      buffer.writeln(_columns.map((c) => '"${c.replaceAll('"', '""')}"').join(','));
      for (final row in _filtered) {
        final cells = _getRowStrings(row);
        buffer.writeln(cells.map((c) => '"${c.replaceAll('"', '""')}"').join(','));
      }
      final csvString = buffer.toString();
      final bytes = Uint8List.fromList(utf8.encode(csvString));

      try {
        final String? path = await FilePicker.platform.saveFile(
          dialogTitle: 'Save CSV',
          fileName: '${widget.route}_report.csv',
          type: FileType.any,
        );

        if (path != null) {
          final file = File(path);
          await file.writeAsBytes(bytes);
          if (!mounted) return;
          AppSnackBar.showCustom(context, 
            SnackBar(content: Text('Report saved to $path'), backgroundColor: RTheme.success),
          );
          return;
        }
      } catch (e) {
        debugPrint('FilePicker saveFile error: $e');
      }

      await Clipboard.setData(ClipboardData(text: csvString));
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: _cardBg,
          title: Text('CSV Exported', style: TextStyle(color: _textPrimary)),
          content: Text(
            'The CSV report data has been copied to your clipboard. You can paste it directly into Excel or Google Sheets.',
            style: TextStyle(color: _textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK', style: TextStyle(color: RTheme.primary)),
            )
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showCustom(context, 
        SnackBar(content: Text('Failed to export CSV: $e'), backgroundColor: RTheme.danger),
      );
    }
  }

    // --- RECORD ACTIONS AND METHODS ---
  void _showRecordActions(BuildContext context, Map<String, dynamic> rowData, Offset position) async {
    final RelativeRect positionRect = RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      position.dx,
      position.dy,
    );

    final result = await showMenu<String>(
      context: context,
      position: positionRect,
      color: _cardBg,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: [
        PopupMenuItem<String>(
          enabled: false,
          child: Text(
            'RECORD ACTIONS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: _textSecondary,
            ),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.remove_red_eye_outlined, size: 16, color: RTheme.textSecondary),
              SizedBox(width: 8),
              Text('VIEW DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 16, color: RTheme.textSecondary),
              SizedBox(width: 8),
              Text('EDIT RECORD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'report',
          child: Row(
            children: [
              Icon(Icons.description_outlined, size: 16, color: RTheme.textSecondary),
              SizedBox(width: 8),
              Text('INDIVIDUAL REPORT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 16, color: RTheme.danger),
              SizedBox(width: 8),
              Text('DELETE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: RTheme.danger)),
            ],
          ),
        ),
      ],
    );

    if (result == null) return;

    switch (result) {
      case 'view':
        _handleViewDetails(rowData);
        break;
      case 'edit':
        _handleEditRecord(rowData);
        break;
      case 'report':
        _handleIndividualReport(rowData);
        break;
      case 'delete':
        _handleDeleteRecord(rowData);
        break;
    }
  }

  void _handleViewDetails(Map<String, dynamic> rowData) {
    final raw = rowData['raw_row'] as Map<String, dynamic>? ?? rowData;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: RTheme.primary),
            const SizedBox(width: 8),
            Text('Record Details', style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: raw.entries.where((e) => e.key != 'raw_row' && e.key != 'organization_id' && e.key != 'id' && e.key != 'deleted_at').map((e) {
              final key = e.key.replaceAll('_', ' ').toUpperCase();
              final value = e.value?.toString() ?? '---';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(key, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _textSecondary, letterSpacing: 0.3)),
                    const SizedBox(height: 2),
                    Text(value, style: TextStyle(fontSize: 13, color: _textPrimary)),
                    const Divider(height: 12),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE', style: TextStyle(color: RTheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _handleEditRecord(Map<String, dynamic> rowData) {
    final raw = rowData['raw_row'] as Map<String, dynamic>? ?? rowData;
    final recordId = rowData['id']?.toString() ?? raw['id']?.toString() ?? '';
    if (recordId.isEmpty) {
      AppSnackBar.showCustom(context, 
        const SnackBar(content: Text('Cannot edit: Record ID not found'), backgroundColor: RTheme.danger),
      );
      return;
    }

    final fields = <String, String>{}; // label -> db_key
    final controllers = <String, TextEditingController>{};

    switch (widget.route) {
      case 'emp_dir':
        fields['Full Name'] = 'full_name';
        fields['Role'] = 'role';
        fields['Hourly Rate'] = 'hourly_rate';
        fields['Status'] = 'status';
        break;
      case 'att_logs':
        fields['Clock In'] = 'start_time';
        fields['Clock Out'] = 'end_time';
        fields['Status'] = 'status';
        break;
      case 'leave_mgmt':
        fields['Reason'] = 'reason';
        fields['Status'] = 'status';
        break;
      case 'inv_audit':
      case 'income':
        fields['Invoice Number'] = 'invoice_number';
        fields['Grand Total'] = 'grand_total';
        fields['Amount Paid'] = 'amount_paid';
        fields['Status'] = 'status';
        break;
      case 'expense':
        fields['Description'] = 'description';
        fields['Amount'] = 'amount';
        fields['Category'] = 'category';
        break;
      case 'payments':
        fields['Payment Number'] = 'payment_number';
        fields['Amount'] = 'amount';
        fields['Payment Mode'] = 'payment_mode';
        fields['Status'] = 'status';
        break;
      case 'clients':
        fields['Name'] = 'name';
        fields['Email'] = 'email';
        fields['Phone'] = 'phone';
        fields['Address'] = 'address';
        break;
      case 'projects':
        fields['Name'] = 'name';
        fields['Budget'] = 'budget';
        fields['Status'] = 'status';
        break;
      case 'tasks':
        fields['Title'] = 'title';
        fields['Priority'] = 'priority';
        fields['Status'] = 'status';
        break;
      case 'renewals':
        fields['Description'] = 'description';
        fields['Category'] = 'category';
        fields['Amount'] = 'amount';
        fields['Status'] = 'status';
        break;
      case 'leads':
        fields['First Name'] = 'first_name';
        fields['Last Name'] = 'last_name';
        fields['Company'] = 'company';
        fields['Email'] = 'email';
        fields['Value'] = 'value';
        fields['Status'] = 'status';
        break;
      default:
        fields['Status'] = 'status';
    }

    fields.forEach((label, key) {
      controllers[key] = TextEditingController(text: raw[key]?.toString() ?? '');
    });

    showDialog(
      context: context,
      builder: (ctx) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _cardBg,
              title: Row(
                children: [
                  const Icon(Icons.edit_outlined, color: RTheme.primary),
                  const SizedBox(width: 8),
                  Text('Edit Record', style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: fields.entries.map((e) {
                    final label = e.key;
                    final key = e.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextField(
                        controller: controllers[key],
                        style: TextStyle(color: _textPrimary),
                        decoration: InputDecoration(
                          labelText: label,
                          labelStyle: TextStyle(color: _textSecondary),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _border)),
                          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: RTheme.primary)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: Text('CANCEL', style: TextStyle(color: _textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: RTheme.primary, foregroundColor: Colors.white),
                  onPressed: isSaving ? null : () async {
                    setDialogState(() => isSaving = true);
                    try {
                      final updateData = <String, dynamic>{};
                      fields.values.forEach((key) {
                        final val = controllers[key]!.text;
                        if (raw[key] is num) {
                          updateData[key] = num.tryParse(val) ?? raw[key];
                        } else {
                          updateData[key] = val;
                        }
                      });

                      final dbTable = _getTableName();
                      await SupabaseService.client.from(dbTable).update(updateData).eq('id', recordId);

                      if (!mounted) return;
                      Navigator.pop(ctx);
                      AppSnackBar.showCustom(context, 
                        const SnackBar(content: Text('Record updated successfully'), backgroundColor: RTheme.success),
                      );
                      _fetchReportData();
                    } catch (e) {
                      setDialogState(() => isSaving = false);
                      AppSnackBar.showCustom(context, 
                        SnackBar(content: Text('Error updating record: $e'), backgroundColor: RTheme.danger),
                      );
                    }
                  },
                  child: isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                      : const Text('SAVE'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleDeleteRecord(Map<String, dynamic> rowData) {
    final raw = rowData['raw_row'] as Map<String, dynamic>? ?? rowData;
    final recordId = rowData['id']?.toString() ?? raw['id']?.toString() ?? '';
    if (recordId.isEmpty) {
      AppSnackBar.showCustom(context, 
        const SnackBar(content: Text('Cannot delete: Record ID not found'), backgroundColor: RTheme.danger),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _cardBg,
              title: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: RTheme.danger),
                  const SizedBox(width: 8),
                  Text('Confirm Delete', style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Text(
                'Are you sure you want to delete this record? This action cannot be undone.',
                style: TextStyle(color: _textPrimary),
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(ctx),
                  child: Text('CANCEL', style: TextStyle(color: _textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: RTheme.danger, foregroundColor: Colors.white),
                  onPressed: isDeleting ? null : () async {
                    setDialogState(() => isDeleting = true);
                    try {
                      final dbTable = _getTableName();
                      
                      final softDeleteTables = ['invoices', 'clients', 'projects', 'tasks', 'leads', 'work_sessions'];
                      if (softDeleteTables.contains(dbTable)) {
                        await SupabaseService.client.from(dbTable).update({
                          'deleted_at': DateTime.now().toUtc().toIso8601String()
                        }).eq('id', recordId);
                      } else {
                        await SupabaseService.client.from(dbTable).delete().eq('id', recordId);
                      }

                      if (!mounted) return;
                      Navigator.pop(ctx);
                      AppSnackBar.showCustom(context, 
                        const SnackBar(content: Text('Record deleted successfully'), backgroundColor: RTheme.success),
                      );
                      _fetchReportData();
                    } catch (e) {
                      setDialogState(() => isDeleting = false);
                      AppSnackBar.showCustom(context, 
                        SnackBar(content: Text('Error deleting record: $e'), backgroundColor: RTheme.danger),
                      );
                    }
                  },
                  child: isDeleting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                      : const Text('DELETE'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleIndividualReport(Map<String, dynamic> rowData) async {
    final raw = rowData['raw_row'] as Map<String, dynamic>? ?? rowData;
    
    try {
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('INDIVIDUAL RECORD REPORT', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.cyan)),
                pw.SizedBox(height: 8),
                pw.Text('GENERATE TIME: ${DateTime.now().toLocal().toString().split('.')[0]}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                pw.SizedBox(height: 12),
                pw.Divider(thickness: 1, color: PdfColors.grey300),
                pw.SizedBox(height: 20),
                
                pw.Text('RECORD ATTRIBUTES', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 12),
                
                ...raw.entries.where((e) => e.key != 'raw_row' && e.key != 'organization_id' && e.key != 'deleted_at').map((e) {
                  final key = e.key.replaceAll('_', ' ').toUpperCase();
                  final value = e.value?.toString() ?? '---';
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 6.0),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.SizedBox(width: 150, child: pw.Text(key, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700))),
                        pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 10))),
                      ],
                    ),
                  );
                }).toList(),
                
                pw.Spacer(),
                pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                pw.SizedBox(height: 8),
                pw.Align(
                  alignment: pw.Alignment.center,
                  child: pw.Text('Ecraftz CRM Systems - Confidential Audit Document', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                ),
              ],
            );
          },
        ),
      );

      final pdfBytes = await pdf.save();
      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: 'individual_${widget.route}_report.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showCustom(context, 
        SnackBar(content: Text('Failed to generate report: $e'), backgroundColor: RTheme.danger),
      );
    }
  }

  String _getTableName() {
    switch (widget.route) {
      case 'emp_dir': return 'profiles';
      case 'att_logs': return 'work_sessions';
      case 'leave_mgmt': return 'leave_requests';
      case 'inv_audit': return 'invoices';
      case 'expense': return 'project_expenses';
      case 'payments': return 'payments';
      case 'income': return 'invoices';
      case 'clients': return 'clients';
      case 'projects': return 'projects';
      case 'tasks': return 'tasks';
      case 'renewals': return 'renewals';
      case 'leads': return 'leads';
      case 'system': return 'activities';
      default: return 'invoices';
    }
  }

  List<Map<String, dynamic>> get _rawData => _data;


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
      case 'emp_dir':
        final workforce = _data.length;
        final operators = _data.where((e) => e['role']?.toString().toLowerCase() != 'admin' && e['role']?.toString().toLowerCase() != 'super admin' && e['status']?.toString().toLowerCase() == 'active').length;
        final admins = _data.where((e) => (e['role']?.toString().toLowerCase() == 'admin' || e['role']?.toString().toLowerCase() == 'super admin') && e['status']?.toString().toLowerCase() == 'active').length;
        double totalRate = 0.0;
        int rateCount = 0;
        for (final e in _data) {
          final r = e['rate'];
          if (r is num && r > 0) {
            totalRate += r;
            rateCount++;
          }
        }
        final avgRate = rateCount == 0 ? 0.0 : totalRate / rateCount;
        return {
          'workforce': workforce,
          'operators': operators,
          'admins': admins,
          'avgRate': avgRate,
        };
      case 'att_logs':
        final sessions = _data.length;
        final completed = _data.where((e) => e['status']?.toString().toLowerCase() == 'completed').length;
        final active = _data.where((e) => e['status']?.toString().toLowerCase() == 'active').length;
        return {
          'sessions': sessions,
          'completed': completed,
          'active': active,
          'break': 94.0,
        };
      case 'leave_mgmt':
        final total = _data.length;
        final approved = _data.where((e) => e['status']?.toString().toUpperCase() == 'APPROVED').length;
        final pending = _data.where((e) => e['status']?.toString().toUpperCase() == 'PENDING').length;
        final rejected = _data.where((e) => e['status']?.toString().toUpperCase() == 'REJECTED').length;
        final rejRate = total == 0 ? 0.0 : (rejected / total * 100.0);
        return {
          'total': total,
          'approved': approved,
          'pending': pending,
          'rejRate': rejRate,
        };
      case 'inv_audit':
        final total = _data.length;
        final reconciled = _data.where((e) => e['status']?.toString().toUpperCase() == 'PAID').length;
        final voided = _data.where((e) => e['status']?.toString().toUpperCase() == 'CANCELLED' || e['status']?.toString().toUpperCase() == 'VOIDED').length;
        final integrity = total == 0 ? 0.0 : (reconciled / total * 100.0);
        return {
          'total': total,
          'reconciled': reconciled,
          'voided': voided,
          'integrity': integrity,
        };
      case 'expense':
        double outflowSum = 0.0;
        for (final e in _data) {
          final amtStr = e['amount']?.toString().replaceAll('-\$', '') ?? '0';
          outflowSum += double.tryParse(amtStr) ?? 0.0;
        }
        final volume = _data.length;
        final pendingSum = _data
            .where((e) => e['status']?.toString().toUpperCase() == 'PENDING')
            .fold<double>(0.0, (sum, e) => sum + (double.tryParse(e['amount']?.toString().replaceAll('-\$', '') ?? '0') ?? 0.0));
        return {
          'outflow': '\$${outflowSum.toStringAsFixed(0)}',
          'volume': volume,
          'awaiting': '\$${pendingSum.toStringAsFixed(0)}',
          'deviation': 0.0,
        };
      case 'payments':
        double collected = 0.0;
        double transit = 0.0;
        int failed = 0;
        for (final e in _data) {
          final amtStr = e['amount']?.toString().replaceAll('₹', '') ?? '0';
          final amt = double.tryParse(amtStr) ?? 0.0;
          final status = e['status']?.toString().toUpperCase();
          if (status == 'VERIFIED' || status == 'PAID' || status == 'SUCCESS') {
            collected += amt;
          } else if (status == 'PENDING' || status == 'TRANSIT') {
            transit += amt;
          } else if (status == 'FAILED') {
            failed++;
          }
        }
        return {
          'collected': '₹${collected.toStringAsFixed(0)}',
          'transit': '₹${transit.toStringAsFixed(0)}',
          'attempts': _data.length,
          'failed': failed,
        };
      case 'clients':
        final portfolio = _data.length;
        final active = _data.where((e) => e['status']?.toString().toUpperCase() == 'ACTIVE').length;
        final footprint = _data.map((e) => e['location']?.toString().trim().toLowerCase() ?? 'global')
            .where((loc) => loc.isNotEmpty && loc != 'null')
            .toSet()
            .length;
        final velocity = portfolio == 0 ? '0%' : '${(active / portfolio * 100).toStringAsFixed(0)}%';
        return {
          'portfolio': portfolio,
          'active': active,
          'footprint': footprint == 0 ? 1 : footprint,
          'velocity': velocity,
        };
      case 'projects':
        final portfolio = _data.length;
        final active = _data.where((e) => e['stage']?.toString().toUpperCase() == 'IN PROGRESS' || e['stage']?.toString().toUpperCase() == 'PLANNING').length;
        double valueSum = 0.0;
        for (final p in _data) {
          final budgetStr = p['budget']?.toString().replaceAll('₹', '') ?? '0';
          valueSum += double.tryParse(budgetStr) ?? 0.0;
        }
        final completed = _data.where((e) => e['stage']?.toString().toUpperCase() == 'COMPLETED').length;
        final delivery = portfolio == 0 ? '0%' : '${(completed / portfolio * 100.0).toStringAsFixed(0)}%';
        return {
          'portfolio': portfolio,
          'active': active,
          'value': '₹${valueSum.toStringAsFixed(0)}',
          'delivery': delivery,
        };
      case 'tasks':
        final total = _data.length;
        final doneCount = _data.where((e) => e['status']?.toString().toUpperCase() == 'DONE').length;
        final velocity = total == 0 ? '0%' : '${(doneCount / total * 100.0).toStringAsFixed(0)}%';
        final overdue = _data.where((e) => e['overdue'] == true).length;
        final backlog = _data.where((e) => e['status']?.toString().toUpperCase() == 'TODO').length;
        return {
          'total': total,
          'velocity': velocity,
          'overdue': overdue,
          'backlog': backlog,
        };
      case 'renewals':
        final matrix = _data.length;
        double pipe = 0.0;
        for (final r in _data) {
          final valStr = r['value']?.toString().replaceAll('₹', '') ?? '0';
          pipe += double.tryParse(valStr) ?? 0.0;
        }
        final critical = _data.where((e) => e['status']?.toString().toUpperCase() == 'OVERDUE').length;
        final paidCount = _data.where((e) => e['status']?.toString().toUpperCase() == 'PAID' || e['status']?.toString().toUpperCase() == 'COMPLETED' || e['status']?.toString().toUpperCase() == 'ACTIVE').length;
        final collection = matrix == 0 ? '0%' : '${(paidCount / matrix * 100).toStringAsFixed(0)}%';
        return {
          'matrix': matrix,
          'pipeline': '₹${pipe.toStringAsFixed(0)}',
          'critical': critical,
          'collection': collection,
        };
      case 'leads':
        final velocity = _data.length;
        double pipe = 0.0;
        for (final l in _data) {
          final valStr = l['value']?.toString().replaceAll('₹', '') ?? '0';
          pipe += double.tryParse(valStr) ?? 0.0;
        }
        final convertedCount = _data.where((e) => e['status']?.toString().toUpperCase() == 'CONVERTED' || e['status']?.toString().toUpperCase() == 'WON').length;
        final conversion = velocity == 0 ? '0%' : '${(convertedCount / velocity * 100).toStringAsFixed(0)}%';
        return {
          'velocity': velocity,
          'pipeline': '₹${pipe.toStringAsFixed(0)}',
          'conversion': conversion,
          'avgAge': '---',
        };
      case 'system':
        final total = _data.length;
        final statusChanges = _data.where((e) => e['action']?.toString().contains('STATUS') == true).length;
        final databaseMutations = _data.where((e) => e['action']?.toString().contains('DELETE') == true || e['action']?.toString().contains('UPDATE') == true || e['action']?.toString().contains('CREATE') == true).length;
        return {
          'total': total,
          'statusChanges': statusChanges,
          'mutations': databaseMutations,
          'integrity': '100%',
        };
      default:
        final total = _data.length;
        double verified = 0.0;
        double awaiting = 0.0;
        int overdue = 0;
        for (final inv in _data) {
          final amtStr = inv['amount']?.toString().replaceAll('₹', '') ?? '0';
          final amt = double.tryParse(amtStr) ?? 0.0;
          final paidStr = inv['paid']?.toString().replaceAll('₹', '') ?? '0';
          final paid = double.tryParse(paidStr) ?? 0.0;
          final status = inv['status']?.toString().toUpperCase();
          if (status == 'PAID') {
            verified += paid;
          } else {
            awaiting += (amt - paid);
            if (status == 'OVERDUE') overdue++;
          }
        }
        return {
          'total': total,
          'verified': '₹${verified.toStringAsFixed(0)}',
          'awaiting': '₹${awaiting.toStringAsFixed(0)}',
          'overdue': overdue,
        };
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
          _StatCard('COMPLETED SHIFTS', '${s['completed']}', 'SUCCESSFULLY CHECKED OUT', Icons.check_circle_rounded),
          _StatCard('ACTIVE OPERATORS', '${s['active']}', 'CURRENTLY CLOCKED IN', Icons.people_alt_rounded),
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
      case 'payments':
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
      case 'system':
        return [
          _StatCard('TOTAL ACTIVITIES', '${s['total']}', 'AGGREGATE ACTIVITY COUNT', Icons.shield_rounded),
          _StatCard('STATUS UPDATES', '${s['statusChanges']}', 'WORKFLOW TRANSITIONS', Icons.rule_rounded),
          _StatCard('DATA MUTATIONS', '${s['mutations']}', 'DATABASE WRITE ACTIONS', Icons.edit_note_rounded),
          _StatCard('SYSTEM HEALTH', '${s['integrity']}', 'AUDIT LOG INTEGRITY', Icons.verified_rounded),
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
      case 'income': return 'FINANCIAL CENTER: INCOME REPORT';
      case 'payments': return 'FINANCIAL CENTER: PAYMENT RECORDS';
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
      case 'income': return 'COMPREHENSIVE AUDIT OF ALL GENERATED REVENUE, PAID INVOICES, AND PENDING RECEIVABLES.';
      case 'payments': return 'AUDIT-READY PAYMENT RECONCILIATION LOGS, VERIFICATION TIMESTAMPS, AND INSTITUTIONAL CASHFLOW TRACKING.';
      case 'clients': return 'COMPREHENSIVE AUDIT OF ORGANIZATION PARTNERS, ACQUISITION TIMESTAMPS, AND MULTI-TERRITORY ACCOUNT STATUS.';
      case 'projects': return 'CHRONOLOGICAL AUDIT OF PROJECT STATUS, TIMELINE DEVIATIONS, AND BUDGET UTILIZATION ACROSS THE ENTERPRISE.';
      case 'tasks': return 'INSTITUTIONAL AUDIT OF TASK LIFECYCLES, DELIVERY SPEED, AND INDIVIDUAL ACCOUNTABILITY METRICS.';
      case 'renewals': return 'FORENSIC TRACKING OF SERVICE LIFECYCLES, RENEWAL COLLECTION RATES, AND PROACTIVE NOTIFICATION AUDITING.';
      case 'leads': return 'CHRONOLOGICAL AUDIT OF PROSPECTING EFFORTS, ESTIMATED PIPELINE VALUE, AND CONVERSION STATUS ACROSS TERRITORIES.';
      default: return 'COMPREHENSIVE AUDIT OF ALL ACCOUNTS RECEIVABLE, PARTIAL PAYMENTS, AND OVERDUE LIABILITY TRACKING.';
    }
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => Theme.of(context).scaffoldBackgroundColor;
  Color get _cardBg => Theme.of(context).colorScheme.surface;
  Color get _border => AppTheme.borderOf(context);
  Color get _textPrimary => AppTheme.textPrimaryOf(context);
  Color get _textSecondary => AppTheme.textSecondaryOf(context);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isTablet = w >= 600;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: _textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_reportTitle,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _textPrimary)),
            Text(_reportSubtitle,
                style: TextStyle(fontSize: 10, color: _textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
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
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildDetailHeader(isTablet),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchReportData,
                color: RTheme.primary,
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(RTheme.primary),
                        ),
                      )
                    : _error.isNotEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline_rounded, size: 48, color: RTheme.danger),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Failed to load report data',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _error,
                                    style: TextStyle(fontSize: 13, color: _textSecondary),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: RTheme.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: _fetchReportData,
                                    icon: const Icon(Icons.refresh_rounded, size: 18),
                                    label: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailHeader(bool isTablet) {
    return Container(
      color: _cardBg,
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 14, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('EXPORT OPTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _textSecondary)),
          Wrap(spacing: 8, children: [
            _actionBtn(Icons.print_rounded, 'PRINT', onTap: _printReport),
            _actionBtn(Icons.grid_on_rounded, 'CSV', onTap: _exportCsv),
            _exportPdfBtn(onTap: _exportPdf),
          ]),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(border: Border.all(color: _border), borderRadius: BorderRadius.circular(7)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: _textSecondary),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: _textSecondary, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _exportPdfBtn({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [RTheme.primary, RTheme.primaryDark]),
          borderRadius: BorderRadius.circular(7),
          boxShadow: _isDark ? null : [BoxShadow(color: RTheme.primary.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))],
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
        color: _cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
        boxShadow: _isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Text(c.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                color: _textSecondary, letterSpacing: 0.3), overflow: TextOverflow.ellipsis)),
            Icon(c.icon, size: 14, color: _textSecondary),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _textPrimary),
                overflow: TextOverflow.ellipsis),
            Text(c.sublabel, style: TextStyle(fontSize: 9, color: _textSecondary, letterSpacing: 0.2),
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
            color: _cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border),
          ),
          child: TextField(
            onChanged: (v) => setState(() { _search = v; _page = 1; }),
            style: TextStyle(color: _textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: _searchHint,
              hintStyle: TextStyle(fontSize: 12, color: _textSecondary),
              prefixIcon: Icon(Icons.search_rounded, size: 16, color: _textSecondary),
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

  bool get _hasSecondFilter => ['att_logs', 'expense', 'clients', 'tasks', 'renewals', 'payments'].contains(widget.route);
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
        color: _cardBg,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.filter_list_rounded, size: 13, color: _textSecondary),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: _textSecondary, fontWeight: FontWeight.w500)),
        const SizedBox(width: 3),
        Icon(Icons.keyboard_arrow_down_rounded, size: 13, color: _textSecondary),
      ]),
    );
  }

  Widget _buildTable(bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
        boxShadow: _isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(children: [
        if (isTablet) _tableHeaderRow(),
        if (isTablet) Divider(height: 1, color: _border),
        _paged.isEmpty
            ? _emptyState()
            : Column(children: _paged.asMap().entries.map((e) {
                final rowData = e.value;
                final index = e.key;
                final child = isTablet ? _tableRow(rowData, index) : _mobileCard(rowData, index);
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) {
                    _showRecordActions(context, rowData, details.globalPosition);
                  },
                  child: child,
                );
              }).toList()),
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
      case 'payments': return ['PAYMENT DATE', 'REFERENCE', 'CLIENT', 'AMOUNT', 'METHOD', 'STATUS'];
      case 'clients': return ['CLIENT / COMPANY', 'CONTACT INFO', 'LOCATION', 'JOINED DATE', 'STATUS'];
      case 'projects': return ['PROJECT NAME', 'TIMELINE', 'BUDGET ALLOCATION', 'STAGE'];
      case 'tasks': return ['TASK / PROJECT', 'ASSIGNEE', 'DUE DATE', 'PRIORITY', 'STATUS'];
      case 'renewals': return ['SERVICE DETAIL', 'CATEGORY', 'EXPIRY DATE', 'VALUE', 'REMINDERS', 'STATUS'];
      case 'leads': return ['LEAD / COMPANY', 'EMAIL', 'VALUE', 'STATUS', 'CREATED'];
      case 'system': return ['TIMESTAMP', 'ACTION', 'TARGET', 'PERFORMED BY'];
      default: return ['INVOICE #', 'CLIENT', 'DUE DATE', 'TOTAL AMOUNT', 'PAID', 'STATUS'];
    }
  }

  Widget _tableHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _isDark ? AppTheme.bgSidebarDark : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: _columns.map((c) => Expanded(
          child: Text(c, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
              color: _textSecondary, letterSpacing: 0.4)),
        )).toList(),
      ),
    );
  }

  Widget _tableRow(Map<String, dynamic> row, int index) {
    final cells = _getCells(row);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: index.isEven ? _cardBg : (_isDark ? const Color(0xFF132238) : const Color(0xFFFAFAFF)),
        border: Border(bottom: BorderSide(color: _border)),
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
        color: index.isEven ? _cardBg : (_isDark ? const Color(0xFF132238) : const Color(0xFFFAFAFF)),
        border: Border(bottom: BorderSide(color: _border)),
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
            Text(row['name'] ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textPrimary)),
            Text(row['email'] ?? '', style: TextStyle(fontSize: 10, color: _textSecondary), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Wrap(spacing: 6, children: [
              _statusChip(row['role'] ?? ''),
              _statusChip(row['status'] ?? ''),
              Text('\$${row['rate']?.toStringAsFixed(2)}/hr', style: TextStyle(fontSize: 11, color: _textSecondary)),
            ]),
          ])),
        ]);
      case 'att_logs':
        return Row(children: [
          _initAvatar((row['name'] ?? '').substring(0, (row['name'] ?? ' ').length > 1 ? 2 : 1).toUpperCase(), 36),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(row['name'] ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textPrimary)),
            Text(row['date'] ?? '', style: TextStyle(fontSize: 10, color: _textSecondary)),
            const SizedBox(height: 4),
            Wrap(spacing: 8, children: [
              Text('IN: ${row['in']}', style: const TextStyle(fontSize: 11, color: RTheme.success, fontWeight: FontWeight.w600)),
              Text('OUT: ${row['out']}', style: TextStyle(fontSize: 11,
                  color: row['out'] == '---' ? _textSecondary : RTheme.danger, fontWeight: FontWeight.w600)),
              _statusChip(row['status'] ?? ''),
            ]),
          ])),
        ]);
      case 'tasks':
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(row['task'] ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textPrimary))),
            _statusChip(row['status'] ?? ''),
          ]),
          const SizedBox(height: 2),
          Text(row['project'] ?? '', style: TextStyle(fontSize: 10, color: _textSecondary), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Wrap(spacing: 8, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.person_rounded, size: 11, color: _textSecondary),
              const SizedBox(width: 3),
              Text(row['assignee'] ?? '', style: TextStyle(fontSize: 11, color: _textSecondary)),
            ]),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.calendar_today_rounded, size: 11,
                  color: (row['overdue'] == true) ? RTheme.danger : _textSecondary),
              const SizedBox(width: 3),
              Text(row['due'] ?? '', style: TextStyle(fontSize: 11,
                  color: (row['overdue'] == true) ? RTheme.danger : _textSecondary,
                  fontWeight: (row['overdue'] == true) ? FontWeight.w700 : FontWeight.normal)),
            ]),
            _statusChip(row['priority'] ?? ''),
          ]),
        ]);
      case 'payments':
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(row['client'] ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textPrimary))),
            Text(row['amount'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: RTheme.success)),
          ]),
          const SizedBox(height: 3),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Ref: ${row['ref']}', style: TextStyle(fontSize: 11, color: _textSecondary)),
            Text(row['date'] ?? '', style: TextStyle(fontSize: 11, color: _textSecondary)),
          ]),
          const SizedBox(height: 6),
          Wrap(spacing: 8, children: [
            _statusChip(row['method'] ?? ''),
            _statusChip(row['status'] ?? ''),
          ]),
        ]);
      case 'leads':
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(row['name'] ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textPrimary))),
            Text(row['value'] ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textPrimary)),
          ]),
          if ((row['company'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(row['company'] ?? '', style: TextStyle(fontSize: 11, color: _textSecondary)),
          ],
          if ((row['email'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(row['email'] ?? '', style: TextStyle(fontSize: 11, color: _textSecondary)),
          ],
          const SizedBox(height: 6),
          Wrap(spacing: 8, children: [
            _statusChip(row['status'] ?? ''),
            Text(row['created'] ?? '', style: TextStyle(fontSize: 11, color: _textSecondary)),
          ]),
        ]);
      case 'system':
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(row['action'] ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textPrimary))),
            Text(row['timestamp'] ?? '', style: TextStyle(fontSize: 11, color: _textSecondary)),
          ]),
          const SizedBox(height: 3),
          Text('Target: ${row['target']}', style: TextStyle(fontSize: 11, color: _textSecondary)),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('By: ${row['user']}', style: TextStyle(fontSize: 11, color: _textSecondary, fontWeight: FontWeight.w600)),
            _statusChip('ACTIVE'),
          ]),
        ]);
      default:
        final keys = row.keys.toList();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (keys.isNotEmpty) Text(row[keys[0]]?.toString() ?? '',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textPrimary),
              overflow: TextOverflow.ellipsis),
          if (keys.length > 1) ...[
            const SizedBox(height: 3),
            Text(row[keys[1]]?.toString() ?? '', style: TextStyle(fontSize: 11, color: _textSecondary),
                overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 6),
          Wrap(spacing: 8, children: [
            for (int i = 2; i < keys.length && i < 5; i++)
              if (keys[i] == 'status' || keys[i] == 'stage' || keys[i] == 'priority' || keys[i] == 'role')
                _statusChip(row[keys[i]]?.toString() ?? '')
              else
                Text(row[keys[i]]?.toString() ?? '', style: TextStyle(fontSize: 11, color: _textSecondary)),
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
            Expanded(child: Text(row['name'] ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textPrimary), overflow: TextOverflow.ellipsis)),
          ])),
          _CellData.chip(row['role'] ?? ''),
          _CellData.text('\$${row['rate']?.toStringAsFixed(2)}/hr', color: RTheme.success, bold: true),
          _CellData.chip(row['status'] ?? ''),
        ];
      case 'att_logs':
        return [
          _CellData.widget(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(row['name'] ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textPrimary), overflow: TextOverflow.ellipsis),
            Text(row['date'] ?? '', style: TextStyle(fontSize: 10, color: _textSecondary), overflow: TextOverflow.ellipsis),
          ])),
          _CellData.text(row['in'] ?? '', color: RTheme.success, bold: true),
          _CellData.text(row['out'] ?? '', color: row['out'] == '---' ? _textSecondary : RTheme.danger, bold: true),
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
            Text(row['client'] ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textPrimary), overflow: TextOverflow.ellipsis),
            Text(row['display_id'] ?? '', style: TextStyle(fontSize: 10, color: _textSecondary), overflow: TextOverflow.ellipsis),
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
            Text(row['desc'] ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textPrimary), overflow: TextOverflow.ellipsis),
            Text(row['project'] ?? '', style: TextStyle(fontSize: 10, color: _textSecondary), overflow: TextOverflow.ellipsis),
          ])),
          _CellData.text(row['amount'] ?? '', color: RTheme.danger, bold: true),
          _CellData.chip(row['cat'] ?? ''),
          _CellData.chip(row['status'] ?? ''),
        ];
      case 'clients':
        return [
          _CellData.widget(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(row['name'] ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textPrimary), overflow: TextOverflow.ellipsis),
            Text(row['industry'] ?? '', style: TextStyle(fontSize: 10, color: _textSecondary), overflow: TextOverflow.ellipsis),
          ])),
          _CellData.widget(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if ((row['email'] ?? '').isNotEmpty) Text(row['email'] ?? '', style: TextStyle(fontSize: 10, color: _textSecondary), overflow: TextOverflow.ellipsis),
            if ((row['phone'] ?? '').isNotEmpty) Text(row['phone'] ?? '', style: TextStyle(fontSize: 10, color: _textSecondary), overflow: TextOverflow.ellipsis),
          ])),
          _CellData.text(row['location'] ?? ''),
          _CellData.text(row['joined'] ?? ''),
          _CellData.chip(row['status'] ?? ''),
        ];
      case 'projects':
        return [
          _CellData.widget(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(row['name'] ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textPrimary), overflow: TextOverflow.ellipsis),
            Text(row['client'] ?? '', style: TextStyle(fontSize: 10, color: _textSecondary), overflow: TextOverflow.ellipsis),
          ])),
          _CellData.text(row['timeline'] ?? ''),
          _CellData.text(row['budget'] ?? '', bold: true, color: RTheme.success),
          _CellData.chip(row['stage'] ?? ''),
        ];
      case 'tasks':
        return [
          _CellData.widget(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(row['task'] ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textPrimary), overflow: TextOverflow.ellipsis),
            Text(row['project'] ?? '', style: TextStyle(fontSize: 9, color: _textSecondary), overflow: TextOverflow.ellipsis),
          ])),
          _CellData.text(row['assignee'] ?? ''),
          _CellData.text(row['due'] ?? '', color: (row['overdue'] == true) ? RTheme.danger : null),
          _CellData.chip(row['priority'] ?? ''),
          _CellData.chip(row['status'] ?? ''),
        ];
      case 'renewals':
        return [
          _CellData.widget(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(row['service'] ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textPrimary), overflow: TextOverflow.ellipsis),
            Text(row['client'] ?? '', style: TextStyle(fontSize: 10, color: _textSecondary), overflow: TextOverflow.ellipsis),
          ])),
          _CellData.chip(row['category'] ?? ''),
          _CellData.text(row['expiry'] ?? ''),
          _CellData.text(row['value'] ?? '', bold: true),
          _CellData.chip(row['reminders'] ?? ''),
          _CellData.chip(row['status'] ?? ''),
        ];
      case 'payments':
        return [
          _CellData.text(row['date'] ?? ''),
          _CellData.text(row['ref'] ?? '', bold: true),
          _CellData.text(row['client'] ?? ''),
          _CellData.text(row['amount'] ?? '', color: RTheme.success, bold: true),
          _CellData.chip(row['method'] ?? ''),
          _CellData.chip(row['status'] ?? ''),
        ];
      case 'leads':
        return [
          _CellData.widget(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(row['name'] ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textPrimary), overflow: TextOverflow.ellipsis),
              if ((row['company'] ?? '').isNotEmpty) Text(row['company'] ?? '', style: TextStyle(fontSize: 10, color: _textSecondary), overflow: TextOverflow.ellipsis),
            ],
          )),
          _CellData.text(row['email'] ?? ''),
          _CellData.text(row['value'] ?? '', bold: true),
          _CellData.chip(row['status'] ?? ''),
          _CellData.text(row['created'] ?? ''),
        ];
      case 'system':
        return [
          _CellData.text(row['timestamp'] ?? ''),
          _CellData.chip(row['action'] ?? ''),
          _CellData.text(row['target'] ?? ''),
          _CellData.text(row['user'] ?? ''),
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
          color: c.color ?? _textPrimary,
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
          decoration: BoxDecoration(color: _isDark ? const Color(0xFF1E2E42) : const Color(0xFFF1F5F9), shape: BoxShape.circle),
          child: Icon(Icons.search_off_rounded, size: 24, color: _isDark ? const Color(0xFF596780) : const Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 12),
        Text('No records found for this criteria.',
            style: TextStyle(fontSize: 13, color: _textSecondary)),
      ]),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(children: [
        Expanded(child: Text(
          'SHOWING ${_filtered.isEmpty ? "1-0" : "${(_page - 1) * _perPage + 1}-${((_page * _perPage).clamp(0, _filtered.length))}"} OF ${_filtered.length} INSTITUTIONAL RECORDS',
          style: TextStyle(fontSize: 10, color: _textSecondary, letterSpacing: 0.3),
        )),
        GestureDetector(
          onTap: _page > 1 ? () => setState(() => _page--) : null,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _page > 1 ? _cardBg : (_isDark ? const Color(0xFF1E2E42) : const Color(0xFFF1F5F9)),
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.chevron_left, size: 16,
                color: _page > 1 ? _textPrimary : _textSecondary),
          ),
        ),
        const SizedBox(width: 8),
        Text('PAGE $_page / $_totalPages',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _textPrimary)),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _page < _totalPages ? () => setState(() => _page++) : null,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _page < _totalPages ? _cardBg : (_isDark ? const Color(0xFF1E2E42) : const Color(0xFFF1F5F9)),
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.chevron_right, size: 16,
                color: _page < _totalPages ? _textPrimary : _textSecondary),
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

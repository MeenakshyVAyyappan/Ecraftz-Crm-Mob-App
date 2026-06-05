// asset_renewals_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/app_drawer.dart';
import '../../theme/app_theme.dart';
import '../../blocs/theme/theme_bloc.dart';
import '../../services/supabase_service.dart';

// ─── DATA MODELS ─────────────────────────────────────────────────────────────

enum RenewalStatus { pending, paid, overdue, cancelled }

extension RenewalStatusExt on RenewalStatus {
  String get label {
    switch (this) {
      case RenewalStatus.pending: return 'PENDING';
      case RenewalStatus.paid: return 'PAID';
      case RenewalStatus.overdue: return 'OVERDUE';
      case RenewalStatus.cancelled: return 'CANCELLED';
    }
  }

  Color get color {
    switch (this) {
      case RenewalStatus.pending: return const Color(0xFFF59E0B);
      case RenewalStatus.paid: return const Color(0xFF10B981);
      case RenewalStatus.overdue: return const Color(0xFFEF4444);
      case RenewalStatus.cancelled: return const Color(0xFF6B7280);
    }
  }
}

enum ServiceCategory { hosting, domain, hostingDomain, email, ssl, maintenance, other }

extension ServiceCategoryExt on ServiceCategory {
  String get label {
    switch (this) {
      case ServiceCategory.hosting: return 'HOSTING';
      case ServiceCategory.domain: return 'DOMAIN';
      case ServiceCategory.hostingDomain: return 'HOSTING & DOMAIN';
      case ServiceCategory.email: return 'ENTERPRISE EMAIL';
      case ServiceCategory.ssl: return 'SSL CERTIFICATE';
      case ServiceCategory.maintenance: return 'MAINTENANCE';
      case ServiceCategory.other: return 'OTHER';
    }
  }

  IconData get icon {
    switch (this) {
      case ServiceCategory.hosting: return Icons.dns_outlined;
      case ServiceCategory.domain: return Icons.language_outlined;
      case ServiceCategory.hostingDomain: return Icons.shield_outlined;
      case ServiceCategory.email: return Icons.email_outlined;
      case ServiceCategory.ssl: return Icons.lock_outline_rounded;
      case ServiceCategory.maintenance: return Icons.build_outlined;
      case ServiceCategory.other: return Icons.settings_outlined;
    }
  }

  Color get color {
    switch (this) {
      case ServiceCategory.hosting: return const Color(0xFF3B82F6);
      case ServiceCategory.domain: return const Color(0xFF8B5CF6);
      case ServiceCategory.hostingDomain: return const Color(0xFF00BCD4);
      case ServiceCategory.email: return const Color(0xFFF59E0B);
      case ServiceCategory.ssl: return const Color(0xFF10B981);
      case ServiceCategory.maintenance: return const Color(0xFFF97316);
      case ServiceCategory.other: return const Color(0xFF6B7280);
    }
  }
}

class AssetRenewal {
  final String id;
  String serviceName;
  String clientName;
  String clientEntity;
  ServiceCategory category;
  DateTime expiryDate;
  double amount;
  RenewalStatus status;
  String description;
  String associatedProject;

  AssetRenewal({
    required this.id,
    required this.serviceName,
    required this.clientName,
    required this.clientEntity,
    required this.category,
    required this.expiryDate,
    required this.amount,
    required this.status,
    this.description = '',
    this.associatedProject = 'Independent Service',
  });

  factory AssetRenewal.fromJson(Map<String, dynamic> json) {
    final clientsMap = json['clients'];
    final cName = (clientsMap is Map && clientsMap['name'] != null)
        ? clientsMap['name'].toString()
        : '';
        
    final projectsMap = json['projects'];
    final pName = (projectsMap is Map && projectsMap['name'] != null)
        ? projectsMap['name'].toString()
        : '';

    return AssetRenewal(
      id: json['id']?.toString() ?? '',
      serviceName: json['service_name'] ?? '',
      clientName: cName.isNotEmpty ? cName : (json['client_id']?.toString() ?? ''),
      clientEntity: json['client_entity'] ?? '',
      category: _categoryFromString(json['category']),
      expiryDate: json['expiry_date'] != null 
          ? DateTime.tryParse(json['expiry_date']) ?? DateTime.now()
          : DateTime.now(),
      amount: (json['amount'] ?? 0).toDouble(),
      status: _statusFromString(json['status']),
      description: json['description'] ?? '',
      associatedProject: pName.isNotEmpty ? pName : (json['project_id']?.toString() ?? 'Independent Service'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'service_name': serviceName,
      'client_name': clientName,
      'client_entity': clientEntity,
      'category': category.name,
      'expiry_date': expiryDate.toIso8601String(),
      'amount': amount,
      'status': status.name,
      'description': description,
      'associated_project': associatedProject,
    };
  }

  static ServiceCategory _categoryFromString(String? val) {
    if (val == null) return ServiceCategory.hosting;
    return ServiceCategory.values.firstWhere((e) => e.name == val, orElse: () => ServiceCategory.hosting);
  }

  static RenewalStatus _statusFromString(String? val) {
    if (val == null) return RenewalStatus.pending;
    return RenewalStatus.values.firstWhere((e) => e.name == val, orElse: () => RenewalStatus.pending);
  }

  bool get isExpiringSoon =>
      expiryDate.difference(DateTime.now()).inDays <= 30 &&
      expiryDate.isAfter(DateTime.now());

  bool get isExpired => expiryDate.isBefore(DateTime.now());

  String get expiryLabel {
    final diff = expiryDate.difference(DateTime.now()).inDays;
    if (isExpired) return 'Expired';
    if (diff == 0) return 'Expires today';
    if (diff == 1) return 'Expires tomorrow';
    return 'Expires in $diff days';
  }

  String get formattedExpiry {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[expiryDate.month-1]} ${expiryDate.day}, ${expiryDate.year}';
  }
}

// ─── MAIN PAGE ────────────────────────────────────────────────────────────────

class AssetRenewalsPage extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;  
  const AssetRenewalsPage({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    });


  @override
  State<AssetRenewalsPage> createState() => _AssetRenewalsPageState();
}

class _AssetRenewalsPageState extends State<AssetRenewalsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchCtrl = TextEditingController();
  String _search = '';
  
  List<AssetRenewal> _renewals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRenewals();
  }

  Future<void> _fetchRenewals() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // Fetch renewals, joining clients and projects to get their names
      final data = await SupabaseService.client
          .from('renewals')
          .select('*, clients(name), projects(name)')
          .order('expiry_date', ascending: true);
      if (!mounted) return;
      setState(() {
        _renewals = (data as List).map((e) => AssetRenewal.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _snack('Failed to load renewals: $e', Colors.red);
    }
  }

  List<AssetRenewal> get _filtered {
    if (_search.isEmpty) return _renewals;
    final q = _search.toLowerCase();
    return _renewals.where((r) =>
        r.serviceName.toLowerCase().contains(q) ||
        r.clientName.toLowerCase().contains(q) ||
        r.clientEntity.toLowerCase().contains(q) ||
        r.category.label.toLowerCase().contains(q)).toList();
  }

  int get _totalRenewals => _renewals.length;
  int get _criticalWindow => _renewals.where((r) => r.isExpiringSoon).length;
  double get _revenueLocked => _renewals.fold(0, (s, r) => s + r.amount);

  void _showScheduleDialog({AssetRenewal? existing}) {
    showDialog(
      context: context,
      builder: (_) => _ScheduleRenewalDialog(
        existing: existing,
        clients: _renewals.map((r) => r.clientName).toSet().toList(),
        onSave: (r) async {
          setState(() => _isLoading = true);
          try {
            if (existing != null) {
              await SupabaseService.client.from('renewals').update(r.toJson()).eq('id', existing.id);
            } else {
              await SupabaseService.client.from('renewals').insert(r.toJson());
            }
            await _fetchRenewals();
            if (mounted) _snack(existing != null ? 'Renewal updated!' : 'Renewal scheduled!', const Color(0xFF10B981));
          } catch (e) {
            if (mounted) {
              setState(() => _isLoading = false);
              _snack('Error saving renewal: $e', Colors.red);
            }
          }
        },
      ),
    );
  }

  Future<void> _markAsPaid(AssetRenewal r) async {
    setState(() => _isLoading = true);
    try {
      await SupabaseService.client.from('renewals').update({'status': 'paid'}).eq('id', r.id);
      await _fetchRenewals();
      if (mounted) _snack('Marked as PAID', const Color(0xFF10B981));
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _snack('Failed to update status: $e', Colors.red);
      }
    }
  }

  void _sendReminder(AssetRenewal r) =>
      _snack('Reminder sent for ${r.serviceName}', const Color(0xFF3B82F6));

  void _deleteRenewal(AssetRenewal r) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Renewal'),
        content: Text('Delete "${r.serviceName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await SupabaseService.client.from('renewals').delete().eq('id', r.id);
                await _fetchRenewals();
                if (mounted) _snack('Renewal deleted', Colors.red);
              } catch (e) {
                if (mounted) {
                  setState(() => _isLoading = false);
                  _snack('Failed to delete: $e', Colors.red);
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, duration: const Duration(seconds: 2)),
    );
  }

  // Quick-create FAB menu
  void _showQuickCreate() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuickCreateSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 650;
    final filtered = _filtered;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickCreate,
        backgroundColor: const Color(0xFF00BCD4),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: isWide
            ? null
            : IconButton(
                icon: Icon(Icons.menu_rounded, color: isDark ? Colors.white : const Color(0xFF374151)),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Asset Renewals',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryOf(context))),
            Text('Track and manage recurring service renewals.',
                style: TextStyle(fontSize: 10, color: AppTheme.textSecondaryOf(context))),
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
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.borderOf(context)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Description
          Text(
            'Track and manage recurring service renewals for project hosting, domains, and enterprise mail systems.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryOf(context), height: 1.5),
          ),
          const SizedBox(height: 16),
          // Stats
          _buildStats(isWide),
          const SizedBox(height: 16),
          // Search + Schedule btn
          if (!isWide) ...[
            TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search by client, domain or category...',
                hintStyle: TextStyle(color: AppTheme.textMutedOf(context), fontSize: 12),
                prefixIcon: Icon(Icons.search, color: AppTheme.textMutedOf(context), size: 18),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close, size: 16, color: AppTheme.textSecondaryOf(context)),
                        onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); })
                    : null,
                filled: true,
                fillColor: isDark ? AppTheme.bgCardDark : Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.borderOf(context))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.borderOf(context))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showScheduleDialog(),
                icon: const Icon(Icons.add, size: 15),
                label: const Text('Schedule Renewal',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BCD4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: 'Search by client, domain or category...',
                      hintStyle: TextStyle(color: AppTheme.textMutedOf(context), fontSize: 12),
                      prefixIcon: Icon(Icons.search, color: AppTheme.textMutedOf(context), size: 18),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close, size: 16, color: AppTheme.textSecondaryOf(context)),
                              onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); })
                          : null,
                      filled: true,
                      fillColor: isDark ? AppTheme.bgCardDark : Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.borderOf(context))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.borderOf(context))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => _showScheduleDialog(),
                  icon: const Icon(Icons.add, size: 15),
                  label: const Text('Schedule Renewal',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCD4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          // Table
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4))),
            )
          else
            _buildTable(filtered, isWide),
        ],
      ),
    );
  }

  // ── STATS ─────────────────────────────────────────────────────────────────

  Widget _buildStats(bool isWide) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cards = [
      _StatData('TOTAL RENEWALS', '$_totalRenewals', 'Active recurring services',
          Icons.calendar_month_outlined, isDark ? AppTheme.textSecondaryOf(context) : const Color(0xFF374151), isDark ? AppTheme.bgCardDark : Colors.white),
      _StatData('CRITICAL WINDOW', '$_criticalWindow', 'Expiring within 30 days',
          Icons.warning_amber_rounded, const Color(0xFFF59E0B), isDark ? const Color(0xFF2E1F0F) : const Color(0xFFFFFBEB)),
      _StatData('REVENUE LOCKED', '\$$_revenueLocked', 'Current period collection',
          Icons.check_circle_outline_rounded, const Color(0xFF10B981), isDark ? const Color(0xFF08271C) : const Color(0xFFF0FDF4),
          valueColor: const Color(0xFF10B981), valueLarge: true),
    ];

    return isWide
        ? Row(children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 8), child: _StatCard(data: c)))).toList())
        : Column(children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _StatCard(data: c))).toList());
  }

  // ── TABLE ─────────────────────────────────────────────────────────────────

  Widget _buildTable(List<AssetRenewal> renewals, bool isWide) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        // Header
        if (isWide)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
              border: Border.all(color: AppTheme.borderOf(context)),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                const Expanded(flex: 4, child: _TH('SERVICE / CLIENT')),
                const Expanded(flex: 2, child: _TH('CATEGORY')),
                const Expanded(flex: 2, child: _TH('EXPIRY DATE')),
                const Expanded(flex: 2, child: _TH('AMOUNT')),
                const Expanded(flex: 2, child: _TH('STATUS')),
                const SizedBox(width: 40),
              ],
            ),
          ),
        if (renewals.isEmpty)
          Container(
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.bgCardDark : Colors.white,
              border: Border.all(color: AppTheme.borderOf(context)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                const Icon(Icons.autorenew_rounded, size: 40, color: Color(0xFFD1D5DB)),
                const SizedBox(height: 12),
                Text('No renewals found', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimaryOf(context))),
                const SizedBox(height: 6),
                Text('Schedule a renewal to start tracking.', style: TextStyle(color: AppTheme.textSecondaryOf(context), fontSize: 12)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showScheduleDialog(),
                  icon: const Icon(Icons.add, size: 15),
                  label: const Text('Schedule Renewal'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCD4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          )
        else if (isWide)
          ...renewals.asMap().entries.map((e) => _RenewalRow(
            renewal: e.value,
            isLast: e.key == renewals.length - 1,
            onEdit: () => _showScheduleDialog(existing: e.value),
            onMarkPaid: () => _markAsPaid(e.value),
            onReminder: () => _sendReminder(e.value),
            onDelete: () => _deleteRenewal(e.value),
          ))
        else
          ...renewals.map((r) => _RenewalCardMobile(
            renewal: r,
            onEdit: () => _showScheduleDialog(existing: r),
            onMarkPaid: () => _markAsPaid(r),
            onReminder: () => _sendReminder(r),
            onDelete: () => _deleteRenewal(r),
          )),
      ],
    );
  }
}

// ─── STAT DATA + CARD ─────────────────────────────────────────────────────────

class _StatData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color? valueColor;
  final bool valueLarge;

  const _StatData(this.title, this.value, this.subtitle, this.icon,
      this.iconColor, this.bgColor, {this.valueColor, this.valueLarge = false});
}

class _StatCard extends StatelessWidget {
  final _StatData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: data.bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppTheme.borderOf(context) : data.iconColor.withOpacity(0.15)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(data.icon, size: 14, color: data.iconColor),
              const SizedBox(width: 6),
              Text(data.title,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: data.iconColor,
                      letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 10),
          Text(data.value,
              style: TextStyle(
                  fontSize: data.valueLarge ? 26 : 22,
                  fontWeight: FontWeight.w800,
                  color: data.valueColor ?? AppTheme.textPrimaryOf(context))),
          const SizedBox(height: 2),
          Text(data.subtitle,
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryOf(context))),
        ],
      ),
    );
  }
}

// ─── RENEWAL ROW ─────────────────────────────────────────────────────────────

class _RenewalRow extends StatelessWidget {
  final AssetRenewal renewal;
  final bool isLast;
  final VoidCallback onEdit;
  final VoidCallback onMarkPaid;
  final VoidCallback onReminder;
  final VoidCallback onDelete;

  const _RenewalRow({
    required this.renewal,
    required this.isLast,
    required this.onEdit,
    required this.onMarkPaid,
    required this.onReminder,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: AppTheme.borderOf(context)),
          right: BorderSide(color: AppTheme.borderOf(context)),
          bottom: BorderSide(color: isLast ? Colors.transparent : AppTheme.borderOf(context)),
          top: renewal.isExpiringSoon
              ? BorderSide(color: isDark ? const Color(0xFF5B4010) : const Color(0xFFFEF9C3), width: 0)
              : BorderSide.none,
        ),
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(10))
            : BorderRadius.zero,
        color: renewal.isExpired
            ? (isDark ? const Color(0xFF3B1F21) : const Color(0xFFFEF2F2)).withOpacity(0.4)
            : renewal.isExpiringSoon
                ? (isDark ? const Color(0xFF2E1F0F) : const Color(0xFFFFFBEB)).withOpacity(0.5)
                : (isDark ? AppTheme.bgCardDark : Colors.white),
      ),
      child: Row(
        children: [
          // Service / Client
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (renewal.description.isNotEmpty)
                  Text(renewal.description,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimaryOf(context)),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                if (renewal.description.isNotEmpty && renewal.clientName.isNotEmpty)
                  const SizedBox(height: 4),
                if (renewal.clientName.isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.person_outline_rounded, size: 12, color: AppTheme.textSecondaryOf(context)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(renewal.clientName,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textSecondaryOf(context)),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                if (renewal.clientName.isNotEmpty && renewal.associatedProject.isNotEmpty && renewal.associatedProject != 'Independent Service')
                  const SizedBox(height: 2),
                if (renewal.associatedProject.isNotEmpty && renewal.associatedProject != 'Independent Service')
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_outlined, size: 12, color: AppTheme.textSecondaryOf(context)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(renewal.associatedProject,
                            style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryOf(context)),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Category
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(renewal.category.icon, size: 14, color: renewal.category.color),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(renewal.category.label,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: renewal.category.color,
                          letterSpacing: 0.3),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          // Expiry
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(renewal.formattedExpiry,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimaryOf(context))),
                Text(renewal.expiryLabel,
                    style: TextStyle(
                        fontSize: 10,
                        color: renewal.isExpired
                            ? const Color(0xFFEF4444)
                            : renewal.isExpiringSoon
                                ? const Color(0xFFF59E0B)
                                : AppTheme.textMutedOf(context))),
              ],
            ),
          ),
          // Amount
          Expanded(
            flex: 2,
            child: Text('\$${renewal.amount.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryOf(context))),
          ),
          // Status
          Expanded(
            flex: 2,
            child: _StatusBadge(status: renewal.status),
          ),
          // Actions
          SizedBox(
            width: 40,
            child: PopupMenuButton<String>(
              icon: Icon(Icons.more_horiz, size: 18, color: AppTheme.textMutedOf(context)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              itemBuilder: (_) => [
                _menuItem(Icons.edit_outlined, 'EDIT RECORD', isDark ? Colors.white : const Color(0xFF374151), 'edit'),
                _menuItem(Icons.notifications_outlined, 'SEND REMINDER', const Color(0xFF3B82F6), 'remind'),
                _menuItem(Icons.check_circle_outline, 'MARK AS PAID', const Color(0xFF10B981), 'paid'),
                _menuItem(Icons.delete_outline, 'DELETE ENTRY', const Color(0xFFEF4444), 'delete'),
              ],
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'remind') onReminder();
                if (v == 'paid') onMarkPaid();
                if (v == 'delete') onDelete();
              },
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _menuItem(IconData icon, String label, Color color, String value) {
    return PopupMenuItem(
      value: value,
      height: 40,
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color, letterSpacing: 0.3)),
        ],
      ),
    );
  }
}

// ─── SCHEDULE RENEWAL DIALOG ─────────────────────────────────────────────────

class _ScheduleRenewalDialog extends StatefulWidget {
  final AssetRenewal? existing;
  final List<String> clients;
  final Function(AssetRenewal) onSave;

  const _ScheduleRenewalDialog({this.existing, required this.clients, required this.onSave});

  @override
  State<_ScheduleRenewalDialog> createState() => _ScheduleRenewalDialogState();
}

class _ScheduleRenewalDialogState extends State<_ScheduleRenewalDialog> {
  late TextEditingController _nameCtrl, _amountCtrl, _descCtrl, _entityCtrl;
  String _selectedClient = '';
  String _associatedProject = 'Independent Service';
  ServiceCategory _category = ServiceCategory.hosting;
  RenewalStatus _status = RenewalStatus.pending;
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));

  final _projectOptions = ['Independent Service', 'JANANI Web Project', 'Arsenal Project', 'ECRAFTZ Internal'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.serviceName ?? '');
    _amountCtrl = TextEditingController(text: e?.amount.toString() ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _entityCtrl = TextEditingController(text: e?.clientEntity ?? '');
    _selectedClient = e?.clientName ?? '';
    _associatedProject = e?.associatedProject ?? 'Independent Service';
    _category = e?.category ?? ServiceCategory.hosting;
    _status = e?.status ?? RenewalStatus.pending;
    _expiryDate = e?.expiryDate ?? DateTime.now().add(const Duration(days: 365));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _entityCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service name required'), backgroundColor: Colors.red),
      );
      return;
    }
    final renewal = AssetRenewal(
      id: widget.existing?.id ?? '',
      serviceName: _nameCtrl.text.trim(),
      clientName: _selectedClient.isEmpty ? 'Unknown' : _selectedClient,
      clientEntity: _entityCtrl.text.trim().isEmpty
          ? (_selectedClient.isEmpty ? 'Unknown' : _selectedClient)
          : _entityCtrl.text.trim(),
      category: _category,
      expiryDate: _expiryDate,
      amount: double.tryParse(_amountCtrl.text) ?? 0,
      status: _status,
      description: _descCtrl.text.trim(),
      associatedProject: _associatedProject,
    );
    widget.onSave(renewal);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final isMobile = MediaQuery.of(context).size.width <= 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppTheme.bgCardDark : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit ? 'EDIT RENEWAL' : 'SCHEDULE NEW RENEWAL',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryOf(context), letterSpacing: 0.3),
                      ),
                      Text(
                        'Configure renewal tracking for hosting, domains, or enterprise mail services.',
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryOf(context), height: 1.4),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 20, color: AppTheme.textSecondaryOf(context)),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Service Name
            _DlgLabel(context, 'SERVICE NAME'),
            const SizedBox(height: 6),
            _DlgInput(context, _nameCtrl, 'e.g. AWS Production Hosting'),
            const SizedBox(height: 14),
            // Client + Project
            if (isMobile) ...[
              _DlgLabel(context, 'CLIENT SELECTION'),
              const SizedBox(height: 6),
              _DropdownField(
                value: _selectedClient.isEmpty ? null : _selectedClient,
                hint: 'Select Client',
                items: [...widget.clients, 'CHIMBU', 'JANANI', 'ARSENAL']
                    .toSet()
                    .toList(),
                onChanged: (v) => setState(() => _selectedClient = v ?? ''),
              ),
              const SizedBox(height: 14),
              _DlgLabel(context, 'ASSOCIATED PROJECT (OPTIONAL)'),
              const SizedBox(height: 6),
              _DropdownField(
                value: _associatedProject,
                items: _projectOptions,
                onChanged: (v) => setState(() => _associatedProject = v ?? 'Independent Service'),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DlgLabel(context, 'CLIENT SELECTION'),
                        const SizedBox(height: 6),
                        _DropdownField(
                          value: _selectedClient.isEmpty ? null : _selectedClient,
                          hint: 'Select Client',
                          items: [...widget.clients, 'CHIMBU', 'JANANI', 'ARSENAL']
                              .toSet()
                              .toList(),
                          onChanged: (v) => setState(() => _selectedClient = v ?? ''),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DlgLabel(context, 'ASSOCIATED PROJECT (OPTIONAL)'),
                        const SizedBox(height: 6),
                        _DropdownField(
                          value: _associatedProject,
                          items: _projectOptions,
                          onChanged: (v) => setState(() => _associatedProject = v ?? 'Independent Service'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            // Category + Expiry
            if (isMobile) ...[
              _DlgLabel(context, 'SERVICE CATEGORY'),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.bgCardDark : Colors.white,
                  border: Border.all(color: AppTheme.borderOf(context)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ServiceCategory>(
                    value: _category,
                    isExpanded: true,
                    style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context)),
                    items: ServiceCategory.values.map((c) =>
                        DropdownMenuItem(value: c, child: Text(c.label, style: TextStyle(fontSize: 12, color: AppTheme.textPrimaryOf(context))))).toList(),
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _DlgLabel(context, 'EXPIRATION DATE'),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _expiryDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.light(primary: Color(0xFF00BCD4))),
                      child: child!,
                    ),
                  );
                  if (d != null) setState(() => _expiryDate = d);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.bgCardDark : Colors.white,
                    border: Border.all(color: AppTheme.borderOf(context)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textMutedOf(context)),
                      const SizedBox(width: 6),
                      Text('${_expiryDate.day.toString().padLeft(2,'0')}-${_expiryDate.month.toString().padLeft(2,'0')}-${_expiryDate.year}',
                          style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context))),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DlgLabel(context, 'SERVICE CATEGORY'),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.bgCardDark : Colors.white,
                            border: Border.all(color: AppTheme.borderOf(context)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<ServiceCategory>(
                              value: _category,
                              isExpanded: true,
                              style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context)),
                              items: ServiceCategory.values.map((c) =>
                                  DropdownMenuItem(value: c, child: Text(c.label, style: TextStyle(fontSize: 12, color: AppTheme.textPrimaryOf(context))))).toList(),
                              onChanged: (v) => setState(() => _category = v!),
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
                        _DlgLabel(context, 'EXPIRATION DATE'),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _expiryDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                              builder: (ctx, child) => Theme(
                                data: Theme.of(ctx).copyWith(
                                    colorScheme: const ColorScheme.light(primary: Color(0xFF00BCD4))),
                                child: child!,
                              ),
                            );
                            if (d != null) setState(() => _expiryDate = d);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.bgCardDark : Colors.white,
                              border: Border.all(color: AppTheme.borderOf(context)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textMutedOf(context)),
                                const SizedBox(width: 6),
                                Text('${_expiryDate.day.toString().padLeft(2,'0')}-${_expiryDate.month.toString().padLeft(2,'0')}-${_expiryDate.year}',
                                    style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            // Amount + Status
            if (isMobile) ...[
              _DlgLabel(context, 'RENEWAL AMOUNT (\$)'),
              const SizedBox(height: 6),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context)),
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle: TextStyle(color: AppTheme.textMutedOf(context), fontSize: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.borderOf(context))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.borderOf(context))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  filled: true,
                  fillColor: isDark ? AppTheme.bgCardDark : Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              _DlgLabel(context, 'STATUS'),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.bgCardDark : Colors.white,
                  border: Border.all(color: AppTheme.borderOf(context)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<RenewalStatus>(
                    value: _status,
                    isExpanded: true,
                    style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context)),
                    items: RenewalStatus.values.map((s) =>
                        DropdownMenuItem(value: s, child: Text(s.label, style: TextStyle(fontSize: 12, color: AppTheme.textPrimaryOf(context))))).toList(),
                    onChanged: (v) => setState(() => _status = v!),
                  ),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DlgLabel(context, 'RENEWAL AMOUNT (\$)'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _amountCtrl,
                          keyboardType: TextInputType.number,
                          style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context)),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            hintStyle: TextStyle(color: AppTheme.textMutedOf(context), fontSize: 13),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.borderOf(context))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.borderOf(context))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 1.5)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            filled: true,
                            fillColor: isDark ? AppTheme.bgCardDark : Colors.white,
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
                        _DlgLabel(context, 'STATUS'),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.bgCardDark : Colors.white,
                            border: Border.all(color: AppTheme.borderOf(context)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<RenewalStatus>(
                              value: _status,
                              isExpanded: true,
                              style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context)),
                              items: RenewalStatus.values.map((s) =>
                                  DropdownMenuItem(value: s, child: Text(s.label, style: TextStyle(fontSize: 12, color: AppTheme.textPrimaryOf(context))))).toList(),
                              onChanged: (v) => setState(() => _status = v!),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            // Description
            _DlgLabel(context, 'DESCRIPTION / SERVICE DETAILS'),
            const SizedBox(height: 6),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context)),
              decoration: InputDecoration(
                hintText: 'e.g. AWS Production Hosting, Google Workspace Business Starter...',
                hintStyle: TextStyle(color: AppTheme.textMutedOf(context), fontSize: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.borderOf(context))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.borderOf(context))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 1.5)),
                contentPadding: const EdgeInsets.all(12),
                filled: true,
                fillColor: isDark ? AppTheme.bgCardDark : Colors.white,
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
                  elevation: 0,
                ),
                child: Text(
                  isEdit ? 'UPDATE RENEWAL' : 'SCHEDULE RENEWAL',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── QUICK CREATE SHEET ───────────────────────────────────────────────────────

class _QuickCreateSheet extends StatelessWidget {
  const _QuickCreateSheet();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = [
      (Icons.people_alt_outlined, 'New Lead', const Color(0xFF3B82F6)),
      (Icons.folder_outlined, 'New Project', const Color(0xFF8B5CF6)),
      (Icons.receipt_long_outlined, 'New Invoice', const Color(0xFF10B981)),
      (Icons.check_circle_outline_rounded, 'New Task', const Color(0xFFF59E0B)),
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('QUICK CREATE',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondaryOf(context), letterSpacing: 0.8)),
          const SizedBox(height: 12),
          ...items.map((item) => GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: isDark ? AppTheme.borderOf(context) : const Color(0xFFF3F4F6))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: item.$3.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(item.$1, size: 16, color: item.$3),
                  ),
                  const SizedBox(width: 12),
                  Text(item.$2, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimaryOf(context))),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.textMutedOf(context)),
                ],
              ),
            ),
          )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── STATUS BADGE ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final RenewalStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 10, color: status.color),
          const SizedBox(width: 4),
          Text(status.label,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: status.color, letterSpacing: 0.3)),
        ],
      ),
    );
  }
}

// ─── SHARED HELPERS ───────────────────────────────────────────────────────────

class _TH extends StatelessWidget {
  final String text;
  const _TH(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textSecondaryOf(context), letterSpacing: 0.4));
}

Widget _DlgLabel(BuildContext context, String text) => Text(text,
    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textSecondaryOf(context), letterSpacing: 0.4));

Widget _DlgInput(BuildContext context, TextEditingController ctrl, String hint) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return TextField(
    controller: ctrl,
    style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context)),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppTheme.textMutedOf(context), fontSize: 13),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.borderOf(context))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.borderOf(context))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      filled: true,
      fillColor: isDark ? AppTheme.bgCardDark : Colors.white,
    ),
  );
}

class _DropdownField extends StatelessWidget {
  final String? value;
  final String? hint;
  final List<String> items;
  final Function(String?) onChanged;

  const _DropdownField({this.value, this.hint, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        border: Border.all(color: AppTheme.borderOf(context)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: hint != null ? Text(hint!, style: TextStyle(color: AppTheme.textMutedOf(context), fontSize: 13)) : null,
          isExpanded: true,
          style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context)),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context))))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─── RENEWAL CARD MOBILE ─────────────────────────────────────────────────────

class _RenewalCardMobile extends StatelessWidget {
  final AssetRenewal renewal;
  final VoidCallback onEdit;
  final VoidCallback onMarkPaid;
  final VoidCallback onReminder;
  final VoidCallback onDelete;

  const _RenewalCardMobile({
    required this.renewal,
    required this.onEdit,
    required this.onMarkPaid,
    required this.onReminder,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: renewal.isExpired
              ? const Color(0xFFEF4444).withOpacity(0.3)
              : renewal.isExpiringSoon
                  ? const Color(0xFFF59E0B).withOpacity(0.4)
                  : AppTheme.borderOf(context),
        ),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Category Icon/Label & Actions menu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: renewal.category.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(renewal.category.icon, size: 12, color: renewal.category.color),
                    const SizedBox(width: 4),
                    Text(
                      renewal.category.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: renewal.category.color,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _StatusBadge(status: renewal.status),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 18, color: AppTheme.textMutedOf(context)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    itemBuilder: (_) => [
                      _menuItem(Icons.edit_outlined, 'EDIT RECORD', isDark ? Colors.white : const Color(0xFF374151), 'edit'),
                      _menuItem(Icons.notifications_outlined, 'SEND REMINDER', const Color(0xFF3B82F6), 'remind'),
                      _menuItem(Icons.check_circle_outline, 'MARK AS PAID', const Color(0xFF10B981), 'paid'),
                      _menuItem(Icons.delete_outline, 'DELETE ENTRY', const Color(0xFFEF4444), 'delete'),
                    ],
                    onSelected: (v) {
                      if (v == 'edit') onEdit();
                      if (v == 'remind') onReminder();
                      if (v == 'paid') onMarkPaid();
                      if (v == 'delete') onDelete();
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Description as Title
          if (renewal.description.isNotEmpty) ...[
            Text(
              renewal.description,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: 6),
          ],
          // Client details
          if (renewal.clientName.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.person_outline_rounded, size: 14, color: AppTheme.textSecondaryOf(context)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    renewal.clientName,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textSecondaryOf(context)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          // Project
          if (renewal.associatedProject.isNotEmpty && renewal.associatedProject != 'Independent Service') ...[
            Row(
              children: [
                Icon(Icons.folder_outlined, size: 14, color: AppTheme.textSecondaryOf(context)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    renewal.associatedProject,
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryOf(context)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          Divider(height: 20, color: AppTheme.borderOf(context)),
          // Row 3: Expiry Date & Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EXPIRY DATE',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.textMutedOf(context), letterSpacing: 0.3),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        renewal.formattedExpiry,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryOf(context)),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${renewal.expiryLabel})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: renewal.isExpired
                              ? const Color(0xFFEF4444)
                              : renewal.isExpiringSoon
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'AMOUNT',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.textMutedOf(context), letterSpacing: 0.3),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${renewal.amount.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryOf(context)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _menuItem(IconData icon, String label, Color color, String value) {
    return PopupMenuItem(
      value: value,
      height: 40,
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color, letterSpacing: 0.3)),
        ],
      ),
    );
  }
}
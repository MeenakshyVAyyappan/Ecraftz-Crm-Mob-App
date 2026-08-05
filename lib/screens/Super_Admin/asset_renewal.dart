// asset_renewals_page.dart
import 'package:ecraftz_crm/widgets/app_refresh_button.dart';
import 'package:ecraftz_crm/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../widgets/app_drawer.dart';
import '../../theme/app_theme.dart';
import '../../blocs/theme/theme_bloc.dart';
import '../../services/supabase_service.dart';
import '../../services/renewal_import_service.dart';

// ─── DATA MODELS ─────────────────────────────────────────────────────────────

enum RenewalStatus { pending, paid, overdue, cancelled }

extension RenewalStatusExt on RenewalStatus {
  String get label {
    switch (this) {
      case RenewalStatus.pending:
        return 'PENDING';
      case RenewalStatus.paid:
        return 'PAID';
      case RenewalStatus.overdue:
        return 'OVERDUE';
      case RenewalStatus.cancelled:
        return 'CANCELLED';
    }
  }

  Color get color {
    switch (this) {
      case RenewalStatus.pending:
        return const Color(0xFFF59E0B);
      case RenewalStatus.paid:
        return const Color(0xFF10B981);
      case RenewalStatus.overdue:
        return const Color(0xFFEF4444);
      case RenewalStatus.cancelled:
        return const Color(0xFF6B7280);
    }
  }
}

enum ServiceCategory {
  hosting,
  domain,
  hostingDomain,
  email,
  ssl,
  maintenance,
  other
}

extension ServiceCategoryExt on ServiceCategory {
  String get label {
    switch (this) {
      case ServiceCategory.hosting:
        return 'HOSTING';
      case ServiceCategory.domain:
        return 'DOMAIN';
      case ServiceCategory.hostingDomain:
        return 'HOSTING & DOMAIN';
      case ServiceCategory.email:
        return 'ENTERPRISE EMAIL';
      case ServiceCategory.ssl:
        return 'SSL CERTIFICATE';
      case ServiceCategory.maintenance:
        return 'MAINTENANCE';
      case ServiceCategory.other:
        return 'OTHER';
    }
  }

  IconData get icon {
    switch (this) {
      case ServiceCategory.hosting:
        return Icons.dns_outlined;
      case ServiceCategory.domain:
        return Icons.language_outlined;
      case ServiceCategory.hostingDomain:
        return Icons.shield_outlined;
      case ServiceCategory.email:
        return Icons.email_outlined;
      case ServiceCategory.ssl:
        return Icons.lock_outline_rounded;
      case ServiceCategory.maintenance:
        return Icons.build_outlined;
      case ServiceCategory.other:
        return Icons.settings_outlined;
    }
  }

  Color get color {
    switch (this) {
      case ServiceCategory.hosting:
        return const Color(0xFF3B82F6);
      case ServiceCategory.domain:
        return const Color(0xFF8B5CF6);
      case ServiceCategory.hostingDomain:
        return const Color(0xFF00BCD4);
      case ServiceCategory.email:
        return const Color(0xFFF59E0B);
      case ServiceCategory.ssl:
        return const Color(0xFF10B981);
      case ServiceCategory.maintenance:
        return const Color(0xFFF97316);
      case ServiceCategory.other:
        return const Color(0xFF6B7280);
    }
  }
}

class AssetRenewal {
  final String id;
  final String? organizationId;
  final String? clientId;
  final String? projectId;
  ServiceCategory category;
  String description;
  double amount;
  DateTime expiryDate;
  RenewalStatus status;
  int remindersSent;
  DateTime? lastReminderAt;
  Map<String, dynamic> metadata;

  // Joined/Fallback metadata attributes
  String clientName;
  String projectName;

  AssetRenewal({
    required this.id,
    this.organizationId,
    this.clientId,
    this.projectId,
    required this.category,
    required this.description,
    required this.amount,
    required this.expiryDate,
    required this.status,
    this.remindersSent = 0,
    this.lastReminderAt,
    Map<String, dynamic>? metadata,
    this.clientName = '',
    this.projectName = '',
  }) : metadata = metadata ?? {};

  factory AssetRenewal.fromJson(Map<String, dynamic> json) {
    // 1. Client resolution from Supabase join or metadata
    String cName = '';
    final clientsMap = json['clients'];
    if (clientsMap is Map && clientsMap['name'] != null) {
      cName = clientsMap['name'].toString();
    } else if (json['metadata'] is Map &&
        json['metadata']['client_name'] != null) {
      cName = json['metadata']['client_name'].toString();
    }

    // 2. Project resolution from Supabase join or metadata
    String pName = '';
    final projectsMap = json['projects'];
    if (projectsMap is Map && projectsMap['name'] != null) {
      pName = projectsMap['name'].toString();
    } else if (json['metadata'] is Map &&
        json['metadata']['project_name'] != null) {
      pName = json['metadata']['project_name'].toString();
    }

    // 3. Category & Status parsing
    final cat = _categoryFromString(json['category']);
    final stat = _statusFromString(json['status']);

    // 4. Description / Service title
    String desc = json['description']?.toString() ?? '';
    if (desc.isEmpty && json['service_name'] != null) {
      desc = json['service_name'].toString();
    }

    return AssetRenewal(
      id: json['id']?.toString() ?? '',
      organizationId: json['organization_id']?.toString(),
      clientId: json['client_id']?.toString(),
      projectId: json['project_id']?.toString(),
      category: cat,
      description: desc.isNotEmpty ? desc : cat.label,
      amount: (json['amount'] ?? 0).toDouble(),
      expiryDate: json['expiry_date'] != null
          ? DateTime.tryParse(json['expiry_date'].toString()) ??
              DateTime.now()
          : DateTime.now(),
      status: stat,
      remindersSent: (json['reminders_sent'] ?? 0) as int,
      lastReminderAt: json['last_reminder_at'] != null
          ? DateTime.tryParse(json['last_reminder_at'].toString())
          : null,
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'])
          : {},
      clientName: cName.isNotEmpty ? cName : 'General Client',
      projectName: pName.isNotEmpty ? pName : 'Independent Service',
    );
  }

  Map<String, dynamic> toSupabasePayload(
      {String defaultOrgId = '00000000-0000-0000-0000-000000000000'}) {
    return {
      'organization_id': (organizationId != null && organizationId!.isNotEmpty)
          ? organizationId
          : defaultOrgId,
      'client_id': (clientId != null && clientId!.isNotEmpty) ? clientId : null,
      'project_id':
          (projectId != null && projectId!.isNotEmpty) ? projectId : null,
      'category': category.name,
      'description': description,
      'amount': amount,
      'expiry_date': expiryDate.toIso8601String(),
      'status': status.name,
      'reminders_sent': remindersSent,
      if (lastReminderAt != null)
        'last_reminder_at': lastReminderAt!.toIso8601String(),
      'metadata': {
        'service_name': description,
        'client_name': clientName,
        'project_name': projectName,
        ...metadata,
      },
    };
  }

  static ServiceCategory _categoryFromString(String? val) {
    if (val == null) return ServiceCategory.hosting;
    return ServiceCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => ServiceCategory.hosting,
    );
  }

  static RenewalStatus _statusFromString(String? val) {
    if (val == null) return RenewalStatus.pending;
    return RenewalStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => RenewalStatus.pending,
    );
  }

  bool get isExpiringSoon =>
      status != RenewalStatus.paid &&
      status != RenewalStatus.cancelled &&
      expiryDate.difference(DateTime.now()).inDays <= 30 &&
      expiryDate.isAfter(DateTime.now());

  bool get isExpired =>
      status != RenewalStatus.paid &&
      status != RenewalStatus.cancelled &&
      expiryDate.isBefore(DateTime.now());

  RenewalStatus get effectiveStatus {
    if (status == RenewalStatus.paid) return RenewalStatus.paid;
    if (status == RenewalStatus.cancelled) return RenewalStatus.cancelled;
    if (isExpired) return RenewalStatus.overdue;
    return status;
  }

  String get serviceName => description.isNotEmpty ? description : category.label;

  String get expiryLabel {
    final diff = expiryDate.difference(DateTime.now()).inDays;
    if (isExpired) return 'Expired';
    if (diff == 0) return 'Expires today';
    if (diff == 1) return 'Expires tomorrow';
    return 'Expires in $diff days';
  }

  String get formattedExpiry {
    return DateFormat('MMM dd, yyyy').format(expiryDate);
  }
}

// ─── MAIN PAGE ────────────────────────────────────────────────────────────────

class AssetRenewalsPage extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool showAppBar;
  const AssetRenewalsPage({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.showAppBar = true,
  });

  @override
  State<AssetRenewalsPage> createState() => _AssetRenewalsPageState();
}

class _AssetRenewalsPageState extends State<AssetRenewalsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchCtrl = TextEditingController();
  String _search = '';
  String _statusFilter = 'ALL';
  String _sortBy = 'sort_by';
  DateTime? _fromDate;
  DateTime? _toDate;

  // 0 = Asset Renewals (income), 1 = Server Renewals (expense)
  int _mainTab = 0;

  List<AssetRenewal> _assetRenewals = [];  // metadata['type'] != 'server'
  List<AssetRenewal> _serverRenewals = []; // metadata['type'] == 'server'
  bool _isLoading = true;

  // Returns the active list depending on which tab is selected
  List<AssetRenewal> get _activeList =>
      _mainTab == 0 ? _assetRenewals : _serverRenewals;

  @override
  void initState() {
    super.initState();
    _fetchRenewals();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchRenewals() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.client
          .from('renewals')
          .select('*, clients(id, name), projects(id, name)')
          .order('expiry_date', ascending: true);

      if (!mounted) return;
      final all = (data as List).map((e) => AssetRenewal.fromJson(e)).toList();

      setState(() {
        // The web CRM tags server renewals with metadata['type'] = 'server_infra'
        // All other records (domain/hosting for clients) are asset renewals.
        _serverRenewals = all.where((r) =>
            r.metadata['type']?.toString() == 'server_infra').toList();
        _assetRenewals = all.where((r) =>
            r.metadata['type']?.toString() != 'server_infra').toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _snack('Failed to load renewals from database: $e', Colors.red);
    }
  }

  List<AssetRenewal> get _filtered {
    // Always filter from the active tab's list (asset or server)
    List<AssetRenewal> list = List.from(_activeList);

    // Status Tab Filter
    if (_statusFilter == 'UPCOMING') {
      list = list.where((r) => r.isExpiringSoon || r.status == RenewalStatus.pending).toList();
    } else if (_statusFilter == 'PAID') {
      list = list.where((r) => r.status == RenewalStatus.paid).toList();
    } else if (_statusFilter == 'OVERDUE') {
      list = list.where((r) => r.isExpired || r.status == RenewalStatus.overdue).toList();
    } else if (_statusFilter == 'CANCELLED') {
      list = list.where((r) => r.status == RenewalStatus.cancelled).toList();
    }

    // Date Range Expiry Filtering
    if (_fromDate != null) {
      final startOfFrom = DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
      list = list.where((r) {
        final exp = DateTime(r.expiryDate.year, r.expiryDate.month, r.expiryDate.day);
        return exp.isAtSameMomentAs(startOfFrom) || exp.isAfter(startOfFrom);
      }).toList();
    }
    if (_toDate != null) {
      final endOfTo = DateTime(_toDate!.year, _toDate!.month, _toDate!.day);
      list = list.where((r) {
        final exp = DateTime(r.expiryDate.year, r.expiryDate.month, r.expiryDate.day);
        return exp.isAtSameMomentAs(endOfTo) || exp.isBefore(endOfTo);
      }).toList();
    }

    // Search Query
    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((r) =>
          r.description.toLowerCase().contains(q) ||
          r.clientName.toLowerCase().contains(q) ||
          r.projectName.toLowerCase().contains(q) ||
          r.category.label.toLowerCase().contains(q) ||
          (r.metadata['vendor']?.toString().toLowerCase() ?? '').contains(q)).toList();
    }

    // Sorting
    if (_sortBy == 'date_earliest') {
      list.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    } else if (_sortBy == 'date_latest') {
      list.sort((a, b) => b.expiryDate.compareTo(a.expiryDate));
    } else if (_sortBy == 'amount_low_high') {
      list.sort((a, b) => a.amount.compareTo(b.amount));
    } else if (_sortBy == 'amount_high_low') {
      list.sort((a, b) => b.amount.compareTo(a.amount));
    } else {
      list.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    }

    return list;
  }

  // ── Tab-aware stats ────────────────────────────────────────────────────────
  int get _totalRenewals =>
      _activeList.where((r) => r.status != RenewalStatus.cancelled).length;
  int get _criticalWindow => _activeList.where((r) => r.isExpiringSoon).length;
  int get _overdueCount => _activeList.where((r) => r.isExpired).length;
  int get _renewedCount => _activeList.where((r) => r.status == RenewalStatus.paid).length;

  void _showScheduleDialog({AssetRenewal? existing}) {
    if (_mainTab == 1) {
      // Server Renewal dialog
      showDialog(
        context: context,
        builder: (_) => _ScheduleServerRenewalDialog(
          existing: existing,
          onSave: (r) async {
            setState(() => _isLoading = true);
            try {
              final payload = r.toSupabasePayload();
              // Stamp type = server_infra (matches web CRM convention)
              final meta = Map<String, dynamic>.from(payload['metadata'] ?? {});
              meta['type'] = 'server_infra';
              payload['metadata'] = meta;
              if (existing != null) {
                await SupabaseService.client
                    .from('renewals')
                    .update(payload)
                    .eq('id', existing.id);
              } else {
                await SupabaseService.client.from('renewals').insert(payload);
              }
              await _fetchRenewals();
              if (mounted) {
                _snack(
                  existing != null ? 'Server renewal updated!' : 'Server renewal scheduled!',
                  const Color(0xFF10B981),
                );
              }
            } catch (e) {
              if (mounted) {
                setState(() => _isLoading = false);
                _snack('Error saving server renewal: $e', Colors.red);
              }
            }
          },
        ),
      );
    } else {
      // Asset Renewal dialog
      showDialog(
        context: context,
        builder: (_) => _ScheduleRenewalDialog(
          existing: existing,
          onSave: (r) async {
            setState(() => _isLoading = true);
            try {
              final payload = r.toSupabasePayload();
              // Asset renewals do NOT get a type tag (matches web CRM convention)
              if (existing != null) {
                await SupabaseService.client
                    .from('renewals')
                    .update(payload)
                    .eq('id', existing.id);
              } else {
                await SupabaseService.client.from('renewals').insert(payload);
              }
              await _fetchRenewals();
              if (mounted) {
                _snack(
                  existing != null ? 'Renewal updated!' : 'Renewal scheduled!',
                  const Color(0xFF10B981),
                );
              }
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
  }

  Future<void> _markAsPaid(AssetRenewal r) async {
    setState(() => _isLoading = true);
    try {
      await SupabaseService.client
          .from('renewals')
          .update({'status': 'paid'}).eq('id', r.id);
      await _fetchRenewals();
      if (mounted) _snack('Marked as PAID', const Color(0xFF10B981));
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _snack('Failed to update status: $e', Colors.red);
      }
    }
  }

  // Builds the segmented tab row (Asset Renewals | Server Renewals)
  Widget _buildMainTabs(bool isDark) {
    Widget tab(int idx, String label, IconData icon, Color activeColor) {
      final selected = _mainTab == idx;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() {
            _mainTab = idx;
            _statusFilter = 'ALL';
            _search = '';
            _searchCtrl.clear();
            _fromDate = null;
            _toDate = null;
            _sortBy = 'sort_by';
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? activeColor
                  : (isDark ? AppTheme.bgCardDark : Colors.white),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? activeColor : AppTheme.borderOf(context),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 14,
                    color: selected
                        ? Colors.white
                        : AppTheme.textSecondaryOf(context)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? Colors.white
                        : AppTheme.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tab(0, 'Asset Renewals', Icons.language_outlined, const Color(0xFF00BCD4)),
        const SizedBox(width: 8),
        tab(1, 'Server Renewals', Icons.dns_outlined, const Color(0xFFF59E0B)),
      ],
    );
  }

  Future<void> _sendReminder(AssetRenewal r) async {
    try {
      final newCount = r.remindersSent + 1;
      final nowStr = DateTime.now().toIso8601String();
      await SupabaseService.client.from('renewals').update({
        'reminders_sent': newCount,
        'last_reminder_at': nowStr,
      }).eq('id', r.id);
      setState(() {
        r.remindersSent = newCount;
        r.lastReminderAt = DateTime.now();
      });
      if (mounted) {
        _snack(
            'Reminder notification #${newCount} sent to ${r.clientName}!',
            const Color(0xFF3B82F6));
      }
    } catch (e) {
      if (mounted) {
        _snack('Failed to log reminder: $e', Colors.red);
      }
    }
  }

  void _deleteRenewal(AssetRenewal r) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Renewal'),
        content: Text('Delete "${r.serviceName}"?'),
        actions: [
          AppRefreshButton(
            onRefresh: () async {
              await _fetchRenewals();
              await Future.delayed(const Duration(milliseconds: 600));
            },
          ),
          const SizedBox(width: 4),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await SupabaseService.client
                    .from('renewals')
                    .delete()
                    .eq('id', r.id);
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
    AppSnackBar.showCustom(context, 
      SnackBar(
          content: Text(msg),
          backgroundColor: color,
          duration: const Duration(seconds: 2)),
    );
  }

  void _showQuickCreate() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuickCreateSheet(onItemSelected: widget.onItemSelected),
    );
  }

  Widget _buildDatePickerButton({
    required BuildContext context,
    required String label,
    required DateTime? selectedDate,
    required Function(DateTime?) onDateSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayStr = selectedDate != null
        ? DateFormat('dd-MM-yyyy').format(selectedDate)
        : label;
    return GestureDetector(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
        );
        if (d != null) onDateSelected(d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.bgCardDark : Colors.white,
          border: Border.all(color: AppTheme.borderOf(context)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 14, color: AppTheme.textMutedOf(context)),
            const SizedBox(width: 8),
            Text(displayStr,
                style: TextStyle(
                    fontSize: 12,
                    color: selectedDate != null
                        ? AppTheme.textPrimaryOf(context)
                        : AppTheme.textMutedOf(context))),
            if (selectedDate != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => onDateSelected(null),
                child: Icon(Icons.close,
                    size: 14, color: AppTheme.textSecondaryOf(context)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static InputDecoration _filterInputDec(BuildContext context, String hint, {bool isDark = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppTheme.textMutedOf(context), fontSize: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: AppTheme.borderOf(context))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: AppTheme.borderOf(context))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      filled: true,
      fillColor: isDark ? AppTheme.bgCardDark : Colors.white,
    );
  }

  Future<void> _handleExcelImport() async {
    final service = RenewalImportService();
    final fileResult = await service.pickExcelFile();
    if (fileResult == null || fileResult.files.isEmpty) return;

    final bytes = fileResult.files.single.bytes;
    if (bytes == null) {
      _snack('Failed to read file data.', Colors.red);
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF00BCD4)),
                SizedBox(width: 20),
                Text("Importing renewals..."),
              ],
            ),
          ),
        );
      },
    );

    try {
      final result = await service.importRenewalsFromExcel(bytes: bytes);
      Navigator.pop(context); // Close loading dialog

      // Show results dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Excel Import Result'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Processed: ${result.totalRows} row(s)'),
                  Text('Succeeded: ${result.successCount}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  Text('Failed: ${result.failedCount}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  if (result.errorDetails.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text('Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...result.errorDetails.map((detail) => Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text('• $detail', style: const TextStyle(fontSize: 12)),
                        )),
                  ]
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      await _fetchRenewals();
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading dialog
      _snack('Import failed: $e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 650;
    final filtered = _filtered;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      drawer: widget.showAppBar
          ? AppDrawer(
              selectedIndex: widget.selectedIndex,
              onItemSelected: (i) {
                widget.onItemSelected(i);
                Navigator.pop(context);
              },
            )
          : null,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickCreate,
        backgroundColor: const Color(0xFF00BCD4),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      appBar: widget.showAppBar
          ? AppBar(
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
                  Text('Asset Renewals',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimaryOf(context))),
                  Text('Track and manage recurring service renewals.',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondaryOf(context))),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _fetchRenewals,
                ),
                BlocBuilder<ThemeBloc, ThemeState>(
                  builder: (context, themeState) {
                    final isDarkTheme = themeState.themeMode == ThemeMode.dark;
                    return IconButton(
                      icon: Icon(
                        isDarkTheme
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        color:
                            isDarkTheme ? Colors.white : const Color(0xFF374151),
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
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Track and manage recurring service renewals for project hosting, domains, and enterprise mail systems.',
            style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryOf(context),
                height: 1.5),
          ),
          const SizedBox(height: 16),

          // 1. Main Tab Toggle (Asset Renewals | Server Renewals)
          _buildMainTabs(isDark),
          const SizedBox(height: 16),

          // 2. Stats Bar (recalculates per tab)
          _buildStats(isWide),
          const SizedBox(height: 16),

          // 3. Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterTab('ALL', 'All Records'),
                _buildFilterTab('UPCOMING', 'Expiring Soon (${_criticalWindow})'),
                _buildFilterTab('PAID', 'Renewed / Paid'),
                _buildFilterTab('OVERDUE', 'Overdue (${_overdueCount})'),
                _buildFilterTab('CANCELLED', 'Cancelled'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3. Search & Controls Row
          if (!isWide) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Search by client, domain or category...',
                    hintStyle: TextStyle(
                        color: AppTheme.textMutedOf(context), fontSize: 12),
                    prefixIcon: Icon(Icons.search,
                        color: AppTheme.textMutedOf(context), size: 18),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close,
                                size: 16, color: AppTheme.textSecondaryOf(context)),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _search = '');
                            })
                        : null,
                    filled: true,
                    fillColor: isDark ? AppTheme.bgCardDark : Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppTheme.borderOf(context))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppTheme.borderOf(context))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFF00BCD4), width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildDatePickerButton(
                        context: context,
                        label: 'From Date',
                        selectedDate: _fromDate,
                        onDateSelected: (d) => setState(() => _fromDate = d),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDatePickerButton(
                        context: context,
                        label: 'To Date',
                        selectedDate: _toDate,
                        onDateSelected: (d) => setState(() => _toDate = d),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _sortBy,
                        decoration: _filterInputDec(context, 'Sort by...', isDark: isDark),
                        items: const [
                          DropdownMenuItem(value: 'sort_by', child: Text('Sort by...', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'date_earliest', child: Text('Date: Earliest First ↑', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'date_latest', child: Text('Date: Latest First ↓', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'amount_low_high', child: Text('Amount: Low → High ↑', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'amount_high_low', child: Text('Amount: High → Low ↓', style: TextStyle(fontSize: 12))),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _sortBy = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _handleExcelImport,
                        icon: const Icon(Icons.file_upload_outlined, size: 16),
                        label: const Text('Import Excel',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? AppTheme.bgCardDark : Colors.white,
                          foregroundColor: const Color(0xFF10B981),
                          side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showScheduleDialog(),
                        icon: const Icon(Icons.add, size: 15),
                        label: const Text('Schedule',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00BCD4),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ] else ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _search = v),
                        decoration: InputDecoration(
                          hintText: 'Search by client, domain or category...',
                          hintStyle: TextStyle(
                              color: AppTheme.textMutedOf(context), fontSize: 12),
                          prefixIcon: Icon(Icons.search,
                              color: AppTheme.textMutedOf(context), size: 18),
                          suffixIcon: _search.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.close,
                                      size: 16,
                                      color: AppTheme.textSecondaryOf(context)),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _search = '');
                                  })
                              : null,
                          filled: true,
                          fillColor: isDark ? AppTheme.bgCardDark : Colors.white,
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
                                  color: Color(0xFF00BCD4), width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _handleExcelImport,
                      icon: const Icon(Icons.file_upload_outlined, size: 16),
                      label: const Text('Import Excel',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppTheme.bgCardDark : Colors.white,
                        foregroundColor: const Color(0xFF10B981),
                        side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () => _showScheduleDialog(),
                      icon: const Icon(Icons.add, size: 15),
                      label: const Text('Schedule Renewal',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00BCD4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildDatePickerButton(
                      context: context,
                      label: 'From Expiry Date',
                      selectedDate: _fromDate,
                      onDateSelected: (d) => setState(() => _fromDate = d),
                    ),
                    const SizedBox(width: 10),
                    _buildDatePickerButton(
                      context: context,
                      label: 'To Expiry Date',
                      selectedDate: _toDate,
                      onDateSelected: (d) => setState(() => _toDate = d),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 200,
                      child: DropdownButtonFormField<String>(
                        value: _sortBy,
                        decoration: _filterInputDec(context, 'Sort by...', isDark: isDark),
                        items: const [
                          DropdownMenuItem(value: 'sort_by', child: Text('Sort by...', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'date_earliest', child: Text('Date: Earliest First ↑', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'date_latest', child: Text('Date: Latest First ↓', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'amount_low_high', child: Text('Amount: Low → High ↑', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'amount_high_low', child: Text('Amount: High → Low ↓', style: TextStyle(fontSize: 12))),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _sortBy = v);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            )
          ],
          const SizedBox(height: 14),

          // 4. Data Table / Cards
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF00BCD4))),
            )
          else if (_mainTab == 0)
            _buildTable(filtered, isWide)
          else
            _buildServerTable(filtered, isWide),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String code, String label) {
    final isSelected = _statusFilter == code;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : AppTheme.textSecondaryOf(context),
          ),
        ),
        selected: isSelected,
        selectedColor: const Color(0xFF0F172A),
        backgroundColor: isDark ? AppTheme.bgCardDark : Colors.white,
        side: BorderSide(
          color: isSelected
              ? const Color(0xFF0F172A)
              : AppTheme.borderOf(context),
        ),
        onSelected: (_) => setState(() => _statusFilter = code),
      ),
    );
  }

  // ── STATS ─────────────────────────────────────────────────────────────────

  Widget _buildStats(bool isWide) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAsset = _mainTab == 0;

    final cards = [
      _StatData(
          isAsset ? 'TOTAL ASSET RENEWALS' : 'TOTAL SERVER RENEWALS',
          '$_totalRenewals',
          isAsset ? 'Active domain & hosting assets' : 'Active infrastructure services',
          Icons.calendar_month_outlined,
          isDark ? AppTheme.textSecondaryOf(context) : const Color(0xFF374151),
          isDark ? AppTheme.bgCardDark : Colors.white),
      _StatData(
          'CRITICAL WINDOW',
          '$_criticalWindow',
          'Expiring within 30 days',
          Icons.warning_amber_rounded,
          const Color(0xFFF59E0B),
          isDark ? const Color(0xFF2E1F0F) : const Color(0xFFFFFBEB)),
      _StatData(
          isAsset ? 'RENEWED ASSETS' : 'RENEWED SERVICES',
          '$_renewedCount',
          'Successfully renewed',
          Icons.check_circle_outline_rounded,
          const Color(0xFF10B981),
          isDark ? const Color(0xFF08271C) : const Color(0xFFF0FDF4),
          valueColor: const Color(0xFF10B981),
          valueLarge: true),
    ];

    return isWide
        ? Row(
            children: cards
                .map((c) => Expanded(
                        child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _StatCard(data: c),
                    )))
                .toList())
        : Column(
            children: cards
                .map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _StatCard(data: c),
                    ))
                .toList());
  }

  // ── ASSET RENEWALS TABLE ───────────────────────────────────────────────────

  Widget _buildTable(List<AssetRenewal> renewals, bool isWide) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        if (isWide)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
              border: Border.all(color: AppTheme.borderOf(context)),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: const [
                Expanded(flex: 4, child: _TH('ASSET / DOMAIN')),
                Expanded(flex: 3, child: _TH('CLIENT NAME')),
                Expanded(flex: 2, child: _TH('CATEGORY')),
                Expanded(flex: 2, child: _TH('EXPIRY DATE')),
                Expanded(flex: 2, child: _TH('AMOUNT')),
                Expanded(flex: 2, child: _TH('STATUS')),
                SizedBox(width: 40),
              ],
            ),
          ),
        if (renewals.isEmpty)
          _buildEmptyState('No asset renewals found',
              'Schedule a renewal to start tracking.', const Color(0xFF00BCD4))
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

  // ── SERVER RENEWALS TABLE ──────────────────────────────────────────────────

  Widget _buildServerTable(List<AssetRenewal> renewals, bool isWide) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        if (isWide)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
              border: Border.all(color: AppTheme.borderOf(context)),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: const [
                Expanded(flex: 4, child: _TH('VENDOR / SERVICE')),
                Expanded(flex: 2, child: _TH('CATEGORY')),
                Expanded(flex: 2, child: _TH('EXPIRY DATE')),
                Expanded(flex: 2, child: _TH('AMOUNT')),
                Expanded(flex: 2, child: _TH('STATUS')),
                SizedBox(width: 40),
              ],
            ),
          ),
        if (renewals.isEmpty)
          _buildEmptyState('No server renewals found',
              'Schedule a server renewal to track infrastructure costs.', const Color(0xFFF59E0B))
        else if (isWide)
          ...renewals.asMap().entries.map((e) => _ServerRenewalRow(
                renewal: e.value,
                isLast: e.key == renewals.length - 1,
                onEdit: () => _showScheduleDialog(existing: e.value),
                onMarkPaid: () => _markAsPaid(e.value),
                onReminder: () => _sendReminder(e.value),
                onDelete: () => _deleteRenewal(e.value),
              ))
        else
          ...renewals.map((r) => _ServerRenewalCardMobile(
                renewal: r,
                onEdit: () => _showScheduleDialog(existing: r),
                onMarkPaid: () => _markAsPaid(r),
                onReminder: () => _sendReminder(r),
                onDelete: () => _deleteRenewal(r),
              )),
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle, Color accent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        border: Border.all(color: AppTheme.borderOf(context)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(Icons.autorenew_rounded, size: 40, color: accent.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryOf(context))),
          const SizedBox(height: 6),
          Text(subtitle,
              style: TextStyle(
                  color: AppTheme.textSecondaryOf(context), fontSize: 12),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showScheduleDialog(),
            icon: const Icon(Icons.add, size: 15),
            label: Text(_mainTab == 0 ? 'Schedule Renewal' : 'Schedule Server Renewal'),
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SCHEDULE RENEWAL DIALOG ─────────────────────────────────────────────────

class _ScheduleRenewalDialog extends StatefulWidget {
  final AssetRenewal? existing;
  final Function(AssetRenewal) onSave;

  const _ScheduleRenewalDialog({this.existing, required this.onSave});

  @override
  State<_ScheduleRenewalDialog> createState() => _ScheduleRenewalDialogState();
}

class _ScheduleRenewalDialogState extends State<_ScheduleRenewalDialog> {
  late TextEditingController _descCtrl, _amountCtrl;
  late TextEditingController _clientNameCtrl;
  late TextEditingController _sourceCtrl;
  late TextEditingController _remarksCtrl;
  String? _selectedClientId;
  String? _selectedClientName;
  String? _selectedProjectId;
  String? _selectedProjectName;
  ServiceCategory _category = ServiceCategory.hostingDomain;
  RenewalStatus _status = RenewalStatus.pending;
  DateTime _expiryDate = DateTime.now();

  List<Map<String, dynamic>> _clientList = [];
  bool _loadingLookups = true;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _amountCtrl = TextEditingController(text: e?.amount.toString() ?? '');
    _clientNameCtrl = TextEditingController(
        text: e?.metadata['client_name']?.toString() ?? e?.clientName ?? '');
    _sourceCtrl = TextEditingController(text: e?.metadata['source']?.toString() ?? '');
    _remarksCtrl = TextEditingController(text: e?.metadata['remarks']?.toString() ?? '');
    _selectedClientId = e?.clientId;
    _selectedClientName = e?.clientName;
    _selectedProjectId = e?.projectId;
    _selectedProjectName = e?.projectName;
    _category = e?.category ?? ServiceCategory.hostingDomain;
    _status = e?.status ?? RenewalStatus.pending;
    _expiryDate = e?.expiryDate ?? DateTime.now();

    _fetchLookups();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _clientNameCtrl.dispose();
    _sourceCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchLookups() async {
    try {
      final clientsData = await SupabaseService.client
          .from('clients')
          .select('id, name')
          .order('name');

      if (!mounted) return;
      setState(() {
        _clientList = List<Map<String, dynamic>>.from(clientsData);
        _loadingLookups = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingLookups = false);
    }
  }

  void _pickExpiryDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (d != null) setState(() => _expiryDate = d);
  }

  void _save() {
    final domainName = _descCtrl.text.trim();
    if (domainName.isEmpty) {
      AppSnackBar.showCustom(context, 
        const SnackBar(
            content: Text('Domain / Asset name required'),
            backgroundColor: Colors.red),
      );
      return;
    }

    String finalClientName = _clientNameCtrl.text.trim();
    if (finalClientName.isEmpty) {
      finalClientName = domainName;
    }

    final renewal = AssetRenewal(
      id: widget.existing?.id ?? '',
      organizationId: widget.existing?.organizationId,
      clientId: _selectedClientId,
      projectId: _selectedProjectId,
      category: _category,
      description: domainName,
      amount: double.tryParse(_amountCtrl.text) ?? 0,
      expiryDate: _expiryDate,
      status: _status,
      remindersSent: widget.existing?.remindersSent ?? 0,
      lastReminderAt: widget.existing?.lastReminderAt,
      clientName: _selectedClientId != null ? (_selectedClientName ?? 'General Client') : finalClientName,
      projectName: _selectedProjectName ?? 'Independent Service',
      metadata: {
        ...widget.existing?.metadata ?? {},
        'service_name': domainName,
        'client_name': _selectedClientId != null ? (_selectedClientName ?? 'General Client') : finalClientName,
        'source': _sourceCtrl.text.trim(),
        'remarks': _remarksCtrl.text.trim(),
      },
    );
    widget.onSave(renewal);
    Navigator.pop(context);
  }

  static InputDecoration _formInputDec(BuildContext context, String hint,
      {required bool isDark}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
          color: isDark ? Colors.white38 : const Color(0xFF64748B),
          fontSize: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: Color(0xFF00BCD4), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: isDark ? AppTheme.bgCardDark : const Color(0xFFF1F5F9),
    );
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BCD4).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.calendar_month_outlined, color: Color(0xFF00BCD4), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Schedule Asset Renewal',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimaryOf(context),
                            letterSpacing: 0.3),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Add domain or hosting details to track expiration and send reminders to clients.',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondaryOf(context),
                            height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.cancel_outlined, size: 22, color: Color(0xFF00BCD4)),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_loadingLookups)
              const Padding(
                padding: EdgeInsets.all(48.0),
                child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF00BCD4))),
              )
            else ...[
              if (isMobile) ...[
                _DlgLabel(context, 'DOMAIN / ASSET NAME *'),
                TextField(
                  controller: _descCtrl,
                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context)),
                  decoration: _formInputDec(context, 'e.g. dtrend.in or freejob.org', isDark: isDark),
                ),
                const SizedBox(height: 12),
                _DlgLabel(context, 'CLIENT NAME (TEXT)'),
                TextField(
                  controller: _clientNameCtrl,
                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context)),
                  decoration: _formInputDec(context, 'Defaults to domain name if left empty', isDark: isDark),
                ),
                const SizedBox(height: 12),
                _DlgLabel(context, 'SOURCE / REGISTRAR'),
                TextField(
                  controller: _sourceCtrl,
                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context)),
                  decoration: _formInputDec(context, 'E.G. GODADDY, HOSTINGER', isDark: isDark),
                ),
                const SizedBox(height: 12),
                _DlgLabel(context, 'SERVICE CATEGORY'),
                DropdownButtonFormField<ServiceCategory>(
                  value: _category,
                  decoration: _formInputDec(context, 'Select Category', isDark: isDark),
                  items: ServiceCategory.values
                      .map((c) => DropdownMenuItem(value: c, child: Text(c.label, style: const TextStyle(fontSize: 12))))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v!),
                ),
                const SizedBox(height: 12),
                _DlgLabel(context, 'EXPIRATION DATE'),
                GestureDetector(
                  onTap: _pickExpiryDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.bgCardDark : const Color(0xFFF1F5F9),
                      border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(DateFormat('dd-MM-yyyy').format(_expiryDate),
                            style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context))),
                        const Spacer(),
                        Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.textMutedOf(context)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _DlgLabel(context, 'RENEWAL AMOUNT (₹)'),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context)),
                  decoration: _formInputDec(context, '0.00', isDark: isDark),
                ),
                const SizedBox(height: 12),
                _DlgLabel(context, 'STATUS'),
                DropdownButtonFormField<RenewalStatus>(
                  value: _status,
                  decoration: _formInputDec(context, 'Status', isDark: isDark),
                  items: RenewalStatus.values
                      .map((s) => DropdownMenuItem(value: s, child: Text(s.label, style: const TextStyle(fontSize: 12))))
                      .toList(),
                  onChanged: (v) => setState(() => _status = v!),
                ),
                const SizedBox(height: 12),
                _DlgLabel(context, 'UPLOAD STATUS / REMARKS'),
                TextField(
                  controller: _remarksCtrl,
                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context)),
                  decoration: _formInputDec(context, 'e.g. UPLOADED, DOMAIN TR', isDark: isDark),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DlgLabel(context, 'DOMAIN / ASSET NAME *'),
                          TextField(
                            controller: _descCtrl,
                            style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context)),
                            decoration: _formInputDec(context, 'e.g. dtrend.in or freejob.org', isDark: isDark),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DlgLabel(context, 'CLIENT NAME (TEXT)'),
                          TextField(
                            controller: _clientNameCtrl,
                            style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context)),
                            decoration: _formInputDec(context, 'Defaults to domain name if left empty', isDark: isDark),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DlgLabel(context, 'SOURCE / REGISTRAR'),
                          TextField(
                            controller: _sourceCtrl,
                            style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context)),
                            decoration: _formInputDec(context, 'E.G. GODADDY, HOSTINGER', isDark: isDark),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DlgLabel(context, 'SERVICE CATEGORY'),
                          DropdownButtonFormField<ServiceCategory>(
                            value: _category,
                            decoration: _formInputDec(context, 'Select Category', isDark: isDark),
                            items: ServiceCategory.values
                                .map((c) => DropdownMenuItem(value: c, child: Text(c.label, style: const TextStyle(fontSize: 12))))
                                .toList(),
                            onChanged: (v) => setState(() => _category = v!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DlgLabel(context, 'EXPIRATION DATE'),
                          GestureDetector(
                            onTap: _pickExpiryDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.bgCardDark : const Color(0xFFF1F5F9),
                                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Text(DateFormat('dd-MM-yyyy').format(_expiryDate),
                                      style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context))),
                                  const Spacer(),
                                  Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.textMutedOf(context)),
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
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DlgLabel(context, 'RENEWAL AMOUNT (₹)'),
                          TextField(
                            controller: _amountCtrl,
                            keyboardType: TextInputType.number,
                            style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context)),
                            decoration: _formInputDec(context, '0.00', isDark: isDark),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DlgLabel(context, 'STATUS'),
                          DropdownButtonFormField<RenewalStatus>(
                            value: _status,
                            decoration: _formInputDec(context, 'Status', isDark: isDark),
                            items: RenewalStatus.values
                                .map((s) => DropdownMenuItem(value: s, child: Text(s.label, style: const TextStyle(fontSize: 12))))
                                .toList(),
                            onChanged: (v) => setState(() => _status = v!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DlgLabel(context, 'UPLOAD STATUS / REMARKS'),
                          TextField(
                            controller: _remarksCtrl,
                            style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context)),
                            decoration: _formInputDec(context, 'e.g. UPLOADED, DOMAIN TR', isDark: isDark),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              _DlgLabel(context, 'LINK CRM ACTIVE CLIENT (OPTIONAL)'),
              DropdownButtonFormField<String?>(
                value: _selectedClientId,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  filled: true,
                  fillColor: isDark ? AppTheme.bgCardDark : const Color(0xFFF8FAFC),
                ),
                icon: Icon(Icons.unfold_more, color: AppTheme.textMutedOf(context)),
                items: [
                  const DropdownMenuItem(
                      value: null,
                      child: Text('No CRM client linked (Standalone Asset)', style: TextStyle(fontSize: 12))),
                  ..._clientList.map((c) => DropdownMenuItem(
                        value: c['id'].toString(),
                        child: Text(c['name'].toString(), style: const TextStyle(fontSize: 12)),
                      )),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedClientId = val;
                    if (val != null) {
                      final match = _clientList.firstWhere(
                          (c) => c['id'].toString() == val,
                          orElse: () => {});
                      _selectedClientName = match['name']?.toString() ?? 'General Client';
                    } else {
                      _selectedClientName = null;
                    }
                  });
                },
              ),
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
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: Text(
                    isEdit ? 'UPDATE RENEWAL' : 'SCHEDULE RENEWAL',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── QUICK CREATE SHEET ───────────────────────────────────────────────────────

class _QuickCreateSheet extends StatelessWidget {
  final Function(int) onItemSelected;
  const _QuickCreateSheet({required this.onItemSelected});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = [
      (Icons.people_alt_outlined, 'New Lead', const Color(0xFF3B82F6)),
      (Icons.folder_outlined, 'New Project', const Color(0xFF8B5CF6)),
      (Icons.receipt_long_outlined, 'New Invoice', const Color(0xFF10B981)),
      (
        Icons.check_circle_outline_rounded,
        'New Task',
        const Color(0xFFF59E0B)
      ),
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1), blurRadius: 20)
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('QUICK CREATE',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondaryOf(context),
                  letterSpacing: 0.8)),
          const SizedBox(height: 12),
          ...items.map((item) => GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  if (item.$2 == 'New Lead') {
                    onItemSelected(1);
                  } else if (item.$2 == 'New Project') {
                    onItemSelected(4);
                  } else if (item.$2 == 'New Invoice') {
                    onItemSelected(7);
                  } else if (item.$2 == 'New Task') {
                    onItemSelected(5);
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(
                            color: isDark
                                ? AppTheme.borderOf(context)
                                : const Color(0xFFF3F4F6))),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: item.$3.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(item.$1, size: 16, color: item.$3),
                      ),
                      const SizedBox(width: 12),
                      Text(item.$2,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryOf(context))),
                      const Spacer(),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 12, color: AppTheme.textMutedOf(context)),
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
        color: status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 10, color: status.color),
          const SizedBox(width: 4),
          Text(status.label,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: status.color,
                  letterSpacing: 0.3)),
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
      style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondaryOf(context),
          letterSpacing: 0.4));
}

Widget _DlgLabel(BuildContext context, String text) => Text(text,
    style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppTheme.textSecondaryOf(context),
        letterSpacing: 0.4));

// ─── RENEWAL ROW (DESKTOP) ───────────────────────────────────────────────────

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
          bottom: BorderSide(
              color: isLast ? Colors.transparent : AppTheme.borderOf(context)),
        ),
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(10))
            : BorderRadius.zero,
        color: renewal.isExpired
            ? (isDark ? const Color(0xFF3B1F21) : const Color(0xFFFEF2F2))
                .withValues(alpha: 0.4)
            : renewal.isExpiringSoon
                ? (isDark ? const Color(0xFF2E1F0F) : const Color(0xFFFFFBEB))
                    .withValues(alpha: 0.5)
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
                Text(renewal.serviceName,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryOf(context)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.person_outline_rounded,
                        size: 12, color: AppTheme.textSecondaryOf(context)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(renewal.clientName,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondaryOf(context)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                if (renewal.projectName.isNotEmpty &&
                    renewal.projectName != 'Independent Service') ...[
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_outlined,
                          size: 12, color: AppTheme.textSecondaryOf(context)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(renewal.projectName,
                            style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondaryOf(context)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Category
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(renewal.category.icon,
                    size: 14, color: renewal.category.color),
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
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryOf(context))),
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
            child: Text('₹${renewal.amount.toStringAsFixed(0)}',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryOf(context))),
          ),
          // Status
          Expanded(
            flex: 2,
            child: _StatusBadge(status: renewal.effectiveStatus),
          ),
          // Actions
          SizedBox(
            width: 40,
            child: PopupMenuButton<String>(
              icon: Icon(Icons.more_horiz,
                  size: 18, color: AppTheme.textMutedOf(context)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              itemBuilder: (_) => [
                _menuItem(Icons.edit_outlined, 'EDIT RECORD',
                    isDark ? Colors.white : const Color(0xFF374151), 'edit'),
                _menuItem(Icons.notifications_outlined, 'SEND REMINDER',
                    const Color(0xFF3B82F6), 'remind'),
                _menuItem(Icons.check_circle_outline, 'MARK AS PAID',
                    const Color(0xFF10B981), 'paid'),
                _menuItem(Icons.delete_outline, 'DELETE ENTRY',
                    const Color(0xFFEF4444), 'delete'),
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

  PopupMenuItem<String> _menuItem(
      IconData icon, String label, Color color, String value) {
    return PopupMenuItem(
      value: value,
      height: 40,
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                  letterSpacing: 0.3)),
        ],
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
              ? const Color(0xFFEF4444).withValues(alpha: 0.3)
              : renewal.isExpiringSoon
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                  : AppTheme.borderOf(context),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category & Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: renewal.category.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(renewal.category.icon,
                        size: 12, color: renewal.category.color),
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
                  _StatusBadge(status: renewal.effectiveStatus),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert,
                        size: 18, color: AppTheme.textMutedOf(context)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    itemBuilder: (_) => [
                      _menuItem(
                          Icons.edit_outlined,
                          'EDIT RECORD',
                          isDark ? Colors.white : const Color(0xFF374151),
                          'edit'),
                      _menuItem(Icons.notifications_outlined, 'SEND REMINDER',
                          const Color(0xFF3B82F6), 'remind'),
                      _menuItem(Icons.check_circle_outline, 'MARK AS PAID',
                          const Color(0xFF10B981), 'paid'),
                      _menuItem(Icons.delete_outline, 'DELETE ENTRY',
                          const Color(0xFFEF4444), 'delete'),
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

          // Service Description
          Text(
            renewal.serviceName,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 6),

          // Client details
          Row(
            children: [
              Icon(Icons.person_outline_rounded,
                  size: 14, color: AppTheme.textSecondaryOf(context)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  renewal.clientName,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondaryOf(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Project
          if (renewal.projectName.isNotEmpty &&
              renewal.projectName != 'Independent Service') ...[
            Row(
              children: [
                Icon(Icons.folder_outlined,
                    size: 14, color: AppTheme.textSecondaryOf(context)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    renewal.projectName,
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textSecondaryOf(context)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          Divider(height: 20, color: AppTheme.borderOf(context)),

          // Expiry & Amount Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EXPIRY DATE',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMutedOf(context),
                        letterSpacing: 0.3),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        renewal.formattedExpiry,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimaryOf(context)),
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
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMutedOf(context),
                        letterSpacing: 0.3),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${renewal.amount.toStringAsFixed(0)}',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimaryOf(context)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
      IconData icon, String label, Color color, String value) {
    return PopupMenuItem(
      value: value,
      height: 40,
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                  letterSpacing: 0.3)),
        ],
      ),
    );
  }
}

// ─── SERVER RENEWAL ROW (DESKTOP) ────────────────────────────────────────────

class _ServerRenewalRow extends StatelessWidget {
  final AssetRenewal renewal;
  final bool isLast;
  final VoidCallback onEdit;
  final VoidCallback onMarkPaid;
  final VoidCallback onReminder;
  final VoidCallback onDelete;

  const _ServerRenewalRow({
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
    final vendor = renewal.metadata['vendor']?.toString() ?? renewal.serviceName;
    final source = renewal.metadata['source']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: AppTheme.borderOf(context)),
          right: BorderSide(color: AppTheme.borderOf(context)),
          bottom: BorderSide(
              color: isLast ? Colors.transparent : AppTheme.borderOf(context)),
        ),
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(10))
            : BorderRadius.zero,
        color: renewal.isExpired
            ? (isDark ? const Color(0xFF3B1F21) : const Color(0xFFFEF2F2))
                .withValues(alpha: 0.4)
            : renewal.isExpiringSoon
                ? (isDark ? const Color(0xFF2E1F0F) : const Color(0xFFFFFBEB))
                    .withValues(alpha: 0.5)
                : (isDark ? AppTheme.bgCardDark : Colors.white),
      ),
      child: Row(
        children: [
          // Vendor / Service
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vendor,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryOf(context)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                if (source.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(source.toUpperCase(),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFF59E0B),
                          letterSpacing: 0.3)),
                ],
              ],
            ),
          ),
          // Category
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(renewal.category.icon,
                    size: 14, color: renewal.category.color),
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
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryOf(context))),
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
          // Amount (expense shown in amber/orange)
          Expanded(
            flex: 2,
            child: Text('₹${renewal.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF59E0B))),
          ),
          // Status
          Expanded(
            flex: 2,
            child: _StatusBadge(status: renewal.effectiveStatus),
          ),
          // Actions
          SizedBox(
            width: 40,
            child: PopupMenuButton<String>(
              icon: Icon(Icons.more_horiz,
                  size: 18, color: AppTheme.textMutedOf(context)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              itemBuilder: (_) => [
                _srvMenuItem(Icons.edit_outlined, 'EDIT RECORD',
                    isDark ? Colors.white : const Color(0xFF374151), 'edit'),
                _srvMenuItem(Icons.notifications_outlined, 'SEND REMINDER',
                    const Color(0xFF3B82F6), 'remind'),
                _srvMenuItem(Icons.check_circle_outline, 'MARK AS PAID',
                    const Color(0xFF10B981), 'paid'),
                _srvMenuItem(Icons.delete_outline, 'DELETE ENTRY',
                    const Color(0xFFEF4444), 'delete'),
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

  PopupMenuItem<String> _srvMenuItem(
      IconData icon, String label, Color color, String value) {
    return PopupMenuItem(
      value: value,
      height: 40,
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                  letterSpacing: 0.3)),
        ],
      ),
    );
  }
}

// ─── SERVER RENEWAL CARD (MOBILE) ────────────────────────────────────────────

class _ServerRenewalCardMobile extends StatelessWidget {
  final AssetRenewal renewal;
  final VoidCallback onEdit;
  final VoidCallback onMarkPaid;
  final VoidCallback onReminder;
  final VoidCallback onDelete;

  const _ServerRenewalCardMobile({
    required this.renewal,
    required this.onEdit,
    required this.onMarkPaid,
    required this.onReminder,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vendor = renewal.metadata['vendor']?.toString() ?? renewal.serviceName;
    final source = renewal.metadata['source']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: renewal.isExpired
              ? const Color(0xFFEF4444).withValues(alpha: 0.3)
              : renewal.isExpiringSoon
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                  : AppTheme.borderOf(context),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category badge + Status + Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: renewal.category.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(renewal.category.icon,
                        size: 12, color: renewal.category.color),
                    const SizedBox(width: 4),
                    Text(renewal.category.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: renewal.category.color,
                          letterSpacing: 0.3,
                        )),
                  ],
                ),
              ),
              Row(
                children: [
                  _StatusBadge(status: renewal.effectiveStatus),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert,
                        size: 18, color: AppTheme.textMutedOf(context)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    itemBuilder: (_) => [
                      _srvMenuItem(Icons.edit_outlined, 'EDIT RECORD',
                          isDark ? Colors.white : const Color(0xFF374151),
                          'edit'),
                      _srvMenuItem(Icons.notifications_outlined,
                          'SEND REMINDER', const Color(0xFF3B82F6), 'remind'),
                      _srvMenuItem(Icons.check_circle_outline, 'MARK AS PAID',
                          const Color(0xFF10B981), 'paid'),
                      _srvMenuItem(Icons.delete_outline, 'DELETE ENTRY',
                          const Color(0xFFEF4444), 'delete'),
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

          // Vendor / Service name
          Text(vendor,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryOf(context))),

          if (source.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.dns_outlined,
                    size: 14, color: const Color(0xFFF59E0B)),
                const SizedBox(width: 6),
                Text(source.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF59E0B))),
              ],
            ),
          ],

          Divider(height: 20, color: AppTheme.borderOf(context)),

          // Expiry & Amount Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('EXPIRY DATE',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMutedOf(context),
                          letterSpacing: 0.3)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(renewal.formattedExpiry,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimaryOf(context))),
                      const SizedBox(width: 6),
                      Text('(${renewal.expiryLabel})',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: renewal.isExpired
                                ? const Color(0xFFEF4444)
                                : renewal.isExpiringSoon
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFF10B981),
                          )),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('EXPENSE',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMutedOf(context),
                          letterSpacing: 0.3)),
                  const SizedBox(height: 2),
                  Text('₹${renewal.amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFF59E0B))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _srvMenuItem(
      IconData icon, String label, Color color, String value) {
    return PopupMenuItem(
      value: value,
      height: 40,
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                  letterSpacing: 0.3)),
        ],
      ),
    );
  }
}

// ─── SCHEDULE SERVER RENEWAL DIALOG ──────────────────────────────────────────

class _ScheduleServerRenewalDialog extends StatefulWidget {
  final AssetRenewal? existing;
  final Function(AssetRenewal) onSave;

  const _ScheduleServerRenewalDialog({this.existing, required this.onSave});

  @override
  State<_ScheduleServerRenewalDialog> createState() =>
      _ScheduleServerRenewalDialogState();
}

class _ScheduleServerRenewalDialogState
    extends State<_ScheduleServerRenewalDialog> {
  late TextEditingController _vendorCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _sourceCtrl;
  late TextEditingController _remarksCtrl;
  ServiceCategory _category = ServiceCategory.hosting;
  RenewalStatus _status = RenewalStatus.pending;
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _vendorCtrl = TextEditingController(
        text: e?.metadata['vendor']?.toString() ?? e?.description ?? '');
    _descCtrl = TextEditingController(
        text: e?.description ?? '');
    _amountCtrl =
        TextEditingController(text: e != null ? e.amount.toString() : '');
    _sourceCtrl = TextEditingController(
        text: e?.metadata['source']?.toString() ?? '');
    _remarksCtrl = TextEditingController(
        text: e?.metadata['remarks']?.toString() ?? '');
    _category = e?.category ?? ServiceCategory.hosting;
    _status = e?.status ?? RenewalStatus.pending;
    _expiryDate =
        e?.expiryDate ?? DateTime.now().add(const Duration(days: 365));
  }

  @override
  void dispose() {
    _vendorCtrl.dispose();
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _sourceCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  void _pickExpiryDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (d != null) setState(() => _expiryDate = d);
  }

  void _save() {
    final vendor = _vendorCtrl.text.trim();
    if (vendor.isEmpty) {
      AppSnackBar.showCustom(
        context,
        const SnackBar(
            content: Text('Vendor / Service name is required'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final renewal = AssetRenewal(
      id: widget.existing?.id ?? '',
      organizationId: widget.existing?.organizationId,
      clientId: null,
      projectId: null,
      category: _category,
      description: vendor,
      amount: double.tryParse(_amountCtrl.text) ?? 0,
      expiryDate: _expiryDate,
      status: _status,
      remindersSent: widget.existing?.remindersSent ?? 0,
      lastReminderAt: widget.existing?.lastReminderAt,
      clientName: 'Ecraftz (Internal)',
      projectName: 'Infrastructure',
      metadata: {
        ...widget.existing?.metadata ?? {},
        'type': 'server',
        'vendor': vendor,
        'source': _sourceCtrl.text.trim(),
        'remarks': _remarksCtrl.text.trim(),
        'service_name': _descCtrl.text.trim().isNotEmpty
            ? _descCtrl.text.trim()
            : vendor,
      },
    );
    widget.onSave(renewal);
    Navigator.pop(context);
  }

  static InputDecoration _inp(BuildContext context, String hint,
      {required bool isDark}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
          color: isDark ? Colors.white38 : const Color(0xFF64748B),
          fontSize: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: Color(0xFFF59E0B), width: 1.5)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: isDark ? AppTheme.bgCardDark : const Color(0xFFF1F5F9),
    );
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.dns_outlined,
                      color: Color(0xFFF59E0B), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit
                            ? 'Edit Server Renewal'
                            : 'Schedule Server Renewal',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimaryOf(context),
                            letterSpacing: 0.3),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Track infrastructure expenses — hosting, VPS, domains and other server costs.',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondaryOf(context),
                            height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.cancel_outlined,
                      size: 22, color: Color(0xFFF59E0B)),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (isMobile) ...[
              _DlgLabel(context, 'VENDOR / SERVICE NAME *'),
              TextField(
                controller: _vendorCtrl,
                style: TextStyle(
                    fontSize: 13, color: AppTheme.textPrimaryOf(context)),
                decoration:
                    _inp(context, 'e.g. Hostinger, AWS, DigitalOcean', isDark: isDark),
              ),
              const SizedBox(height: 12),
              _DlgLabel(context, 'SERVICE DESCRIPTION'),
              TextField(
                controller: _descCtrl,
                style: TextStyle(
                    fontSize: 13, color: AppTheme.textPrimaryOf(context)),
                decoration: _inp(context,
                    'e.g. Premium Web Hosting - General', isDark: isDark),
              ),
              const SizedBox(height: 12),
              _DlgLabel(context, 'PLAN / SOURCE'),
              TextField(
                controller: _sourceCtrl,
                style: TextStyle(
                    fontSize: 13, color: AppTheme.textPrimaryOf(context)),
                decoration:
                    _inp(context, 'e.g. Business Plan, Premium', isDark: isDark),
              ),
              const SizedBox(height: 12),
              _DlgLabel(context, 'SERVER CATEGORY'),
              DropdownButtonFormField<ServiceCategory>(
                value: _category,
                decoration: _inp(context, 'Select Category', isDark: isDark),
                items: ServiceCategory.values
                    .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.label,
                            style: const TextStyle(fontSize: 12))))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 12),
              _DlgLabel(context, 'EXPIRY DATE'),
              GestureDetector(
                onTap: _pickExpiryDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.bgCardDark
                        : const Color(0xFFF1F5F9),
                    border: Border.all(
                        color: isDark
                            ? Colors.white10
                            : const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(DateFormat('dd-MM-yyyy').format(_expiryDate),
                          style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimaryOf(context))),
                      const Spacer(),
                      Icon(Icons.calendar_today_outlined,
                          size: 16, color: AppTheme.textMutedOf(context)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _DlgLabel(context, 'EXPENSE AMOUNT (₹)'),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(
                    fontSize: 13, color: AppTheme.textPrimaryOf(context)),
                decoration: _inp(context, '0.00', isDark: isDark),
              ),
              const SizedBox(height: 12),
              _DlgLabel(context, 'STATUS'),
              DropdownButtonFormField<RenewalStatus>(
                value: _status,
                decoration: _inp(context, 'Status', isDark: isDark),
                items: RenewalStatus.values
                    .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.label,
                            style: const TextStyle(fontSize: 12))))
                    .toList(),
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 12),
              _DlgLabel(context, 'REMARKS'),
              TextField(
                controller: _remarksCtrl,
                style: TextStyle(
                    fontSize: 13, color: AppTheme.textPrimaryOf(context)),
                decoration:
                    _inp(context, 'e.g. Auto-renewal enabled', isDark: isDark),
              ),
            ] else ...[
              // Wide layout — 2 columns
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DlgLabel(context, 'VENDOR / SERVICE NAME *'),
                        TextField(
                          controller: _vendorCtrl,
                          style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimaryOf(context)),
                          decoration: _inp(context,
                              'e.g. Hostinger, AWS, DigitalOcean',
                              isDark: isDark),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DlgLabel(context, 'SERVICE DESCRIPTION'),
                        TextField(
                          controller: _descCtrl,
                          style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimaryOf(context)),
                          decoration: _inp(
                              context, 'e.g. Premium Web Hosting - General',
                              isDark: isDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DlgLabel(context, 'PLAN / SOURCE'),
                        TextField(
                          controller: _sourceCtrl,
                          style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimaryOf(context)),
                          decoration: _inp(
                              context, 'e.g. Business Plan, Premium',
                              isDark: isDark),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DlgLabel(context, 'SERVER CATEGORY'),
                        DropdownButtonFormField<ServiceCategory>(
                          value: _category,
                          decoration: _inp(context, 'Select Category',
                              isDark: isDark),
                          items: ServiceCategory.values
                              .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c.label,
                                      style:
                                          const TextStyle(fontSize: 12))))
                              .toList(),
                          onChanged: (v) => setState(() => _category = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DlgLabel(context, 'EXPIRY DATE'),
                        GestureDetector(
                          onTap: _pickExpiryDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppTheme.bgCardDark
                                  : const Color(0xFFF1F5F9),
                              border: Border.all(
                                  color: isDark
                                      ? Colors.white10
                                      : const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Text(
                                    DateFormat('dd-MM-yyyy')
                                        .format(_expiryDate),
                                    style: TextStyle(
                                        fontSize: 13,
                                        color:
                                            AppTheme.textPrimaryOf(context))),
                                const Spacer(),
                                Icon(Icons.calendar_today_outlined,
                                    size: 16,
                                    color: AppTheme.textMutedOf(context)),
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
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DlgLabel(context, 'EXPENSE AMOUNT (₹)'),
                        TextField(
                          controller: _amountCtrl,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimaryOf(context)),
                          decoration:
                              _inp(context, '0.00', isDark: isDark),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DlgLabel(context, 'STATUS'),
                        DropdownButtonFormField<RenewalStatus>(
                          value: _status,
                          decoration:
                              _inp(context, 'Status', isDark: isDark),
                          items: RenewalStatus.values
                              .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s.label,
                                      style:
                                          const TextStyle(fontSize: 12))))
                              .toList(),
                          onChanged: (v) => setState(() => _status = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DlgLabel(context, 'REMARKS'),
                        TextField(
                          controller: _remarksCtrl,
                          style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimaryOf(context)),
                          decoration: _inp(
                              context, 'e.g. Auto-renewal enabled',
                              isDark: isDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: Text(
                  isEdit
                      ? 'UPDATE SERVER RENEWAL'
                      : 'SCHEDULE SERVER RENEWAL',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── STAT CARD ─────────────────────────────────────────────────────────────


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
      this.iconColor, this.bgColor,
      {this.valueColor, this.valueLarge = false});
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
        border: Border.all(
            color: isDark
                ? AppTheme.borderOf(context)
                : data.iconColor.withValues(alpha: 0.15)),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ],
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
              style: TextStyle(
                  fontSize: 11, color: AppTheme.textSecondaryOf(context))),
        ],
      ),
    );
  }
}

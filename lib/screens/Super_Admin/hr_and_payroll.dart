import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../theme/app_theme.dart';
import '../../blocs/theme/theme_bloc.dart';
import '../../widgets/app_drawer.dart';
import '../../services/supabase_service.dart';

// ─── MODELS ───────────────────────────────────────────────────────────────────


class Employee {
  final String id;
  final String profileId;
  final String name;
  final String department;
  final String departmentId;
  final String role;
  final DateTime joinDate;
  final double kpiScore;
  final double baseSalary;

  const Employee({
    required this.id,
    required this.profileId,
    required this.name,
    required this.department,
    required this.departmentId,
    required this.role,
    required this.joinDate,
    required this.kpiScore,
    required this.baseSalary,
  });

  factory Employee.fromSupabase(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>? ?? {};
    final dept = map['departments'] as Map<String, dynamic>? ?? {};
    final payrolls = profile['payroll'] as List? ?? [];
    final payroll = payrolls.isNotEmpty ? payrolls.first as Map<String, dynamic> : {};

    double baseSal = 0.0;
    if (payroll['net_pay'] != null) {
      baseSal = (payroll['net_pay'] is num)
          ? (payroll['net_pay'] as num).toDouble()
          : double.tryParse(payroll['net_pay'].toString()) ?? 0.0;
    }

    final String fullName = profile['full_name']?.toString() ?? 'Unknown';
    final String role = profile['role']?.toString() ?? 'Employee';
    final String deptName = dept['name']?.toString() ?? 'None';
    final String deptId = dept['id']?.toString() ?? '';
    final String profId = profile['id']?.toString() ?? '';
    final String dmId = map['id']?.toString() ?? '';
    final String joinDateStr = profile['created_at']?.toString() ?? '';
    final DateTime joinDate = joinDateStr.isNotEmpty ? DateTime.parse(joinDateStr) : DateTime.now();

    return Employee(
      id: dmId,
      profileId: profId,
      name: fullName,
      department: deptName,
      departmentId: deptId,
      role: role,
      joinDate: joinDate,
      kpiScore: 100.0,
      baseSalary: baseSal,
    );
  }
}

class AttendanceRecord {
  final String id;
  final String employeeName;
  final DateTime date;
  final String? clockIn;
  final String? clockOut;
  final bool isPresent;

  const AttendanceRecord({
    required this.id,
    required this.employeeName,
    required this.date,
    this.clockIn,
    this.clockOut,
    required this.isPresent,
  });
}

class LeaveRequest {
  final String id;
  final String employeeName;
  final String profileId;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String status; // pending, approved, rejected
  final String? rejectionNote;

  const LeaveRequest({
    required this.id,
    required this.employeeName,
    required this.profileId,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    this.rejectionNote,
  });

  factory LeaveRequest.fromSupabase(Map<String, dynamic> map, {String? rejectionNote}) {
    final profile = (map['profiles!user_id'] as Map<String, dynamic>?) ?? (map['profiles'] as Map<String, dynamic>?) ?? (map['profiles!leave_requests_user_profile_fk_v2'] as Map<String, dynamic>?) ?? {};
    final String fullName = profile['full_name']?.toString() ?? 'Unknown';
    final String profId = profile['id']?.toString() ?? '';
    final String id = map['id']?.toString() ?? '';
    
    final leaveTypes = map['leave_types'] as Map<String, dynamic>?;
    final String leaveType = leaveTypes?['name']?.toString() ?? map['leave_type']?.toString() ?? 'Annual Leave';
    
    final String reason = map['reason']?.toString() ?? '';
    final String status = map['status']?.toString() ?? 'pending';

    final String startStr = map['start_date']?.toString() ?? '';
    final String endStr = map['end_date']?.toString() ?? '';
    final DateTime startDate = startStr.isNotEmpty ? DateTime.parse(startStr) : DateTime.now();
    final DateTime endDate = endStr.isNotEmpty ? DateTime.parse(endStr) : DateTime.now();

    return LeaveRequest(
      id: id,
      employeeName: fullName,
      profileId: profId,
      leaveType: leaveType,
      startDate: startDate,
      endDate: endDate,
      reason: reason,
      status: status,
      rejectionNote: rejectionNote,
    );
  }
}


List<LeaveRequest> sampleLeaves = [];


// ─── THEME ────────────────────────────────────────────────────────────────────

class HRTheme {
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

  static Color backgroundOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? AppTheme.bgBaseDark : const Color(0xFFF8FAFC);

  static Color cardBgOf(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  static Color textPrimaryOf(BuildContext context) =>
      AppTheme.textPrimaryOf(context);

  static Color textSecondaryOf(BuildContext context) =>
      AppTheme.textSecondaryOf(context);

  static Color borderOf(BuildContext context) =>
      AppTheme.borderOf(context);

  static Color statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'present': return success;
      case 'absent': return danger;
      case 'approved': return success;
      case 'rejected': return danger;
      case 'pending': return warning;
      default: return purple;
    }
  }

}

// ─── MAIN SCREEN ──────────────────────────────────────────────────────────────

class HRPayrollScreen extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const HRPayrollScreen({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  State<HRPayrollScreen> createState() => _HRPayrollScreenState();
}

class _HRPayrollScreenState extends State<HRPayrollScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  int _activeTab = 0;
  String _searchQuery = '';
  final _currencyFmt = NumberFormat('#,##0', 'en_IN');

  final _client = SupabaseService.client;
  List<Employee> _employees = [];
  List<LeaveRequest> _leaves = [];
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _profiles = [];
  List<Map<String, dynamic>> _leaveTypes = [];
  bool _isLoadingEmployees = true;
  bool _isLoadingLeaves = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _activeTab = _tabController.index);
      }
    });
    _fetchDepartments();
    _fetchEmployees();
    _fetchLeaves();
    _fetchProfiles();
    _fetchLeaveTypes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfiles() async {
    try {
      final res = await _client.from('profiles').select('id, full_name, role');
      setState(() {
        _profiles = (res as List).map((x) => x as Map<String, dynamic>).toList();
      });
    } catch (e) {
      debugPrint('Error fetching profiles: $e');
    }
  }

  Future<void> _fetchLeaveTypes() async {
    try {
      final res = await _client.from('leave_types').select('id, name');
      setState(() {
        _leaveTypes = (res as List).map((x) => x as Map<String, dynamic>).toList();
      });
    } catch (e) {
      debugPrint('Error fetching leave types: $e');
    }
  }

  Future<void> _fetchDepartments() async {
    try {
      final res = await _client.from('departments').select('id, name');
      setState(() {
        _departments = (res as List).map((x) => x as Map<String, dynamic>).toList();
      });
    } catch (e) {
      debugPrint('Error fetching departments: $e');
    }
  }

  Future<void> _fetchEmployees() async {
    setState(() => _isLoadingEmployees = true);
    try {
      final res = await _client
          .from('department_members')
          .select('*, profiles(id, full_name, email, role, status, payroll(net_pay)), departments(id, name)');
      final list = (res as List)
          .where((x) {
            final profile = x['profiles'] as Map<String, dynamic>? ?? {};
            final status = profile['status']?.toString().toLowerCase() ?? 'active';
            return status != 'archived' && status != 'inactive';
          })
          .map((x) => Employee.fromSupabase(x as Map<String, dynamic>))
          .toList();
      setState(() {
        _employees = list;
        _isLoadingEmployees = false;
      });
    } catch (e) {
      setState(() => _isLoadingEmployees = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load employees: $e'), backgroundColor: HRTheme.danger),
      );
    }
  }

  Future<void> _fetchLeaves() async {
    setState(() => _isLoadingLeaves = true);
    try {
      final resLeaves = await _client
          .from('leave_requests')
          .select('*, profiles!user_id(id, full_name), leave_types(name)');
      final resActions = await _client
          .from('leave_request_actions')
          .select('*');

      final actionsList = List<Map<String, dynamic>>.from(resActions as List);
      // Sort by created_at ascending so that the latest action is stored last
      actionsList.sort((a, b) {
        final aTime = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aTime.compareTo(bTime);
      });

      final actionsMap = <String, Map<String, dynamic>>{};
      for (final act in actionsList) {
        final leaveId = act['leave_request_id']?.toString() ?? '';
        actionsMap[leaveId] = act;
      }

      final list = (resLeaves as List).map((x) {
        final map = x as Map<String, dynamic>;
        final String id = map['id']?.toString() ?? '';
        final actionData = actionsMap[id];
        final String? rejectionNote = actionData != null ? actionData['note']?.toString() : null;

        return LeaveRequest.fromSupabase(map, rejectionNote: rejectionNote);
      }).toList();

      setState(() {
        _leaves = list;
        _isLoadingLeaves = false;
      });
    } catch (e) {
      setState(() => _isLoadingLeaves = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load leaves: $e'), backgroundColor: HRTheme.danger),
      );
    }
  }

  String _fmt(double v) => '₹${_currencyFmt.format(v)}';

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isTablet = w >= 600;

    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(
        selectedIndex: widget.selectedIndex,
        onItemSelected: widget.onItemSelected,
      ),
      backgroundColor: HRTheme.backgroundOf(context),
      floatingActionButton: _activeTab == 1
          ? FloatingActionButton(
              backgroundColor: HRTheme.primary,
              onPressed: _showLeaveRequestSheet,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isTablet),
            _buildTabBar(isTablet),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _DirectoryTab(
                    employees: _employees,
                    searchQuery: _searchQuery,
                    onSearchChanged: (v) => setState(() => _searchQuery = v),
                    isTablet: isTablet,
                    fmtSalary: _fmt,
                    onRefresh: _fetchEmployees,
                    onEdit: _showEditEmployeeSheet,
                    onDelete: _confirmDeleteEmployee,
                    isLoading: _isLoadingEmployees,
                  ),
                  _TimeLeaveTab(
                    leaves: _leaves,
                    isTablet: isTablet,
                    onRequestLeave: _showLeaveRequestSheet,
                    onApproveLeave: (lr) => _updateLeaveStatus(lr, 'approved'),
                    onRejectLeave: _showRejectionDialog,
                    isLoading: _isLoadingLeaves,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isTablet) {
    final _cardBg = HRTheme.cardBgOf(context);
    final _textPrimary = HRTheme.textPrimaryOf(context);
    final _textSecondary = HRTheme.textSecondaryOf(context);

    return Container(
      color: _cardBg,
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (!isTablet) ...[
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.menu, size: 18, color: _textSecondary),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              const SizedBox(width: 10),
            ],
            Icon(Icons.grid_view_rounded, size: 13, color: _textSecondary),
            const SizedBox(width: 4),
            _crumb('Dashboard', false),
            Icon(Icons.chevron_right, size: 15, color: _textSecondary),
            _crumb('HR', true),
            const Spacer(),
            BlocBuilder<ThemeBloc, ThemeState>(
              builder: (context, state) {
                final isDark = state.themeMode == ThemeMode.dark;
                return IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    isDark ? Icons.light_mode : Icons.dark_mode,
                    size: 18,
                    color: isDark ? Colors.amber : Colors.blueGrey,
                  ),
                  onPressed: () {
                    context.read<ThemeBloc>().add(ToggleThemeEvent());
                  },
                );
              },
            ),
          ]),
          const SizedBox(height: 8),
          Text('HR & Employee Management',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _textPrimary)),
          const SizedBox(height: 3),
          Text('Manage your team, track attendance, and approve leaves.',
              style: TextStyle(fontSize: 12, color: _textSecondary)),
        ],
      ),
    );
  }

  Widget _crumb(String label, bool active) {
    final _textSecondary = HRTheme.textSecondaryOf(context);
    return Text(label,
      style: TextStyle(fontSize: 12,
          color: active ? HRTheme.primary : _textSecondary,
          fontWeight: active ? FontWeight.w600 : FontWeight.normal));
  }

  // ── TAB BAR ─────────────────────────────────────────────────────────────────

  Widget _buildTabBar(bool isTablet) {
    final _cardBg = HRTheme.cardBgOf(context);
    final _textSecondary = HRTheme.textSecondaryOf(context);
    final _border = HRTheme.borderOf(context);

    final tabs = [
      _TabItem(Icons.people_alt_rounded, 'Directory'),
      _TabItem(Icons.access_time_rounded, 'Time & Leave'),
    ];
    return Container(
      color: _cardBg,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.asMap().entries.map((e) {
          final selected = _activeTab == e.key;
          return GestureDetector(
            onTap: () {
              _tabController.animateTo(e.key);
              setState(() => _activeTab = e.key);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 6),
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 12, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? HRTheme.primary.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: selected ? HRTheme.primary : _border,
                    width: selected ? 1.5 : 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(e.value.icon, size: 14,
                    color: selected ? HRTheme.primary : _textSecondary),
                const SizedBox(width: 5),
                Text(e.value.label,
                    style: TextStyle(fontSize: 12,
                        color: selected ? HRTheme.primary : _textSecondary,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.normal)),
              ]),
            ),
          );
        }).toList(),
        ),
      ),
    );
  }

  // ── ACTIONS ─────────────────────────────────────────────────────────────────

  void _handleClockIn(AttendanceRecord record) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${record.employeeName} clocked out!'),
          backgroundColor: HRTheme.success),
    );
  }

  Future<void> _updateLeaveStatus(LeaveRequest lr, String newStatus, {String? note}) async {
    try {
      await _client.from('leave_requests').update({
        'status': newStatus,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', lr.id);

      final currentUserId = _client.auth.currentUser?.id;
      await _client.from('leave_request_actions').insert({
        'leave_request_id': lr.id,
        'actor_id': currentUserId ?? '00000000-0000-0000-0000-000000000000',
        'action': newStatus,
        'note': note ?? (newStatus == 'approved' ? 'Approved by HR' : 'Rejected by HR'),
      });

      _fetchLeaves();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Leave request $newStatus!'), backgroundColor: HRTheme.success),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update leave status: $e'), backgroundColor: HRTheme.danger),
      );
    }
  }

  void _showRejectionDialog(LeaveRequest lr) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        final _cardBg = HRTheme.cardBgOf(ctx);
        final _textPrimary = HRTheme.textPrimaryOf(ctx);
        final _textSecondary = HRTheme.textSecondaryOf(ctx);
        final _border = HRTheme.borderOf(ctx);

        return AlertDialog(
          backgroundColor: _cardBg,
          title: Text('Reject Leave Request', style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Please enter the reason for rejecting this leave request:', style: TextStyle(color: _textSecondary, fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                style: TextStyle(color: _textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Enter rejection reason...',
                  hintStyle: TextStyle(color: _textSecondary, fontSize: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: HRTheme.danger, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(10),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: _textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: HRTheme.danger),
              onPressed: () {
                if (noteCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a rejection reason'), backgroundColor: HRTheme.danger),
                  );
                  return;
                }
                Navigator.pop(ctx);
                _updateLeaveStatus(lr, 'rejected', note: noteCtrl.text.trim());
              },
              child: const Text('Reject Request', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showLeaveRequestSheet() {
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 1));
    final reasonCtrl = TextEditingController();
    String? selectedUserId = _profiles.isNotEmpty ? _profiles.first['id']?.toString() : null;
    String? selectedLeaveTypeId = _leaveTypes.isNotEmpty ? _leaveTypes.first['id']?.toString() : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final _cardBgModal = HRTheme.cardBgOf(ctx);
          final _textPrimaryModal = HRTheme.textPrimaryOf(ctx);
          final _textSecondaryModal = HRTheme.textSecondaryOf(ctx);
          final _borderModal = HRTheme.borderOf(ctx);

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(
                  color: _cardBgModal,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sheetHandle(ctx),
                    Text('Apply Leave (On Behalf)',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _textPrimaryModal)),
                    const SizedBox(height: 4),
                    Text('Directly apply leave on behalf of an employee or boss.',
                        style: TextStyle(fontSize: 12, color: _textSecondaryModal)),
                    const SizedBox(height: 18),
                    _fieldLabel(ctx, 'Employee / Boss'),
                    Container(
                      decoration: BoxDecoration(
                          border: Border.all(color: _borderModal),
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedUserId,
                          isExpanded: true,
                          dropdownColor: _cardBgModal,
                          items: _profiles.map((p) {
                            final name = p['full_name']?.toString() ?? 'Unknown';
                            final role = p['role']?.toString() ?? '';
                            final label = role.isNotEmpty ? '$name ($role)' : name;
                            return DropdownMenuItem(
                              value: p['id']?.toString(),
                              child: Text(label, style: TextStyle(color: _textPrimaryModal, fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (v) => setModalState(() => selectedUserId = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _fieldLabel(ctx, 'Leave Type'),
                    Container(
                      decoration: BoxDecoration(
                          border: Border.all(color: HRTheme.primary, width: 1.5),
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedLeaveTypeId,
                          isExpanded: true,
                          dropdownColor: _cardBgModal,
                          style: TextStyle(fontSize: 14, color: _textPrimaryModal),
                          items: _leaveTypes.map((t) => DropdownMenuItem(
                              value: t['id']?.toString(),
                              child: Text(t['name']?.toString() ?? '', style: TextStyle(color: _textPrimaryModal)))).toList(),
                          onChanged: (v) => setModalState(() => selectedLeaveTypeId = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _fieldLabel(ctx, 'Start Date'),
                        _datePicker(ctx, startDate, (d) => setModalState(() => startDate = d)),
                      ])),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _fieldLabel(ctx, 'End Date'),
                        _datePicker(ctx, endDate, (d) => setModalState(() => endDate = d)),
                      ])),
                    ]),
                    const SizedBox(height: 14),
                    _fieldLabel(ctx, 'Reason'),
                    TextField(
                      controller: reasonCtrl,
                      maxLines: 3,
                      style: TextStyle(color: _textPrimaryModal),
                      decoration: InputDecoration(
                        hintText: 'Explain the reason for leave...',
                        hintStyle: TextStyle(color: _textSecondaryModal, fontSize: 13),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: _borderModal),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: HRTheme.primary, width: 1.5),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: _borderModal)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HRTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          if (selectedUserId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select an employee'), backgroundColor: HRTheme.danger),
                            );
                            return;
                          }
                          if (selectedLeaveTypeId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select a leave type'), backgroundColor: HRTheme.danger),
                            );
                            return;
                          }
                          try {
                            await _client.from('leave_requests').insert({
                              'user_id': selectedUserId,
                              'leave_type_id': selectedLeaveTypeId,
                              'start_date': DateFormat('yyyy-MM-dd').format(startDate),
                              'end_date': DateFormat('yyyy-MM-dd').format(endDate),
                              'reason': reasonCtrl.text,
                              'status': 'approved',
                              'organization_id': '00000000-0000-0000-0000-000000000000',
                            });
                            Navigator.pop(ctx);
                            _fetchLeaves();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Leave applied successfully!'), backgroundColor: HRTheme.success),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to apply leave: $e'), backgroundColor: HRTheme.danger),
                            );
                          }
                        },
                        child: const Text('Apply Leave',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _datePicker(BuildContext ctx, DateTime date, Function(DateTime) onPicked) {
    final _textPrimary = HRTheme.textPrimaryOf(ctx);
    final _textSecondary = HRTheme.textSecondaryOf(ctx);
    final _border = HRTheme.borderOf(ctx);

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: ctx,
          initialDate: date,
          firstDate: DateTime(2024),
          lastDate: DateTime(2028),
          builder: (_, child) => Theme(
            data: Theme.of(ctx).brightness == Brightness.dark
                ? ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(
                        primary: HRTheme.primary,
                        onPrimary: Colors.white,
                        surface: AppTheme.bgCardDark,
                        onSurface: Colors.white))
                : ThemeData.light().copyWith(
                    colorScheme: const ColorScheme.light(
                        primary: HRTheme.primary,
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: HRTheme.textPrimary)),
            child: child!,
          ),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Icon(Icons.calendar_today_rounded, size: 14, color: _textSecondary),
          const SizedBox(width: 8),
          Text(DateFormat('dd-MM-yyyy').format(date),
              style: TextStyle(fontSize: 13, color: _textPrimary)),
        ]),
      ),
    );
  }

  void _showAddEmployeeSheet() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String selectedRole = 'employee';
    final salaryCtrl = TextEditingController();
    String? selectedDeptId = _departments.isNotEmpty ? _departments.first['id']?.toString() : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final _cardBgModal = HRTheme.cardBgOf(context);
            final _textPrimaryModal = HRTheme.textPrimaryOf(context);
            final _borderModal = HRTheme.borderOf(context);

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                decoration: BoxDecoration(
                    color: _cardBgModal,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _sheetHandle(context),
                    Text('Add Employee',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _textPrimaryModal)),
                    const SizedBox(height: 16),
                    _inputField(context, nameCtrl, 'Full Name', Icons.person_rounded),
                    const SizedBox(height: 10),
                    _inputField(context, emailCtrl, 'Email Address', Icons.email_rounded),
                    const SizedBox(height: 10),
                    _fieldLabel(context, 'Department'),
                    Container(
                      decoration: BoxDecoration(
                          border: Border.all(color: _borderModal),
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedDeptId,
                          isExpanded: true,
                          dropdownColor: _cardBgModal,
                          items: _departments.map((d) => DropdownMenuItem(
                            value: d['id']?.toString(),
                            child: Text(d['name']?.toString() ?? '', style: TextStyle(color: _textPrimaryModal)),
                          )).toList(),
                          onChanged: (v) => setModalState(() => selectedDeptId = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _fieldLabel(context, 'Role'),
                    Container(
                      decoration: BoxDecoration(
                          border: Border.all(color: _borderModal),
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedRole,
                          isExpanded: true,
                          dropdownColor: _cardBgModal,
                          items: const [
                            DropdownMenuItem(
                              value: 'employee',
                              child: Text('Employee', style: TextStyle(fontSize: 13)),
                            ),
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('Admin', style: TextStyle(fontSize: 13)),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setModalState(() => selectedRole = v);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _inputField(context, salaryCtrl, 'Base Salary (₹)', Icons.currency_rupee, isNumber: true),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HRTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          if (nameCtrl.text.isEmpty || selectedDeptId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter name and select a department'), backgroundColor: HRTheme.danger),
                            );
                            return;
                          }
                          Navigator.pop(context);
                          final double sal = double.tryParse(salaryCtrl.text) ?? 0.0;
                          await _addEmployee(nameCtrl.text, emailCtrl.text, selectedRole, sal, selectedDeptId!);
                        },
                        child: const Text('Add Employee',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                  ]),
                ),
              ),
            );
          }
        );
      },
    );
  }

  Future<void> _addEmployee(String name, String email, String role, double salary, String deptId) async {
    try {
      final profileRes = await _client.from('profiles').insert({
        'full_name': name,
        'email': email.isEmpty ? '${name.toLowerCase().replaceAll(' ', '')}@ecraftz.com' : email,
        'role': role,
        'status': 'active',
        'organization_id': '00000000-0000-0000-0000-000000000000',
      }).select();
      
      if ((profileRes as List).isEmpty) {
        throw Exception('Failed to create user profile');
      }
      final newProfileId = profileRes.first['id'];

      await _client.from('department_members').insert({
        'profile_id': newProfileId,
        'department_id': deptId,
      });

      final now = DateTime.now();
      final currentMonth = DateFormat('MMMM').format(now);
      final currentYear = now.year;

      await _client.from('payroll').insert({
        'user_id': newProfileId,
        'net_pay': salary,
        'allowances': 0,
        'deductions': 0,
        'status': 'draft',
        'month': currentMonth,
        'year': currentYear,
        'organization_id': '00000000-0000-0000-0000-000000000000',
      });

      _fetchEmployees();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee added successfully!'), backgroundColor: HRTheme.success),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add employee: $e'), backgroundColor: HRTheme.danger),
      );
    }
  }

  void _showEditEmployeeSheet(Employee emp) {
    final nameCtrl = TextEditingController(text: emp.name);
    String selectedRole = emp.role.toLowerCase() == 'admin' ? 'admin' : 'employee';
    final salaryCtrl = TextEditingController(text: emp.baseSalary.toStringAsFixed(0));
    String? selectedDeptId = emp.departmentId.isNotEmpty ? emp.departmentId : (_departments.isNotEmpty ? _departments.first['id']?.toString() : null);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final _cardBgModal = HRTheme.cardBgOf(context);
            final _textPrimaryModal = HRTheme.textPrimaryOf(context);
            final _borderModal = HRTheme.borderOf(context);

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                decoration: BoxDecoration(
                    color: _cardBgModal,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _sheetHandle(context),
                    Text('Edit Employee',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _textPrimaryModal)),
                    const SizedBox(height: 16),
                    _inputField(context, nameCtrl, 'Full Name', Icons.person_rounded),
                    const SizedBox(height: 10),
                    _fieldLabel(context, 'Department'),
                    Container(
                      decoration: BoxDecoration(
                          border: Border.all(color: _borderModal),
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedDeptId,
                          isExpanded: true,
                          dropdownColor: _cardBgModal,
                          items: _departments.map((d) => DropdownMenuItem(
                            value: d['id']?.toString(),
                            child: Text(d['name']?.toString() ?? '', style: TextStyle(color: _textPrimaryModal)),
                          )).toList(),
                          onChanged: (v) => setModalState(() => selectedDeptId = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _fieldLabel(context, 'Role'),
                    Container(
                      decoration: BoxDecoration(
                          border: Border.all(color: _borderModal),
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedRole,
                          isExpanded: true,
                          dropdownColor: _cardBgModal,
                          items: const [
                            DropdownMenuItem(
                              value: 'employee',
                              child: Text('Employee', style: TextStyle(fontSize: 13)),
                            ),
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('Admin', style: TextStyle(fontSize: 13)),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setModalState(() => selectedRole = v);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _inputField(context, salaryCtrl, 'Base Salary (₹)', Icons.currency_rupee, isNumber: true),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HRTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          final double sal = double.tryParse(salaryCtrl.text) ?? 0.0;
                          await _editEmployee(emp, nameCtrl.text, selectedRole, sal, selectedDeptId);
                        },
                        child: const Text('Update Employee',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                  ]),
                ),
              ),
            );
          }
        );
      },
    );
  }

  Future<void> _editEmployee(Employee emp, String name, String role, double salary, String? deptId) async {
    try {
      await _client.from('profiles').update({
        'full_name': name,
        'role': role,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', emp.profileId);

      if (deptId != null) {
        await _client.from('department_members').update({
          'department_id': deptId,
        }).eq('id', emp.id);
      }

      final now = DateTime.now();
      final currentMonth = DateFormat('MMMM').format(now);
      final currentYear = now.year;

      final payrolls = await _client.from('payroll').select().eq('user_id', emp.profileId);
      if ((payrolls as List).isEmpty) {
        await _client.from('payroll').insert({
          'user_id': emp.profileId,
          'net_pay': salary,
          'allowances': 0,
          'deductions': 0,
          'status': 'draft',
          'month': currentMonth,
          'year': currentYear,
          'organization_id': '00000000-0000-0000-0000-000000000000',
        });
      } else {
        final payId = payrolls.first['id'];
        await _client.from('payroll').update({
          'net_pay': salary,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', payId);
      }

      _fetchEmployees();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee updated successfully!'), backgroundColor: HRTheme.success),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update employee: $e'), backgroundColor: HRTheme.danger),
      );
    }
  }

  void _confirmDeleteEmployee(Employee emp) {
    showDialog(
      context: context,
      builder: (ctx) {
        final _cardBg = HRTheme.cardBgOf(ctx);
        final _textPrimary = HRTheme.textPrimaryOf(ctx);
        final _textSecondary = HRTheme.textSecondaryOf(ctx);

        return AlertDialog(
          backgroundColor: _cardBg,
          title: Text('Delete Employee', style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to remove ${emp.name} from the directory?', style: TextStyle(color: _textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: _textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: HRTheme.danger),
              onPressed: () async {
                Navigator.pop(ctx);
                await _deleteEmployee(emp);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteEmployee(Employee emp) async {
    try {
      await _client.from('profiles').update({
        'status': 'archived',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', emp.profileId);

      _fetchEmployees();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee deleted successfully!'), backgroundColor: HRTheme.success),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete employee: $e'), backgroundColor: HRTheme.danger),
      );
    }
  }

  // ── HELPERS ─────────────────────────────────────────────────────────────────

  Widget _sheetHandle(BuildContext ctx) {
    final _border = HRTheme.borderOf(ctx);
    return Center(
      child: Container(
        width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)),
      ),
    );
  }

  Widget _fieldLabel(BuildContext ctx, String label) {
    final _textSecondary = HRTheme.textSecondaryOf(ctx);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
          color: _textSecondary, letterSpacing: 0.3)),
    );
  }

  Widget _inputField(BuildContext ctx, TextEditingController ctrl, String hint, IconData icon,
      {bool isNumber = false}) {
    final _textPrimary = HRTheme.textPrimaryOf(ctx);
    final _textSecondary = HRTheme.textSecondaryOf(ctx);
    final _border = HRTheme.borderOf(ctx);

    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: _textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: _textSecondary),
        prefixIcon: Icon(icon, size: 16, color: _textSecondary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: HRTheme.primary, width: 1.5),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _border)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      ),
    );
  }
}

// ─── TAB 1: DIRECTORY ────────────────────────────────────────────────────────

class _DirectoryTab extends StatelessWidget {
  final List<Employee> employees;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final bool isTablet;
  final String Function(double) fmtSalary;
  final VoidCallback onRefresh;
  final Function(Employee) onEdit;
  final Function(Employee) onDelete;
  final bool isLoading;

  const _DirectoryTab({
    required this.employees,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.isTablet,
    required this.fmtSalary,
    required this.onRefresh,
    required this.onEdit,
    required this.onDelete,
    required this.isLoading,
  });

  List<Employee> get filtered => employees.where((e) =>
      e.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
      e.department.toLowerCase().contains(searchQuery.toLowerCase()) ||
      e.role.toLowerCase().contains(searchQuery.toLowerCase())).toList();

  @override
  Widget build(BuildContext context) {
    final _cardBg = HRTheme.cardBgOf(context);
    final _textPrimary = HRTheme.textPrimaryOf(context);
    final _textSecondary = HRTheme.textSecondaryOf(context);
    final _border = HRTheme.borderOf(context);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(isTablet ? 16 : 12),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _border),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
                  ),
                  child: TextField(
                    onChanged: onSearchChanged,
                    style: TextStyle(color: _textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search employees by name, department, or designation...',
                      hintStyle: TextStyle(fontSize: 12, color: _textSecondary),
                      prefixIcon: Icon(Icons.search_rounded, size: 18, color: _textSecondary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onRefresh,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    border: Border.all(color: _border),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.refresh_rounded, size: 15, color: _textSecondary),
                    if (isTablet) ...[
                      const SizedBox(width: 5),
                      Text('Refresh Directory',
                          style: TextStyle(fontSize: 12, color: _textSecondary)),
                    ],
                  ]),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(HRTheme.primary),
                  ),
                )
              : isTablet
                  ? _buildTable(context)
                  : _buildCards(context),
        ),
      ],
    );
  }

  Widget _buildTable(BuildContext context) {
    final cols = ['EMPLOYEE', 'DEPARTMENT & ROLE', 'JOIN DATE', 'KPI SCORE', 'BASE SALARY', 'ACTIONS'];
    final flexes = [3, 3, 2, 2, 2, 2];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final _cardBg = HRTheme.cardBgOf(context);
    final _textSecondary = HRTheme.textSecondaryOf(context);
    final _border = HRTheme.borderOf(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: cols.asMap().entries.map((e) => Expanded(
                flex: flexes[e.key],
                child: Text(e.value,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                        color: _textSecondary, letterSpacing: 0.5)),
              )).toList(),
            ),
          ),
          Divider(height: 1, color: _border),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text('No employees found matching your search.',
                  style: TextStyle(fontSize: 13, color: _textSecondary)),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: _border),
                itemBuilder: (ctx, i) => _tableRow(ctx, filtered[i], flexes),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tableRow(BuildContext ctx, Employee emp, List<int> flexes) {
    final _textPrimary = HRTheme.textPrimaryOf(ctx);
    final _textSecondary = HRTheme.textSecondaryOf(ctx);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: flexes[0], child: Row(children: [
            _empAvatar(ctx, emp.name, 32),
            const SizedBox(width: 8),
            Expanded(child: Text(emp.name,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textPrimary),
                overflow: TextOverflow.ellipsis)),
          ])),
          Expanded(flex: flexes[1], child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(emp.department, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textPrimary), overflow: TextOverflow.ellipsis),
            Text(emp.role, style: TextStyle(fontSize: 11, color: _textSecondary), overflow: TextOverflow.ellipsis),
          ])),
          Expanded(flex: flexes[2], child: Text(DateFormat('dd MMM yyyy').format(emp.joinDate),
              style: TextStyle(fontSize: 12, color: _textSecondary))),
          Expanded(flex: flexes[3], child: _kpiChip(emp.kpiScore)),
          Expanded(flex: flexes[4], child: Text(fmtSalary(emp.baseSalary),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textPrimary))),
          Expanded(flex: flexes[5], child: Row(children: [
            _iconBtn(Icons.edit_rounded, HRTheme.primary, () => onEdit(emp)),
            const SizedBox(width: 6),
            _iconBtn(Icons.delete_rounded, HRTheme.danger, () => onDelete(emp)),
          ])),
        ],
      ),
    );
  }

  Widget _buildCards(BuildContext context) {
    final _textSecondary = HRTheme.textSecondaryOf(context);

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text('No employees found matching your search.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _textSecondary)),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) => _employeeCard(ctx, filtered[i]),
    );
  }

  Widget _employeeCard(BuildContext ctx, Employee emp) {
    final _cardBg = HRTheme.cardBgOf(ctx);
    final _textPrimary = HRTheme.textPrimaryOf(ctx);
    final _textSecondary = HRTheme.textSecondaryOf(ctx);
    final _border = HRTheme.borderOf(ctx);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
      ),
      child: Row(
        children: [
          _empAvatar(ctx, emp.name, 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(emp.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textPrimary)),
              const SizedBox(height: 2),
              Text('${emp.department} • ${emp.role}',
                  style: TextStyle(fontSize: 11, color: _textSecondary), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Wrap(spacing: 8, runSpacing: 4, children: [
                _kpiChip(emp.kpiScore),
                _infoChip(ctx, DateFormat('dd MMM yyyy').format(emp.joinDate), Icons.calendar_today_rounded),
                _infoChip(ctx, fmtSalary(emp.baseSalary), Icons.currency_rupee),
              ]),
            ]),
          ),
          Column(children: [
            _iconBtn(Icons.edit_rounded, HRTheme.primary, () => onEdit(emp)),
            const SizedBox(height: 6),
            _iconBtn(Icons.delete_rounded, HRTheme.danger, () => onDelete(emp)),
          ]),
        ],
      ),
    );
  }

  Widget _empAvatar(BuildContext ctx, String name, double size) {
    final initials = name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join();
    final colors = [HRTheme.primary, HRTheme.purple, HRTheme.success, HRTheme.warning];
    final color = colors[name.codeUnitAt(0) % colors.length];
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(size * 0.25)),
      child: Center(child: Text(initials,
          style: TextStyle(fontSize: size * 0.35, fontWeight: FontWeight.w700, color: color))),
    );
  }

  Widget _kpiChip(double score) {
    final color = score >= 90 ? HRTheme.success : score >= 75 ? HRTheme.warning : HRTheme.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text('KPI: ${score.toInt()}',
          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
    );
  }

  Widget _infoChip(BuildContext ctx, String label, IconData icon) {
    final _textSecondary = HRTheme.textSecondaryOf(ctx);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 10, color: _textSecondary),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(fontSize: 10, color: _textSecondary)),
    ]);
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}

// ─── TAB 2: TIME & LEAVE ─────────────────────────────────────────────────────

class _TimeLeaveTab extends StatelessWidget {
  final List<LeaveRequest> leaves;
  final bool isTablet;
  final VoidCallback onRequestLeave;
  final Function(LeaveRequest) onApproveLeave;
  final Function(LeaveRequest) onRejectLeave;
  final bool isLoading;

  const _TimeLeaveTab({
    required this.leaves,
    required this.isTablet,
    required this.onRequestLeave,
    required this.onApproveLeave,
    required this.onRejectLeave,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      child: _leaveSection(context),
    );
  }

  Widget _leaveSection(BuildContext ctx) {
    final _cardBg = HRTheme.cardBgOf(ctx);
    final _textPrimary = HRTheme.textPrimaryOf(ctx);
    final _textSecondary = HRTheme.textSecondaryOf(ctx);
    final _border = HRTheme.borderOf(ctx);

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: HRTheme.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.calendar_month_rounded, color: HRTheme.purple, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text('Leave Requests',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textPrimary))),
            ]),
          ),
          Divider(height: 1, color: _border),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(HRTheme.purple),
                ),
              ),
            )
          else if (leaves.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              child: Column(children: [
                const Icon(Icons.event_busy_rounded, size: 28, color: Color(0xFF94A3B8)),
                const SizedBox(height: 8),
                Text('No leave requests found.',
                    style: TextStyle(fontSize: 13, color: _textSecondary)),
              ]),
            )
          else
            ...leaves.map((lr) => _leaveRow(ctx, lr)),
        ],
      ),
    );
  }

  Widget _leaveRow(BuildContext ctx, LeaveRequest lr) {
    final statusColor = HRTheme.statusColor(lr.status);
    final _textPrimary = HRTheme.textPrimaryOf(ctx);
    final _textSecondary = HRTheme.textSecondaryOf(ctx);
    final _border = HRTheme.borderOf(ctx);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: _border))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(lr.employeeName,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textPrimary))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
            child: Text(lr.status.toUpperCase(),
                style: TextStyle(fontSize: 9, color: statusColor, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 4),
        Text('${lr.leaveType} • ${DateFormat('dd MMM').format(lr.startDate)} – ${DateFormat('dd MMM yyyy').format(lr.endDate)}',
            style: TextStyle(fontSize: 11, color: _textSecondary)),
        if (lr.reason.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(lr.reason, style: TextStyle(fontSize: 11, color: _textSecondary),
              maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
        if (lr.rejectionNote != null && lr.rejectionNote!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: statusColor.withOpacity(0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  lr.status.toLowerCase() == 'rejected' ? Icons.info_outline_rounded : Icons.check_circle_outline_rounded,
                  size: 13,
                  color: statusColor,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Note: ${lr.rejectionNote}',
                    style: TextStyle(fontSize: 10.5, color: statusColor, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (lr.status.toLowerCase() == 'pending') ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => onRejectLeave(lr),
                icon: const Icon(Icons.close_rounded, size: 14, color: HRTheme.danger),
                label: const Text('Reject', style: TextStyle(fontSize: 11, color: HRTheme.danger, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => onApproveLeave(lr),
                icon: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                label: const Text('Approve', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HRTheme.success,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ]),
    );
  }
}

// ─── HELPER MODELS ────────────────────────────────────────────────────────────

class _TabItem {
  final IconData icon;
  final String label;
  const _TabItem(this.icon, this.label);
}
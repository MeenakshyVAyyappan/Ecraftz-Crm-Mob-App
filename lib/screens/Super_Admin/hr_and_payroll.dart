import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../theme/app_theme.dart';
import '../../blocs/theme/theme_bloc.dart';
import '../../widgets/app_drawer.dart';

// ─── MODELS ───────────────────────────────────────────────────────────────────

enum PayrollStatus { draft, approved, paid }

class Employee {
  final String id;
  final String name;
  final String department;
  final String role;
  final DateTime joinDate;
  final double kpiScore;
  final double baseSalary;

  const Employee({
    required this.id,
    required this.name,
    required this.department,
    required this.role,
    required this.joinDate,
    required this.kpiScore,
    required this.baseSalary,
  });
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
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String status; // pending, approved, rejected

  const LeaveRequest({
    required this.id,
    required this.employeeName,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
  });
}

class PayrollRecord {
  final String id;
  final String employeeName;
  final String period;
  final double basicSalary;
  final double allowances;
  final double deductions;
  final double netPay;
  final PayrollStatus status;

  const PayrollRecord({
    required this.id,
    required this.employeeName,
    required this.period,
    required this.basicSalary,
    required this.allowances,
    required this.deductions,
    required this.netPay,
    required this.status,
  });
}

// ─── SAMPLE DATA ──────────────────────────────────────────────────────────────

final List<Employee> sampleEmployees = [
  Employee(id: '1', name: 'Sasi Kumar', department: 'Engineering', role: 'Senior Developer',
      joinDate: DateTime(2023, 3, 15), kpiScore: 92, baseSalary: 75000),
  Employee(id: '2', name: 'Viswajith E', department: 'Design', role: 'UI/UX Designer',
      joinDate: DateTime(2022, 8, 1), kpiScore: 88, baseSalary: 65000),
  Employee(id: '3', name: 'Priya R', department: 'HR', role: 'HR Manager',
      joinDate: DateTime(2021, 5, 20), kpiScore: 95, baseSalary: 70000),
  Employee(id: '4', name: 'Arjun M', department: 'Marketing', role: 'Marketing Lead',
      joinDate: DateTime(2024, 1, 10), kpiScore: 80, baseSalary: 60000),
];

final List<AttendanceRecord> sampleAttendance = [
  AttendanceRecord(id: 'a1', employeeName: 'Sasi Kumar', date: DateTime(2026, 5, 12),
      clockIn: '2:52 PM', clockOut: null, isPresent: false),
  AttendanceRecord(id: 'a2', employeeName: 'Viswajith E', date: DateTime(2026, 5, 12),
      clockIn: '5:53 PM', clockOut: '5:53 PM', isPresent: true),
  AttendanceRecord(id: 'a3', employeeName: 'Viswajith E', date: DateTime(2026, 5, 9),
      clockIn: '12:21 PM', clockOut: '12:21 PM', isPresent: true),
  AttendanceRecord(id: 'a4', employeeName: 'Priya R', date: DateTime(2026, 5, 9),
      clockIn: '9:00 AM', clockOut: '6:00 PM', isPresent: true),
];

List<LeaveRequest> sampleLeaves = [];

final List<PayrollRecord> samplePayroll = [
  PayrollRecord(id: 'p1', employeeName: 'Viswajith E', period: 'MAY 2026',
      basicSalary: 65000, allowances: 0, deductions: 0, netPay: 0, status: PayrollStatus.draft),
  PayrollRecord(id: 'p2', employeeName: 'Sasi Kumar', period: 'MAY 2026',
      basicSalary: 75000, allowances: 5000, deductions: 8000, netPay: 72000, status: PayrollStatus.approved),
  PayrollRecord(id: 'p3', employeeName: 'Priya R', period: 'APR 2026',
      basicSalary: 70000, allowances: 3000, deductions: 7000, netPay: 66000, status: PayrollStatus.paid),
];

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

  static Color payrollStatusColor(PayrollStatus s) {
    switch (s) {
      case PayrollStatus.draft: return warning;
      case PayrollStatus.approved: return success;
      case PayrollStatus.paid: return primary;
    }
  }

  static String payrollStatusLabel(PayrollStatus s) {
    switch (s) {
      case PayrollStatus.draft: return 'DRAFT';
      case PayrollStatus.approved: return 'APPROVED';
      case PayrollStatus.paid: return 'PAID';
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
  String _payrollSearch = '';
  final _currencyFmt = NumberFormat('#,##0', 'en_IN');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _activeTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: HRTheme.primary,
        onPressed: () {
          if (_activeTab == 0) _showAddEmployeeSheet();
          else if (_activeTab == 1) _showLeaveRequestSheet();
          else _showRunPayrollDialog();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
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
                    employees: sampleEmployees,
                    searchQuery: _searchQuery,
                    onSearchChanged: (v) => setState(() => _searchQuery = v),
                    isTablet: isTablet,
                    fmtSalary: _fmt,
                    onRefresh: () => setState(() {}),
                  ),
                  _TimeLeaveTab(
                    attendance: sampleAttendance,
                    leaves: sampleLeaves,
                    isTablet: isTablet,
                    onClockIn: _handleClockIn,
                    onRequestLeave: _showLeaveRequestSheet,
                  ),
                  _PayrollTab(
                    records: samplePayroll,
                    searchQuery: _payrollSearch,
                    onSearchChanged: (v) => setState(() => _payrollSearch = v),
                    isTablet: isTablet,
                    fmtSalary: _fmt,
                    onRunPayroll: _showRunPayrollDialog,
                    onDownloadPayslip: _downloadPayslip,
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
          Text('Manage your team, track attendance, approve leaves, and generate payroll.',
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
      _TabItem(Icons.attach_money_rounded, 'Payroll'),
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

  void _showLeaveRequestSheet() {
    String leaveType = 'Annual Leave';
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 1));
    final reasonCtrl = TextEditingController();

    final leaveTypes = ['Annual Leave', 'Sick Leave', 'Casual Leave', 'Maternity Leave', 'Paternity Leave', 'Unpaid Leave'];

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
                    Text('Submit Leave Request',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _textPrimaryModal)),
                    const SizedBox(height: 4),
                    Text('Request time off for approval by HR.',
                        style: TextStyle(fontSize: 12, color: _textSecondaryModal)),
                    const SizedBox(height: 18),
                    _fieldLabel(ctx, 'Leave Type'),
                    Container(
                      decoration: BoxDecoration(
                          border: Border.all(color: HRTheme.primary, width: 1.5),
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: leaveType,
                          isExpanded: true,
                          dropdownColor: _cardBgModal,
                          style: TextStyle(fontSize: 14, color: _textPrimaryModal),
                          items: leaveTypes.map((t) => DropdownMenuItem(value: t,
                              child: Text(t, style: TextStyle(color: _textPrimaryModal)))).toList(),
                          onChanged: (v) => setModalState(() => leaveType = v!),
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
                        hintText: 'Explain your reason for leave...',
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
                        onPressed: () {
                          setState(() {
                            sampleLeaves.add(LeaveRequest(
                              id: 'lr${sampleLeaves.length + 1}',
                              employeeName: 'Current User',
                              leaveType: leaveType,
                              startDate: startDate,
                              endDate: endDate,
                              reason: reasonCtrl.text,
                              status: 'pending',
                            ));
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Leave request submitted!'),
                                backgroundColor: HRTheme.success),
                          );
                        },
                        child: const Text('Submit Leave Request',
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
    final deptCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    final salaryCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final _cardBgModal = HRTheme.cardBgOf(ctx);
        final _textPrimaryModal = HRTheme.textPrimaryOf(ctx);

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
                color: _cardBgModal,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                _sheetHandle(ctx),
                Text('Add Employee',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _textPrimaryModal)),
                const SizedBox(height: 16),
                _inputField(ctx, nameCtrl, 'Full Name', Icons.person_rounded),
                const SizedBox(height: 10),
                _inputField(ctx, deptCtrl, 'Department', Icons.business_rounded),
                const SizedBox(height: 10),
                _inputField(ctx, roleCtrl, 'Role / Designation', Icons.work_rounded),
                const SizedBox(height: 10),
                _inputField(ctx, salaryCtrl, 'Base Salary (₹)', Icons.currency_rupee, isNumber: true),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HRTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Employee added successfully!'),
                            backgroundColor: HRTheme.success),
                      );
                    },
                    child: const Text('Add Employee',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }

  void _showRunPayrollDialog() {
    final _cardBg = HRTheme.cardBgOf(context);
    final _textPrimary = HRTheme.textPrimaryOf(context);
    final _textSecondary = HRTheme.textSecondaryOf(context);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: HRTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.attach_money_rounded, color: HRTheme.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Text('Run May Payroll', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textPrimary)),
        ]),
        content: Text(
            'This will generate payroll records for all active employees for May 2026. Continue?',
            style: TextStyle(fontSize: 13, color: _textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: _textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: HRTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payroll generated for May 2026!'),
                    backgroundColor: HRTheme.success),
              );
            },
            child: const Text('Run Payroll', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _downloadPayslip(PayrollRecord r) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading payslip for ${r.employeeName}...'),
          backgroundColor: HRTheme.primary),
    );
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

  const _DirectoryTab({
    required this.employees,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.isTablet,
    required this.fmtSalary,
    required this.onRefresh,
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
        isTablet ? _buildTable(context) : _buildCards(context),
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

    return Expanded(
      child: Container(
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
            _iconBtn(Icons.edit_rounded, HRTheme.primary, () {}),
            const SizedBox(width: 6),
            _iconBtn(Icons.delete_rounded, HRTheme.danger, () {}),
          ])),
        ],
      ),
    );
  }

  Widget _buildCards(BuildContext context) {
    final _textSecondary = HRTheme.textSecondaryOf(context);

    if (filtered.isEmpty) {
      return Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text('No employees found matching your search.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _textSecondary)),
          ),
        ),
      );
    }
    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) => _employeeCard(ctx, filtered[i]),
      ),
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
            _iconBtn(Icons.edit_rounded, HRTheme.primary, () {}),
            const SizedBox(height: 6),
            _iconBtn(Icons.delete_rounded, HRTheme.danger, () {}),
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
  final List<AttendanceRecord> attendance;
  final List<LeaveRequest> leaves;
  final bool isTablet;
  final Function(AttendanceRecord) onClockIn;
  final VoidCallback onRequestLeave;

  const _TimeLeaveTab({
    required this.attendance,
    required this.leaves,
    required this.isTablet,
    required this.onClockIn,
    required this.onRequestLeave,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      child: isTablet
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _attendanceSection(context)),
              const SizedBox(width: 12),
              Expanded(child: _leaveSection(context)),
            ])
          : Column(children: [
              _attendanceSection(context),
              const SizedBox(height: 12),
              _leaveSection(context),
            ]),
    );
  }

  Widget _attendanceSection(BuildContext ctx) {
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
                decoration: BoxDecoration(color: HRTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.access_time_rounded, color: HRTheme.primary, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text('Daily Attendance',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textPrimary))),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [HRTheme.primary, HRTheme.primaryDark]),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: HRTheme.primary.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: const Text('Clock In',
                      style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
          Divider(height: 1, color: _border),
          if (attendance.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text('No attendance records today.',
                  style: TextStyle(fontSize: 13, color: _textSecondary)),
            )
          else
            ...attendance.map((rec) => _attendanceRow(ctx, rec)),
        ],
      ),
    );
  }

  Widget _attendanceRow(BuildContext ctx, AttendanceRecord rec) {
    final initials = rec.employeeName.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join();
    final hasClockOut = rec.clockOut != null;
    final _textPrimary = HRTheme.textPrimaryOf(ctx);
    final _textSecondary = HRTheme.textSecondaryOf(ctx);
    final _border = HRTheme.borderOf(ctx);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: _border))),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: HRTheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(initials,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: HRTheme.primary))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(rec.employeeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textPrimary)),
            Text(DateFormat('MMM d, yyyy').format(rec.date),
                style: TextStyle(fontSize: 11, color: _textSecondary)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('IN: ${rec.clockIn ?? '----'}',
                style: const TextStyle(fontSize: 11, color: HRTheme.success, fontWeight: FontWeight.w600)),
            Text('OUT: ${rec.clockOut ?? '----'}',
                style: TextStyle(fontSize: 11,
                    color: hasClockOut ? HRTheme.danger : _textSecondary,
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(width: 8),
          if (!hasClockOut)
            GestureDetector(
              onTap: () => onClockIn(rec),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                    border: Border.all(color: _border),
                    borderRadius: BorderRadius.circular(6)),
                child: Text('Clock Out',
                    style: TextStyle(fontSize: 10, color: _textSecondary, fontWeight: FontWeight.w600)),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: HRTheme.success.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: const Text('PRESENT',
                  style: TextStyle(fontSize: 9, color: HRTheme.success, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            ),
        ],
      ),
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
              GestureDetector(
                onTap: onRequestLeave,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      border: Border.all(color: HRTheme.primary),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Text('Request Leave',
                      style: TextStyle(fontSize: 11, color: HRTheme.primary, fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ),
          Divider(height: 1, color: _border),
          if (leaves.isEmpty)
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
      ]),
    );
  }
}

// ─── TAB 3: PAYROLL ──────────────────────────────────────────────────────────

class _PayrollTab extends StatelessWidget {
  final List<PayrollRecord> records;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final bool isTablet;
  final String Function(double) fmtSalary;
  final VoidCallback onRunPayroll;
  final Function(PayrollRecord) onDownloadPayslip;

  const _PayrollTab({
    required this.records,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.isTablet,
    required this.fmtSalary,
    required this.onRunPayroll,
    required this.onDownloadPayslip,
  });

  List<PayrollRecord> get filtered => records.where((r) =>
      r.employeeName.toLowerCase().contains(searchQuery.toLowerCase()) ||
      r.period.toLowerCase().contains(searchQuery.toLowerCase())).toList();

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
          child: Row(children: [
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
                    hintText: 'Search payroll records...',
                    hintStyle: TextStyle(fontSize: 12, color: _textSecondary),
                    prefixIcon: Icon(Icons.search_rounded, size: 18, color: _textSecondary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Row(children: [
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                      color: _cardBg,
                      border: Border.all(color: _border),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.filter_list_rounded, size: 16, color: _textSecondary),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onRunPayroll,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [HRTheme.primary, HRTheme.primaryDark]),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: HRTheme.primary.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(isTablet ? 'Run May Payroll' : 'Run Payroll',
                        style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ]),
          ]),
        ),
        isTablet ? _buildTable(context) : _buildCards(context),
      ],
    );
  }

  Widget _buildTable(BuildContext context) {
    final cols = ['EMPLOYEE', 'PERIOD', 'BASIC + ALLOWANCES', 'DEDUCTIONS', 'NET PAY', 'STATUS', 'PAYSLIP'];
    final flexes = [3, 2, 3, 2, 2, 2, 1];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final _cardBg = HRTheme.cardBgOf(context);
    final _textSecondary = HRTheme.textSecondaryOf(context);
    final _border = HRTheme.borderOf(context);

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Column(
          children: [
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
            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Text('No payroll records found.',
                      style: TextStyle(fontSize: 13, color: _textSecondary)))
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: _border),
                      itemBuilder: (ctx, i) => _tableRow(ctx, filtered[i], flexes),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableRow(BuildContext ctx, PayrollRecord r, List<int> flexes) {
    final statusColor = HRTheme.payrollStatusColor(r.status);
    final initials = r.employeeName.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join();
    final _textPrimary = HRTheme.textPrimaryOf(ctx);
    final _textSecondary = HRTheme.textSecondaryOf(ctx);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: flexes[0], child: Row(children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(color: HRTheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(7)),
              child: Center(child: Text(initials,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: HRTheme.primary))),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(r.employeeName,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textPrimary),
                overflow: TextOverflow.ellipsis)),
          ])),
          Expanded(flex: flexes[1], child: Text(r.period,
              style: TextStyle(fontSize: 12, color: _textSecondary))),
          Expanded(flex: flexes[2], child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(fmtSalary(r.basicSalary + r.allowances),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textPrimary)),
            Text('+${fmtSalary(r.allowances)}',
                style: const TextStyle(fontSize: 10, color: HRTheme.success)),
          ])),
          Expanded(flex: flexes[3], child: Text('-${fmtSalary(r.deductions)}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: HRTheme.danger))),
          Expanded(flex: flexes[4], child: Text(fmtSalary(r.netPay),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _textPrimary))),
          Expanded(flex: flexes[5], child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(HRTheme.payrollStatusLabel(r.status),
                style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
          )),
          Expanded(flex: flexes[6], child: GestureDetector(
            onTap: () => onDownloadPayslip(r),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: HRTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
              child: const Icon(Icons.download_rounded, size: 16, color: HRTheme.primary),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildCards(BuildContext context) {
    final _textSecondary = HRTheme.textSecondaryOf(context);
    return Expanded(
      child: filtered.isEmpty
          ? Center(child: Text('No payroll records found.',
              style: TextStyle(fontSize: 13, color: _textSecondary)))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) => _payrollCard(ctx, filtered[i]),
            ),
    );
  }

  Widget _payrollCard(BuildContext ctx, PayrollRecord r) {
    final statusColor = HRTheme.payrollStatusColor(r.status);
    final initials = r.employeeName.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join();
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
      child: Column(
        children: [
          Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: HRTheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
              child: Center(child: Text(initials,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: HRTheme.primary))),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.employeeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textPrimary)),
              Text(r.period, style: TextStyle(fontSize: 11, color: _textSecondary)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(HRTheme.payrollStatusLabel(r.status),
                  style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 12),
          Divider(height: 1, color: _border),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _payrollStat(ctx, 'Basic + Allow.', fmtSalary(r.basicSalary + r.allowances), _textPrimary)),
            Expanded(child: _payrollStat(ctx, 'Deductions', '-${fmtSalary(r.deductions)}', HRTheme.danger)),
            Expanded(child: _payrollStat(ctx, 'Net Pay', fmtSalary(r.netPay), HRTheme.success)),
          ]),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () => onDownloadPayslip(r),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                    border: Border.all(color: HRTheme.primary),
                    borderRadius: BorderRadius.circular(8)),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.download_rounded, size: 14, color: HRTheme.primary),
                  SizedBox(width: 6),
                  Text('Download Payslip',
                      style: TextStyle(fontSize: 12, color: HRTheme.primary, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _payrollStat(BuildContext ctx, String label, String value, Color valueColor) {
    final _textSecondary = HRTheme.textSecondaryOf(ctx);
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: valueColor)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 10, color: _textSecondary)),
    ]);
  }
}

// ─── HELPER MODELS ────────────────────────────────────────────────────────────

class _TabItem {
  final IconData icon;
  final String label;
  const _TabItem(this.icon, this.label);
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/app_drawer.dart';

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

  static Color statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'present': return success;
      case 'absent': return danger;
      case 'approved': return success;
      case 'rejected': return danger;
      case 'pending': return warning;
      default: return textSecondary;
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
      backgroundColor: HRTheme.background,
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
    return Container(
      color: HRTheme.cardBg,
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (!isTablet) ...[
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.menu, size: 18, color: HRTheme.textSecondary),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              const SizedBox(width: 10),
            ],
            const Icon(Icons.grid_view_rounded, size: 13, color: HRTheme.textSecondary),
            const SizedBox(width: 4),
            _crumb('Dashboard', false),
            const Icon(Icons.chevron_right, size: 15, color: HRTheme.textSecondary),
            _crumb('HR', true),
          ]),
          const SizedBox(height: 8),
          const Text('HR & Employee Management',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: HRTheme.textPrimary)),
          const SizedBox(height: 3),
          Text('Manage your team, track attendance, approve leaves, and generate payroll.',
              style: TextStyle(fontSize: 12, color: HRTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _crumb(String label, bool active) => Text(label,
      style: TextStyle(fontSize: 12,
          color: active ? HRTheme.primary : HRTheme.textSecondary,
          fontWeight: active ? FontWeight.w600 : FontWeight.normal));

  // ── TAB BAR ─────────────────────────────────────────────────────────────────

  Widget _buildTabBar(bool isTablet) {
    final tabs = [
      _TabItem(Icons.people_alt_rounded, 'Directory'),
      _TabItem(Icons.access_time_rounded, 'Time & Leave'),
      _TabItem(Icons.attach_money_rounded, 'Payroll'),
    ];
    return Container(
      color: HRTheme.cardBg,
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
                    color: selected ? HRTheme.primary : HRTheme.border,
                    width: selected ? 1.5 : 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(e.value.icon, size: 14,
                    color: selected ? HRTheme.primary : HRTheme.textSecondary),
                const SizedBox(width: 5),
                Text(e.value.label,
                    style: TextStyle(fontSize: 12,
                        color: selected ? HRTheme.primary : HRTheme.textSecondary,
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
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sheetHandle(),
                  const Text('Submit Leave Request',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: HRTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Request time off for approval by HR.',
                      style: TextStyle(fontSize: 12, color: HRTheme.textSecondary)),
                  const SizedBox(height: 18),
                  _fieldLabel('Leave Type'),
                  Container(
                    decoration: BoxDecoration(
                        border: Border.all(color: HRTheme.primary, width: 1.5),
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: leaveType,
                        isExpanded: true,
                        style: const TextStyle(fontSize: 14, color: HRTheme.textPrimary),
                        items: leaveTypes.map((t) => DropdownMenuItem(value: t,
                            child: Text(t))).toList(),
                        onChanged: (v) => setModalState(() => leaveType = v!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _fieldLabel('Start Date'),
                      _datePicker(ctx, startDate, (d) => setModalState(() => startDate = d)),
                    ])),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _fieldLabel('End Date'),
                      _datePicker(ctx, endDate, (d) => setModalState(() => endDate = d)),
                    ])),
                  ]),
                  const SizedBox(height: 14),
                  _fieldLabel('Reason'),
                  TextField(
                    controller: reasonCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Explain your reason for leave...',
                      hintStyle: TextStyle(color: HRTheme.textSecondary, fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: HRTheme.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: HRTheme.primary, width: 1.5)),
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
        ),
      ),
    );
  }

  Widget _datePicker(BuildContext ctx, DateTime date, Function(DateTime) onPicked) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: ctx,
          initialDate: date,
          firstDate: DateTime(2024),
          lastDate: DateTime(2028),
          builder: (_, child) => Theme(
            data: ThemeData.light().copyWith(
                colorScheme: const ColorScheme.light(primary: HRTheme.primary)),
            child: child!,
          ),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
            border: Border.all(color: HRTheme.border),
            borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          const Icon(Icons.calendar_today_rounded, size: 14, color: HRTheme.textSecondary),
          const SizedBox(width: 8),
          Text(DateFormat('dd-MM-yyyy').format(date),
              style: const TextStyle(fontSize: 13, color: HRTheme.textPrimary)),
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
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              _sheetHandle(),
              const Text('Add Employee',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: HRTheme.textPrimary)),
              const SizedBox(height: 16),
              _inputField(nameCtrl, 'Full Name', Icons.person_rounded),
              const SizedBox(height: 10),
              _inputField(deptCtrl, 'Department', Icons.business_rounded),
              const SizedBox(height: 10),
              _inputField(roleCtrl, 'Role / Designation', Icons.work_rounded),
              const SizedBox(height: 10),
              _inputField(salaryCtrl, 'Base Salary (₹)', Icons.currency_rupee, isNumber: true),
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
      ),
    );
  }

  void _showRunPayrollDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: HRTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.attach_money_rounded, color: HRTheme.primary, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('Run May Payroll', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
        content: const Text(
            'This will generate payroll records for all active employees for May 2026. Continue?',
            style: TextStyle(fontSize: 13, color: HRTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: HRTheme.textSecondary)),
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

  Widget _sheetHandle() => Center(
    child: Container(
      width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: HRTheme.border, borderRadius: BorderRadius.circular(2)),
    ),
  );

  Widget _fieldLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
        color: HRTheme.textSecondary, letterSpacing: 0.3)),
  );

  Widget _inputField(TextEditingController ctrl, String hint, IconData icon,
      {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: HRTheme.textSecondary),
        prefixIcon: Icon(icon, size: 16, color: HRTheme.textSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: HRTheme.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: HRTheme.primary, width: 1.5)),
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
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(isTablet ? 16 : 12),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: HRTheme.cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: HRTheme.border),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
                  ),
                  child: TextField(
                    onChanged: onSearchChanged,
                    decoration: const InputDecoration(
                      hintText: 'Search employees by name, department, or designation...',
                      hintStyle: TextStyle(fontSize: 12, color: HRTheme.textSecondary),
                      prefixIcon: Icon(Icons.search_rounded, size: 18, color: HRTheme.textSecondary),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                    color: HRTheme.cardBg,
                    border: Border.all(color: HRTheme.border),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.refresh_rounded, size: 15, color: HRTheme.textSecondary),
                    if (isTablet) ...[
                      const SizedBox(width: 5),
                      const Text('Refresh Directory',
                          style: TextStyle(fontSize: 12, color: HRTheme.textSecondary)),
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

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: HRTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: HRTheme.border),
        ),
        child: Column(
          children: [
            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: cols.asMap().entries.map((e) => Expanded(
                  flex: flexes[e.key],
                  child: Text(e.value,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                          color: HRTheme.textSecondary, letterSpacing: 0.5)),
                )).toList(),
              ),
            ),
            const Divider(height: 1, color: HRTheme.border),
            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text('No employees found matching your search.',
                    style: TextStyle(fontSize: 13, color: HRTheme.textSecondary)),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: HRTheme.border),
                  itemBuilder: (ctx, i) => _tableRow(ctx, filtered[i], flexes),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tableRow(BuildContext ctx, Employee emp, List<int> flexes) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: flexes[0], child: Row(children: [
            _empAvatar(emp.name, 32),
            const SizedBox(width: 8),
            Expanded(child: Text(emp.name,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: HRTheme.textPrimary),
                overflow: TextOverflow.ellipsis)),
          ])),
          Expanded(flex: flexes[1], child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(emp.department, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: HRTheme.textPrimary), overflow: TextOverflow.ellipsis),
            Text(emp.role, style: const TextStyle(fontSize: 11, color: HRTheme.textSecondary), overflow: TextOverflow.ellipsis),
          ])),
          Expanded(flex: flexes[2], child: Text(DateFormat('dd MMM yyyy').format(emp.joinDate),
              style: const TextStyle(fontSize: 12, color: HRTheme.textSecondary))),
          Expanded(flex: flexes[3], child: _kpiChip(emp.kpiScore)),
          Expanded(flex: flexes[4], child: Text(fmtSalary(emp.baseSalary),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: HRTheme.textPrimary))),
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
    if (filtered.isEmpty) {
      return Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text('No employees found matching your search.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: HRTheme.textSecondary)),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HRTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HRTheme.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
      ),
      child: Row(
        children: [
          _empAvatar(emp.name, 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(emp.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: HRTheme.textPrimary)),
              const SizedBox(height: 2),
              Text('${emp.department} • ${emp.role}',
                  style: const TextStyle(fontSize: 11, color: HRTheme.textSecondary), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Wrap(spacing: 8, runSpacing: 4, children: [
                _kpiChip(emp.kpiScore),
                _infoChip(DateFormat('dd MMM yyyy').format(emp.joinDate), Icons.calendar_today_rounded),
                _infoChip(fmtSalary(emp.baseSalary), Icons.currency_rupee),
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

  Widget _empAvatar(String name, double size) {
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

  Widget _infoChip(String label, IconData icon) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 10, color: HRTheme.textSecondary),
      const SizedBox(width: 3),
      Text(label, style: const TextStyle(fontSize: 10, color: HRTheme.textSecondary)),
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
    return Container(
      decoration: BoxDecoration(
        color: HRTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HRTheme.border),
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
              const Expanded(child: Text('Daily Attendance',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: HRTheme.textPrimary))),
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
          const Divider(height: 1, color: HRTheme.border),
          if (attendance.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text('No attendance records today.',
                  style: TextStyle(fontSize: 13, color: HRTheme.textSecondary)),
            )
          else
            ...attendance.map((rec) => _attendanceRow(rec)),
        ],
      ),
    );
  }

  Widget _attendanceRow(AttendanceRecord rec) {
    final initials = rec.employeeName.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join();
    final hasClockOut = rec.clockOut != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: HRTheme.border))),
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
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: HRTheme.textPrimary)),
            Text(DateFormat('MMM d, yyyy').format(rec.date),
                style: const TextStyle(fontSize: 11, color: HRTheme.textSecondary)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('IN: ${rec.clockIn ?? '----'}',
                style: const TextStyle(fontSize: 11, color: HRTheme.success, fontWeight: FontWeight.w600)),
            Text('OUT: ${rec.clockOut ?? '----'}',
                style: TextStyle(fontSize: 11,
                    color: hasClockOut ? HRTheme.danger : HRTheme.textSecondary,
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(width: 8),
          if (!hasClockOut)
            GestureDetector(
              onTap: () => onClockIn(rec),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                    border: Border.all(color: HRTheme.border),
                    borderRadius: BorderRadius.circular(6)),
                child: const Text('Clock Out',
                    style: TextStyle(fontSize: 10, color: HRTheme.textSecondary, fontWeight: FontWeight.w600)),
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
    return Container(
      decoration: BoxDecoration(
        color: HRTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HRTheme.border),
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
              const Expanded(child: Text('Leave Requests',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: HRTheme.textPrimary))),
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
          const Divider(height: 1, color: HRTheme.border),
          if (leaves.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              child: Column(children: [
                Icon(Icons.event_busy_rounded, size: 28, color: Color(0xFF94A3B8)),
                SizedBox(height: 8),
                Text('No leave requests found.',
                    style: TextStyle(fontSize: 13, color: HRTheme.textSecondary)),
              ]),
            )
          else
            ...leaves.map((lr) => _leaveRow(lr)),
        ],
      ),
    );
  }

  Widget _leaveRow(LeaveRequest lr) {
    final statusColor = HRTheme.statusColor(lr.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: HRTheme.border))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(lr.employeeName,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: HRTheme.textPrimary))),
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
            style: const TextStyle(fontSize: 11, color: HRTheme.textSecondary)),
        if (lr.reason.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(lr.reason, style: const TextStyle(fontSize: 11, color: HRTheme.textSecondary),
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
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(isTablet ? 16 : 12),
          child: Row(children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: HRTheme.cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: HRTheme.border),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
                ),
                child: TextField(
                  onChanged: onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: 'Search payroll records...',
                    hintStyle: TextStyle(fontSize: 12, color: HRTheme.textSecondary),
                    prefixIcon: Icon(Icons.search_rounded, size: 18, color: HRTheme.textSecondary),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                      color: HRTheme.cardBg,
                      border: Border.all(color: HRTheme.border),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.filter_list_rounded, size: 16, color: HRTheme.textSecondary),
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

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: HRTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: HRTheme.border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: cols.asMap().entries.map((e) => Expanded(
                  flex: flexes[e.key],
                  child: Text(e.value,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                          color: HRTheme.textSecondary, letterSpacing: 0.5)),
                )).toList(),
              ),
            ),
            const Divider(height: 1, color: HRTheme.border),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No payroll records found.',
                      style: TextStyle(fontSize: 13, color: HRTheme.textSecondary)))
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: HRTheme.border),
                      itemBuilder: (_, i) => _tableRow(filtered[i], flexes),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableRow(PayrollRecord r, List<int> flexes) {
    final statusColor = HRTheme.payrollStatusColor(r.status);
    final initials = r.employeeName.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join();

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
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: HRTheme.textPrimary),
                overflow: TextOverflow.ellipsis)),
          ])),
          Expanded(flex: flexes[1], child: Text(r.period,
              style: const TextStyle(fontSize: 12, color: HRTheme.textSecondary))),
          Expanded(flex: flexes[2], child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(fmtSalary(r.basicSalary + r.allowances),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: HRTheme.textPrimary)),
            Text('+${fmtSalary(r.allowances)}',
                style: const TextStyle(fontSize: 10, color: HRTheme.success)),
          ])),
          Expanded(flex: flexes[3], child: Text('-${fmtSalary(r.deductions)}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: HRTheme.danger))),
          Expanded(flex: flexes[4], child: Text(fmtSalary(r.netPay),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: HRTheme.textPrimary))),
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
    return Expanded(
      child: filtered.isEmpty
          ? const Center(child: Text('No payroll records found.',
              style: TextStyle(fontSize: 13, color: HRTheme.textSecondary)))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _payrollCard(filtered[i]),
            ),
    );
  }

  Widget _payrollCard(PayrollRecord r) {
    final statusColor = HRTheme.payrollStatusColor(r.status);
    final initials = r.employeeName.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HRTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HRTheme.border),
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
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: HRTheme.textPrimary)),
              Text(r.period, style: const TextStyle(fontSize: 11, color: HRTheme.textSecondary)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(HRTheme.payrollStatusLabel(r.status),
                  style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 12),
          const Divider(height: 1, color: HRTheme.border),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _payrollStat('Basic + Allow.', fmtSalary(r.basicSalary + r.allowances), HRTheme.textPrimary)),
            Expanded(child: _payrollStat('Deductions', '-${fmtSalary(r.deductions)}', HRTheme.danger)),
            Expanded(child: _payrollStat('Net Pay', fmtSalary(r.netPay), HRTheme.success)),
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

  Widget _payrollStat(String label, String value, Color valueColor) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: valueColor)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 10, color: HRTheme.textSecondary)),
    ]);
  }
}

// ─── HELPER MODELS ────────────────────────────────────────────────────────────

class _TabItem {
  final IconData icon;
  final String label;
  const _TabItem(this.icon, this.label);
}
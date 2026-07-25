import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/attendance_device/attendance_device_bloc.dart';
import '../../blocs/theme/theme_bloc.dart';
import '../../models/attendance_device_model.dart';
import '../../models/attendance_register_model.dart';
import '../../models/employee_shift_model.dart';
import '../../services/supabase_service.dart';
import '../../services/attendance_register_service.dart';
import '../../services/attendance_export_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_drawer.dart';

class AttendanceDeviceScreen extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool showAppBar;

  const AttendanceDeviceScreen({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.showAppBar = true,
  });

  @override
  State<AttendanceDeviceScreen> createState() => _AttendanceDeviceScreenState();
}

class _AttendanceDeviceScreenState extends State<AttendanceDeviceScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _matrixResultsKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  final TextEditingController _searchCtrl = TextEditingController();

  // Date Filter Improvements: From Date defaults to null ("Select Date")
  DateTime? _fromDate;
  DateTime _toDate = DateTime.now();
  DateTime _snapshotDate = DateTime.now();
  String _dataSource = 'Cloud Database (Sync Agent)';

  // Navigation tab state: 0 = Attendance Register, 1 = API Logs
  int _activeViewTab = 0;

  bool  get _isDark        => Theme.of(context).brightness == Brightness.dark;
  Color get _bg            => Theme.of(context).scaffoldBackgroundColor;
  Color get _cardBg        => Theme.of(context).colorScheme.surface;
  Color get _border        => AppTheme.borderOf(context);
  Color get _textPrimary   => AppTheme.textPrimaryOf(context);
  Color get _textSecondary => AppTheme.textSecondaryOf(context);
  Color get _textMuted     => AppTheme.textMutedOf(context);

  @override
  void initState() {
    super.initState();
    context.read<AttendanceDeviceBloc>().add(LoadAttendanceDevicesEvent());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    if (_fromDate != null) {
      context.read<AttendanceDeviceBloc>().add(
            LoadAttendanceRegisterEvent(
              startDate: _fromDate,
              endDate: _toDate,
              snapshotDate: _snapshotDate,
              searchQuery: q.trim(),
            ),
          );
    }
  }

  void _onFetchAttendance() {
    if (_fromDate == null) {
      _showSnack('Please select From Date before fetching attendance.', isError: true);
      return;
    }

    context.read<AttendanceDeviceBloc>().add(
          LoadAttendanceRegisterEvent(
            startDate: _fromDate,
            endDate: _toDate,
            snapshotDate: _snapshotDate,
            searchQuery: _searchCtrl.text.trim(),
          ),
        );
  }

  void _scrollToResults() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_matrixResultsKey.currentContext != null) {
        Scrollable.ensureVisible(
          _matrixResultsKey.currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime(DateTime.now().year, DateTime.now().month, 1),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _fromDate = picked);
    }
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _toDate = picked);
    }
  }

  Future<void> _pickSnapshotDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _snapshotDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _snapshotDate = picked);
      if (_fromDate != null) _onFetchAttendance();
    }
  }

  void _openEmployeeMappingDialog(AttendanceDeviceState state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EmployeeMappingDialog(
        devices: state.devices,
        onSync: (device, empId, empName, empCode, cardNo, cmdId) {
          context.read<AttendanceDeviceBloc>().add(
                SyncEmployeeToDeviceEvent(
                  device: device,
                  employeeId: empId,
                  employeeName: empName,
                  employeeCode: empCode,
                  cardNumber: cardNo,
                  commandId: cmdId,
                ),
              );
        },
      ),
    );
  }

  void _openDeviceSettingsDialog(AttendanceDeviceState state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DeviceSettingsDialog(
        devices: state.devices,
        onAddDevice: (data) {
          context.read<AttendanceDeviceBloc>().add(
                CreateAttendanceDeviceEvent(
                  deviceName: data['deviceName'] as String,
                  serialNumber: data['serialNumber'] as String,
                  ipAddress: data['ipAddress'] as String?,
                  port: data['port'] as int?,
                  apiUrl: data['apiUrl'] as String,
                  apiKey: data['apiKey'] as String,
                  username: data['username'] as String,
                  password: data['password'] as String,
                ),
              );
        },
        onDeleteDevice: (id) {
          context.read<AttendanceDeviceBloc>().add(DeleteAttendanceDeviceEvent(id));
        },
        onTestConnection: (url, key) {
          context.read<AttendanceDeviceBloc>().add(
                TestDeviceConnectionEvent(apiUrl: url, apiKey: key),
              );
        },
      ),
    );
  }

  // ignore: unused_element
  void _openAssignShiftDialog(AttendanceDeviceState state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AssignShiftDialog(
        onAssign: (empId, shiftId) {
          context.read<AttendanceDeviceBloc>().add(
                AssignEmployeeShiftEvent(employeeId: empId, shiftId: shiftId),
              );
        },
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bg,
      drawer: widget.showAppBar
          ? AppDrawer(
              selectedIndex: widget.selectedIndex,
              onItemSelected: (i) {
                widget.onItemSelected(i);
                Navigator.pop(context);
              },
            )
          : null,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: _cardBg,
              elevation: 0,
              leading: isWide
                  ? null
                  : IconButton(
                      icon: Icon(Icons.menu_rounded,
                          color: _isDark ? Colors.white : const Color(0xFF374151)),
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
              title: Row(
                children: [
                  const Icon(Icons.developer_board_rounded, color: Color(0xFF0EA5E9), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Attendance Register',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w800, color: _textPrimary)),
                        Text('Biometric attendance fetched from your eSSL device.',
                            style: TextStyle(fontSize: 11, color: _textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                BlocBuilder<ThemeBloc, ThemeState>(
                  builder: (context, s) => IconButton(
                    icon: Icon(
                      s.themeMode == ThemeMode.dark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      color: _isDark ? Colors.white : const Color(0xFF374151),
                    ),
                    onPressed: () => context.read<ThemeBloc>().add(ToggleThemeEvent()),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,
      body: SafeArea(
        child: BlocConsumer<AttendanceDeviceBloc, AttendanceDeviceState>(
          listener: (context, state) {
            if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
              _showSnack(state.errorMessage!, isError: true);
            } else if (state.successMessage != null && state.successMessage!.isNotEmpty) {
              _showSnack(state.successMessage!, isError: false);
            }

            // Auto Scroll to Results Section when data finishes loading
            if (state.status == AttendanceDeviceStatusState.loaded && state.registerRows.isNotEmpty) {
              _scrollToResults();
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                // Top Header Action Bar
                _buildHeaderActionBar(state),
                Divider(height: 1, color: _border),

                // Main View Body
                Expanded(
                  child: _activeViewTab == 0
                      ? _buildAttendanceRegisterView(state)
                      : _buildApiLogsView(state),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─── HEADER ACTION BAR ([👥 Employee Mapping] [⏰ Assign Shift] [⚙️ Device Settings] [📋 API Logs]) ───

  Widget _buildHeaderActionBar(AttendanceDeviceState state) {
    return Container(
      color: _cardBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => _openEmployeeMappingDialog(state),
              style: OutlinedButton.styleFrom(
                foregroundColor: _textPrimary,
                side: BorderSide(color: _border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: const Icon(Icons.people_alt_outlined, size: 16, color: Color(0xFF3B82F6)),
              label: const Text('Employee Mapping', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            // Temporarily hidden Assign Shifts feature (retained for future re-enabling)
            /*
            OutlinedButton.icon(
              onPressed: () => _openAssignShiftDialog(state),
              style: OutlinedButton.styleFrom(
                foregroundColor: _textPrimary,
                side: BorderSide(color: _border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: const Icon(Icons.access_time_filled_rounded, size: 16, color: Color(0xFF8B5CF6)),
              label: const Text('Assign Shifts', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            */
            OutlinedButton.icon(
              onPressed: () => _openDeviceSettingsDialog(state),
              style: OutlinedButton.styleFrom(
                foregroundColor: _textPrimary,
                side: BorderSide(color: _border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: const Icon(Icons.settings_outlined, size: 16, color: Color(0xFF10B981)),
              label: const Text('Device Settings', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () {
                setState(() => _activeViewTab = _activeViewTab == 0 ? 1 : 0);
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: _activeViewTab == 1 ? const Color(0xFF3B82F6).withValues(alpha: 0.1) : null,
                foregroundColor: _activeViewTab == 1 ? const Color(0xFF3B82F6) : _textPrimary,
                side: BorderSide(color: _activeViewTab == 1 ? const Color(0xFF3B82F6) : _border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: Icon(
                _activeViewTab == 1 ? Icons.arrow_back_rounded : Icons.receipt_long_rounded,
                size: 16,
                color: _activeViewTab == 1 ? const Color(0xFF3B82F6) : const Color(0xFF8B5CF6),
              ),
              label: Text(
                _activeViewTab == 1 ? 'Back to Register' : 'API Logs',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── VIEW 1: ATTENDANCE REGISTER (Screenshot 3 Matching Layout) ────────────

  Widget _buildAttendanceRegisterView(AttendanceDeviceState state) {
    final isLoading = state.status == AttendanceDeviceStatusState.loading;
    final rows = state.registerRows;
    final snapshot = state.snapshot ?? AttendanceRegisterService.instance.computeSnapshot(rows: rows, targetDate: _snapshotDate);

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. DATA SOURCE & DATE RANGE FILTER BAR
          _buildFilterControlCard(state, isLoading),
          const SizedBox(height: 14),

          // 2. ATTENDANCE SNAPSHOT SECTION
          _buildAttendanceSnapshotSection(snapshot),
          const SizedBox(height: 16),

          // 3. BIOMETRIC ATTENDANCE REGISTER MATRIX / LIST
          Container(
            key: _matrixResultsKey,
            child: _buildAttendanceRegisterMatrix(rows, isLoading),
          ),
        ],
      ),
    );
  }

  // ─── 1. FILTER CONTROL CARD & EXPORT ACTIONS ────────────────────────────────

  Widget _buildFilterControlCard(AttendanceDeviceState state, bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Data Source Dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DATA SOURCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _textMuted, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: _isDark ? const Color(0xFF1E2E42) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _dataSource,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textPrimary),
                        dropdownColor: _cardBg,
                        items: ['Cloud Database (Sync Agent)', 'Biometric Device Direct', 'All Sources'].map((s) {
                          return DropdownMenuItem(value: s, child: Text(s));
                        }).toList(),
                        onChanged: (v) => setState(() => _dataSource = v!),
                      ),
                    ),
                  ),
                ],
              ),

              // FROM Date (Defaults to null: "Select Date")
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FROM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _textMuted, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: _pickFromDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: _fromDate == null
                            ? const Color(0xFF3B82F6).withValues(alpha: 0.08)
                            : (_isDark ? const Color(0xFF1E2E42) : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _fromDate == null ? const Color(0xFF3B82F6) : _border,
                          width: _fromDate == null ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_month_outlined,
                              size: 14, color: _fromDate == null ? const Color(0xFF3B82F6) : _textMuted),
                          const SizedBox(width: 6),
                          Text(
                            _fromDate == null ? 'Select Date' : DateFormat('dd-MM-yyyy').format(_fromDate!),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _fromDate == null ? const Color(0xFF3B82F6) : _textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // TO Date (Defaults to Today)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _textMuted, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: _pickToDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: _isDark ? const Color(0xFF1E2E42) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_month_outlined, size: 14, color: _textMuted),
                          const SizedBox(width: 6),
                          Text(DateFormat('dd-MM-yyyy').format(_toDate),
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textPrimary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Fetch Attendance Button
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : _onFetchAttendance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  icon: isLoading
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.cloud_download_outlined, size: 16),
                  label: const Text('Fetch Attendance', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),

              // Export Excel / CSV Button
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: OutlinedButton.icon(
                  onPressed: state.registerRows.isEmpty
                      ? null
                      : () => AttendanceExportService.instance.exportToExcelCsv(
                            rows: state.registerRows,
                            startDate: _fromDate,
                            endDate: _toDate,
                          ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF10B981),
                    side: const BorderSide(color: Color(0xFF10B981)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  icon: const Icon(Icons.table_chart_outlined, size: 16),
                  label: const Text('Export Sheet', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),

              // Export PDF Button
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: OutlinedButton.icon(
                  onPressed: state.registerRows.isEmpty
                      ? null
                      : () => AttendanceExportService.instance.exportToPdf(
                            rows: state.registerRows,
                            startDate: _fromDate,
                            endDate: _toDate,
                          ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                  label: const Text('Export PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(color: _border, height: 1),
          const SizedBox(height: 10),

          // Legend Bar (Responsive Horizontal Scroll)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _legendDot(const Color(0xFF10B981), 'Present'),
                const SizedBox(width: 12),
                _legendDot(const Color(0xFFF59E0B), 'Late (Grace 15m)'),
                const SizedBox(width: 12),
                _legendDot(const Color(0xFFEF4444), 'Absent'),
                const SizedBox(width: 12),
                _legendDot(const Color(0xFF3B82F6), 'WFH'),
                const SizedBox(width: 16),
                Text('Req. 9 hrs / day', style: TextStyle(fontSize: 11, color: _textMuted, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: _textSecondary, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ─── 2. ATTENDANCE SNAPSHOT SECTION ────────────────────────────────────────

  Widget _buildAttendanceSnapshotSection(AttendanceSnapshotData snapshot) {
    final dateStr = DateFormat('EEEE, MMM d, yyyy').format(_snapshotDate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ATTENDANCE SNAPSHOT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _textMuted, letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Text(dateStr, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _textPrimary)),
                ],
              ),
              const Spacer(),
              InkWell(
                onTap: _pickSnapshotDate,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isDark ? const Color(0xFF1E2E42) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: [
                      Text('Select Date: ${DateFormat("MMM d").format(_snapshotDate)}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _textPrimary)),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down_rounded, size: 16, color: _textMuted),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3 Snapshot Cards (Present, Absent, Work From Home)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              return Flex(
                direction: isWide ? Axis.horizontal : Axis.vertical,
                children: [
                  Expanded(
                    flex: isWide ? 1 : 0,
                    child: _snapshotCard(
                      title: 'Present (${snapshot.presentCount})',
                      color: const Color(0xFF10B981),
                      items: snapshot.presentList,
                      emptyMessage: 'No employees checked in',
                    ),
                  ),
                  SizedBox(width: isWide ? 10 : 0, height: isWide ? 0 : 10),
                  Expanded(
                    flex: isWide ? 1 : 0,
                    child: _snapshotCard(
                      title: 'Absent (${snapshot.absentCount})',
                      color: const Color(0xFFEF4444),
                      items: snapshot.absentList,
                      emptyMessage: 'All employees present today',
                    ),
                  ),
                  SizedBox(width: isWide ? 10 : 0, height: isWide ? 0 : 10),
                  Expanded(
                    flex: isWide ? 1 : 0,
                    child: _snapshotCard(
                      title: 'Work From Home (${snapshot.wfhCount})',
                      color: const Color(0xFF3B82F6),
                      items: snapshot.wfhList,
                      emptyMessage: 'No one working from home',
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _snapshotCard({
    required String title,
    required Color color,
    required List<SnapshotEmployeeItem> items,
    required String emptyMessage,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 120, maxHeight: 180),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(emptyMessage,
                        style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: _textMuted)),
                  )
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final item = items[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _textPrimary),
                              ),
                            ),
                            Text('ID: ${item.displayId}',
                                style: TextStyle(fontSize: 10, color: _textMuted)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ─── 3. BIOMETRIC ATTENDANCE REGISTER MATRIX / LIST ───────────────────────

  Widget _buildAttendanceRegisterMatrix(List<EmployeeAttendanceSummaryRow> rows, bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('BIOMETRIC ATTENDANCE REGISTER',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _textPrimary, letterSpacing: 0.5)),
              const Spacer(),
              Text('${rows.length} employees', style: TextStyle(fontSize: 11, color: _textMuted)),
            ],
          ),
          const SizedBox(height: 12),

          // Search Field
          TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            style: TextStyle(color: _textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Quick Search employee by name or ID…',
              hintStyle: TextStyle(color: _textMuted, fontSize: 12),
              prefixIcon: Icon(Icons.search_rounded, size: 18, color: _textMuted),
              filled: true,
              fillColor: _isDark ? const Color(0xFF1E2E42) : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 14),

          // Register Matrix Rows
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_fromDate == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    const Icon(Icons.touch_app_rounded, size: 36, color: Color(0xFF0EA5E9)),
                    const SizedBox(height: 8),
                    Text('Select "FROM" date above and click "Fetch Attendance"',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textPrimary)),
                    const SizedBox(height: 4),
                    Text('Choose your date range to generate attendance records.',
                        style: TextStyle(fontSize: 11, color: _textMuted)),
                  ],
                ),
              ),
            )
          else if (rows.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('No attendance records found for selected filter',
                    style: TextStyle(fontSize: 13, color: _textMuted)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rows.length,
              separatorBuilder: (_, __) => Divider(color: _border, height: 16),
              itemBuilder: (_, i) {
                final empRow = rows[i];
                return _buildEmployeeRegisterRow(empRow, i + 1);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmployeeRegisterRow(EmployeeAttendanceSummaryRow empRow, int index) {
    final start = _fromDate ?? DateTime.now();
    final end = _toDate;

    // Generate exact list of DateTimes within selected From Date to To Date range
    final List<DateTime> displayDates = [];
    DateTime cur = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);

    while (!cur.isAfter(last)) {
      displayDates.add(cur);
      cur = cur.add(const Duration(days: 1));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Employee Header Line with Shift Badge
        Row(
          children: [
            Text('#$index', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _textMuted)),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.15),
              child: Text(
                empRow.employeeName.isNotEmpty ? empRow.employeeName[0].toUpperCase() : 'E',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF3B82F6)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(empRow.employeeName,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _textPrimary)),
                  Text('ID: ${empRow.employeeCode}  •  Shift: ${empRow.shift.shiftName}',
                      style: TextStyle(fontSize: 10, color: _textMuted, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Days Grid Pill Row (Filtered to Selected Date Range)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: displayDates.map((date) {
              final dayNum = date.day;
              final rec = empRow.dailyRecords[dayNum];
              final dayName = DateFormat('EEE').format(date).toUpperCase().substring(0, 3);

              final status = rec?.status ?? 'A';
              final color = rec?.statusColor ?? const Color(0xFFEF4444);

              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: () => _showDayDetailBottomSheet(empRow, date, rec, empRow.shift),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 44,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Text('$dayNum', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _textPrimary)),
                        Text(dayName, style: TextStyle(fontSize: 8, color: _textMuted)),
                        const SizedBox(height: 4),
                        Text(
                          status,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color),
                        ),
                        if (rec?.checkIn != null && status != 'A' && status != 'WFH')
                          Text(rec!.checkIn!,
                              style: TextStyle(fontSize: 7, color: _textMuted, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showDayDetailBottomSheet(EmployeeAttendanceSummaryRow empRow, DateTime date, AttendanceDailyRecord? rec, EmployeeShift shift) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) {
        final dateStr = DateFormat('EEEE, d MMMM yyyy').format(date);
        final color = rec?.statusColor ?? const Color(0xFFEF4444);
        final lateThresholdStr = DateFormat('hh:mm a').format(shift.lateThreshold(date));
        final isWfh = rec?.status == 'WFH';

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Text(rec?.status ?? 'A', style: TextStyle(fontWeight: FontWeight.w900, color: color)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(empRow.employeeName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _textPrimary)),
                        Text(dateStr, style: TextStyle(fontSize: 12, color: _textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(color: _border),
              const SizedBox(height: 10),
              _detailRow('Assigned Shift', shift.shiftName),
              _detailRow('Late Threshold (15m Grace)', 'Late after $lateThresholdStr'),
              _detailRow('Status', rec?.statusLabel ?? 'Absent', color: color),
              _detailRow('Check-in Time', rec?.checkIn ?? 'Not Recorded'),
              _detailRow('Check-out Time', rec?.checkOut ?? 'Not Recorded'),
              _detailRow('Total Work Duration', rec?.formattedWorkHours ?? '0.0 hrs'),
              _detailRow('Deficit / Remaining (of 9 hrs)', rec?.formattedRemainingHours ?? '9.0 hrs', color: const Color(0xFFF59E0B)),
              _detailRow('Overtime Duration', rec?.formattedOvertimeHours ?? '0.0 hrs', color: const Color(0xFF10B981)),
              const SizedBox(height: 16),

              // Action button to Toggle/Mark WFH
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<AttendanceDeviceBloc>().add(
                          MarkWorkFromHomeEvent(
                            employeeId: empRow.employeeId,
                            date: date,
                            isWfh: !isWfh,
                          ),
                        );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isWfh ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: Icon(isWfh ? Icons.close_rounded : Icons.home_work_rounded, size: 18),
                  label: Text(
                    isWfh ? 'Remove WFH Mark' : 'Mark as Work From Home (WFH)',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: _textSecondary)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color ?? _textPrimary)),
        ],
      ),
    );
  }

  // ─── VIEW 2: API TROUBLESHOOTING LOGS ──────────────────────────────────────

  Widget _buildApiLogsView(AttendanceDeviceState state) {
    final logs = state.syncLogs;

    return Column(
      children: [
        Container(
          color: _cardBg,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Text('SOAP API Troubleshooting Logs (${logs.length})',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textPrimary)),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: _textSecondary),
                onPressed: () {
                  context.read<AttendanceDeviceBloc>().add(LoadDeviceSyncLogsEvent());
                },
              ),
            ],
          ),
        ),
        Divider(height: 1, color: _border),
        Expanded(
          child: logs.isEmpty
              ? Center(
                  child: Text('No API logs available', style: TextStyle(color: _textMuted, fontSize: 13)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final log = logs[i];
                    final isSuccess = log.status == 'success';
                    final color = isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444);

                    return ExpansionTile(
                      backgroundColor: _cardBg,
                      collapsedBackgroundColor: _cardBg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: _border)),
                      collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: _border)),
                      leading: Icon(isSuccess ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded, color: color),
                      title: Text('${log.action} — ${log.status.toUpperCase()}',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textPrimary)),
                      subtitle: Text(DateFormat('d MMM yyyy, h:mm:ss a').format(log.createdAt),
                          style: TextStyle(fontSize: 11, color: _textMuted)),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('SOAP REQUEST PAYLOAD:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF3B82F6))),
                              const SizedBox(height: 4),
                              _codeBlock(log.requestPayload),
                              const SizedBox(height: 10),
                              const Text('SOAP RESPONSE PAYLOAD:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                              const SizedBox(height: 4),
                              _codeBlock(log.responsePayload),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _codeBlock(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SelectableText(
            text,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          ),
        ),
      );
}

// ─── DIALOG 1: EMPLOYEE MAPPING DIALOG ───────────────────────────────────────

class _EmployeeMappingDialog extends StatefulWidget {
  final List<AttendanceDevice> devices;
  final Function(AttendanceDevice device, String empId, String empName, String empCode, String cardNo, String cmdId) onSync;

  const _EmployeeMappingDialog({
    required this.devices,
    required this.onSync,
  });

  @override
  State<_EmployeeMappingDialog> createState() => _EmployeeMappingDialogState();
}

class _EmployeeMappingDialogState extends State<_EmployeeMappingDialog> {
  AttendanceDevice? _selectedDevice;
  Map<String, dynamic>? _selectedEmployee;
  List<Map<String, dynamic>> _employees = [];
  bool _isLoading = false;

  final _empCodeCtrl = TextEditingController();
  final _cardNoCtrl  = TextEditingController();
  final _cmdIdCtrl   = TextEditingController();

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _cardBg => Theme.of(context).colorScheme.surface;
  Color get _border => AppTheme.borderOf(context);
  Color get _textPrimary => AppTheme.textPrimaryOf(context);
  Color get _textSecondary => AppTheme.textSecondaryOf(context);
  Color get _textMuted => AppTheme.textMutedOf(context);

  @override
  void initState() {
    super.initState();
    if (widget.devices.isNotEmpty) {
      _selectedDevice = widget.devices.first;
    }
    _cmdIdCtrl.text = 'CMD_${DateTime.now().millisecondsSinceEpoch}';
    _loadEmployees();
  }

  @override
  void dispose() {
    _empCodeCtrl.dispose();
    _cardNoCtrl.dispose();
    _cmdIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);
    try {
      final res = await SupabaseService.client
          .from('profiles')
          .select('id, full_name, email')
          .order('full_name', ascending: true);
      final list = res as List;
      setState(() {
        _employees = list.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onEmployeeSelected(Map<String, dynamic>? emp) {
    setState(() {
      _selectedEmployee = emp;
      if (emp != null) {
        final idStr = emp['id']?.toString() ?? '';
        final code = idStr.length >= 6 ? idStr.substring(0, 6).toUpperCase() : 'EMP101';
        _empCodeCtrl.text = code;
        _cardNoCtrl.text  = code;
      }
    });
  }

  void _submit() {
    if (_selectedEmployee == null || _selectedDevice == null) return;

    widget.onSync(
      _selectedDevice!,
      _selectedEmployee!['id'].toString(),
      _selectedEmployee!['full_name']?.toString() ?? 'Employee',
      _empCodeCtrl.text.trim().isEmpty ? 'EMP101' : _empCodeCtrl.text.trim(),
      _cardNoCtrl.text.trim().isEmpty ? 'EMP101' : _cardNoCtrl.text.trim(),
      _cmdIdCtrl.text.trim().isEmpty ? 'CMD_${DateTime.now().millisecondsSinceEpoch}' : _cmdIdCtrl.text.trim(),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
              child: Row(
                children: [
                  const Icon(Icons.people_alt_rounded, color: Color(0xFF3B82F6), size: 20),
                  const SizedBox(width: 10),
                  Text('Employee Device Mapping', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _textPrimary)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close_rounded, color: _textSecondary)),
                ],
              ),
            ),
            Divider(height: 1, color: _border),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select Attendance Device *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _textSecondary)),
                    const SizedBox(height: 4),
                    Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: _isDark ? const Color(0xFF1E2E42) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<AttendanceDevice>(
                          value: _selectedDevice,
                          isExpanded: true,
                          dropdownColor: _cardBg,
                          items: widget.devices.map((d) => DropdownMenuItem(
                            value: d,
                            child: Text('${d.deviceName} (SN: ${d.serialNumber})', style: TextStyle(fontSize: 13, color: _textPrimary)),
                          )).toList(),
                          onChanged: (d) => setState(() => _selectedDevice = d),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Select Employee *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _textSecondary)),
                    const SizedBox(height: 4),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: _isDark ? const Color(0xFF1E2E42) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Map<String, dynamic>>(
                            value: _selectedEmployee,
                            hint: Text('Select an employee profile', style: TextStyle(fontSize: 13, color: _textMuted)),
                            isExpanded: true,
                            dropdownColor: _cardBg,
                            items: _employees.map((e) => DropdownMenuItem(
                              value: e,
                              child: Text('${e["full_name"] ?? "Employee"} (${e["email"] ?? ""})', style: TextStyle(fontSize: 13, color: _textPrimary)),
                            )).toList(),
                            onChanged: _onEmployeeSelected,
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _field('Employee Code *', _empCodeCtrl, 'EMP101')),
                        const SizedBox(width: 10),
                        Expanded(child: _field('Card Number', _cardNoCtrl, 'Card No')),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _field('Command ID', _cmdIdCtrl, 'CMD_12345678'),
                    const SizedBox(height: 16),
                    Text('Device Operations (eTimeTrackLite SOAP Web API)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _textSecondary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: (_selectedEmployee == null || _selectedDevice == null)
                              ? null
                              : () {
                                  context.read<AttendanceDeviceBloc>().add(
                                        BlockUnblockDeviceUserEvent(
                                          device: _selectedDevice!,
                                          employeeCode: _empCodeCtrl.text.trim().isEmpty ? 'EMP101' : _empCodeCtrl.text.trim(),
                                          employeeName: _selectedEmployee!['full_name']?.toString() ?? 'Employee',
                                          isBlock: true,
                                          commandId: _cmdIdCtrl.text.trim(),
                                        ),
                                      );
                                  Navigator.pop(context);
                                },
                          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFF59E0B)),
                          icon: const Icon(Icons.block_rounded, size: 14),
                          label: const Text('Block User', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                        OutlinedButton.icon(
                          onPressed: (_selectedEmployee == null || _selectedDevice == null)
                              ? null
                              : () {
                                  context.read<AttendanceDeviceBloc>().add(
                                        BlockUnblockDeviceUserEvent(
                                          device: _selectedDevice!,
                                          employeeCode: _empCodeCtrl.text.trim().isEmpty ? 'EMP101' : _empCodeCtrl.text.trim(),
                                          employeeName: _selectedEmployee!['full_name']?.toString() ?? 'Employee',
                                          isBlock: false,
                                          commandId: _cmdIdCtrl.text.trim(),
                                        ),
                                      );
                                  Navigator.pop(context);
                                },
                          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF10B981)),
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
                          label: const Text('Unblock User', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                        OutlinedButton.icon(
                          onPressed: (_selectedEmployee == null || _selectedDevice == null)
                              ? null
                              : () {
                                  context.read<AttendanceDeviceBloc>().add(
                                        DeleteDeviceUserEvent(
                                          device: _selectedDevice!,
                                          employeeCode: _empCodeCtrl.text.trim().isEmpty ? 'EMP101' : _empCodeCtrl.text.trim(),
                                          commandId: _cmdIdCtrl.text.trim(),
                                        ),
                                      );
                                  Navigator.pop(context);
                                },
                          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
                          icon: const Icon(Icons.delete_outline_rounded, size: 14),
                          label: const Text('Delete User', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                        OutlinedButton.icon(
                          onPressed: (_selectedDevice == null)
                              ? null
                              : () {
                                  context.read<AttendanceDeviceBloc>().add(
                                        CheckCommandStatusEvent(
                                          device: _selectedDevice!,
                                          commandId: _cmdIdCtrl.text.trim(),
                                        ),
                                      );
                                  Navigator.pop(context);
                                },
                          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF3B82F6)),
                          icon: const Icon(Icons.fact_check_outlined, size: 14),
                          label: const Text('Check Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: _border),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: (_selectedEmployee == null || _selectedDevice == null) ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                      label: const Text('Add Employee', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _textSecondary)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          style: TextStyle(color: _textPrimary, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _textMuted, fontSize: 12),
            filled: true,
            fillColor: _isDark ? const Color(0xFF1E2E42) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _border)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}

// ─── DIALOG 2: ASSIGN EMPLOYEE SHIFT DIALOG ───────────────────────────────

class _AssignShiftDialog extends StatefulWidget {
  final Function(String employeeId, String shiftId) onAssign;

  const _AssignShiftDialog({required this.onAssign});

  @override
  State<_AssignShiftDialog> createState() => _AssignShiftDialogState();
}

class _AssignShiftDialogState extends State<_AssignShiftDialog> {
  Map<String, dynamic>? _selectedEmp;
  EmployeeShift _selectedShift = EmployeeShift.defaultShifts.first;
  List<Map<String, dynamic>> _employees = [];
  bool _isLoading = false;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _cardBg => Theme.of(context).colorScheme.surface;
  Color get _border => AppTheme.borderOf(context);
  Color get _textPrimary => AppTheme.textPrimaryOf(context);
  Color get _textSecondary => AppTheme.textSecondaryOf(context);
  Color get _textMuted => AppTheme.textMutedOf(context);

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);
    try {
      final res = await SupabaseService.client
          .from('profiles')
          .select('id, full_name, email')
          .order('full_name', ascending: true);
      setState(() {
        _employees = (res as List).map((e) => Map<String, dynamic>.from(e)).toList();
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _submit() {
    if (_selectedEmp == null) return;
    widget.onAssign(_selectedEmp!['id'].toString(), _selectedShift.id);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
              child: Row(
                children: [
                  const Icon(Icons.access_time_filled_rounded, color: Color(0xFF8B5CF6), size: 20),
                  const SizedBox(width: 10),
                  Text('Assign Employee Shift', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _textPrimary)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close_rounded, color: _textSecondary)),
                ],
              ),
            ),
            Divider(height: 1, color: _border),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select Employee *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _textSecondary)),
                  const SizedBox(height: 4),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: _isDark ? const Color(0xFF1E2E42) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Map<String, dynamic>>(
                          value: _selectedEmp,
                          hint: Text('Select Employee', style: TextStyle(fontSize: 13, color: _textMuted)),
                          isExpanded: true,
                          dropdownColor: _cardBg,
                          items: _employees.map((e) => DropdownMenuItem(
                            value: e,
                            child: Text('${e["full_name"] ?? "Employee"} (${e["email"] ?? ""})', style: TextStyle(fontSize: 13, color: _textPrimary)),
                          )).toList(),
                          onChanged: (e) => setState(() => _selectedEmp = e),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text('Select Shift Timings *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _textSecondary)),
                  const SizedBox(height: 6),
                  Column(
                    children: EmployeeShift.defaultShifts.map((s) {
                      final isSelected = _selectedShift.id == s.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () => setState(() => _selectedShift = s),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF8B5CF6).withValues(alpha: 0.1)
                                  : (_isDark ? const Color(0xFF1E2E42) : const Color(0xFFF8FAFC)),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF8B5CF6) : _border,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                                  size: 18,
                                  color: isSelected ? const Color(0xFF8B5CF6) : _textMuted,
                                ),
                                const SizedBox(width: 10),
                                Text(s.shiftName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textPrimary)),
                                const Spacer(),
                                Text('Grace: 15m', style: TextStyle(fontSize: 10, color: _textMuted)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: _border),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _selectedEmp == null ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Assign Shift', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── DIALOG 3: DEVICE SETTINGS DIALOG ─────────────────────────────────────────

class _DeviceSettingsDialog extends StatefulWidget {
  final List<AttendanceDevice> devices;
  final Function(Map<String, dynamic> data) onAddDevice;
  final Function(String id) onDeleteDevice;
  final Function(String apiUrl, String apiKey) onTestConnection;

  const _DeviceSettingsDialog({
    required this.devices,
    required this.onAddDevice,
    required this.onDeleteDevice,
    required this.onTestConnection,
  });

  @override
  State<_DeviceSettingsDialog> createState() => _DeviceSettingsDialogState();
}

class _DeviceSettingsDialogState extends State<_DeviceSettingsDialog> {
  bool _showAddForm = false;
  final _nameCtrl = TextEditingController(text: 'eTimeTrackLite Device 1');
  final _snCtrl   = TextEditingController(text: 'SN85920311');
  final _urlCtrl  = TextEditingController(text: 'http://192.168.1.34:85/iclock/WebAPIService.asmx');
  final _keyCtrl  = TextEditingController(text: 'API_KEY_123');
  final _userCtrl = TextEditingController(text: 'admin');
  final _passCtrl = TextEditingController(text: 'admin123');

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _cardBg => Theme.of(context).colorScheme.surface;
  Color get _border => AppTheme.borderOf(context);
  Color get _textPrimary => AppTheme.textPrimaryOf(context);
  Color get _textSecondary => AppTheme.textSecondaryOf(context);
  Color get _textMuted => AppTheme.textMutedOf(context);

  @override
  void dispose() {
    for (final c in [_nameCtrl, _snCtrl, _urlCtrl, _keyCtrl, _userCtrl, _passCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _saveNewDevice() {
    if (_nameCtrl.text.isEmpty || _urlCtrl.text.isEmpty || _keyCtrl.text.isEmpty) return;
    widget.onAddDevice({
      'deviceName': _nameCtrl.text.trim(),
      'serialNumber': _snCtrl.text.trim(),
      'apiUrl': _urlCtrl.text.trim(),
      'apiKey': _keyCtrl.text.trim(),
      'username': _userCtrl.text.trim(),
      'password': _passCtrl.text.trim(),
    });
    setState(() => _showAddForm = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
              child: Row(
                children: [
                  const Icon(Icons.settings_outlined, color: Color(0xFF10B981), size: 20),
                  const SizedBox(width: 10),
                  Text('Device Settings & Configuration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _textPrimary)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close_rounded, color: _textSecondary)),
                ],
              ),
            ),
            Divider(height: 1, color: _border),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _showAddForm ? _buildAddDeviceForm() : _buildDeviceList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceList() {
    final devs = widget.devices;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Configured Biometric Devices (${devs.length})', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textPrimary)),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => setState(() => _showAddForm = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Device', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (devs.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text('No attendance devices configured yet.', style: TextStyle(color: _textMuted, fontSize: 13)),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: devs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final d = devs[i];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isDark ? const Color(0xFF1E2E42) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.developer_board_rounded, color: Color(0xFF10B981), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(d.deviceName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _textPrimary)),
                        ),
                        TextButton.icon(
                          onPressed: () => widget.onTestConnection(d.apiUrl, d.apiKey),
                          icon: const Icon(Icons.network_check_rounded, size: 14, color: Color(0xFF3B82F6)),
                          label: const Text('Test Connection', style: TextStyle(fontSize: 11, color: Color(0xFF3B82F6), fontWeight: FontWeight.w700)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                          onPressed: () => widget.onDeleteDevice(d.id),
                        ),
                      ],
                    ),
                    Text('SN: ${d.serialNumber}  |  URL: ${d.apiUrl}', style: TextStyle(fontSize: 11, color: _textMuted)),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildAddDeviceForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Add New Attendance Device', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _textPrimary)),
            const Spacer(),
            TextButton(
              onPressed: () => setState(() => _showAddForm = false),
              child: const Text('Back to List'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _f('Device Name *', _nameCtrl, 'e.g. Main Entrance Device'),
        const SizedBox(height: 10),
        _f('Serial Number *', _snCtrl, 'SN85920311'),
        const SizedBox(height: 10),
        _f('Web API URL *', _urlCtrl, 'http://192.168.1.34:85/iclock/WebAPIService.asmx'),
        const SizedBox(height: 10),
        _f('API Key *', _keyCtrl, 'API_KEY_123'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _f('UserName *', _userCtrl, 'admin')),
            const SizedBox(width: 10),
            Expanded(child: _f('UserPassword *', _passCtrl, '••••••', obscure: true)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveNewDevice,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Save Device', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _f(String label, TextEditingController ctrl, String hint, {bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _textSecondary)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          style: TextStyle(color: _textPrimary, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _textMuted, fontSize: 12),
            filled: true,
            fillColor: _isDark ? const Color(0xFF1E2E42) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _border)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}
